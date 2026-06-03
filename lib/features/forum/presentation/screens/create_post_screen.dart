// FILE: features/forum/presentation/screens/create_post_screen.dart

import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:go_router/go_router.dart';

import 'package:iconsax/iconsax.dart';

import 'package:acneia/core/constants/app_constants.dart';

import 'package:acneia/core/theme/app_theme.dart';

import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/core/localization/app_localizations.dart';
import 'package:acneia/features/forum/data/services/forum_service.dart';



class CreatePostScreen extends StatefulWidget {

  const CreatePostScreen({super.key});

  @override State<CreatePostScreen> createState() => _CreatePostScreenState();

}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String _translateCategory(String cat, BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (cat) {
      case 'Général': return l.translate('cat_general');
      case 'Routine beauté': return l.translate('cat_routine');
      case 'Alimentation': return l.translate('cat_diet');
      case 'Hormones': return l.translate('cat_hormones');
      case 'Traitements': return l.translate('cat_treatments');
      case 'Témoignages': return l.translate('cat_stories');
      case 'Questions': return l.translate('cat_questions');
      default: return cat;
    }
  }


  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController(), _contentCtrl = TextEditingController();

  String _cat = AppConstants.forumCategories.first;

  bool _loading = false;

  final _svc = ForumService();



  @override void dispose() { _titleCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }



  Future<void> _submit() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {

      final id = await _svc.createPost(title: _titleCtrl.text.trim(), content: _contentCtrl.text.trim(), category: _cat);

      if (mounted) context.go('/forum/$id');

    } catch (e) {

      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l.translate('error_prefix')}: $e'), backgroundColor: AppColors.error));

        setState(() => _loading = false);

      }

    }

  }



  @override

  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(

      appBar: AppBar(title: Text(l.translate('new_post_title'))),

      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Container(padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.info.withValues(alpha: 0.25))),

          child: Row(children: [const Icon(Iconsax.shield_tick, color: AppColors.info, size: 18), const SizedBox(width: 10),

            Expanded(child: Text(l.translate('anon_post_warning'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.info)))])).animate().fadeIn(),

        const SizedBox(height: 22),

        Text(l.translate('category_label'), style: Theme.of(context).textTheme.labelLarge),

        const SizedBox(height: 8),

        Wrap(spacing: 8, runSpacing: 8, children: AppConstants.forumCategories.map((c) {

          final sel = _cat == c;

          return GestureDetector(onTap: () => setState(() => _cat = c),

            child: AnimatedContainer(duration: const Duration(milliseconds: 200),

              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

              decoration: BoxDecoration(color: sel ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(50)),

              child: Text(_translateCategory(c, context), style: TextStyle(color: sel ? Colors.white : AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600))));

        }).toList()).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 22),

        Text(l.translate('title_with_asterisk'), style: Theme.of(context).textTheme.labelLarge),

        const SizedBox(height: 8),

        TextFormField(controller: _titleCtrl,

          decoration: InputDecoration(hintText: l.translate('post_title_hint')),

          validator: (v) => (v == null || v.trim().length < 5) ? l.translate('min_5_chars') : null,

          maxLength: 100).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 14),

        Text(l.translate('content_with_asterisk'), style: Theme.of(context).textTheme.labelLarge),

        const SizedBox(height: 8),

        TextFormField(controller: _contentCtrl, maxLines: 8, minLines: 5,

          decoration: InputDecoration(hintText: l.translate('post_content_hint'), alignLabelWithHint: true),

          validator: (v) => (v == null || v.trim().length < 20) ? l.translate('min_20_chars') : null,

          maxLength: 2000).animate().fadeIn(delay: 280.ms),

        const SizedBox(height: 28),

        PrimaryButton(label: l.translate('publish_anon_label'), icon: Iconsax.send_1, onTap: _submit, isLoading: _loading)
            .animate().fadeIn(delay: 360.ms),

        const SizedBox(height: 40),

      ]))),

    );

  }

}



