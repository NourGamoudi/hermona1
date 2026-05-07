import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



// ─────────────────────────────────────────────────────────────────────────────

// AppColors – palette complète de l'application

// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  static const Color primary      = Color(0xFFFF69B4); // Hot Pink
  static const Color primaryDark  = Color(0xFFE05297);
  static const Color primaryLight = Color(0xFFFFB6C1); // Light Pink
  static const Color secondary    = Color(0xFF9B59B6); // Amethyst
  static const Color accent       = Color(0xFFFFD700); // Gold

  static const Color bgLight      = Color(0xFFFFF0F3); // Soft Blush Pink
  static const Color bgDark       = Color(0xFF0F0F0F); 
  
  static const Color surfaceLight = Color(0xFFFFE4E9); // Deeper Soft Pink
  static const Color surfaceDark  = Color(0xFF1A1A1A);
  
  static const Color textPrimaryLight   = Color(0xFF141413); // Solid Ink
  static const Color textSecondaryLight = Color(0xFF4A4A4A); // Solid Grey
  static const Color textMutedPink      = Color(0xFF8E6A74); // Softer, luxury muted pink
  static const Color textPrimaryDark    = Color(0xFFFFFFFF);
  static const Color textSecondaryDark  = Color(0xFF94A3B8);

  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error   = Color(0xFFE74C3C);
  static const Color info    = Color(0xFF3498DB);

  static const Color dividerLight = Color(0xFFFFD1DC);
  static const Color dividerDark  = Color(0xFF2D3748);
  static const Color cardDark     = Color(0xFF1A1A1A);

  static const Color severityNormal     = success;
  static const Color severityModerate   = warning;
  static const Color severitySevere     = error;
  static const Color severityVerySevere = Color(0xFF8E44AD); // Deep Purple
}



// ─────────────────────────────────────────────────────────────────────────────

// AppTheme – thème Material 3 avec couleur primaire dynamique

// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  static Color _primary = AppColors.primary;

  static void setPrimary(Color c) => _primary = c;
  static Color get primary => _primary;

  static ThemeData light() => _build(false);
  static ThemeData dark()  => _build(true);

  static ThemeData _build(bool isDark) {
    final bg      = isDark ? AppColors.bgDark      : AppColors.bgLight;
    final surface = isDark ? AppColors.surfaceDark  : AppColors.surfaceLight;
    final textPri = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimaryLight;
    final textSec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final divider = isDark ? AppColors.dividerDark  : AppColors.dividerLight;

    return (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness  : isDark ? Brightness.dark : Brightness.light,
        primary     : _primary,
        onPrimary   : Colors.white,
        secondary   : AppColors.secondary,
        onSecondary : Colors.white,
        surface     : surface,
        onSurface   : textPri,
        error       : AppColors.error,
        onError     : Colors.white,
        background  : bg,
        onBackground: textPri,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge  : GoogleFonts.fraunces(fontSize: 48, fontWeight: FontWeight.w400, color: textPri, letterSpacing: -1.5),
        displayMedium : GoogleFonts.fraunces(fontSize: 36, fontWeight: FontWeight.w400, color: textPri, letterSpacing: -1.0),
        displaySmall  : GoogleFonts.fraunces(fontSize: 28, fontWeight: FontWeight.w400, color: textPri, letterSpacing: -0.5),
        headlineLarge : GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: textPri),
        headlineMedium: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: textPri),
        bodyLarge  : GoogleFonts.outfit(fontSize: 16, color: textPri, height: 1.55),
        bodyMedium : GoogleFonts.outfit(fontSize: 14, color: textPri, height: 1.55),
        bodySmall  : GoogleFonts.outfit(fontSize: 12, color: textSec),
        labelLarge : GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: textPri),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        centerTitle: true,
        titleTextStyle: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: textPri),
        iconTheme: IconThemeData(color: _primary, size: 24), // Use Primary color for icons to ensure they POP
      ),
      cardTheme: CardThemeData(
        color: surface, 
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: divider.withOpacity(0.5), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary, 
          foregroundColor: Colors.white, 
          elevation: 8,
          shadowColor: _primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, 
        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? divider.withOpacity(0.5) : AppColors.dividerLight, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primary, width: 2)),
        hintStyle: GoogleFonts.inter(color: textSec.withOpacity(0.6), fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.surfaceLight,
        selectedColor: _primary,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : AppColors.dividerLight),
      ),
    );
  }
}

