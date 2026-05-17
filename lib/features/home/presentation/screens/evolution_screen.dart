import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:acneia/core/localization/app_localizations.dart';
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
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).translate('my_evolution')),
          backgroundColor: Colors.white.withAlpha(200), // Fond semi-transparent
          surfaceTintColor: Colors.transparent,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
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
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        Positioned(top: -60, right: -60, child: _Blob(size: 220, color: AppTheme.primary.withValues(alpha: 0.07))),
        Positioned(bottom: 200, left: -60, child: _Blob(size: 200, color: AppColors.secondary.withValues(alpha: 0.06))),

        RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
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
                            Text(l.translate('skin_history'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text('${severityPoints.length} ${l.translate('reports')} • ${riskPoints.length} ${l.translate('trackings')}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- MAIN SEVERITY CHART (Filtered: Latest vs ~1 Week ago) ---
              PremiumFadeIn(
                delay: 50,
                child: _ChartSection(
                  title: l.translate('severity_weekly'),
                  subtitle: l.translate('evolution_photo_analysis'),
                  icon: Iconsax.scan,
                  color: AppColors.primary,
                  isEmpty: severityPoints.isEmpty,
                  emptyMessage: l.translate('no_photo_analysis'),
                  chart: severityPoints.isEmpty ? null : _IndividualChart(
                    spots: _generateTimeSpots(_filterPointsForWeeklyComparison(_filterOnePointPerDay(severityPoints, (p) => p.date))),
                    color: AppColors.primary,
                    labels: _generateTimeLabels(context, _filterPointsForWeeklyComparison(_filterOnePointPerDay(severityPoints, (p) => p.date))),
                    onTap: (i) {
                      final filtered = _filterPointsForWeeklyComparison(_filterOnePointPerDay(severityPoints, (p) => p.date));
                      _showSeverityDetail(context, filtered[i]);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),


              PremiumFadeIn(
                delay: 200,
                child: _ChartSection(
                  title: l.translate('risk_daily_tracking'),
                  subtitle: l.translate('evolution_responses'),
                  icon: Iconsax.status_up,
                  color: AppColors.error,
                  isEmpty: riskPoints.isEmpty,
                  emptyMessage: l.translate('no_daily_tracking'),
                  chart: riskPoints.isEmpty ? null : _IndividualChart(
                    spots: _generateRiskTimeSpots(_filterOnePointPerDay(riskPoints, (p) => p.date)),
                    color: AppColors.error,
                    labels: _generateRiskTimeLabels(context, _filterOnePointPerDay(riskPoints, (p) => p.date)),
                    onTap: (i) => _showRiskDetail(context, _filterOnePointPerDay(riskPoints, (p) => p.date)[i]),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              PremiumFadeIn(
                delay: 300,
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.translate('tap_point_details'),
                          style: const TextStyle(fontSize: 12, height: 1.5),
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

  List<_SeverityPoint> _filterPointsForWeeklyComparison(List<_SeverityPoint> points) {
    if (points.length < 2) return points;
    
    final latest = points.last;
    final targetDate = latest.date.subtract(const Duration(days: 7));
    
    // Priority: find the point that is at least 6-8 days before latest
    for (int i = points.length - 2; i >= 0; i--) {
      final daysDiff = latest.date.difference(points[i].date).inDays;
      if (daysDiff >= 6) {
        return [points[i], latest];
      }
    }
    
    // Fallback: if no point is old enough, just show the earliest and latest to show max possible span
    return [points.first, latest];
  }

  List<T> _filterOnePointPerDay<T>(List<T> points, DateTime Function(T) dateExtractor) {
    if (points.isEmpty) return [];
    final Map<String, T> dailyMap = {};
    for (var p in points) {
      final date = dateExtractor(p);
      final key = DateFormat('yyyy-MM-dd').format(date);
      // We keep the latest one for each day (assuming they are in chronological order)
      dailyMap[key] = p;
    }
    return dailyMap.values.toList()..sort((a, b) => dateExtractor(a).compareTo(dateExtractor(b)));
  }

  List<FlSpot> _generateTimeSpots(List<_SeverityPoint> points) {
    if (points.isEmpty) return [];
    final firstDate = points.first.date;
    return points.map((p) {
      final days = p.date.difference(firstDate).inDays.toDouble();
      return FlSpot(days, p.score);
    }).toList();
  }

  Map<double, String> _generateTimeLabels(BuildContext context, List<_SeverityPoint> points) {
    final Map<double, String> labels = {};
    if (points.isEmpty) return labels;
    final firstDate = points.first.date;
    final locale = AppLocalizations.of(context).locale.languageCode;
    for (var p in points) {
      final days = p.date.difference(firstDate).inDays.toDouble();
      labels[days] = DateFormat('d/M', locale).format(p.date);
    }
    return labels;
  }

  List<FlSpot> _generateRiskTimeSpots(List<_RiskPoint> points) {
    if (points.isEmpty) return [];
    final firstDate = points.first.date;
    return points.map((p) {
      final days = p.date.difference(firstDate).inDays.toDouble();
      return FlSpot(days, p.score * 100);
    }).toList();
  }

  Map<double, String> _generateRiskTimeLabels(BuildContext context, List<_RiskPoint> points) {
    final Map<double, String> labels = {};
    if (points.isEmpty) return labels;
    final firstDate = points.first.date;
    final locale = AppLocalizations.of(context).locale.languageCode;
    for (var p in points) {
      final days = p.date.difference(firstDate).inDays.toDouble();
      labels[days] = DateFormat('d/M', locale).format(p.date);
    }
    return labels;
  }

  void _showSeverityDetail(BuildContext context, _SeverityPoint point) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withValues(alpha: 0.8) 
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -10,
                    right: -10,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 28),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      Text(l.translate('severity_score').toUpperCase(), 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2, color: Colors.grey)),
                      const SizedBox(height: 16),
                      
                      // GIANT SCORE
                      Text(
                        '${point.score.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: -2,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE d MMMM yyyy', l.locale.languageCode).format(point.date),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      
                      const SizedBox(height: 48),

                      // VIEW FULL ANALYSIS BUTTON
                      PrimaryButton(
                        label: l.translate('view_full_analysis').toUpperCase(),
                        onTap: () async {
                          Navigator.of(dialogCtx).pop();
                          // Try to fetch full data for navigation
                          final data = await _getRobustPhotoData(point.docId);
                          if (data != null && context.mounted) {
                            context.push('/detection/result', extra: data);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  String? _extractUrlFromData(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    // 1. Direct keys
    final keys = ['imageUrls', 'images', 'image_urls', 'imageUrl', 'image_url', 'photo', 'photoUrl'];
    for (var k in keys) {
      final val = data[k];
      if (val is List && val.isNotEmpty) return val[0].toString();
      if (val is String && val.isNotEmpty) return val;
    }
    
    // 2. Nested 'media' object
    if (data['media'] is Map) {
      final media = data['media'] as Map<String, dynamic>;
      for (var k in keys) {
        final val = media[k];
        if (val is List && val.isNotEmpty) return val[0].toString();
        if (val is String && val.isNotEmpty) return val;
      }
      // Check for 'full' or 'original' inside media
      if (media['full'] != null) return media['full'].toString();
      if (media['original'] != null) return media['original'].toString();
    }
    
    // 3. Recursive search (any long string starting with http or data:)
    for (var val in data.values) {
      if (val is String && val.length > 50 && (val.startsWith('http') || val.startsWith('data:image'))) return val;
      if (val is List && val.isNotEmpty && val[0] is String && val[0].toString().length > 50) {
        if (val[0].toString().startsWith('http') || val[0].toString().startsWith('data:image')) return val[0].toString();
      }
    }
    
    return null;
  }

  Future<Map<String, dynamic>?> _getRobustPhotoData(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('detections').doc(docId).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Check if main doc has images
      if (_extractUrlFromData(data) != null) return data;
      
      // Fallback to subcollection
      final subSnap = await doc.reference.collection('media').doc('images').get();
      if (subSnap.exists) {
        final subData = subSnap.data() as Map<String, dynamic>;
        if (_extractUrlFromData(subData) != null) {
          return {...data, ...subData}; // Merge for UI
        }
      }
      
      return data;
    } catch (e) {
      debugPrint("Error fetching robust photo data: $e");
    }
    return null;
  }

  void _showRiskDetail(BuildContext context, _RiskPoint point) {
    final color = point.score > 0.61 ? AppColors.error : (point.score > 0.48 ? AppColors.warning : AppColors.success);
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(point.score * 100).toInt()}%', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: color)),
              Text(AppLocalizations.of(context).translate('flare_risk'), style: const TextStyle(fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Text(DateFormat('EEEE d MMMM yyyy', AppLocalizations.of(context).locale.languageCode).format(point.date), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              PrimaryButton(label: AppLocalizations.of(context).translate('close'), onTap: () => Navigator.of(dialogCtx).pop()),
            ],
          ),
        ),
      ),
    );
  }
}


class _IndividualChart extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  final Map<double, String> labels;
  final Function(int) onTap;

  const _IndividualChart({required this.spots, required this.color, required this.labels, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) return const SizedBox();
    
    final minX = spots.first.x;
    final maxX = spots.last.x;

    return LineChart(
      LineChartData(
        minY: 0, maxY: 100,
        minX: minX - 0.5,
        maxX: maxX + 0.5,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
          getDrawingVerticalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.05), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(), rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            reservedSize: 22,
            interval: 1, // Ensure we check every X value for labels
            getTitlesWidget: (v, _) {
              // Exact match or very close to a data point
              for (var entry in labels.entries) {
                if ((entry.key - v).abs() < 0.1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(entry.value, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                  );
                }
              }
              return const SizedBox();
            }
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: 20,
            getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 9, color: Colors.grey)),
          )),
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
