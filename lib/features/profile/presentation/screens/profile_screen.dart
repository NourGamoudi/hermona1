import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/core/localization/app_localizations.dart';
import 'package:acneia/core/services/language_service.dart';
import 'package:acneia/main.dart';
import 'package:acneia/features/questionnaire/domain/entities/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).get();
    if (mounted) setState(() { _user = doc.data(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final name = '${_user?['firstName'] ?? ''} ${_user?['lastName'] ?? ''}'.trim();
    final email = _user?['email'] ?? '';
    final init = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary.withValues(alpha: 0.2), AppColors.secondary.withValues(alpha: 0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  _Blob(size: 200, color: AppColors.primary.withValues(alpha: 0.1)).animate().moveY(begin: 0, end: 20, duration: 3.seconds, curve: Curves.easeInOut),
                  
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primary, AppColors.primaryDark]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Center(child: Text(init, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900))),
                      ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 16),
                      Text(name, style: Theme.of(context).textTheme.displaySmall),
                      Text(email, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStats(context),
                const SizedBox(height: 32),

                _buildSection(context, l.translate('section_profile'), [
                  _ProfileItem(Iconsax.user, l.translate('mes_informations'), '${l.translate('age_label')}: ${_user?['age'] ?? '?'}, ${l.translate('imc_label')}: ${_user?['imc'] ?? '?'}', () {
                    if (_user != null) {
                      final p = UserProfile.fromJson(_user!, FirebaseAuth.instance.currentUser!.uid);
                      context.push('/onboarding', extra: p);
                    }
                  }),
                  _ProfileItem(Iconsax.magic_star, l.translate('skin_type'), l.translate(_user?['skinType']?.toString().toLowerCase() ?? 'unknown'), null),
                ]),

                const SizedBox(height: 24),

                _buildSection(context, l.translate('section_tracking'), [
                  _ProfileItem(Iconsax.scan, l.translate('my_analyses'), l.translate('detection_results_sub'), () => context.push('/history?tab=0')),
                  _ProfileItem(Iconsax.chart_21, l.translate('my_predictions'), l.translate('ai_history_sub'), () => context.push('/history?tab=2')),
                  _ProfileItem(Iconsax.message_text, l.translate('conversations'), l.translate('assistant_messages_sub'), () => context.push('/messages')),
                ]),

                const SizedBox(height: 24),

                _buildSection(context, l.translate('personalization'), [
                  _ProfileItem(Iconsax.moon, l.translate('dark_theme'), l.translate('enable_disable'), null, trailing: const _ThemeSwitch()),
                  _ProfileItem(Iconsax.colorfilter, l.translate('brand_color'), l.translate('choose_color_sub'), () => _colorPicker(context)),
                  _ProfileItem(Iconsax.language_square, l.translate('language'), l.translate('change_lang_sub'), () => _languagePicker(context)),
                ]),

                const SizedBox(height: 48),

                PrimaryButton(
                  label: l.translate('logout').toUpperCase(),
                  color: AppColors.error,
                  onTap: () => _logout(context),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final l = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Row(
      children: [
        _StatTile(label: l.translate('analyses'), icon: Iconsax.scan, col: AppConstants.colDetections, uid: uid),
        const SizedBox(width: 12),
        _StatTile(label: l.translate('risks'), icon: Iconsax.chart_2, col: AppConstants.colPredictions, uid: uid),
        const SizedBox(width: 12),
        _StatTile(
          label: l.translate('posts'), 
          icon: Iconsax.people, 
          col: AppConstants.colForumPosts, 
          uid: uid,
          field: 'authorId', // Forum posts use authorId
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildSection(BuildContext context, String title, List<_ProfileItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondaryDark)),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  ListTile(
                    onTap: e.value.onTap,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(e.value.icon, size: 18, color: AppColors.primary),
                    ),
                    title: Text(e.value.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text(e.value.sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                    trailing: e.value.trailing ?? const Icon(Iconsax.arrow_right_3, size: 14, color: AppColors.textSecondaryDark),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  ),
                  if (!isLast) Divider(height: 1, indent: 70, color: Colors.white.withValues(alpha: 0.05)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _colorPicker(BuildContext context) {
    final l = AppLocalizations.of(context);
    Color current = AppTheme.primary;
    showDialog(context: context, builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(l.translate('customize_hermona')),
        content: SingleChildScrollView(child: ColorPicker(
          pickerColor: current, onColorChanged: (c) => current = c, enableAlpha: false, labelTypes: const [],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.translate('cancel'))),
          PrimaryButton(label: l.translate('apply'), width: 120, onTap: () async {
            final navigator = Navigator.of(ctx);
            final appState = HermonaApp.of(context);
            appState?.setPrimaryColor(current);
            final p = await SharedPreferences.getInstance();
            await p.setInt(AppConstants.keyPrimaryColor, current.toARGB32());
            if (mounted) {
              navigator.pop();
            }
          }),
        ],
      ),
    ));
  }

  void _languagePicker(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = l.locale.languageCode;

    showDialog(context: context, builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(l.translate('choose_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langTile(ctx, 'Français', 'fr', current == 'fr'),
            _langTile(ctx, 'English', 'en', current == 'en'),
          ],
        ),
      ),
    ));
  }

  Widget _langTile(BuildContext context, String label, String code, bool active) {
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: active ? FontWeight.w900 : FontWeight.normal, color: active ? AppColors.primary : null)),
      trailing: active ? Icon(Icons.check_circle, color: AppColors.primary) : null,
      onTap: () async {
        final navigator = Navigator.of(context);
        debugPrint("DEBUG AUDIT: Switching language to $code");
        await LanguageService().setLanguage(code);
        if (context.mounted) {
          HermonaApp.of(context)?.setLocale(Locale(code));
          navigator.pop();
        }
      },
    );
  }

  void _logout(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog(context: context, builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l.translate('logout_confirm_title')),
        content: Text(l.translate('logout_confirm_desc')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.translate('stay'))),
          PrimaryButton(label: l.translate('leave'), width: 100, color: AppColors.error, onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              context.go('/welcome');
            }
          }),
        ],
      ),
    ));
  }
}

class _StatTile extends StatelessWidget {
  final String label, col; 
  final IconData icon; 
  final String? uid;
  final String field; // Added field parameter

  const _StatTile({
    required this.label, 
    required this.icon, 
    required this.col, 
    this.uid,
    this.field = 'userId', // Default to userId
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(col)
          .where(field, isEqualTo: uid) // Use the dynamic field name
          .snapshots(),
      builder: (_, snap) => GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 8),
            Text('${snap.data?.docs.length ?? 0}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textSecondaryDark, letterSpacing: 0.5)),
          ],
        ),
      ),
    ),
  );
}

class _ThemeSwitch extends StatefulWidget {
  const _ThemeSwitch();
  @override State<_ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<_ThemeSwitch> {
  bool _dark = false;
  @override
  void initState() { super.initState();
    SharedPreferences.getInstance().then((p) => setState(() => _dark = p.getBool(AppConstants.keyThemeMode) ?? false));
  }
  @override
  Widget build(BuildContext context) => Switch.adaptive(
    value: _dark,
    activeThumbColor: AppColors.primary,
    onChanged: (v) async {
      setState(() => _dark = v);
      final appState = HermonaApp.of(context);
      final p = await SharedPreferences.getInstance();
      await p.setBool(AppConstants.keyThemeMode, v);
      if (mounted) {
        appState?.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
      }
    },
  );
}

class _ProfileItem { 
  final IconData icon; final String title, sub; final VoidCallback? onTap; final Widget? trailing;
  const _ProfileItem(this.icon, this.title, this.sub, this.onTap, {this.trailing}); 
}

class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])));
  }
}
