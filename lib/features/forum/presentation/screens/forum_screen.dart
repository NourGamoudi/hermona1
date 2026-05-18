import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/core/localization/app_localizations.dart';
import 'package:acneia/features/forum/data/services/forum_service.dart';
import 'package:acneia/features/messaging/data/services/messaging_service.dart';
import '../cubit/forum_cubit.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});
  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  String _category = 'ALL', _sort = 'date', _search = '';
  final _searchCtrl = TextEditingController();
  final _svc = ForumService();

  @override
  void initState() { 
    super.initState(); 
    // timeago is initialized in build or via a listener if needed, 
    // but we can set defaults here.
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    timeago.setLocaleMessages('en', timeago.EnMessages());
  }
  
  @override 
  void dispose() { 
    _searchCtrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Use (key, displayLabel) pairs so category state is language-neutral
    final catKeys = [
      ('ALL', l.translate('all_label')),
      ('Général', l.translate('cat_general')),
      ('Routine', l.translate('cat_routine')),
      ('Alimentation', l.translate('cat_diet')),
      ('Hormones', l.translate('cat_hormones')),
      ('Traitements', l.translate('cat_treatments')),
      ('Témoignages', l.translate('cat_stories')),
      ('Questions', l.translate('cat_questions')),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.translate('hermona_community')),
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
        label: Text(l.translate('express_label'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -50,
            right: -50,
            child: _Blob(size: 250, color: AppTheme.primary.withValues(alpha: 0.05)),
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
                          hintText: l.translate('search_subject_hint'),
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
                        _SortChip(label: l.translate('recent_label'), icon: Iconsax.clock, active: _sort == 'date', onTap: () {
                          setState(() => _sort = 'date');
                          context.read<ForumCubit>().loadPosts(category: _category == 'ALL' ? null : _category, sort: 'date');
                        }),
                        const SizedBox(width: 10),
                        _SortChip(label: l.translate('popular_label'), icon: Iconsax.trend_up, active: _sort == 'popular', onTap: () {
                          setState(() => _sort = 'popular');
                          context.read<ForumCubit>().loadPosts(category: _category == 'ALL' ? null : _category, sort: 'popular');
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
                  itemCount: catKeys.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final key = catKeys[i].$1;
                    final label = catKeys[i].$2;
                    final sel = _category == key;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _category = key);
                        context.read<ForumCubit>().loadPosts(category: key == 'ALL' ? null : key, sort: _sort);
                      },
                      child: AnimatedContainer(
                        duration: 300.ms,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sel ? AppColors.primary.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                          boxShadow: sel ? [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                          ] : null,
                        ),
                        child: Center(
                          child: Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              color: sel ? Colors.white : AppColors.textSecondaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
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
                        return Center(child: Text(l.translate('no_results_found'), style: const TextStyle(color: AppColors.textSecondaryDark)));
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
    );
  }

  void _safetyNotice() {
    final l = AppLocalizations.of(context);
    showDialog(context: context, builder: (ctx) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
    child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(children: [Icon(Iconsax.shield_tick, color: AppTheme.primary), const SizedBox(width: 12), Text(l.translate('secure_space'))]),
      content: Text(l.translate('safety_notice_desc'), style: const TextStyle(height: 1.6, fontSize: 14)),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [PrimaryButton(label: l.translate('got_it'), onTap: () => Navigator.pop(ctx))],
    ),
  ));
  }
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
    final likes = (d['likesCount'] as num?)?.toInt() ?? 0;
    final replies = (d['repliesCount'] as num?)?.toInt() ?? 0;
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
                _AuthorBadge(authorId: d['authorId'], svc: widget.svc),
                const Spacer(),
                Text(timeago.format(date, locale: AppLocalizations.of(context).locale.languageCode), style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
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
                      if (context.mounted) {
                        context.push('/messages/$convId');
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Iconsax.send_1, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(AppLocalizations.of(context).translate('direct_label').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary)),
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

  void _confirmDelete() {
    final l = AppLocalizations.of(context);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l.translate('delete_confirm_title')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.translate('cancel_caps'))),
        ElevatedButton(onPressed: () async {
          final messenger = ScaffoldMessenger.of(ctx);
          final nav = Navigator.of(ctx);
          await widget.svc.deletePost(widget.postId);
          nav.pop();
          messenger.showSnackBar(SnackBar(content: Text(l.translate('post_deleted'))));
        }, child: Text(l.translate('yes_caps'))),
      ],
    ));
  }

  void _reportDialog() {
    final l = AppLocalizations.of(context);
    String? reason;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(l.translate('report_content_title')),
      content: RadioGroup<String>(
        groupValue: reason,
        onChanged: (v) => setSt(() => reason = v),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...[
              l.translate('spam_label'),
              l.translate('harassment_label'),
              l.translate('dangerous_medical_label'),
              l.translate('hateful_label')
            ].map((r) =>
              RadioListTile.adaptive(
                activeColor: AppColors.primary, 
                title: Text(r, style: const TextStyle(fontSize: 14)), 
                value: r, 
                contentPadding: EdgeInsets.zero
              )),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.translate('cancel_caps'))),
        PrimaryButton(label: l.translate('report_caps'), width: 120, onTap: reason == null ? null : () async {
          final messenger = ScaffoldMessenger.of(context);
          final nav = Navigator.of(ctx);
          await widget.svc.reportContent(targetId: widget.postId, targetType: 'post', reason: reason!);
          nav.pop();
          messenger.showSnackBar(SnackBar(content: Text(l.translate('report_thanks'))));
        }),
      ],
    )));
  }
}

class _AuthorBadge extends StatefulWidget {
  final String authorId;
  final ForumService svc;
  const _AuthorBadge({required this.authorId, required this.svc});

  @override
  State<_AuthorBadge> createState() => _AuthorBadgeState();
}

class _AuthorBadgeState extends State<_AuthorBadge> {
  late Future<DocumentSnapshot> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.svc.getAuthorProfile(widget.authorId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _profileFuture,
      builder: (ctx, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final pseudo = data?['pseudonym'] ?? AppLocalizations.of(context).translate('anonymous');
        final aIdx = data?['avatarIndex'] ?? 0;
        final avatars = ['🦋', '✨', '🌸', '💖', '🌙', '🌈'];
        final avatar = (aIdx >= 0 && aIdx < avatars.length) ? avatars[aIdx] : '🌸';

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
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
          color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.1)),
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
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])),
    );
  }
}
