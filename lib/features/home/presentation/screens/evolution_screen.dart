import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/features/profile/presentation/cubit/trends_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _SeverityPoint {
  final DateTime date;
  final double score;
  final String docId;
  _SeverityPoint({required this.date, required this.score, required this.docId});
}

class _RiskPoint {
  final DateTime date;
  final double score;
  _RiskPoint({required this.date, required this.score});
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class EvolutionScreen extends StatelessWidget {
  const EvolutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrendsCubit()..loadData(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Mon Évolution'),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/home');
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 18),
              ),
            ),
          ),
        ),
        body: BlocBuilder<TrendsCubit, TrendsState>(
          builder: (context, state) {
            if (state is TrendsLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is TrendsError) {
              return Center(child: Text(state.message));
            }
            if (state is TrendsLoaded) {
              final sPoints = state.detections.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final date = _parseDate(data['analyzedAt']);
                final score = (data['severityScore'] as num?)?.toDouble() ?? 0.0;
                return _SeverityPoint(date: date, score: score, docId: d.id);
              }).toList();

              final rPoints = state.predictions.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final date = _parseDate(data['predictedAt']);
                final score = (data['riskJ3'] as num?)?.toDouble() ?? 0.0;
                return _RiskPoint(date: date, score: score);
              }).toList();

              return _EvolutionBody(
                severityPoints: sPoints,
                riskPoints: rPoints,
                onRefresh: () async => context.read<TrendsCubit>().loadData(),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (val is String) return DateTime.tryParse(val) ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (val is Timestamp) return val.toDate();
    try { return (val as dynamic).toDate(); } catch (_) { return DateTime.fromMillisecondsSinceEpoch(0); }
  }
}

class _EvolutionBody extends StatelessWidget {
  final List<_SeverityPoint> severityPoints;
  final List<_RiskPoint> riskPoints;
  final Future<void> Function() onRefresh;

  const _EvolutionBody({
    required this.severityPoints,
    required this.riskPoints,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: -60, right: -60, child: _Blob(size: 220, color: AppTheme.primary.withValues(alpha: 0.07))),
        Positioned(bottom: 200, left: -60, child: _Blob(size: 200, color: AppColors.secondary.withValues(alpha: 0.06))),

        RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            children: [
              PremiumFadeIn(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Iconsax.chart_21, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Historique de votre peau', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text('${severityPoints.length} bilan(s) • ${riskPoints.length} suivi(s)',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              if (severityPoints.isNotEmpty && riskPoints.isNotEmpty)
                PremiumFadeIn(
                  delay: 50,
                  child: _ChartSection(
                    title: 'Comparaison Croisée',
                    subtitle: 'Corrélation entre votre risque et l\'état réel',
                    icon: Iconsax.status_up,
                    color: Colors.purple,
                    isEmpty: false,
                    emptyMessage: '',
                    chart: SizedBox(height: 200, child: _DualChart(sPoints: severityPoints, rPoints: riskPoints)),
                  ),
                ),
              const SizedBox(height: 24),

              PremiumFadeIn(
                delay: 100,
                child: _ChartSection(
                  title: 'Sévérité (Bilan Hebdo)',
                  subtitle: 'Évolution par analyse photo',
                  icon: Iconsax.scan,
                  color: AppColors.primary,
                  isEmpty: severityPoints.isEmpty,
                  emptyMessage: 'Aucune analyse photo.',
                  chart: severityPoints.isEmpty ? null : _IndividualChart(
                    spots: severityPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.score)).toList(),
                    color: AppColors.primary,
                    labels: severityPoints.map((p) => DateFormat('d/M', 'fr').format(p.date)).toList(),
                    onTap: (i) => _showSeverityDetail(context, severityPoints[i]),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              PremiumFadeIn(
                delay: 200,
                child: _ChartSection(
                  title: 'Risque (Suivi Quotidien)',
                  subtitle: 'Évolution selon vos réponses',
                  icon: Iconsax.status_up,
                  color: AppColors.error,
                  isEmpty: riskPoints.isEmpty,
                  emptyMessage: 'Aucun suivi quotidien.',
                  chart: riskPoints.isEmpty ? null : _IndividualChart(
                    spots: riskPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.score * 100)).toList(),
                    color: AppColors.error,
                    labels: riskPoints.map((p) => DateFormat('d/M', 'fr').format(p.date)).toList(),
                    onTap: (i) => _showRiskDetail(context, riskPoints[i]),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              const PremiumFadeIn(
                delay: 300,
                child: GlassCard(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('💡', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Appuyez sur un point pour voir le détail et les photos historiques.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSeverityDetail(BuildContext context, _SeverityPoint point) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    const Icon(Iconsax.scan, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Bilan Hebdo', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(DateFormat('d MMMM yyyy', 'fr').format(point.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  ]),
                  const SizedBox(height: 20),
                  Text('${point.score.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Text('SCORE DE SÉVÉRITÉ', style: TextStyle(fontSize: 10, letterSpacing: 1)),
                  const SizedBox(height: 20),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('detections').doc(point.docId).collection('media').doc('images').get(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
                      final urls = (snap.data?.data() as Map?)?['imageUrls'] as List?;
                      if (urls == null || urls.isEmpty) return const Text('Photo non disponible');
                      return ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(urls[0], height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.broken_image)));
                    },
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'FERMER', onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRiskDetail(BuildContext context, _RiskPoint point) {
    final color = point.score > 0.61 ? AppColors.error : (point.score > 0.48 ? AppColors.warning : AppColors.success);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(point.score * 100).toInt()}%', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: color)),
              const Text('RISQUE DE POUSSÉE', style: TextStyle(fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Text(DateFormat('EEEE d MMMM', 'fr').format(point.date), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              PrimaryButton(label: 'FERMER', onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DualChart extends StatelessWidget {
  final List<_SeverityPoint> sPoints;
  final List<_RiskPoint> rPoints;
  const _DualChart({required this.sPoints, required this.rPoints});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0, maxY: 100,
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(topTitles: AxisTitles(), rightTitles: AxisTitles(), bottomTitles: AxisTitles(), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30))),
        lineBarsData: [
          LineChartBarData(
            spots: sPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.score)).toList(),
            isCurved: true, color: AppColors.primary, barWidth: 3, dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: rPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.score * 100)).toList(),
            isCurved: true, color: AppColors.error, barWidth: 3, dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class _IndividualChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  final List<String> labels;
  final Function(int) onTap;

  const _IndividualChart({required this.spots, required this.color, required this.labels, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0, maxY: 100,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(), rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= labels.length) return const SizedBox();
            return Text(labels[i], style: const TextStyle(fontSize: 10, color: Colors.grey));
          })),
        ),
        lineTouchData: LineTouchData(touchCallback: (event, res) {
          if (event is FlTapUpEvent && res != null && res.lineBarSpots != null && res.lineBarSpots!.isNotEmpty) {
            onTap(res.lineBarSpots!.first.spotIndex);
          }
        }),
        lineBarsData: [
          LineChartBarData(
            spots: spots, isCurved: true, color: color, barWidth: 4, dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)])),
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title, subtitle, emptyMessage; final IconData icon; final Color color; final bool isEmpty; final Widget? chart;
  const _ChartSection({required this.title, required this.subtitle, required this.icon, required this.color, required this.isEmpty, required this.emptyMessage, this.chart});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))]),
        ]),
        const SizedBox(height: 20),
        isEmpty ? Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.grey, fontSize: 12))) : SizedBox(height: 180, child: chart),
      ]),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])));
  }
}
