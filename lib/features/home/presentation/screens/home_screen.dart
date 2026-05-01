import 'dart:io';
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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadUser(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 32),
              
              // Dashboard Metrics
              _buildDashboardMetrics(uid),
              const SizedBox(height: 32),

              // Quick Actions
              SectionTitle(title: 'Actions Rapides', action: 'Tout voir', onAction: () {}),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              
              const SizedBox(height: 32),
              
              // Daily Follow-up
              _buildDailyFollowUp(context),
              
              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
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
                'Bonjour, ${_firstName ?? '...'} ✨',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Comment se sent ta peau aujourd\'hui ?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Iconsax.notification),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: const Text('🌸'),
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildDashboardMetrics(String? uid) {
    if (uid == null) return const SizedBox();

    return Column(
      children: [
        // Top Row: Risk & Hygiene
        Row(
          children: [
            // Risk Card
            Expanded(
              flex: 3,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.colPredictions)
                    .where('userId', isEqualTo: uid)
                    .orderBy('predictedAt', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  PredictionResult? result;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    result = PredictionResult.fromJson(snapshot.data!.docs.first.data() as Map<String, dynamic>);
                  }

                  return _MetricCard(
                    title: 'Risque Acné',
                    value: result != null ? '${(result.riskScore * 100).toInt()}%' : '--',
                    subtitle: result?.riskLevel.name.toUpperCase() ?? 'En attente',
                    icon: Iconsax.status_up,
                    color: _getRiskColor(result?.riskLevel),
                    onTap: () => context.go('/prediction'),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Hygiene Score Card
            Expanded(
              flex: 2,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('daily_surveys')
                    .where('userId', isEqualTo: uid)
                    .orderBy('date', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  int? score;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    score = snapshot.data!.docs.first['lifestyleScore'] as int?;
                  }

                  return _MetricCard(
                    title: 'Hygiène',
                    value: score != null ? '$score' : '--',
                    subtitle: '/100',
                    icon: Iconsax.mask,
                    color: AppColors.info,
                    onTap: () => context.push('/daily-survey'),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Cycle Phase Card
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).snapshots(),
          builder: (context, snapshot) {
            String phase = 'Inconnue';
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

            return AppCard(
              onTap: () => context.push('/onboarding'),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 30.0,
                    lineWidth: 6.0,
                    percent: (day % 28) / 28,
                    center: Text('$day'),
                    progressColor: AppColors.secondary,
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phase $phase', style: Theme.of(context).textTheme.headlineMedium),
                        Text('Jour $day du cycle', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Iconsax.moon, color: AppColors.secondary.withOpacity(0.5)),
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
      childAspectRatio: 1.5,
      children: [
        _ActionItem(
          title: 'Assistant IA',
          icon: Iconsax.message_notif,
          color: AppTheme.primary,
          onTap: () => context.go('/chat'),
        ),
        _ActionItem(
          title: 'Analyse Photo',
          icon: Iconsax.camera,
          color: AppColors.accent,
          onTap: () => context.push('/weekly-survey'),
        ),
        _ActionItem(
          title: 'Forum Femmes',
          icon: Iconsax.people,
          color: AppColors.secondary,
          onTap: () => context.push('/forum'),
        ),
        _ActionItem(
          title: 'Historique',
          icon: Iconsax.chart,
          color: AppColors.info,
          onTap: () => context.push('/history'),
        ),
      ],
    );
  }

  Widget _buildDailyFollowUp(BuildContext context) {
    return AppCard(
      color: AppTheme.primary.withOpacity(0.05),
      onTap: () => context.push('/daily-survey'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Iconsax.edit, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bilan du jour', style: Theme.of(context).textTheme.labelLarge),
                const Text('Mets à jour ton stress, sommeil et alimentation.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Color _getRiskColor(RiskLevel? level) {
    switch (level) {
      case RiskLevel.low: return AppColors.success;
      case RiskLevel.medium: return AppColors.warning;
      case RiskLevel.high: return AppColors.error;
      default: return Colors.grey;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(value, style: Theme.of(context).textTheme.displayMedium?.copyWith(color: color, height: 1)),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
