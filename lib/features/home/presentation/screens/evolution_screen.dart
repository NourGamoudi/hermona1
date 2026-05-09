import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS (local to this screen)
// ─────────────────────────────────────────────────────────────────────────────

class _SeverityPoint {
  final DateTime date;
  final double score; // 0–100
  final String docId;
  // imageBase64 intentionally removed: base64 images are never stored in
  // Firestore (CursorWindow NO_MEMORY fix). Images only exist in-memory
  // during the active detection session.
  _SeverityPoint({required this.date, required this.score, required this.docId});
}

class _RiskPoint {
  final DateTime date;
  final double score; // 0.0–1.0
  _RiskPoint({required this.date, required this.score});
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class EvolutionScreen extends StatefulWidget {
  const EvolutionScreen({super.key});
  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  List<_SeverityPoint> _severityPoints = [];
  List<_RiskPoint> _riskPoints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _loading = false); return; }

    try {
      // 1. SEVERITY: Fetch latest 15 weekly analysis documents
      final detSnap = await FirebaseFirestore.instance
          .collection(AppConstants.colDetections)
          .where('userId', isEqualTo: uid)
          .orderBy('analyzedAt', descending: true)
          .limit(15)
          .get(const GetOptions(source: Source.serverAndCache));

      // 2. RISK: Fetch latest 15 daily risk predictions
      final predSnap = await FirebaseFirestore.instance
          .collection(AppConstants.colPredictions)
          .where('userId', isEqualTo: uid)
          .orderBy('predictedAt', descending: true)
          .limit(15)
          .get(const GetOptions(source: Source.serverAndCache));

      // DATA INTEGRITY: Strict mapping & chronological sorting (Left -> Right)
      final sPoints = detSnap.docs.map((d) {
        final data = d.data();
        final date = _parseDate(data['analyzedAt']);
        final score = (data['severityScore'] as num?)?.toDouble() ?? 0.0;
        return _SeverityPoint(date: date, score: score, docId: d.id);
      }).toList()..sort((a, b) => a.date.compareTo(b.date));

      final rPoints = predSnap.docs.map((d) {
        final data = d.data();
        final date = _parseDate(data['predictedAt']);
        final score = (data['riskScore'] as num?)?.toDouble() ?? 0.0;
        return _RiskPoint(date: date, score: score);
      }).toList()..sort((a, b) => a.date.compareTo(b.date));

      if (mounted) {
        setState(() {
          _severityPoints = sPoints;
          _riskPoints = rPoints;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Evolution Error: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (val is String) return DateTime.tryParse(val) ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (val is Timestamp) return val.toDate();
    try { return (val as dynamic).toDate(); } catch (_) { return DateTime.fromMillisecondsSinceEpoch(0); }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DIALOG: tap sur un point de sévérité
  // ──────────────────────────────────────────────────────────────────────────
  void _showSeverityDetail(_SeverityPoint point) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.scan, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Analyse Cutanée', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          Text(
                            DateFormat('EEEE d MMMM yyyy', 'fr').format(point.date),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.primary, AppColors.primaryDark]),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Sévérité : ${point.score.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image Loader
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection(AppConstants.colDetections)
                        .doc(point.docId)
                        .collection('media')
                        .doc('images')
                        .get(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: 140,
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(18)),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      final data = snap.data?.data() as Map<String, dynamic>?;
                      final urls = data?['imageUrls'] as List?;
                      
                      if (urls == null || urls.isEmpty) {
                        return Container(
                          height: 140,
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(18)),
                          child: const Center(child: Text('Photo non disponible', style: TextStyle(color: Colors.grey, fontSize: 12))),
                        );
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _buildImage(urls[0]), // Show first zone image
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DIALOG: tap sur un point de risque
  // ──────────────────────────────────────────────────────────────────────────
  void _showRiskDetail(_RiskPoint point) {
    final pct = (point.score * 100).toInt();
    final color = pct > 60 ? AppColors.error : (pct > 35 ? AppColors.warning : AppColors.success);
    final label = pct > 60 ? 'ÉLEVÉ' : (pct > 35 ? 'MODÉRÉ' : 'FAIBLE');

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Iconsax.status_up, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Score de Risque', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          Text(DateFormat('EEEE d MMMM yyyy', 'fr').format(point.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('$pct%', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: color)),
                  StatusBadge(text: label, color: color),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ──────────────────────────────────────────────────────────────────────────
  // IMAGE HELPER
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildImage(String src) {
    if (src.startsWith('data:image')) {
      final comma = src.indexOf(',');
      if (comma != -1) {
        try {
          final bytes = base64Decode(src.substring(comma + 1));
          return Image.memory(bytes, height: 180, width: double.infinity, fit: BoxFit.cover);
        } catch (_) {}
      }
    }
    return Image.network(src, height: 180, width: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(height: 180, child: Center(child: Icon(Icons.broken_image, color: Colors.grey))));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CHART HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  List<FlSpot> _severitySpots() => List.generate(
        _severityPoints.length,
        (i) => FlSpot(i.toDouble(), _severityPoints[i].score),
      );

  List<FlSpot> _riskSpots() => List.generate(
        _riskPoints.length,
        (i) => FlSpot(i.toDouble(), _riskPoints[i].score * 100),
      );

  String _shortDate(DateTime d) => DateFormat('d/M', 'fr').format(d);

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mon Évolution'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
      body: Stack(
        children: [
          // Background blobs
          Positioned(top: -60, right: -60,
              child: _Blob(size: 220, color: AppTheme.primary.withValues(alpha: 0.07))),
          Positioned(bottom: 200, left: -60,
              child: _Blob(size: 200, color: AppColors.secondary.withValues(alpha: 0.06))),

          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
                    children: [
                      // ── Header info ────────────────────────────────────────
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
                                    Text('${_severityPoints.length} analyse(s) • ${_riskPoints.length} prédiction(s)',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Sévérité Chart ─────────────────────────────────────
                      PremiumFadeIn(
                        delay: 100,
                        child: _ChartSection(
                          title: 'Sévérité (Bilan Hebdo)',
                          subtitle: 'Analyse photo hebdomadaire',
                          icon: Iconsax.scan,
                          color: AppColors.primary,
                          isEmpty: _severityPoints.isEmpty,
                          emptyMessage: 'Effectuez une analyse photo\npour voir votre courbe de sévérité.',
                          chart: _severityPoints.isEmpty
                              ? null
                              : _buildLineChart(
                                  spots: _severitySpots(),
                                  color: AppColors.primary,
                                  maxY: 100,
                                  labelX: (v) {
                                    final i = v.toInt();
                                    if (i < 0 || i >= _severityPoints.length) return '';
                                    return _shortDate(_severityPoints[i].date);
                                  },
                                  onTouch: (i) {
                                    if (i >= 0 && i < _severityPoints.length) {
                                      _showSeverityDetail(_severityPoints[i]);
                                    }
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Risque Chart ───────────────────────────────────────
                      PremiumFadeIn(
                        delay: 200,
                        child: _ChartSection(
                          title: 'Risque (Suivi Quotidien)',
                          subtitle: 'Évolution selon vos réponses quotidiennes',
                          icon: Iconsax.status_up,
                          color: AppColors.error,
                          isEmpty: _riskPoints.isEmpty,
                          emptyMessage: 'Remplissez votre questionnaire quotidien\npour voir votre courbe de risque.',
                          chart: _riskPoints.isEmpty
                              ? null
                              : _buildLineChart(
                                  spots: _riskSpots(),
                                  color: AppColors.error,
                                  maxY: 100,
                                  labelX: (v) {
                                    final i = v.toInt();
                                    if (i < 0 || i >= _riskPoints.length) return '';
                                    return _shortDate(_riskPoints[i].date);
                                  },
                                  onTouch: (i) {
                                    if (i >= 0 && i < _riskPoints.length) {
                                      _showRiskDetail(_riskPoints[i]);
                                    }
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ── Tip ────────────────────────────────────────────────
                      PremiumFadeIn(
                        delay: 300,
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Appuyez sur un point pour voir la date, le score et la photo de l\'analyse.',
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
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LINE CHART BUILDER
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildLineChart({
    required List<FlSpot> spots,
    required Color color,
    required double maxY,
    required String Function(double) labelX,
    required void Function(int index) onTouch,
  }) {
    int? _touchedIndex;

    return StatefulBuilder(
      builder: (context, setChartState) {
        return LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: Colors.grey.withValues(alpha: 0.12),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}%',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: spots.length <= 6 ? 1 : (spots.length / 5).ceilToDouble(),
                  getTitlesWidget: (v, _) => Text(
                    labelX(v),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchCallback: (event, response) {
                if (event is FlTapUpEvent && response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
                  final idx = response.lineBarSpots!.first.spotIndex;
                  setChartState(() => _touchedIndex = idx);
                  onTouch(idx);
                }
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                  '${s.y.toStringAsFixed(1)}%',
                  TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13),
                )).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: color,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, i) => FlDotCirclePainter(
                    radius: _touchedIndex == i ? 8 : 5,
                    color: _touchedIndex == i ? color : color.withValues(alpha: 0.7),
                    strokeWidth: _touchedIndex == i ? 3 : 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHART SECTION WRAPPER
// ─────────────────────────────────────────────────────────────────────────────
class _ChartSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isEmpty;
  final String emptyMessage;
  final Widget? chart;

  const _ChartSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isEmpty,
    required this.emptyMessage,
    this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart or empty state
          isEmpty
              ? SizedBox(
                  height: 140,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 36, color: color.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(height: 200, child: chart!),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOB (background decoration)
// ─────────────────────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
