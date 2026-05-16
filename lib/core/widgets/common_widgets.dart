import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PRIMARY BUTTON
/// ─────────────────────────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final Color? color;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final brand = color ?? AppTheme.primary;

    return AnimatedContainer(
      duration: 300.ms,
      width: width ?? double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          shadowColor: brand.withValues(alpha: 0.4),
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// GLASS CARD
/// ─────────────────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.05,
    this.borderRadius = 28,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.surfaceDark.withValues(alpha: opacity)
                  : AppColors.surfaceLight.withValues(alpha: opacity + 0.25), // Stronger pink tint
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppColors.dividerLight.withValues(alpha: 0.8), // Visible pink border
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SKELETON LOADERS
/// ─────────────────────────────────────────────────────────────────────────────
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E212B) : const Color(0xFFF1F5F9),
      highlightColor: isDark ? const Color(0xFF2D3240) : const Color(0xFFFFFFFF),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SECTION HEADER
/// ─────────────────────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// FADE ANIMATION
/// ─────────────────────────────────────────────────────────────────────────────
class PremiumFadeIn extends StatelessWidget {
  final Widget child;
  final int delay;
  final double yOffset;

  const PremiumFadeIn({
    super.key,
    required this.child,
    this.delay = 0,
    this.yOffset = 30,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(delay: delay.ms, duration: 600.ms, curve: Curves.easeOut)
        .moveY(begin: yOffset, end: 0, curve: Curves.easeOutCubic);
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// STATUS BADGE
/// ─────────────────────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double? width;

  const SecondaryButton({super.key, required this.label, required this.onTap, this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          foregroundColor: AppTheme.primary,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    );
  }
}
