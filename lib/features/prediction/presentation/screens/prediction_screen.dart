import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
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
    } else {
      _fetchLastPrediction();
    }
  }

  Future<void> _fetchLastPrediction() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    // Simple fetch from service logic here if needed, or rely on _predict() trigger
  }

  Future<void> _predict() async {
    setState(() => _loading = true);
    try {
      // simulate backend call with answers
      final res = await _svc.predict({}); 
      if (mounted) setState(() { _result = res; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _ResultView(result: _result!, onRetry: () => setState(() => _result = null));

    return Scaffold(
      appBar: AppBar(title: const Text('Prédiction Hermona')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.magic_star, size: 80, color: AppTheme.primary).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text('Prête pour ton bilan ?', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 16),
              const Text(
                'Notre IA va analyser ton cycle, ton hygiène de vie et tes données pour prédire les risques d\'imperfections.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              GradientButton(
                text: 'Lancer l\'analyse IA',
                isLoading: _loading,
                onPressed: _predict,
              ),
            ],
          ),
        ),
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
    final theme = Theme.of(context);
    final color = result.riskLevel == RiskLevel.low ? AppColors.success 
                : result.riskLevel == RiskLevel.medium ? AppColors.warning 
                : AppColors.error;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analyse Hermona'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Routine'),
              Tab(text: 'À éviter'),
              Tab(text: 'Mode de vie'),
            ],
            labelColor: theme.colorScheme.primary,
            indicatorColor: theme.colorScheme.primary,
          ),
        ),
        body: TabBarView(
          children: [
            _buildMainTab(context, color),
            _buildAvoidTab(context),
            _buildLifestyleTab(context),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: onRetry,
          label: const Text('Nouvelle analyse'),
          icon: const Icon(Iconsax.refresh),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMainTab(BuildContext context, Color color) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Risk Card
        AppCard(
          color: color.withOpacity(0.05),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Risque aujourd\'hui', style: Theme.of(context).textTheme.headlineMedium),
                  SeverityBadge(
                    label: result.riskLevel == RiskLevel.low ? 'PRÉVENTION' 
                         : result.riskLevel == RiskLevel.medium ? 'ÉQUILIBRE' 
                         : 'PROTECTION', 
                    color: color
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CircularPercentIndicator(
                radius: 70.0,
                lineWidth: 12.0,
                percent: result.riskScore,
                center: Text('${(result.riskScore * 100).toInt()}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                progressColor: color,
                backgroundColor: color.withOpacity(0.1),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 1000,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InfoColumn(label: 'J+3', value: '${(result.riskJ3 * 100).toInt()}%', color: color),
                  _InfoColumn(label: 'Tendance', value: result.trend == TrendDirection.increasing ? '📈' : '📉', color: color),
                  _InfoColumn(label: 'Cycle', value: 'J${result.cycleDay}', color: AppColors.secondary),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 24),

        // SHAP Factors
        SectionTitle(title: 'Facteurs d\'influence (SHAP)', action: '', onAction: () {}),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: result.shapFactors.entries.map((e) => _ShapBar(label: e.key, value: e.value)).toList(),
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 24),

        // Hygiene Gauge
        SectionTitle(title: 'Score Hygiène', action: '', onAction: () {}),
        const SizedBox(height: 16),
        AppCard(
          child: LinearPercentIndicator(
            lineHeight: 12,
            percent: result.hygieneScore / 100,
            progressColor: AppColors.info,
            backgroundColor: AppColors.info.withOpacity(0.1),
            barRadius: const Radius.circular(10),
            padding: EdgeInsets.zero,
            leading: Text('${result.hygieneScore}', style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Text('100'),
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 24),

        // Recommended Routine
        SectionTitle(title: 'Ta Routine Recommandée', action: '', onAction: () {}),
        const SizedBox(height: 16),
        ...result.routine.map((r) => _TipItem(text: r, icon: Iconsax.magic_star, color: AppColors.success)).toList(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAvoidTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _stepTitle(context, 'À Éviter', 'Ces éléments pourraient aggraver l\'inflammation en phase ${result.cyclePhase}.'),
        const SizedBox(height: 16),
        ...result.toAvoid.map((a) => _TipItem(text: a, icon: Iconsax.close_circle, color: AppColors.error)).toList(),
      ],
    );
  }

  Widget _buildLifestyleTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _stepTitle(context, 'Mode de Vie', 'Conseils personnalisés basés sur tes facteurs SHAP.'),
        const SizedBox(height: 16),
        ...result.lifestyle.map((l) => _TipItem(text: l, icon: Iconsax.heart, color: AppColors.info)).toList(),
      ],
    );
  }

  Widget _stepTitle(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoColumn({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}

class _ShapBar extends StatelessWidget {
  final String label;
  final double value;
  const _ShapBar({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text('+${(value * 100).toInt()}%', style: const TextStyle(fontSize: 11, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 4),
          LinearPercentIndicator(
            lineHeight: 6,
            percent: value.clamp(0, 1),
            progressColor: AppColors.error.withOpacity(0.7),
            backgroundColor: AppColors.error.withOpacity(0.1),
            barRadius: const Radius.circular(5),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _TipItem({required this.text, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}