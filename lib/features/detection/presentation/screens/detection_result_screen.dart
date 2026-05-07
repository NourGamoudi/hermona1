import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/entities/detection_result.dart';

class DetectionResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetectionResultScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final result = DetectionResult.fromJson(data);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F9),
      appBar: AppBar(
        title: Text(
          'Résultats de l\'analyse',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF331E1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => context.go('/home'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildFacePartsList(result),
            const SizedBox(height: 20),
            _buildSeveritySection(result),
            const SizedBox(height: 20),
            _buildAcneTypeSection(result),
            const SizedBox(height: 20),
            _buildClassificationDetails(result),
            const SizedBox(height: 30),
            _buildActionButton(context, result),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFacePartsList(DetectionResult result) {
    if (result.imageUrls.isEmpty) return const SizedBox.shrink();

    final zoneNames = [
      'Front',
      'Joue Droite',
      'Joue Gauche',
      'Menton',
      'Nez',
    ];

    return Column(
      children: List.generate(
        result.imageUrls.length > zoneNames.length ? zoneNames.length : result.imageUrls.length,
        (index) {
          final zoneName = zoneNames[index];
          return Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildBase64Image(result.imageUrls[index]),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            zoneName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (result.zoneCounts?[zoneName]?['total'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC46E6E).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${result.zoneCounts![zoneName]!['total']} lésions",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeveritySection(DetectionResult result) {
    String levelText;
    Color levelColor;
    String description;

    switch (result.severityLevel) {
      case SeverityLevel.normal:
        levelText = "Léger";
        levelColor = Colors.green;
        description = "Acné légère. Une routine adaptée peut suffire.";
        break;
      case SeverityLevel.moderate:
        levelText = "Modéré";
        levelColor = Colors.orange;
        description = "Acné modérée. Restez vigilante sur votre routine.";
        break;
      case SeverityLevel.severe:
        levelText = "Sévère";
        levelColor = const Color(0xFFC46E6E);
        description = "Acné sévère. Consultez un dermatologue en complément des soins.";
        break;
      case SeverityLevel.verySevere:
        levelText = "Très Sévère";
        levelColor = Colors.purple;
        description = "Acné très sévère. Un avis médical est fortement recommandé.";
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE4E4).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Score de sévérité",
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF331E1E),
            ),
          ),
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 12.0,
            percent: (result.severityScore / 100.0).clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${result.severityScore.toInt()}",
                  style: GoogleFonts.outfit(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
                Text(
                  "/100",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: const Color(0xFFFFF0F0),
            progressColor: levelColor,
            animation: true,
            animationDuration: 1500,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: levelColor.withOpacity(0.3)),
            ),
            child: Text(
              levelText,
              style: GoogleFonts.outfit(
                color: levelColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF664444),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcneTypeSection(DetectionResult result) {
    if (result.classifications.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE4E4).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Types d'acné détectés",
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF331E1E),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: result.classifications.map((c) {
                  return PieChartSectionData(
                    color: _getTypeColor(c.type),
                    value: c.percentage * 100,
                    title: '${(c.percentage * 100).toInt()}%',
                    radius: 60,
                    titleStyle: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Legend
          Wrap(
            spacing: 20,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: result.classifications.map((c) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getTypeColor(c.type),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c.type,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(c.percentage * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC46E6E),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationDetails(DetectionResult result) {
    return Column(
      children: result.classifications.map((c) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFE4E4).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTypeColor(c.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      c.type,
                      style: GoogleFonts.outfit(
                        color: _getTypeColor(c.type),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${(c.percentage * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE59A9A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                c.description,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE4B5).withOpacity(0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.cause,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: const Color(0xFF8B4513),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(BuildContext context, DetectionResult result) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFE59A9A), Color(0xFFC46E6E)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC46E6E).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/recommendation/${result.id}', extra: data),
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_outline, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  "Voir mes recommandations",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'blackhead':
        return const Color(0xFFE59A9A);
      case 'papule':
        return const Color(0xFFB784B7);
      case 'pustule':
        return const Color(0xFF96C9B9);
      case 'whitehead':
        return const Color(0xFFEAD7D7);
      case 'nodule':
        return const Color(0xFFC46E6E);
      default:
        return Colors.grey;
    }
  }

  Widget _buildBase64Image(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return _buildErrorPlaceholder();
      }
    }
    return Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildErrorPlaceholder());
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
