import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:acneia/core/localization/app_localizations.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/features/detection/domain/entities/detection_result.dart';

class DetectionResultScreen extends StatelessWidget {
  final Map<String, dynamic> detectionData;

  const DetectionResultScreen({super.key, required this.detectionData});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final result = DetectionResult.fromJson(detectionData);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.translate('analysis_results_title')),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_1),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
          
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 100),
            children: [
              _buildSeverityDonut(context, result),
              const SizedBox(height: 24),
              _buildAcnerypesChart(context, result),
              const SizedBox(height: 32),
              Text(l.translate('lesion_details'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...result.classifications.map((c) => _buildClassificationCard(c)),
              const SizedBox(height: 32),
              Text(l.translate('zone_analysis'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildFacePartsGrid(context, result),
              const SizedBox(height: 40),
              PrimaryButton(
                label: l.translate('view_recommendations'),
                onTap: () => context.go('/my-routine'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityDonut(BuildContext context, DetectionResult result) {
    final l = AppLocalizations.of(context);
    final color = _getSeverityColor(result.severityLevel);
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Text(l.translate('severity_score'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 70,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: color,
                        value: result.severityScore,
                        radius: 12,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        color: color.withValues(alpha: 0.1),
                        value: 100 - result.severityScore,
                        radius: 12,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${result.severityScore.toInt()}',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.primary),
                    ),
                    const Text('/100', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getSeverityLabel(context, result.severityLevel),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _getSeverityDescription(context, result.severityLevel),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcnerypesChart(BuildContext context, DetectionResult result) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.translate('detected_acne_types'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: result.classifications.map((c) {
                        return PieChartSectionData(
                          color: _getTypeColor(c.type),
                          value: c.percentage * 100,
                          radius: 30,
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Column(
                  children: result.classifications.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: _getTypeColor(c.type), shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(c.type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey))),
                        Text('${(c.percentage * 100).toInt()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _getTypeColor(c.type).withValues(alpha: 0.6))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationCard(AcneClassification c) {
    final color = _getTypeColor(c.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Text(c.type, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Text('${(c.percentage * 100).toInt()}%', style: TextStyle(color: color.withValues(alpha: 0.5), fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Text(c.description, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(c.cause, style: const TextStyle(fontSize: 12, color: Color(0xFF8E6A74), height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacePartsGrid(BuildContext context, DetectionResult result) {
    if (result.imageUrls.isEmpty) {
      final l = AppLocalizations.of(context);
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Iconsax.image, size: 48, color: AppColors.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              l.translate('visualization_unavailable'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              l.translate('viz_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      );
    }
    final zones = ['front', 'menton', 'joue_gauche', 'joue_droite', 'nez'];
    final l = AppLocalizations.of(context);
    final zoneNames = [
      l.translate('front'),
      l.translate('chin'),
      l.translate('left_cheek'),
      l.translate('right_cheek'),
      l.translate('nose')
    ];

    return Column(
      children: List.generate(result.imageUrls.length, (index) {
        final zoneId = zones[index];
        final risk = result.zoneRisks?[zoneId] ?? 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: AspectRatio(
                        aspectRatio: 1.5,
                        child: GestureDetector(
                          onTap: () => _showZoomedImage(context, result.imageUrls[index], zoneNames[index]),
                          child: _buildBase64Image(result.imageUrls[index]),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                        child: Text(zoneNames[index], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.translate('risk_label'), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text('${risk.toInt()}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _getRiskColor(risk))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(l.translate('status_label'), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(
                              _getZoneStatus(context, result, index), 
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _getZoneStatus(BuildContext context, DetectionResult result, int index) {
    final l = AppLocalizations.of(context);
    final zones = ['front', 'joue_droite', 'joue_gauche', 'menton', 'nez'];
    if (index >= zones.length) return l.translate('normal');
    final counts = result.zoneCounts?[zones[index]];
    if (counts == null || counts.isEmpty) return l.translate('healthy_skin');
    return counts.entries.map((e) => '${e.value} ${e.key}').join(', ');
  }

  Color _getSeverityColor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.normal: return AppColors.success;
      case SeverityLevel.moderate: return AppColors.warning;
      case SeverityLevel.severe: return AppColors.error;
      case SeverityLevel.verySevere: return Colors.purple;
    }
  }

  String _getSeverityLabel(BuildContext context, SeverityLevel level) {
    final l = AppLocalizations.of(context);
    switch (level) {
      case SeverityLevel.normal: return l.translate('severity_low');
      case SeverityLevel.moderate: return l.translate('severity_moderate');
      case SeverityLevel.severe: return l.translate('severity_severe');
      case SeverityLevel.verySevere: return l.translate('severity_very_severe');
    }
  }

  String _getSeverityDescription(BuildContext context, SeverityLevel level) {
    final l = AppLocalizations.of(context);
    switch (level) {
      case SeverityLevel.normal: return l.translate('severity_desc_low');
      case SeverityLevel.moderate: return l.translate('severity_desc_moderate');
      case SeverityLevel.severe: return l.translate('severity_desc_severe');
      case SeverityLevel.verySevere: return l.translate('severity_desc_very_severe');
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'blackhead': return const Color(0xFFE59A9A);
      case 'papule': return const Color(0xFFB784B7);
      case 'pustule': return const Color(0xFF96C9B9);
      case 'whitehead': return const Color(0xFFEAD7D7);
      case 'nodule': return const Color(0xFFC46E6E);
      default: return Colors.grey;
    }
  }

  Color _getRiskColor(double risk) {
    if (risk < 30) return Colors.green;
    if (risk < 60) return Colors.orange;
    return AppTheme.primary;
  }

  void _showZoomedImage(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(borderRadius: BorderRadius.circular(16), child: _buildBase64Image(imageUrl)),
            ),
            Positioned(
              top: 10, right: 10,
              child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBase64Image(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
      }
    }
    return Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)));
  }
}
