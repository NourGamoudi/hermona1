import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../main.dart';
import '../../../questionnaire/domain/entities/user_profile.dart';

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
                        colors: [AppTheme.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  _Blob(size: 200, color: AppColors.primary.withOpacity(0.1)).animate().moveY(begin: 0, end: 20, duration: 3.seconds, curve: Curves.easeInOut),
                  
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
                          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
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
                _buildStats(),
                const SizedBox(height: 32),

                _buildSection('Mon Profil', [
                  _ProfileItem(Iconsax.user, 'Mes Informations', 'Âge: ${_user?['age'] ?? '?'}, IMC: ${_user?['imc'] ?? '?'}', () {
                    if (_user != null) {
                      final p = UserProfile.fromJson(_user!, FirebaseAuth.instance.currentUser!.uid);
                      context.push('/onboarding', extra: p);
                    }
                  }),
                  _ProfileItem(Iconsax.magic_star, 'Type de Peau', '${_user?['skinType'] ?? 'Inconnu'}', null),
                ]),

                const SizedBox(height: 24),

                _buildSection('Historique & Suivi', [
                  _ProfileItem(Iconsax.scan, 'Mes Analyses', 'Résultats de détection', () => context.push('/history?tab=0')),
                  _ProfileItem(Iconsax.chart_21, 'Mes Prédictions', 'Historique AI', () => context.push('/history?tab=2')),
                  _ProfileItem(Iconsax.message_text, 'Conversations', 'Messages assistante', () => context.push('/messages')),
                ]),

                const SizedBox(height: 24),

                _buildSection('Personnalisation', [
                  _ProfileItem(Iconsax.moon, 'Thème Sombre', 'Activer/Désactiver', null, trailing: const _ThemeSwitch()),
                  _ProfileItem(Iconsax.colorfilter, 'Couleur de Marque', 'Choisir une teinte', () => _colorPicker()),
                ]),

                const SizedBox(height: 48),

                PrimaryButton(
                  label: 'DÉCONNEXION',
                  color: AppColors.error,
                  onTap: _logout,
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Row(
      children: [
        _StatTile(label: 'Analyses', icon: Iconsax.scan, col: AppConstants.colDetections, uid: uid),
        const SizedBox(width: 12),
        _StatTile(label: 'Risques', icon: Iconsax.chart_2, col: AppConstants.colPredictions, uid: uid),
        const SizedBox(width: 12),
        _StatTile(label: 'Posts', icon: Iconsax.people, col: AppConstants.colForumPosts, uid: uid),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildSection(String title, List<_ProfileItem> items) {
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
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(e.value.icon, size: 18, color: AppColors.primary),
                    ),
                    title: Text(e.value.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text(e.value.sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                    trailing: e.value.trailing ?? const Icon(Iconsax.arrow_right_3, size: 14, color: AppColors.textSecondaryDark),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  ),
                  if (!isLast) Divider(height: 1, indent: 70, color: Colors.white.withOpacity(0.05)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _colorPicker() {
    Color current = AppTheme.primary;
    showDialog(context: context, builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Personnaliser Hermona'),
        content: SingleChildScrollView(child: ColorPicker(
          pickerColor: current, onColorChanged: (c) => current = c, enableAlpha: false, labelTypes: const [],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULER')),
          PrimaryButton(label: 'APPLIQUER', width: 120, onTap: () async {
            AppTheme.setPrimary(current);
            final p = await SharedPreferences.getInstance();
            await p.setInt(AppConstants.keyPrimaryColor, current.value);
            if (mounted) setState(() {});
            Navigator.pop(ctx);
          }),
        ],
      ),
    ));
  }

  void _logout() => showDialog(context: context, builder: (ctx) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
    child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Déconnexion'),
      content: const Text('Voulez-vous vraiment quitter votre session Hermona ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('RESTER')),
        PrimaryButton(label: 'QUITTER', width: 100, color: AppColors.error, onTap: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) context.go('/login');
        }),
      ],
    ),
  ));
}

class _StatTile extends StatelessWidget {
  final String label, col; final IconData icon; final String? uid;
  const _StatTile({required this.label, required this.icon, required this.col, this.uid});

  @override
  Widget build(BuildContext context) => Expanded(
    child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(col).where('userId', isEqualTo: uid).snapshots(),
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
    value: _dark, activeColor: AppColors.primary,
    onChanged: (v) async {
      setState(() => _dark = v);
      HermonaApp.of(context)?.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
      final p = await SharedPreferences.getInstance();
      await p.setBool(AppConstants.keyThemeMode, v);
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
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])));
  }
}
