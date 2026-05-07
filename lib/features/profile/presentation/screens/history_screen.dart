import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';

class HistoryScreen extends StatefulWidget {
  final int initialTab;
  const HistoryScreen({super.key, this.initialTab = 0});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Journal Hermona'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.primary),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondaryDark,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
              tabs: const [
                Tab(text: 'ANALYSES'),
                Tab(text: 'ROUTINES'),
                Tab(text: 'PRÉDICTIONS'),
                Tab(text: 'CHATS'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -100,
            right: -50,
            child: _Blob(size: 300, color: AppTheme.primary.withOpacity(0.05)),
          ),

          TabBarView(
            controller: _tab,
            children: [
              _HistoryList(
                col: AppConstants.colDetections,
                uid: _uid,
                orderField: 'analyzedAt',
                emptyTitle: 'Aucune analyse',
                emptySubtitle: 'Lancer un scan pour voir vos résultats.',
                emptyIcon: Iconsax.scan,
                itemBuilder: (ctx, data, id) {
                  final score = data['severityScore'] as int? ?? 0;
                  final level = data['severityLevel'] as String? ?? 'normal';
                  final color = level == 'normal' ? AppColors.success : level == 'moderate' ? AppColors.warning : AppColors.error;
                  return GlassCard(
                    onTap: () => ctx.push('/detection/result', extra: data),
                    child: Row(
                      children: [
                        _CircularScore(score: score, color: color),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusBadge(text: level.toUpperCase(), color: color),
                              const SizedBox(height: 6),
                              Text(_ago(data['analyzedAt']), style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                            ],
                          ),
                        ),
                        const Icon(Iconsax.arrow_right_3, size: 16, color: AppColors.textSecondaryDark),
                      ],
                    ),
                  );
                },
              ),
              _HistoryList(
                col: AppConstants.colRecommendations,
                uid: _uid,
                orderField: 'createdAt',
                emptyTitle: 'Aucune routine',
                emptySubtitle: 'Vos routines personnalisées apparaîtront ici.',
                emptyIcon: Iconsax.star,
                itemBuilder: (ctx, data, id) => GlassCard(
                  onTap: () => ctx.push('/recommendation/${data['detectionId']}', extra: data),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Iconsax.magic_star, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ROUTINE SUR-MESURE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Durée : ${data['duration'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                            Text(_ago(data['createdAt']), style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
                          ],
                        ),
                      ),
                      const Icon(Iconsax.arrow_right_3, size: 16, color: AppColors.textSecondaryDark),
                    ],
                  ),
                ),
              ),
              _HistoryList(
                col: AppConstants.colPredictions,
                uid: _uid,
                orderField: 'predictedAt',
                emptyTitle: 'Aucun risque',
                emptySubtitle: 'Anticipez les poussées avec l\'IA.',
                emptyIcon: Iconsax.chart_2,
                itemBuilder: (ctx, data, id) {
                  final risk = (data['riskScore'] as num?)?.toDouble() ?? 0;
                  final level = data['riskLevel'] as String? ?? 'low';
                  final color = level == 'low' ? AppColors.success : level == 'medium' ? AppColors.warning : AppColors.error;
                  return GlassCard(
                    child: Row(
                      children: [
                        _CircularScore(score: (risk * 100).toInt(), color: color, suffix: '%'),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusBadge(text: level.toUpperCase(), color: color),
                              const SizedBox(height: 6),
                              Text(_ago(data['predictedAt']), style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              _HistoryList(
                col: AppConstants.colChatHistory,
                uid: _uid,
                extraWhere: {'role': 'user'},
                orderField: 'timestamp',
                emptyTitle: 'Aucun chat',
                emptySubtitle: 'Vos questions à l\'assistante Hermona.',
                emptyIcon: Iconsax.message,
                itemBuilder: (ctx, data, id) => GlassCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Iconsax.message_text, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['content'] ?? '', style: const TextStyle(fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Text(_ago(data['timestamp']), style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _ago(dynamic ts) {
    DateTime dt;
    if (ts is String) dt = DateTime.parse(ts);
    else if (ts is Timestamp) dt = ts.toDate();
    else return '';
    return timeago.format(dt, locale: 'fr');
  }
}

class _HistoryList extends StatelessWidget {
  final String col;
  final String? uid;
  final String orderField;
  final String emptyTitle, emptySubtitle;
  final IconData emptyIcon;
  final Map<String, dynamic>? extraWhere;
  final Widget Function(BuildContext ctx, Map<String, dynamic> data, String id) itemBuilder;

  const _HistoryList({
    required this.col, this.uid, required this.orderField,
    required this.emptyTitle, required this.emptySubtitle, required this.emptyIcon,
    required this.itemBuilder, this.extraWhere,
  });

  @override
  Widget build(BuildContext context) {
    Query q = FirebaseFirestore.instance.collection(col).where('userId', isEqualTo: uid);
    if (extraWhere != null) extraWhere!.forEach((k, v) => q = q.where(k, isEqualTo: v));

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 180, 24, 24),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, __) => const SkeletonBox(width: double.infinity, height: 100),
          );
        }
        
        final docs = snap.data?.docs.toList() ?? [];
        docs.sort((a, b) {
           final dataA = a.data() as Map<String, dynamic>;
           final dataB = b.data() as Map<String, dynamic>;
           final tA = dataA[orderField];
           final tB = dataB[orderField];
           if (tA == null || tB == null) return 0;
           DateTime dtA = tA is String ? DateTime.parse(tA) : (tA as Timestamp).toDate();
           DateTime dtB = tB is String ? DateTime.parse(tB) : (tB as Timestamp).toDate();
           return dtB.compareTo(dtA);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, size: 64, color: AppColors.textSecondaryDark.withOpacity(0.2)),
                const SizedBox(height: 24),
                Text(emptyTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                Text(emptySubtitle, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
              ],
            ),
          ).animate().fadeIn();
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 180, 24, 100),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return PremiumFadeIn(delay: i * 100, child: itemBuilder(ctx, data, docs[i].id));
          },
        );
      },
    );
  }
}

class _CircularScore extends StatelessWidget {
  final int score;
  final Color color;
  final String suffix;
  const _CircularScore({required this.score, required this.color, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Text('$score$suffix', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])));
  }
}
