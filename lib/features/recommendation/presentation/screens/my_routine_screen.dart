import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/entities/recommendation_result.dart';

class MyRoutineScreen extends StatefulWidget {
  const MyRoutineScreen({super.key});

  @override
  State<MyRoutineScreen> createState() => _MyRoutineScreenState();
}

class _MyRoutineScreenState extends State<MyRoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  RecommendationResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadLatest();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadLatest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() { _error = 'Utilisateur non connecté.'; _loading = false; });
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('recommendations')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        setState(() { _error = 'Aucune routine disponible pour l\'instant.\nEffectuez d\'abord une analyse photo.'; _loading = false; });
        return;
      }

      final data = snap.docs.first.data();
      setState(() {
        _result = RecommendationResult.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Erreur de chargement : $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Routine'),
        bottom: _result != null
            ? TabBar(
                controller: _tab,
                labelColor: AppTheme.primary,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                indicatorColor: AppTheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(icon: Icon(Iconsax.sun_1), text: 'Matin'),
                  Tab(icon: Icon(Iconsax.moon), text: 'Soir'),
                  Tab(icon: Icon(Iconsax.cup), text: 'Alimentation'),
                ],
              )
            : null,
      ),
      body: _loading
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(
                  4,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonBox(width: double.infinity, height: 100),
                  ),
                ),
              ),
            )
          : _error != null
              ? _buildEmpty()
              : _buildContent(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.magic_star, size: 64, color: AppTheme.primary.withOpacity(0.4)),
            const SizedBox(height: 24),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () { setState(() { _loading = true; _error = null; }); _loadLatest(); },
              icon: const Icon(Iconsax.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ).animate().fadeIn(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Programme duration chip
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppTheme.primary.withOpacity(0.15),
              AppColors.secondary.withOpacity(0.08),
            ]),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Iconsax.clock, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              'Programme de ${_result!.duration}',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ]),
        ).animate().fadeIn(),

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
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RoutineTab extends StatelessWidget {
  final List<RoutineStep> steps;
  final bool isMorning;
  const _RoutineTab({required this.steps, required this.isMorning});

  @override
  Widget build(BuildContext context) {
    final color = isMorning ? AppColors.warning : AppColors.info;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.04)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Text(isMorning ? '☀️' : '🌙',
                style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isMorning ? 'Routine du matin' : 'Routine du soir',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                isMorning ? 'Bien commencer la journée' : 'Régénérer votre peau',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ]),
        ).animate().fadeIn(),
        const SizedBox(height: 18),
        ...steps.asMap().entries.map((e) => PremiumFadeIn(
              delay: e.key * 80,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [AppTheme.primary, AppColors.secondary]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(e.value.icon,
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.product,
                                style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 6),
                            Text(e.value.instruction,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(height: 1.5)),
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
}

class _DietTab extends StatelessWidget {
  final List<String> tips;
  const _DietTab({required this.tips});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.accent.withOpacity(0.3),
            AppColors.accent.withOpacity(0.05)
          ]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          const Text('🥗', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Conseils alimentaires',
                style: Theme.of(context).textTheme.headlineMedium),
            Text('Rayonner de l\'intérieur',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
        ]),
      ).animate().fadeIn(),
      const SizedBox(height: 16),
      ...tips.asMap().entries.map((e) => PremiumFadeIn(
            delay: e.key * 70,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Text(e.value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.55)),
              ),
            ),
          )),
      const SizedBox(height: 80),
    ]);
  }
}
