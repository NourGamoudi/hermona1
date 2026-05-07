import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/forum_service.dart';
import '../../../messaging/data/services/messaging_service.dart';
import '../cubit/forum_cubit.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});
  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  String _category = 'Tous', _sort = 'date', _search = '';
  final _searchCtrl = TextEditingController();
  final _svc = ForumService();

  @override
  void initState() { 
    super.initState(); 
    timeago.setLocaleMessages('fr', timeago.FrMessages()); 
  }
  
  @override 
  void dispose() { 
    _searchCtrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final cats = ['Tous', ...AppConstants.forumCategories];
    final size = MediaQuery.of(context).size;

    return BlocProvider(
      create: (ctx) => ForumCubit(_svc)..loadPosts(category: _category == 'Tous' ? null : _category, sort: _sort),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Communauté Hermona'),
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left_1),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.info_circle, color: AppColors.primary), 
              onPressed: _safetyNotice
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/forum/create'),
          backgroundColor: AppColors.primary,
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Iconsax.add, color: Colors.white),
          label: const Text('EXPRIMER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
        body: Stack(
          children: [
            // Background
            Positioned(
              top: -50,
              right: -50,
              child: _Blob(size: 250, color: AppTheme.primary.withOpacity(0.05)),
            ),

            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 60),
                
                // Search & Filter Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      GlassCard(
                        padding: EdgeInsets.zero,
                        borderRadius: 20,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _search = v),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un sujet...',
                            prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _SortChip(label: 'RÉCENT', icon: Iconsax.clock, active: _sort == 'date', onTap: () {
                            setState(() => _sort = 'date');
                            context.read<ForumCubit>().loadPosts(category: _category == 'Tous' ? null : _category, sort: 'date');
                          }),
                          const SizedBox(width: 10),
                          _SortChip(label: 'POPULAIRE', icon: Iconsax.trend_up, active: _sort == 'popular', onTap: () {
                            setState(() => _sort = 'popular');
                            context.read<ForumCubit>().loadPosts(category: _category == 'Tous' ? null : _category, sort: 'popular');
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Category List
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final c = cats[i];
                      final sel = _category == c;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _category = c);
                          context.read<ForumCubit>().loadPosts(category: c == 'Tous' ? null : c, sort: _sort);
                        },
                        child: AnimatedContainer(
                          duration: 300.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: sel ? Colors.transparent : Colors.white.withOpacity(0.1)),
                          ),
                          child: Center(
                            child: Text(
                              c.toUpperCase(),
                              style: TextStyle(
                                color: sel ? Colors.white : AppColors.textSecondaryDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Post List
                Expanded(
                  child: BlocBuilder<ForumCubit, ForumState>(
                    builder: (ctx, state) {
                      if (state is ForumLoading) {
                        return ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: 4,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (_, __) => const SkeletonBox(width: double.infinity, height: 120),
                        );
                      }
                      if (state is ForumLoaded) {
                        var docs = state.posts;
                        if (_search.isNotEmpty) {
                          docs = docs.where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            final q = _search.toLowerCase();
                            return (data['title'] as String? ?? '').toLowerCase().contains(q) ||
                                   (data['content'] as String? ?? '').toLowerCase().contains(q);
                          }).toList();
                        }
                        if (docs.isEmpty) {
                          return const Center(child: Text('Aucun résultat trouvé.', style: TextStyle(color: AppColors.textSecondaryDark)));
                        }
                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (ctx, i) => _ForumCard(
                            data: docs[i].data() as Map<String, dynamic>,
                            postId: docs[i].id,
                            svc: _svc,
                            delay: i * 100,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _safetyNotice() => showDialog(context: context, builder: (ctx) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
    child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(children: [Icon(Iconsax.shield_tick, color: AppTheme.primary), const SizedBox(width: 12), const Text('Espace Sécurisé')]),
      content: const Text('🔒 Forum 100% anonyme.\n\n⚠️ Ne partagez JAMAIS :\n• Votre nom réel\n• Votre adresse\n• Votre téléphone\n\n🚨 Signalez tout contenu suspect.', style: TextStyle(height: 1.6, fontSize: 14)),
      actions: [PrimaryButton(label: 'COMPRIS !', onTap: () => Navigator.pop(ctx))],
    ),
  ));
}

class _ForumCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String postId;
  final ForumService svc;
  final int delay;
  const _ForumCard({required this.data, required this.postId, required this.svc, required this.delay});

  @override
  State<_ForumCard> createState() => _ForumCardState();
}

class _ForumCardState extends State<_ForumCard> {
  bool _liked = false;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    widget.svc.isLiked(widget.postId).then((v) { if (mounted) setState(() => _liked = v); });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isOwn = d['authorId'] == _uid;
    final likes = d['likesCount'] as int? ?? 0;
    final replies = d['repliesCount'] as int? ?? 0;
    final date = d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : DateTime.now();

    return PremiumFadeIn(
      delay: widget.delay,
      child: GlassCard(
        onTap: () => context.push('/forum/${widget.postId}'),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AuthorBadge(authorId: d['authorId']),
                const Spacer(),
                Text(timeago.format(date, locale: 'fr'), style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
                if (isOwn) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _confirmDelete,
                    child: const Icon(Iconsax.trash, size: 16, color: AppColors.error),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, height: 1.3)),
            const SizedBox(height: 8),
            Text(
              d['content'] ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _InteractionItem(
                  icon: _liked ? Iconsax.heart5 : Iconsax.heart,
                  count: likes,
                  color: _liked ? AppColors.error : AppColors.textSecondaryDark,
                  onTap: () async {
                    await widget.svc.toggleLike(targetId: widget.postId, targetCollection: AppConstants.colForumPosts, counterField: 'likesCount');
                    setState(() => _liked = !_liked);
                  },
                ),
                const SizedBox(width: 20),
                _InteractionItem(
                  icon: Iconsax.message,
                  count: replies,
                  color: AppColors.textSecondaryDark,
                ),
                if (!isOwn) ...[
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () async {
                      final convId = await MessagingService().getOrCreateConversation(d['authorId']);
                      if (mounted) context.push('/messages/$convId');
                    },
                    child: const Row(
                      children: [
                        Icon(Iconsax.send_1, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('DIRECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: _reportDialog,
                  child: const Icon(Iconsax.flag, size: 16, color: AppColors.textSecondaryDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() => showDialog(context: context, builder: (ctx) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Supprimer ?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULER')),
      ElevatedButton(onPressed: () async { await widget.svc.deletePost(widget.postId); Navigator.pop(ctx); }, child: const Text('OUI')),
    ],
  ));

  void _reportDialog() {
    String? reason;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Signaler ce contenu'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ...['Spam', 'Harcèlement', 'Contenu médical dangereux', 'Haineux'].map((r) =>
          RadioListTile<String>(activeColor: AppColors.primary, title: Text(r, style: const TextStyle(fontSize: 14)), value: r, groupValue: reason,
            onChanged: (v) => setSt(() => reason = v), contentPadding: EdgeInsets.zero)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULER')),
        PrimaryButton(label: 'SIGNALER', width: 120, onTap: reason == null ? null : () async {
          await widget.svc.reportContent(targetId: widget.postId, targetType: 'post', reason: reason!);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci pour votre signalement.')));
        }),
      ],
    )));
  }
}

class _AuthorBadge extends StatelessWidget {
  final String authorId;
  const _AuthorBadge({required this.authorId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(AppConstants.colPublicProfiles).doc(authorId).get(),
      builder: (ctx, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final pseudo = data?['pseudonym'] ?? 'Anonyme';
        final aIdx = data?['avatarIndex'] ?? 0;
        final avatars = ['🦋', '✨', '🌸', '💖', '🌙', '🌈'];
        final avatar = (aIdx >= 0 && aIdx < avatars.length) ? avatars[aIdx] : '🌸';

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
              child: Center(child: Text(avatar, style: const TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 10),
            Text(pseudo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        );
      },
    );
  }
}

class _InteractionItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback? onTap;
  const _InteractionItem({required this.icon, required this.count, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary : Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? AppColors.primary : AppColors.textSecondaryDark),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: active ? AppColors.primary : AppColors.textSecondaryDark, letterSpacing: 0.5)),
          ],
        ),
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
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])),
    );
  }
}
