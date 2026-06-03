import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/core/localization/app_localizations.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.translate('notification_center')),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: l.translate('messages')),
              Tab(text: l.translate('alerts') == 'alerts' ? 'Alertes' : l.translate('alerts')),
            ],
            indicatorColor: const Color(0xFFF9A8D4), // AppTheme.primary equivalent if not using it directly
            labelColor: const Color(0xFFF9A8D4),
            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : Colors.black87,
          ),
        ),
        body: uid == null 
          ? Center(child: Text(l.translate('notifications_connect')))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.colNotifications)
                  .where('userId', isEqualTo: uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
  
                final docs = snapshot.data?.docs ?? [];
                
                // Mark as read (background)
                _markAllAsRead(docs);

                final messageDocs = docs.where((d) {
                  final type = (d.data() as Map)['type']?.toString().toUpperCase() ?? '';
                  return type == 'MESSAGE';
                }).toList();

                final alertDocs = docs.where((d) {
                  final type = (d.data() as Map)['type']?.toString().toUpperCase() ?? '';
                  return type != 'MESSAGE';
                }).toList();
  
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

  void _markAllAsRead(List<QueryDocumentSnapshot> docs) {
    final batch = FirebaseFirestore.instance.batch();
    bool hasUnread = false;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final isRead = data['read'] == true; // Safely check if true
      if (!isRead) {
        batch.update(doc.reference, {'read': true});
        hasUnread = true;
      }
    }
    if (hasUnread) batch.commit();
  }

  Widget _buildList(BuildContext context, List<QueryDocumentSnapshot> docs, String emptyTitle, String emptySub) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.notification_status, size: 80, color: AppTheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(emptyTitle, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : const Color(0xFF4F4F4F), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(emptySub, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark.withValues(alpha: 0.7) : Colors.black54, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        return _NotificationCard(data: data);
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
      case 'SURVEY_DAILY':
      case 'SURVEY_WEEKLY':
        icon = Iconsax.task;
        color = AppTheme.primary;
        break;
      case 'MESSAGE':
        icon = Iconsax.message_text;
        color = AppTheme.primary;
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
      onTap: () {
        final meta = data['metadata'] as Map<String, dynamic>?;
        if (type == 'MESSAGE' && meta != null && meta['conversationId'] != null) {
          context.push('/messages/${meta['conversationId']}');
        } else if (type == 'FORUM' && meta != null && meta['postId'] != null) {
          context.push('/forum/${meta['postId']}');
        } else if (type == 'SURVEY_DAILY') {
          context.push('/daily-survey');
        } else if (type == 'SURVEY_WEEKLY') {
          context.push('/weekly-survey');
        } else if (type == 'RISK') {
          context.go('/recommendation');
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate(data['title'] ?? 'Notification'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      DateFormat('HH:mm').format(timestamp),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).translate(data['body'] ?? ''),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMMM yyyy', AppLocalizations.of(context).locale.languageCode).format(timestamp),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}








































