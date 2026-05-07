import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/localization/app_localizations.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.translate('notification_center')),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: l.translate('messages')),
              Tab(text: l.translate('alerts')),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
        body: uid == null 
          ? Center(child: Text(l.translate('notifications_connect')))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.colNotifications)
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
  
                final docs = snapshot.data?.docs ?? [];
  
                final sortedDocs = docs.toList()
                  ..sort((a, b) {
                    final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                    final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                  });

                final messageDocs = sortedDocs.where((d) => (d.data() as Map)['type'] == 'MESSAGE').toList();
                final alertDocs   = sortedDocs.where((d) => (d.data() as Map)['type'] != 'MESSAGE').toList();
  
                return TabBarView(
                  children: [
                    _buildList(context, messageDocs, l.translate('no_message'), l.translate('message_desc')),
                    _buildList(context, alertDocs, l.translate('no_alert'), l.translate('alert_desc')),
                  ],
                );
              },
            ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<QueryDocumentSnapshot> docs, String emptyTitle, String emptySub) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.notification_status, size: 80, color: AppColors.primary.withOpacity(0.2))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -10, duration: 2.seconds, curve: Curves.easeInOut),
            const SizedBox(height: 24),
            Text(emptyTitle, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(emptySub, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        return PremiumFadeIn(
          delay: (index * 50).clamp(0, 500),
          child: _NotificationCard(data: data),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NotificationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? 'INFO';
    final timestamp = data['timestamp'] is Timestamp 
        ? (data['timestamp'] as Timestamp).toDate() 
        : DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    Color color;

    switch (type) {
      case 'RISK':
        icon = Iconsax.warning_2;
        color = AppColors.error;
        break;
      case 'CYCLE':
        icon = Iconsax.calendar_1;
        color = AppColors.accent;
        break;
      case 'MESSAGE':
        icon = Iconsax.message_text;
        color = AppColors.primary;
        break;
      case 'FORUM':
        icon = Iconsax.message_programming;
        color = AppColors.secondary;
        break;
      default:
        icon = Iconsax.info_circle;
        color = AppColors.info;
    }

    return GlassCard(
      padding: const EdgeInsets.all(18),
      onTap: () {
        final meta = data['metadata'] as Map<String, dynamic>?;
        if (type == 'MESSAGE' && meta != null && meta['conversationId'] != null) {
          context.push('/messages/${meta['conversationId']}');
        } else if (type == 'FORUM' && meta != null && meta['postId'] != null) {
          context.push('/forum/${meta['postId']}');
        } else if (type == 'RISK') {
          context.go('/recommendation');
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['title'] ?? 'Notification',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2),
                    ),
                    Text(
                      DateFormat('HH:mm').format(timestamp),
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  data['body'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('d MMMM yyyy', AppLocalizations.of(context).locale.languageCode).format(timestamp),
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark.withOpacity(0.6) : AppColors.textSecondaryLight.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}








































