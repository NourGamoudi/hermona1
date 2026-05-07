import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../cubit/trends_cubit.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  int _selectedDays = 365;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return BlocProvider(
      create: (context) => TrendsCubit()..loadData(),
      child: BlocBuilder<TrendsCubit, TrendsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l.translate('trends_title')),
              actions: [
                PopupMenuButton<int>(
                  icon: const Icon(Iconsax.filter),
                  tooltip: l.translate('trends_filter'),
                  onSelected: (val) => setState(() => _selectedDays = val),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 28, child: Text("4 semaines")),
                    const PopupMenuItem(value: 84, child: Text("12 semaines")),
                    const PopupMenuItem(value: 365, child: Text("1 an")),
                  ],
                ),
              ],
            ),
            body: state is TrendsLoading
                ? const Center(child: CircularProgressIndicator())
                : state is TrendsError
                    ? Center(child: Text(state.message))
                    : state is TrendsLoaded
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildChartCard(
                                  title: l.translate('acne_evolution'),
                                  subtitle: l.translate('acne_evolution_sub'),
                                  docs: state.detections,
                                  dateField: 'analyzedAt',
                                  valueField: 'severityScore',
                                  color: AppColors.severitySevere,
                                  icon: Iconsax.mask,
                                  emptyMsg: l.translate('not_enough_data'),
                                  isDetection: true,
                                ),
                                const SizedBox(height: 20),
                                _buildChartCard(
                                  title: l.translate('risk_evolution'),
                                  subtitle: l.translate('risk_evolution_sub'),
                                  docs: state.predictions,
                                  dateField: 'predictedAt',
                                  valueField: 'riskScore',
                                  color: AppTheme.primary,
                                  icon: Iconsax.chart_2,
                                  isPercentage: true,
                                  emptyMsg: l.translate('not_enough_data'),
                                ),
                                const SizedBox(height: 30),
                                _buildLegendCard(l),
                              ],
                            ),
                          )
                        : const SizedBox(),
          );
        },
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required List<QueryDocumentSnapshot> docs,
    required String dateField,
    required String valueField,
    required Color color,
    required IconData icon,
    required String emptyMsg,
    bool isPercentage = false,
    bool isDetection = false,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: Builder(builder: (ctx) {
              Map<String, List<Map<String, dynamic>>> weeklyGroups = {};
              final cutoff = DateTime.now().subtract(Duration(days: _selectedDays));

              double? absoluteMinWeek;
              for (var d in docs) {
                final data = d.data() as Map<String, dynamic>;
                final ts = data[dateField];
                DateTime? dt;
                if (ts is Timestamp) dt = ts.toDate();
                else if (ts is String) dt = DateTime.tryParse(ts);
                if (dt == null) continue;
                
                final absW = (dt.year * 52) + ((dt.difference(DateTime(dt.year, 1, 1)).inDays) / 7).ceil();
                if (absoluteMinWeek == null || absW < absoluteMinWeek) absoluteMinWeek = absW.toDouble();
              }

              if (absoluteMinWeek == null) return Center(child: Text(emptyMsg));

              for (var d in docs) {
                final data = d.data() as Map<String, dynamic>;
                final ts = data[dateField];
                DateTime dt;
                if (ts is Timestamp) dt = ts.toDate();
                else if (ts is String) dt = DateTime.tryParse(ts) ?? DateTime.now();
                else continue;

                if (dt.isBefore(cutoff)) continue;

                final absW = (dt.year * 52) + ((dt.difference(DateTime(dt.year, 1, 1)).inDays) / 7).ceil();
                final relativeWeekNum = (absW - absoluteMinWeek).toInt() + 1;
                final weekKey = "W$relativeWeekNum";

                data['__dt'] = dt;
                data['__relWeek'] = relativeWeekNum.toDouble();
                data['__weekKey'] = weekKey;
                
                if (!weeklyGroups.containsKey(weekKey)) weeklyGroups[weekKey] = [];
                weeklyGroups[weekKey]!.add(data);
              }

              List<_TrendPoint> dataPoints = [];
              weeklyGroups.forEach((key, list) {
                double sum = 0;
                for (var item in list) {
                  double val = (item[valueField] as num?)?.toDouble() ?? 0.0;
                  if (isPercentage) val *= 100;
                  sum += val;
                }
                double avg = sum / list.length;
                
                list.sort((a, b) => (b['__dt'] as DateTime).compareTo(a['__dt'] as DateTime));
                final latest = list.first;

                dataPoints.add(_TrendPoint(
                  date: latest['__dt'] as DateTime,
                  value: avg,
                  weekLabel: key,
                  x: latest['__relWeek'] as double,
                  fullData: latest,
                ));
              });

              dataPoints.sort((a, b) => a.date.compareTo(b.date));

              if (dataPoints.isEmpty) return Center(child: Text(emptyMsg));
              return _LineChartWidget(points: dataPoints, color: color, isDetection: isDetection);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard(AppLocalizations l) {
    return GlassCard(
      child: Column(
        children: [
          Text(l.translate('expert_tip'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            l.translate('trends_tip_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TrendPoint {
  final DateTime date;
  final double value;
  final String weekLabel;
  final double x;
  final Map<String, dynamic> fullData;
  _TrendPoint({required this.date, required this.value, required this.weekLabel, required this.x, required this.fullData});
}

class _LineChartWidget extends StatelessWidget {
  final List<_TrendPoint> points;
  final Color color;
  final bool isDetection;

  const _LineChartWidget({required this.points, required this.color, this.isDetection = false});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox();
    
    final baseLineX = points.first.x;
    final spots = points.map((p) => FlSpot(p.x - baseLineX, p.value)).toList();
    final maxX = spots.last.x == 0 ? 1.0 : spots.last.x;

    return LineChart(
      LineChartData(
        minY: 0, maxY: 100,
        minX: 0, maxX: maxX,
        lineTouchData: LineTouchData(
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response != null && response.lineBarSpots != null) {
              final index = response.lineBarSpots!.first.spotIndex;
              _showDetails(context, points[index]);
            }
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: color.withOpacity(0.8),
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              '${s.y.round()}%',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )).toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 25,
          verticalInterval: 1,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
          getDrawingVerticalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final matches = points.where((p) => (p.x - baseLineX).toInt() == val.toInt());
                if (matches.isEmpty) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    matches.first.weekLabel.split('-').last,
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              getTitlesWidget: (v, m) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
            left: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: color,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, _TrendPoint point) {
    final l = AppLocalizations.of(context);
    final data = point.fullData;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("${l.translate('week_label')} ${point.weekLabel.split('-').last}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(DateFormat('EEEE d MMMM yyyy', Localizations.localeOf(context).languageCode).format(point.date), style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            
            if (isDetection && data['imageUrls'] != null && (data['imageUrls'] as List).isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildPhoto(data['imageUrls'][0]),
              ),
            
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DetailMiniStat(label: "Score", value: "${point.value.round()}%", color: color),
                const SizedBox(width: 40),
                _DetailMiniStat(
                  label: "Niveau", 
                  value: data['severityLevel'] ?? data['riskLevel'] ?? "N/A", 
                  color: color
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (isDetection)
              PrimaryButton(
                label: l.translate('analysis_results'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/detection/result', extra: data);
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(String url) {
    if (url.startsWith('data:image')) {
      final base64str = url.split(',').last;
      return Image.memory(base64Decode(base64str), height: 180, width: double.infinity, fit: BoxFit.cover);
    }
    return const Icon(Iconsax.image, size: 50, color: Colors.grey);
  }
}

class _DetailMiniStat extends StatelessWidget {
  final String label, value; final Color color;
  const _DetailMiniStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value.toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}






































