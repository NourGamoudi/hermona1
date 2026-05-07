import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _idx(String loc) {
    if (loc.startsWith('/home'))           return 0;
    if (loc.startsWith('/recommendation') || loc.startsWith('/my-routine')) return 1;
    if (loc.startsWith('/prediction'))      return 2;
    if (loc.startsWith('/profile'))         return 3;
    return 0;
  }

  void _go(BuildContext ctx, int i) {
    const routes = ['/home', '/my-routine', '/prediction', '/profile'];
    ctx.go(routes[i]);
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _idx(loc);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surface,
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Iconsax.home_2,   activeIcon: Iconsax.home_25,   label: 'Accueil',    active: idx == 0, onTap: () => _go(context, 0)),
                _NavItem(icon: Iconsax.magic_star, activeIcon: Iconsax.magic_star, label: 'Routine',    active: idx == 1, onTap: () => _go(context, 1)),
                _NavItem(icon: Iconsax.chart_2,   activeIcon: Iconsax.chart_25,  label: 'Analyse', active: idx == 2, onTap: () => _go(context, 2)),
                _NavItem(icon: Iconsax.user,      activeIcon: Iconsax.user5,     label: 'Profil',     active: idx == 3, onTap: () => _go(context, 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? activeIcon : icon, color: active ? p : Colors.grey.shade400, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: active ? p : Colors.grey.shade400)),
        ],
      ),
    );
  }
}
