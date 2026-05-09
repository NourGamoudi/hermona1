import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/features/messaging/data/services/messaging_service.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _svc = MessagingService();

  @override 
  void initState() { 
    super.initState(); 
    timeago.setLocaleMessages('fr', timeago.FrMessages()); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Messagerie Anonyme'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_1),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -50,
            right: -50,
            child: _Blob(size: 250, color: AppColors.primary.withValues(alpha: 0.05)),
          ),

          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 60),
              
              // Safety Warning
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: GlassCard(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Iconsax.shield_tick, color: AppColors.warning, size: 20),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Messagerie 100% anonyme. Ne partagez jamais vos données réelles.',
                          style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.1),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _svc.getConversations(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: 4,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (_, __) => const SkeletonBox(width: double.infinity, height: 80),
                      );
                    }
                    
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.message_text, size: 64, color: AppColors.textSecondaryDark.withValues(alpha: 0.2)),
                            const SizedBox(height: 24),
                            const Text('Aucune conversation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                            const SizedBox(height: 8),
                            const Text('Démarrez un chat depuis le forum.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
                          ],
                        ),
                      ).animate().fadeIn();
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        final date = d['lastMessageAt'] is Timestamp ? (d['lastMessageAt'] as Timestamp).toDate() : DateTime.now();
                        
                        return PremiumFadeIn(
                          delay: i * 100,
                          child: GlassCard(
                            onTap: () => ctx.push('/messages/${docs[i].id}'),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                _AnonymAvatar(seed: docs[i].id),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('MEMBRE HERMONA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                                          Text(timeago.format(date, locale: 'fr'), style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        d['lastMessage'] ?? '',
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.3),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _ConversationMenu(onDelete: () => _svc.deleteConversation(docs[i].id)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnonymAvatar extends StatelessWidget {
  final String seed;
  const _AnonymAvatar({required this.seed});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.5), AppColors.secondary.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const Center(child: Icon(Iconsax.user, color: Colors.white, size: 20)),
    );
  }
}

class _ConversationMenu extends StatelessWidget {
  final VoidCallback onDelete;
  const _ConversationMenu({required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondaryDark),
      padding: EdgeInsets.zero,
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'del',
          child: Row(
            children: [
              Icon(Iconsax.trash, size: 16, color: AppColors.error),
              SizedBox(width: 12),
              Text('Supprimer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
      onSelected: (v) { if (v == 'del') onDelete(); },
    );
  }
}

class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])));
  }
}
