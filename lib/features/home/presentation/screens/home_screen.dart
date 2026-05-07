import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../prediction/domain/entities/prediction_result.dart';
import '../../../questionnaire/domain/entities/daily_survey.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection(AppConstants.colUsers).doc(uid).get()
        .then((d) { 
          if (d.exists && mounted) {
            setState(() => _firstName = d.data()?['firstName'] as String?);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100,
            right: -50,
            child: _Blob(size: 300, color: AppTheme.primary.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _Blob(size: 250, color: AppColors.secondary.withOpacity(0.05)),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _loadUser(),
              color: AppTheme.primary,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  // ───────────────────────────────────────────────────────────
                  // HEADER
                  // ───────────────────────────────────────────────────────────
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  
                  // ───────────────────────────────────────────────────────────
                  // DASHBOARD METRICS (GLASS)
                  // ───────────────────────────────────────────────────────────
                  _buildDashboardMetrics(uid),
                  const SizedBox(height: 32),

                  // ───────────────────────────────────────────────────────────
                  // QUICK ACTIONS
                  // ───────────────────────────────────────────────────────────
                  const SectionHeader(title: 'Explorer'),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  
                  const SizedBox(height: 32),
                  
                  // ───────────────────────────────────────────────────────────
                  // DAILY SURVEY (PREMIUM CARD)
                  // ───────────────────────────────────────────────────────────
                  _buildDailyFollowUp(context),
                  
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue,',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${_firstName ?? 'Chargement...'} ✨',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ],
          ),
        ),
        _HeaderAction(icon: Iconsax.notification, onTap: () => context.push('/notifications')),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Hero(
            tag: 'profile_avatar',
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primary, AppColors.primaryDark]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Center(child: Text('🌸', style: TextStyle(fontSize: 20))),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1);
  }

  Widget _buildDashboardMetrics(String? uid) {
    if (uid == null) return const SizedBox();

    return Column(
      children: [
        Row(
          children: [
            // Risk Analysis
            Expanded(
              flex: 3,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.colPredictions)
                    .where('userId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  PredictionResult? result;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final docs = snapshot.data!.docs.toList();
                    docs.sort((a, b) {
                      DateTime dateA = a['predictedAt'] is Timestamp ? (a['predictedAt'] as Timestamp).toDate() : DateTime.tryParse(a['predictedAt'].toString()) ?? DateTime(2000);
                      DateTime dateB = b['predictedAt'] is Timestamp ? (b['predictedAt'] as Timestamp).toDate() : DateTime.tryParse(b['predictedAt'].toString()) ?? DateTime(2000);
                      return dateB.compareTo(dateA);
                    });
                    result = PredictionResult.fromJson(docs.first.data() as Map<String, dynamic>);
                  }

                  return _GlassMetricCard(
                    title: 'Risque Acné',
                    value: result != null ? '${(result.riskScore * 100).toInt()}%' : '--',
                    label: result?.riskLevel.name.toUpperCase() ?? 'Analyse...',
                    icon: Iconsax.status_up,
                    color: _getRiskColor(result?.riskLevel),
                    onTap: () => context.go('/prediction'),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Lifestyle Score
            Expanded(
              flex: 2,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('daily_surveys')
                    .where('userId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  int? score;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final docs = snapshot.data!.docs.toList();
                    docs.sort((a, b) {
                      DateTime dateA = a['date'] is Timestamp ? (a['date'] as Timestamp).toDate() : DateTime.tryParse(a['date'].toString()) ?? DateTime(2000);
                      DateTime dateB = b['date'] is Timestamp ? (b['date'] as Timestamp).toDate() : DateTime.tryParse(b['date'].toString()) ?? DateTime(2000);
                      return dateB.compareTo(dateA);
                    });
                    score = docs.first['lifestyleScore'] as int?;
                  }

                  return _GlassMetricCard(
                    title: 'Hygiène',
                    value: score != null ? '$score' : '--',
                    label: '/100',
                    icon: Iconsax.heart5,
                    color: AppColors.info,
                    onTap: () => context.push('/daily-survey'),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Cycle Tracking
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).snapshots(),
          builder: (context, snapshot) {
            String phase = 'Calcul...';
            int day = 0;
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              if (data['lastPeriodsDate'] != null) {
                final lastDate = (data['lastPeriodsDate'] as Timestamp).toDate();
                day = DateTime.now().difference(lastDate).inDays + 1;
                if (day <= 5) phase = 'Menstruelle';
                else if (day <= 13) phase = 'Folliculaire';
                else if (day <= 15) phase = 'Ovulatoire';
                else phase = 'Lutéale';
              }
            }

            return GlassCard(
              onTap: () => context.push('/onboarding'),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 35.0,
                    lineWidth: 7.0,
                    percent: (day % 28) / 28,
                    center: Text('$day', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    progressColor: AppColors.secondary,
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cycle : Phase $phase', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 2),
                        Text('Jour $day • Influence hormonale modérée', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Iconsax.moon, color: AppColors.secondary, size: 24),
                ],
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _PremiumAction(
          title: 'IA Assistant',
          subtitle: 'Conseils personnalisés',
          icon: Iconsax.message_notif,
          color: AppTheme.primary,
          onTap: () => context.go('/chat'),
        ),
        _PremiumAction(
          title: 'Selfie Scan',
          subtitle: 'Analyse 5 zones',
          icon: Iconsax.camera,
          color: AppColors.accent,
          onTap: () => context.push('/weekly-survey'),
        ),
        _PremiumAction(
          title: 'Communauté',
          subtitle: 'Échanges anonymes',
          icon: Iconsax.people,
          color: AppColors.secondary,
          onTap: () => context.push('/forum'),
        ),
        _PremiumAction(
          title: 'Historique',
          subtitle: 'Suivi de progrès',
          icon: Iconsax.chart,
          color: AppColors.info,
          onTap: () => context.push('/history'),
        ),
      ],
    );
  }

  Widget _buildDailyFollowUp(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => context.push('/daily-survey'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15)],
                  ),
                  child: const Icon(Iconsax.edit, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bilan du jour', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Actualise tes données de vie pour une précision maximale.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Iconsax.arrow_right_3, size: 20, color: AppColors.textSecondaryDark),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Color _getRiskColor(RiskLevel? level) {
    switch (level) {
      case RiskLevel.low: return AppColors.success;
      case RiskLevel.medium: return AppColors.warning;
      case RiskLevel.high: return AppColors.error;
      default: return AppColors.textSecondaryDark;
    }
  }
}

class _GlassMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GlassMetricCard({
    required this.title,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: Theme.of(context).textTheme.displayMedium?.copyWith(color: color, height: 1, fontSize: 32)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PremiumAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PremiumAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimaryDark),
      ),
    );
  }
}

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
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}
