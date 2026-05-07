import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../detection/data/services/detection_api_service.dart';
import '../../../detection/domain/entities/detection_result.dart';
import '../../data/services/recommendation_api_service.dart';
import '../../domain/entities/recommendation_result.dart';

class RecommendationScreen extends StatefulWidget {
  final String detectionId;
  final Map<String, dynamic>? detectionData;

  const RecommendationScreen({super.key, required this.detectionId, this.detectionData});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  RecommendationResult? _result;
  bool _loading = true;
  final _recSvc = RecommendationApiService();
  final _detSvc = DetectionApiService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final cached = await _recSvc.getForDetection(widget.detectionId);
      if (cached != null) {
        if (mounted) setState(() { _result = cached; _loading = false; });
        return;
      }

      DetectionResult? detection;
      if (widget.detectionData != null) {
        detection = DetectionResult.fromJson(widget.detectionData!);
      } else {
        final history = await _detSvc.getHistory(uid);
        if (history.isNotEmpty) {
          try {
            detection = history.firstWhere((d) => d.id == widget.detectionId);
          } catch (_) {
            detection = history.first;
          }
        }
      }

      if (detection == null) {
        detection = DetectionResult(
          id: widget.detectionId,
          severityScore: 0,
          severityLevel: SeverityLevel.normal,
          classifications: const [],
          analyzedAt: DateTime.now(),
          imageUrls: const [],
        );
      }

      final result = await _recSvc.getRecommendations(detection: detection!, userId: uid);
      await _recSvc.saveResult(result, uid);
      if (mounted) setState(() { _result = result; _loading = false; });
    } catch (e) {
      debugPrint('Error loading routine: $e');
      if (mounted) {
        setState(() { _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de générer la routine : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Moteur de Recommandation',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF331E1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC46E6E)))
          : _result == null
              ? const Center(child: Text('Aucune recommandation trouvée'))
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          if (_result!.explanation.isNotEmpty)
                            _buildAIExplanation(_result!.explanation),
                          _buildSummaryHeader(_result!),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tab,
                          labelColor: const Color(0xFFC46E6E),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFFC46E6E),
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: 'Matin'),
                            Tab(text: 'Soir'),
                            Tab(text: 'Vie & Santé'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tab,
                    children: [
                      _buildRoutineTab(_result!.morningRoutine, const Color(0xFFE59A9A)),
                      _buildRoutineTab(_result!.eveningRoutine, const Color(0xFF331E1E)),
                      _buildHealthTab(_result!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAIExplanation(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFC46E6E).withOpacity(0.1), const Color(0xFFFFF9F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC46E6E).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.magic_star, color: Color(0xFFC46E6E), size: 18),
              const SizedBox(width: 8),
              Text(
                'L\'analyse d\'Hermona',
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: const Color(0xFFC46E6E)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF331E1E), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(RecommendationResult result) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFE4E4).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Sévérité', result.severity <= 1 ? '${(result.severity * 100).toInt()}%' : '${result.severity.toInt()}%', const Color(0xFFC46E6E)),
              _buildMetric('Risque', result.riskScore <= 1 ? '${(result.riskScore * 100).toInt()}%' : '${result.riskScore.toInt()}%', Colors.orange),
              _buildMetric('Stratégie', result.strategy, Colors.blue),
            ],
          ),
          const Divider(height: 32),
          Text(
            result.brands,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildRoutineTab(List<RoutineStep> steps, Color themeColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...steps.map((step) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: themeColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(child: Text(step.icon, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.product, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(step.instruction, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
                        if (step.productExample.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: themeColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                            child: Text('Ex: ${step.productExample}', style: GoogleFonts.outfit(fontSize: 11, color: themeColor, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildHealthTab(RecommendationResult result) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionTitle('🔬 Actifs & Ingrédients', Iconsax.mask),
        _buildActiveChips('À privilégier', result.actives, Colors.green),
        const SizedBox(height: 12),
        _buildActiveChips('À éviter cette semaine', result.avoid, Colors.red),
        
        const Divider(height: 40),
        _buildSectionTitle('🍎 Nutrition & Diététique', Iconsax.cup),
        ...result.nutrition.map((tip) => _buildCheckItem(tip)),
        
        const Divider(height: 40),
        _buildSectionTitle('🧘 Mode de vie', Iconsax.heart),
        ...result.lifestyle.map((tip) => _buildCheckItem(tip)),
        
        const Divider(height: 40),
        _buildSectionTitle('🧼 Habitudes Quotidiennes', Iconsax.refresh),
        ...result.habits.map((tip) => _buildCheckItem(tip)),

        if (result.whyThis.isNotEmpty) ...[
          const Divider(height: 40),
          _buildSectionTitle('💡 Pourquoi ce choix ?', Iconsax.info_circle),
          ...result.whyThis.map((reason) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(child: Text(reason, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic))),
              ],
            ),
          )),
        ],

        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE4E4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Iconsax.danger, color: Color(0xFFC46E6E)),
              const SizedBox(height: 8),
              Text(
                result.disclaimer,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF331E1E), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFC46E6E)),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActiveChips(String label, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((a) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
            child: Text(a, style: GoogleFonts.outfit(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFFC46E6E)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF331E1E)))),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
