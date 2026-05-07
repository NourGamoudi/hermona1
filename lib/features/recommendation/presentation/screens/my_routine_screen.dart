import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

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
          .get();

      if (snap.docs.isEmpty) {
        setState(() { _error = 'Aucune routine disponible.\nFaites une analyse photo.'; _loading = false; });
        return;
      }

      final docs = snap.docs.toList();
      docs.sort((a, b) {
        final ta = a.data()['createdAt'] ?? '';
        final tb = b.data()['createdAt'] ?? '';
        return tb.compareTo(ta);
      });

      final data = docs.first.data();
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
      backgroundColor: const Color(0xFFFFF9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Ma Routine',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF331E1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: _result != null
            ? TabBar(
                controller: _tab,
                labelColor: const Color(0xFFC46E6E),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFC46E6E),
                indicatorWeight: 3,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Matin'),
                  Tab(text: 'Soir'),
                  Tab(text: 'Vie'),
                ],
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC46E6E)))
          : _error != null
              ? _buildEmpty()
              : TabBarView(
                  controller: _tab,
                  children: [
                    _RoutineTab(steps: _result!.morningRoutine, isMorning: true, duration: _result!.duration),
                    _RoutineTab(steps: _result!.eveningRoutine, isMorning: false, duration: _result!.duration),
                    _LifestyleTab(result: _result!),
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.magic_star, size: 64, color: Color(0xFFE59A9A)),
            const SizedBox(height: 24),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey[600], height: 1.6),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Lancer une analyse',
              onTap: () => context.go('/prediction'),
              icon: Iconsax.magic_star,
            ),
          ],
        ),
      ).animate().fadeIn(),
    );
  }
}

class _RoutineTab extends StatelessWidget {
  final List<RoutineStep> steps;
  final bool isMorning;
  final String duration;

  const _RoutineTab({required this.steps, required this.isMorning, required this.duration});

  @override
  Widget build(BuildContext context) {
    final themeColor = isMorning ? const Color(0xFFE59A9A) : const Color(0xFFB784B7);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: themeColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              Icon(isMorning ? Iconsax.sun_1 : Iconsax.moon, color: themeColor, size: 30),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMorning ? 'Routine Matinale' : 'Routine du Soir',
                    style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text('Programme de $duration', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 24),
        ...steps.asMap().entries.map((e) {
          final step = e.value;
          return PremiumFadeIn(
            delay: e.key * 100,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: themeColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Text(step.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.product, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        Text(step.instruction, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _LifestyleTab extends StatelessWidget {
  final RecommendationResult result;
  const _LifestyleTab({required this.result});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Alimentation', '🥗'),
        const SizedBox(height: 12),
        ...result.dietTips.map((tip) => _buildTipCard(tip, const Color(0xFF96C9B9))),
        const SizedBox(height: 24),
        _buildSectionHeader('Mode de vie', '✨'),
        const SizedBox(height: 12),
        ...result.lifestyle.map((tip) => _buildTipCard(tip, const Color(0xFFB784B7))),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTipCard(String tip, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.tick_circle5, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(tip, style: GoogleFonts.outfit(fontSize: 13))),
        ],
      ),
    );
  }
}
