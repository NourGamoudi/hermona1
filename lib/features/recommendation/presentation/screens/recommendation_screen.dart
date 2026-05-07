import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

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

      DetectionResult detection;
      if (widget.detectionData != null) {
        detection = DetectionResult.fromJson(widget.detectionData!);
      } else {
        final history = await _detSvc.getHistory(uid);
        detection = history.firstWhere((d) => d.id == widget.detectionId, orElse: () => history.first);
      }

      final result = await _recSvc.getRecommendations(detection: detection, userId: uid);
      await _recSvc.saveResult(result, uid);
      if (mounted) setState(() { _result = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Mes recommandations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 4, color: AppColors.primary),
            insets: const EdgeInsets.symmetric(horizontal: 16),
          ),
          tabs: const [
            Tab(icon: Icon(Iconsax.sun_1, size: 20),  text: 'Matin'),
            Tab(icon: Icon(Iconsax.moon, size: 20),   text: 'Soir'),
            Tab(icon: Icon(Iconsax.cup, size: 20),    text: 'Alimentation'),
          ],
        ),
      ),
      body: _loading
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SkeletonBox(width: double.infinity, height: 110),
                  ),
                ),
              ),
            )
              : _result == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.danger, size: 64, color: AppColors.error),
                          const SizedBox(height: 24),
                          const Text('Aucune donnée de scan trouvée', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                          const SizedBox(height: 12),
                          const Text('Réalisez un scan 5-zones pour obtenir des conseils.', style: TextStyle(color: AppColors.textSecondaryDark)),
                          const SizedBox(height: 32),
                          PrimaryButton(
                            label: 'LANCER LE SCAN',
                            width: 200,
                            onTap: () => context.push('/weekly-survey'),
                          ),
                        ],
                      ),
                    )
                  : Column(children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        const Icon(Iconsax.timer_1, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          'PROGRAMME DE ${_result!.duration.toUpperCase()}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),

                  Expanded(
                    child: TabBarView(
                      controller: _tab, 
                      children: [
                        _RoutineTab(steps: _result!.morningRoutine, isMorning: true),
                        _RoutineTab(steps: _result!.eveningRoutine, isMorning: false),
                        _DietTab(tips: _result!.dietTips),
                      ],
                    ),
                  ),
                ]),
    );
  }
}

class _RoutineTab extends StatelessWidget {
  final List<RoutineStep> steps;
  final bool isMorning;
  const _RoutineTab({required this.steps, required this.isMorning});

  @override
  Widget build(BuildContext context) {
    final color = isMorning ? AppColors.warning : AppColors.info;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20), 
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Text(isMorning ? '☀️' : '🌙', style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(
                      isMorning ? 'Routine du Matin' : 'Routine du Soir',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMorning ? 'Bien commencer la journée' : 'Régénérer votre peau',
                      style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 24),

        ...steps.asMap().entries.map((e) => PremiumFadeIn(
          delay: e.key * 100,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16), 
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52, 
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 5))],
                  ),
                  child: Center(
                    child: Text(
                      _cleanIcon(e.value.icon), 
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(
                          e.value.product, 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.value.instruction, 
                          style: TextStyle(
                            fontSize: 13, 
                            height: 1.5, 
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  String _cleanIcon(String raw) {
    if (raw.contains('🧴')) return '🧴';
    if (raw.contains('✨')) return '✨';
    if (raw.contains('☀️')) return '☀️';
    if (raw.contains('🌙')) return '🌙';
    return '🧴';
  }
}

class _DietTab extends StatelessWidget {
  final List<String> tips;
  const _DietTab({required this.tips});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20), 
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent.withOpacity(0.15), AppColors.accent.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Text('🥗', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Text('Conseils Alimentaires', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      'Rayonner de l\'intérieur',
                      style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 24),

        ...tips.asMap().entries.map((e) => PremiumFadeIn(
          delay: e.key * 80,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12), 
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle, color: AppColors.accent, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      e.value, 
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
        const SizedBox(height: 100),
      ],
    );
  }
}
