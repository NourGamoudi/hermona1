import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/features/recommendation/domain/entities/recommendation_result.dart';
import 'package:acneia/core/localization/app_localizations.dart';

class MyRoutineScreen extends StatefulWidget {
  const MyRoutineScreen({super.key});

  @override
  State<MyRoutineScreen> createState() => _MyRoutineScreenState();
}

class _MyRoutineScreenState extends State<MyRoutineScreen>
    with SingleTickerProviderStateMixin {
  // Rebuild trigger
  late TabController _tab;

  RecommendationResult? _result;
  Map<String, dynamic>? _predictionData;
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
      if (mounted) {
        final l = AppLocalizations.of(context);
        setState(() {
          _error = l.translate('user_not_connected');
          _loading = false;
        });
      }
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
        if (mounted) {
          // Remove the error state and button, directly redirect to prediction to generate/show the routine
          context.go('/prediction');
        }
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
      if (mounted) {
        final l = AppLocalizations.of(context);
        setState(() {
          _error = '${l.translate('loading_error')}$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withAlpha(180),
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          AppLocalizations.of(context).translate('my_routine_title'),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
        ),
        centerTitle: true,
      ),
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
                : NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: kToolbarHeight + 40),
                              _buildScoreStats(),
                              _buildStrategySection(),
                            ],
                          ),
                        ),
                        SliverAppBar(
                          pinned: true,
                          floating: false,
                          automaticallyImplyLeading: false,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          toolbarHeight: 0,
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(50), // Exact height needed to avoid 5px overflow
                            child: ClipRRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  color: Colors.white.withAlpha(180),
                                  child: Transform.translate(
                                    offset: const Offset(0, -10),
                                    child: _buildTabBar(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ];
                    },
                    body: Column(
                      children: [
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
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            AppLocalizations.of(context).translate('medical_disclaimer'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMutedPink, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }


  Widget _buildScoreStats() {
    if (_result == null) return const SizedBox();
    final l = AppLocalizations.of(context);

    final factors = _predictionData?['shapFactors'] as Map?;
    String riskReason = l.translate('based_on_cycle_analysis');
    if (factors != null && factors.isNotEmpty) {
      final topFactor = factors.entries.first.key;
      riskReason = "${l.translate('top_factor_impact')}${l.translate(topFactor)}";
    }

    final int hScore = (_predictionData?['hygieneScore'] as num? ?? _result!.hygieneScore).toInt();
    String hygieneReason = hScore > 80 ? l.translate('routine_complete') : (hScore > 50 ? l.translate('good_habits_reinforce') : l.translate('improvement_points'));

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ScoreCard(
                  label: l.translate('hygiene'),
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
                  label: l.translate('risk_j3_label'),
                  value: (_predictionData?['riskLevel'] as String? ?? 'low') == 'high' ? l.translate('high').toUpperCase() : ((_predictionData?['riskLevel'] ?? 'medium') == 'medium' ? l.translate('medium').toUpperCase() : l.translate('low').toUpperCase()),
                  icon: Icons.warning_amber_rounded,
                  color: (_predictionData?['riskLevel'] ?? 'low') == 'high' 
                      ? AppColors.error 
                      : ((_predictionData?['riskLevel'] ?? 'low') == 'medium' ? AppColors.warning : AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TabBar(
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        indicatorSize: TabBarIndicatorSize.label,
        controller: _tab,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppColors.textMutedPink,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 4,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
        tabs: [
          Tab(text: l.translate('morning_short')),
          Tab(text: l.translate('evening_short')),
          Tab(text: l.translate('lifestyle_short')),
        ],
      ),
    );
  }

  /// Returns the display strategy string.
  /// NEVER recomputes from riskScore — always trusts the backend's
  /// probabilistic selection result stored in [_result.strategy].
  String _computeStrategy(AppLocalizations l) {
    final backendStrategy = _result?.strategy ?? '';
    if (backendStrategy.isEmpty || backendStrategy == 'SAFE MODE') {
      return l.translate('strategy_equilibrium'); // safe neutral default when no backend data
    }

    final s = backendStrategy.toUpperCase();
    if (s.contains('PROTECTION') || s.contains('REPAIR'))      return l.translate('strategy_protection');
    if (s.contains('EQUILIBRE')  || s.contains('BALANCE') ||
        s.contains('ÉQUILIBRE')) {
      return l.translate('strategy_equilibrium');
    }
    if (s.contains('PREVENTION') || s.contains('PRÉVENTION') ||
        s.contains('PREVENT')) {
      return l.translate('strategy_prevention');
    }
    return backendStrategy; // forward raw string for unknown strategies
  }

  Widget _buildStrategySection() {
    if (_result == null) return const SizedBox();
    final l = AppLocalizations.of(context);

    final strategy = _computeStrategy(l);
    final variation = _result!.variationIndex;

    final Color stratColor = strategy == l.translate('strategy_protection')
        ? AppColors.error
        : strategy == l.translate('strategy_equilibrium')
            ? AppColors.warning
            : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 0),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                  child: Icon(Icons.auto_awesome, color: stratColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.translate('adopted_strategy').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: stratColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strategy,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildError() {
    final l = AppLocalizations.of(context);
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
              label: l.translate('start_analysis_btn'),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        return PremiumFadeIn(
          delay: index * 100,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _RoutineStepCard(step: step, index: index), // Passing index
          ),
        );
      },
    );
  }
}

class _RoutineStepCard extends StatelessWidget {
  final RoutineStep step;
  final int index;

  const _RoutineStepCard({required this.step, required this.index});

  String _normalizeProductKey(String product) {
    final p = product.toLowerCase();
    if (p.contains('huile') || p.contains('baume') || p.contains('démaquillant')) return 'prod_makeup_remover';
    if (p.contains('nettoyant') || p.contains('gel')) return 'prod_cleanser';
    if (p.contains('hydratant') || p.contains('moisturizer') || (p.contains('crème') && !p.contains('nuit'))) return 'prod_moisturizer';
    if (p.contains('spf') || p.contains('solaire')) return 'prod_spf';
    if (p.contains('rétinol')) return 'prod_retinol';
    if (p.contains('sérum')) return 'prod_hydrating_serum';
    return product;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    
    // Logic to find the best explanation
    String? rationale;
    if (step.reason.isNotEmpty && step.reason != '...') {
      rationale = l.translate(step.reason);
    } else {
      // Fallback to our custom keys with normalization
      final normalizedKey = _normalizeProductKey(step.product);
      final whyKey = '${normalizedKey}_why';
      final translatedWhy = l.translate(whyKey);
      if (translatedWhy != whyKey) {
        rationale = translatedWhy;
      }
    }

    return GestureDetector(
      onTap: () => _showProductDetails(context, step, l, rationale, index),
      child: GlassCard(
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
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
                      l.translate(step.product).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      l.translate('step_label'),
                      style: const TextStyle(
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
            l.translate(step.instruction),
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
              runSpacing: 8,
              children: step.productExamples.take(2).map((e) => GestureDetector(
                onTap: () => _showSpecificProductDetails(context, e, _getProductImageUrl(step.product, [e])),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withAlpha(25)),
                  ),
                  child: Text(
                    e,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
          if (rationale != null && rationale.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(30)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.psychology_alt, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rationale,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  void _showProductDetails(BuildContext context, RoutineStep step, AppLocalizations l, String? rationale, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[350],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Text(
                    l.translate(step.product).toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${l.translate('step_label')} ${index + 1}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  // Instruction
                  _sectionTitle(l.translate('how_to_use')),
                  Text(
                    l.translate(step.instruction),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  // Examples
                  if (step.productExamples.isNotEmpty) ...[
                    _sectionTitle(l.translate('recommended_products')),
                    const SizedBox(height: 8),
                    ...step.productExamples.map((e) => InkWell(
                      onTap: () => _showSpecificProductDetails(context, e, _getProductImageUrl(step.product, [e])),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                            const SizedBox(width: 12),
                            Expanded(child: Text(e, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    )),
                  ],
                  const SizedBox(height: 24),
                  // Why this choice
                  if (rationale != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withAlpha(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology, color: AppColors.primary, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                l.translate('why_this_choice').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            rationale,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _getProductImageUrl(String product, List<String> examples) {
    final p = product.toLowerCase();
    final e = examples.isNotEmpty ? examples.first.toLowerCase() : '';
    debugPrint('DEBUG IMAGE: product=$p, first_example=$e');

    // Specific Brand Logic
    if (e.contains('la roche-posay') || e.contains('effaclar')) {
      if (p.contains('nettoyant') || p.contains('gel')) return 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&q=80&w=600'; // Existing blueish
      if (p.contains('hydratant') || p.contains('mat')) return 'https://images.unsplash.com/photo-1629732047847-50bad7558259?auto=format&fit=crop&q=80&w=600'; // Specific tube style
      return 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&q=80&w=600';
    }
    
    if (e.contains('cerave')) {
      return 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&q=80&w=600'; // White/Green pump style
    }

    if (e.contains('bioderma') || e.contains('sebium')) {
      return 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&q=80&w=600'; // Generic beauty
    }

    // Generic Category Logic
    if (p.contains('nettoyant') || p.contains('gel')) {
      return 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&q=80&w=600';
    }
    if (p.contains('hydratant') || p.contains('crème')) {
      return 'https://images.unsplash.com/photo-1612817288484-6f916006741a?auto=format&fit=crop&q=80&w=600';
    }
    if (p.contains('spf') || p.contains('solaire')) {
      return 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?auto=format&fit=crop&q=80&w=600';
    }
    if (p.contains('sérum')) {
      return 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&q=80&w=600';
    }
    if (p.contains('baume') || p.contains('démaquillant')) {
      return 'https://images.unsplash.com/photo-1631730450584-1f973ff3c393?auto=format&fit=crop&q=80&w=600';
    }
    return 'https://images.unsplash.com/photo-1556229167-da3ed2105a4d?auto=format&fit=crop&q=80&w=600';
  }

  Map<String, dynamic> _getProductMetadata(String name) {
    final lName = name.toLowerCase();
    
    String type = 'Soin cible';
    String role = 'Traitement';
    String skinType = 'Tous types de peau';
    String tips = 'Appliquer une noisette sur le visage';
    String priority = 'Recommandé ⭐⭐';
    String price = 'Budget moyen';

    if (lName.contains('gel moussant') || lName.contains('effaclar') || lName.contains('cleanance')) {
      type = 'Nettoyant Purifiant (Cleanser)';
      role = 'Contrôle du sébum et nettoyage en profondeur';
      skinType = 'Peau grasse, mixte, acnéique';
      tips = 'Faire mousser sur visage humide, masser 60s, puis rincer.';
      priority = 'Essentiel ⭐⭐⭐';
      price = 'Budget moyen';
    } else if (lName.contains('hydratant') || lName.contains('toleriane') || lName.contains('tolérance')) {
      type = 'Nettoyant Doux (Cleanser)';
      role = 'Nettoyage respectueux de la barrière cutanée';
      skinType = 'Peau sensible, sèche, fragilisée';
      tips = 'Masser doucement sur visage humide, rincer à l\'eau tiède.';
      priority = 'Essentiel ⭐⭐⭐';
      price = 'Budget moyen';
    } else if (lName.contains('vit c') || lName.contains('ampoule [c]')) {
      type = 'Sérum (Antioxydant)';
      role = 'Éclat du teint et protection contre les radicaux libres';
      skinType = 'Tous types de peau (sauf très sensible)';
      tips = 'Appliquer le matin avant la crème hydratante et le SPF.';
      priority = 'Optionnel ⭐';
      price = 'Budget élevé';
    } else if (lName.contains('niacinamide')) {
      type = 'Sérum (Régulateur)';
      role = 'Réduction des pores, contrôle du sébum et anti-rougeurs';
      skinType = 'Peau mixte, grasse, à imperfections';
      tips = 'Appliquer matin et/ou soir avant la crème hydratante.';
      priority = 'Recommandé ⭐⭐';
      price = (lName.contains('ordinary') || lName.contains('inkey')) ? 'Budget faible' : 'Budget moyen';
    } else if (lName.contains('rétinol') || lName.contains('retinol')) {
      type = 'Sérum (Renouvellement)';
      role = 'Anti-âge, anti-marques, accélération du renouvellement cellulaire';
      skinType = 'Peau mature, peau à marques résiduelles';
      tips = 'Appliquer uniquement le soir. Commencer 2x/semaine. SPF obligatoire le lendemain.';
      priority = 'Recommandé ⭐⭐';
      price = lName.contains('ordinary') ? 'Budget faible' : 'Budget moyen';
    } else if (lName.contains('bha') || lName.contains('salicylic')) {
      type = 'Exfoliant Chimique (Sérum/Lotion)';
      role = 'Désobstruction des pores, anti-points noirs, anti-inflammatoire';
      skinType = 'Peau grasse, sujette aux points noirs';
      tips = 'Appliquer 2 à 3 fois par semaine le soir. Ne pas mélanger avec le rétinol.';
      priority = 'Recommandé ⭐⭐';
      price = (lName.contains('ordinary') || lName.contains('inkey')) ? 'Budget faible' : 'Budget moyen';
    } else if (lName.contains('mat') || lName.contains('phytosolution') || lName.contains('sebiaclear')) {
      type = 'Crème de jour (Moisturizer)';
      role = 'Hydratation légère et contrôle de la brillance';
      skinType = 'Peau grasse, peau mixte';
      tips = 'Appliquer matin et soir sur le visage propre.';
      priority = 'Essentiel ⭐⭐⭐';
      price = 'Budget moyen';
    } else if (lName.contains('crème hydratante') || lName.contains('lipikar') || lName.contains('xeracalm')) {
      type = 'Crème riche (Moisturizer)';
      role = 'Hydratation intense et réparation barrière cutanée';
      skinType = 'Peau sèche, très sèche, sous traitement asséchant';
      tips = 'Appliquer généreusement matin et soir.';
      priority = 'Essentiel ⭐⭐⭐';
      price = 'Budget moyen';
    } else if (lName.contains('uvmune') || lName.contains('sun oil control') || lName.contains('uv-clear') || lName.contains('anthelios')) {
      type = 'Protection Solaire (Sunscreen)';
      role = 'Protection UV, prévention des marques hyperpigmentées';
      skinType = 'Tous types de peau';
      tips = 'Appliquer 2 doigts de produit le matin en fin de routine. Renouveler en cas d\'exposition directe.';
      priority = 'Essentiel ⭐⭐⭐';
      price = 'Budget moyen';
    } else if (lName.contains('take the day off') || lName.contains('squalane cleanser') || lName.contains('cleansing balm')) {
      type = 'Baume Démaquillant (Cleanser)';
      role = 'Démaquillage efficace, élimination du sébum et du SPF';
      skinType = 'Tous types de peau (Double nettoyage)';
      tips = 'Masser sur peau sèche pour dissoudre le maquillage, émulsionner à l\'eau puis rincer.';
      priority = 'Recommandé ⭐⭐';
      price = lName.contains('ordinary') ? 'Budget faible' : 'Budget moyen';
    } else if (lName.contains('baume b5') || lName.contains('cicalfate') || lName.contains('bariéderm')) {
      type = 'Baume Réparateur (Moisturizer)';
      role = 'Cicatrisation, apaisement intense, réparation barrière cutanée';
      skinType = 'Peau irritée, peau fragilisée (Post-traitement)';
      tips = 'Appliquer en couche épaisse sur les zones irritées le soir.';
      priority = 'Recommandé ⭐⭐';
      price = 'Budget moyen';
    }

    return {
      'name': name,
      'type': type,
      'role': role,
      'skinType': skinType,
      'tips': tips,
      'priority': priority,
      'price': price,
    };
  }

  void _showSpecificProductDetails(BuildContext context, String productName, String imageUrl) {
    final meta = _getProductMetadata(productName);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[350],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Text(
                    productName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        meta['type'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  _infoRow(Icons.api_rounded, 'Rôle du produit', meta['role'] as String),
                  _infoRow(Icons.face_retouching_natural, 'Type de peau', meta['skinType'] as String),
                  _infoRow(Icons.lightbulb_outline, 'Conseils d\'utilisation', meta['tips'] as String),
                  _infoRow(Icons.star_border, 'Niveau de priorité', meta['priority'] as String),
                  _infoRow(Icons.sell_outlined, 'Estimation de prix', meta['price'] as String),
                  
                  const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
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
                      AppLocalizations.of(context).translate(items[index]),
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
