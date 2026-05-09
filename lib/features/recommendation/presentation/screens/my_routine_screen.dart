import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/features/recommendation/domain/entities/recommendation_result.dart';

class MyRoutineScreen extends StatefulWidget {
  const MyRoutineScreen({super.key});

  @override
  State<MyRoutineScreen> createState() => _MyRoutineScreenState();
}

class _MyRoutineScreenState extends State<MyRoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  RecommendationResult? _result;
  Map<String, dynamic>? _predictionData; // Latest prediction scores
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadLatest();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime(2000);
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime(2000);
    return DateTime(2000);
  }

  Future<void> _loadLatest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (!mounted) return;

    if (uid == null) {
      setState(() {
        _error = 'Utilisateur non connecté.';
        _loading = false;
      });
      return;
    }

    try {
      // Load recommendation AND latest prediction in parallel
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('recommendations')
            .where('userId', isEqualTo: uid)
            .get(),
        FirebaseFirestore.instance
            .collection('predictions')
            .where('userId', isEqualTo: uid)
            .get(),
      ]);

      if (!mounted) return;

      final recSnap = results[0] as QuerySnapshot;
      final predSnap = results[1] as QuerySnapshot;

      // Extract latest recommendation (for routine steps)
      final docs = recSnap.docs.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final id = (data['id'] ?? '') as String;
        return !id.startsWith('fallback_');
      }).toList();

      if (docs.isEmpty) {
        setState(() {
          _error = 'Aucune routine disponible.\nFaites une analyse photo.';
          _loading = false;
        });
        return;
      }

      docs.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        final DateTime aTime = _parseDate(dataA['createdAt'] ?? dataA['analyzedAt']);
        final DateTime bTime = _parseDate(dataB['createdAt'] ?? dataB['analyzedAt']);
        return bTime.compareTo(aTime);
      });

      // Extract latest prediction (for scores: hygiene, risk)
      Map<String, dynamic>? latestPrediction;
      if (predSnap.docs.isNotEmpty) {
        final predDocs = predSnap.docs.toList();
        predDocs.sort((a, b) {
          final da = _parseDate((a.data() as Map<String, dynamic>)['predictedAt']);
          final db = _parseDate((b.data() as Map<String, dynamic>)['predictedAt']);
          return db.compareTo(da);
        });
        latestPrediction = predDocs.first.data() as Map<String, dynamic>;
      }

      setState(() {
        _result = RecommendationResult.fromJson(docs.first.data() as Map<String, dynamic>);
        _predictionData = latestPrediction;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement : $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgLight,
              AppColors.bgLight.withAlpha(204),
              AppColors.surfaceLight,
            ],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        _buildScoreStats(),
                        _buildStrategySection(),
                        const SizedBox(height: 10),
                        _buildTabBar(),
                        Expanded(
                          child: TabBarView(
                            controller: _tab,
                            children: [
                              _RoutineTab(
                                steps: _result!.morningRoutine,
                                isMorning: true,
                                result: _result!,
                              ),
                              _RoutineTab(
                                steps: _result!.eveningRoutine,
                                isMorning: false,
                                result: _result!,
                              ),
                              _LifestyleTab(result: _result!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          Text(
            'MA ROUTINE',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(width: 48), // Placeholder for balance
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildScoreStats() {
    if (_result == null) return const SizedBox();

    final factors = _predictionData?['shapFactors'] as Map?;
    String riskReason = "Basé sur votre cycle et analyse.";
    if (factors != null && factors.isNotEmpty) {
      final topFactor = factors.entries.first.key;
      riskReason = "Impact majeur : $topFactor";
    }

    final int hScore = (_predictionData?['hygieneScore'] as num? ?? _result!.hygieneScore).toInt();
    String hygieneReason = hScore > 80 ? "Routine très complète" : (hScore > 50 ? "Bons gestes à renforcer" : "Points d'amélioration détectés");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ScoreCard(
                  label: "Hygiène",
                  value: "$hScore%",
                  icon: Icons.clean_hands_outlined,
                  color: hScore > 70
                      ? AppColors.success
                      : (hScore > 40 ? AppColors.warning : AppColors.error),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ScoreCard(
                  label: "Risque",
                  value: (_predictionData?['riskLevel'] as String? ?? (
                    _result!.riskScore > 0.7 ? 'high' : (_result!.riskScore > 0.35 ? 'medium' : 'low')
                  )) == 'high' ? 'Haut' : ((_predictionData?['riskLevel'] ?? 'medium') == 'medium' ? 'Moyen' : 'Bas'),
                  icon: Icons.warning_amber_rounded,
                  color: (_predictionData?['riskScore'] as num? ?? _result!.riskScore) > 0.7 
                      ? AppColors.error 
                      : (_result!.riskScore > 0.35 ? AppColors.warning : AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  hygieneReason,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  riskReason,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(curve: Curves.easeOutBack);
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TabBar(
        controller: _tab,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppColors.textMutedPink,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 4,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
        tabs: const [
          Tab(text: 'MATIN'),
          Tab(text: 'SOIR'),
          Tab(text: 'VIE'),
        ],
      ),
    );
  }

  /// Returns the display strategy string.
  /// NEVER recomputes from riskScore — always trusts the backend's
  /// probabilistic selection result stored in [_result.strategy].
  String _computeStrategy() {
    final backendStrategy = _result?.strategy ?? '';
    if (backendStrategy.isEmpty || backendStrategy == 'SAFE MODE') {
      return 'ÉQUILIBRE'; // safe neutral default when no backend data
    }

    final s = backendStrategy.toUpperCase();
    if (s.contains('PROTECTION') || s.contains('REPAIR'))      return 'PROTECTION';
    if (s.contains('EQUILIBRE')  || s.contains('BALANCE') ||
        s.contains('ÉQUILIBRE'))                                return 'ÉQUILIBRE';
    if (s.contains('PREVENTION') || s.contains('PRÉVENTION') ||
        s.contains('PREVENT'))                                  return 'PRÉVENTION';
    return backendStrategy; // forward raw string for unknown strategies
  }

  Widget _buildStrategySection() {
    if (_result == null) return const SizedBox();

    final strategy = _computeStrategy();
    final altStrategy = _result!.alternativeStrategy.isNotEmpty
        ? _result!.alternativeStrategy
        : null;
    final variation = _result!.variationIndex;

    final Color stratColor = strategy == 'PROTECTION'
        ? AppColors.error
        : strategy == 'ÉQUILIBRE'
            ? AppColors.warning
            : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stratColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, color: stratColor, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "STRATÉGIE ADOPTÉE",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: stratColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strategy,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: stratColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Variation index badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'V$variation',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary.withAlpha(180),
                    ),
                  ),
                ),
              ],
            ),
            if (altStrategy != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.swap_horiz, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    'Alternative : ',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    altStrategy,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textMutedPink),
            ),
            const SizedBox(height: 30),
            PrimaryButton(
              label: "Lancer une analyse",
              onTap: () => context.go('/prediction'),
            )
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ScoreCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMutedPink,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineTab extends StatelessWidget {
  final List<RoutineStep> steps;
  final bool isMorning;
  final RecommendationResult result;

  const _RoutineTab({
    required this.steps,
    required this.isMorning,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        return PremiumFadeIn(
          delay: index * 100,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _RoutineStepCard(step: step),
          ),
        );
      },
    );
  }
}

class _RoutineStepCard extends StatelessWidget {
  final RoutineStep step;

  const _RoutineStepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step.step,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.product.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      "Étape",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMutedPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMutedPink.withAlpha(128)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            step.instruction,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textPrimaryLight,
            ),
          ),
          if (step.productExamples.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: step.productExamples.take(2).map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withAlpha(25)),
                ),
                child: Text(
                  e,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _LifestyleTab extends StatelessWidget {
  final RecommendationResult result;

  const _LifestyleTab({required this.result});

  @override
  Widget build(BuildContext context) {
    final items = [
      ...result.lifestyle,
      ...result.nutrition,
      ...result.habits,
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return PremiumFadeIn(
          delay: index * 50,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: 16,
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.secondary, size: 18),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      items[index],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
