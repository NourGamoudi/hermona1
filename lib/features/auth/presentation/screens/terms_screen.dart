import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/localization/app_localizations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('terms_title_appbar')),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(Iconsax.shield_tick, color: AppTheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(l.translate('terms_header'),
                style: Theme.of(context).textTheme.titleLarge)),
            ]),
          ),
          const SizedBox(height: 24),
          _s(context, l.translate('terms_section_1_title'), l.translate('terms_section_1_content')),
          _s(context, l.translate('terms_section_2_title'), l.translate('terms_section_2_content')),
          _s(context, l.translate('terms_section_3_title'), l.translate('terms_section_3_content')),
          _s(context, l.translate('terms_section_4_title'), l.translate('terms_section_4_content')),
          _s(context, l.translate('terms_section_5_title'), l.translate('terms_section_5_content')),
          _s(context, l.translate('terms_section_6_title'), l.translate('terms_section_6_content')),
          _s(context, l.translate('terms_section_7_title'), l.translate('terms_section_7_content')),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3))),
            child: Text(
              l.translate('terms_medical_note'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.info)),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _s(BuildContext ctx, String title, String content) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(ctx).textTheme.titleLarge),
      const SizedBox(height: 6),
      Text(content, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6)),
    ]),
  );
}
