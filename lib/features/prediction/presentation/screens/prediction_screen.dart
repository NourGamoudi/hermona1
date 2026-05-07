import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/prediction_api_service.dart';
import '../../domain/entities/prediction_result.dart';

class PredictionScreen extends StatefulWidget {
  final PredictionResult? initialResult;
  const PredictionScreen({super.key, this.initialResult});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  bool _loading = false;
  PredictionResult? _result;
  final _svc = PredictionApiService();

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      _result = widget.initialResult;
    }
  }

  Future<void> _predict() async {
    setState(() { _loading = true; _result = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      final dailySnap = await FirebaseFirestore.instance
          .collection('daily_surveys')
          .where('userId', isEqualTo: uid)
          .get();

      Map<String, dynamic> answers = {};
      if (dailySnap.docs.isNotEmpty) {
        final docs = dailySnap.docs.toList();
        docs.sort((a, b) {
          DateTime dateA = a['date'] is Timestamp ? (a['date'] as Timestamp).toDate() : DateTime.tryParse(a['date'].toString()) ?? DateTime(2000);
          DateTime dateB = b['date'] is Timestamp ? (b['date'] as Timestamp).toDate() : DateTime.tryParse(b['date'].toString()) ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
        
        final d = docs.first.data();
        answers = {
          'stress': d['stress'] > 7 ? 'high' : d['stress'] > 4 ? 'medium' : 'low',
          'sleep': d['sleepDuration'] < 6 ? 'poor' : 'good',
          'diet': (d['food'] as List).contains('sucre') ? 'bad' : 'good',
          'hormonal_cycle': d['cyclePhase'],
          'hygieneScore': d['lifestyleScore'],
        };
      }

      final res = await _svc.predict(answers); 
      await _svc.saveResult(res, uid);

      if (mounted) setState(() { _result = res; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur IA : $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _ResultView(result: _result!, onRetry: () => setState(() => _result = null));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Bilan Prédictif')),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -100,
            right: -50,
            child: _Blob(size: 300, color: AppTheme.primary.withOpacity(0.05)),
          ),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _ScanIcon(),
                  const SizedBox(height: 32),
                  Text('Analyse Prédictive', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 12),
                  const Text(
                    'Prédit tes futurs risques d\'acné basés sur ton cycle, ton hygiène et tes habitudes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondaryDark, height: 1.5),
                  ),
                  const SizedBox(height: 48),
                  PrimaryButton(
                    label: 'LANCER L\'ANALYSE IA',
                    isLoading: _loading,
                    onTap: _predict,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final PredictionResult result;
  final VoidCallback onRetry;
  const _ResultView({required this.result, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final color = result.riskLevel == RiskLevel.low ? AppColors.success 
                : result.riskLevel == RiskLevel.medium ? AppColors.warning 
                : AppColors.error;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Rapport Hermona'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondaryDark,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                tabs: const [
                  Tab(text: 'ANALYSE'),
                  Tab(text: 'ROUTINE'),
                  Tab(text: 'LIFESTYLE'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _AnalysisTab(result: result, color: color),
            _RoutineTab(result: result),
            _LifestyleTab(result: result),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: onRetry,
          label: const Text('NOUVEAU SCAN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          icon: const Icon(Iconsax.refresh, size: 20),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  final PredictionResult result;
  final Color color;
  const _AnalysisTab({required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 160, 24, 100),
      children: [
        // Main Risk Card
        GlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Risque Estimé', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  StatusBadge(
                    text: result.riskLevel.name.toUpperCase(),
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CircularPercentIndicator(
                radius: 80.0,
                lineWidth: 14.0,
                percent: result.riskScore,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(result.riskScore * 100).toInt()}%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
                    const Text('INDICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ],
                ),
                progressColor: color,
                backgroundColor: color.withOpacity(0.1),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 1200,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InfoBox(label: 'Tendance', value: result.trend == TrendDirection.increasing ? 'EN HAUSSE' : 'STABLE', color: color),
                  _VerticalDivider(),
                  _InfoBox(label: 'Phase Cycle', value: result.cyclePhase.toUpperCase(), color: AppColors.secondary),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

        const SizedBox(height: 32),

        // SHAP Factors
        const SectionHeader(title: 'Facteurs d\'Influence'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: result.shapFactors.entries.map((e) => _ShapIndicator(label: e.key, value: e.value)).toList(),
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }
}

class _RoutineTab extends StatelessWidget {
  final PredictionResult result;
  const _RoutineTab({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 160, 24, 100),
      children: [
        const SectionHeader(title: 'Votre Routine sur-mesure'),
        const SizedBox(height: 12),
        ...result.routine.asMap().entries.map((e) => PremiumFadeIn(
          delay: e.key * 100,
          child: _TipCard(text: e.value, icon: Iconsax.magic_star, color: AppColors.primary),
        )),
        const SizedBox(height: 24),
        const SectionHeader(title: 'À Éviter'),
        ...result.toAvoid.asMap().entries.map((e) => PremiumFadeIn(
          delay: (e.key + 5) * 100,
          child: _TipCard(text: e.value, icon: Iconsax.close_circle, color: AppColors.error),
        )),
      ],
    );
  }
}

class _LifestyleTab extends StatelessWidget {
  final PredictionResult result;
  const _LifestyleTab({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 160, 24, 100),
      children: [
        const SectionHeader(title: 'Habitudes & Hygiène'),
        const SizedBox(height: 12),
        ...result.lifestyle.asMap().entries.map((e) => PremiumFadeIn(
          delay: e.key * 100,
          child: _TipCard(text: e.value, icon: Iconsax.heart5, color: AppColors.info),
        )),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// COMPONENTS
/// ─────────────────────────────────────────────────────────────────────────────

class _ScanIcon extends StatelessWidget {
  const _ScanIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Iconsax.magic_star, size: 80, color: AppColors.primary),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds).fadeIn(duration: 1.seconds).fadeOut(delay: 1.seconds),
        ],
      ),
    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut);
  }
}

class _InfoBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondaryDark, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1));
  }
}

class _ShapIndicator extends StatelessWidget {
  final String label;
  final double value;
  const _ShapIndicator({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text('+${(value * 100).toInt()}%', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 6,
            percent: value.clamp(0, 1),
            progressColor: AppColors.error,
            backgroundColor: AppColors.error.withOpacity(0.1),
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 1000,
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _TipCard({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])),
    );
  }
}
