import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



// ─────────────────────────────────────────────────────────────────────────────

// AppColors – palette complète de l'application

// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // Vibrant Primary Palette
  static const Color primary      = Color(0xFFE85886); // Luxury Pink
  static const Color primaryDark  = Color(0xFFC7436D);
  static const Color primaryLight = Color(0xFFFF85AA);
  static const Color secondary    = Color(0xFF6B5AE0); // Deep Indigo
  static const Color accent       = Color(0xFF45D9B3); // Mint Crystal

  // Backgrounds & Surfaces
  static const Color bgLight      = Color(0xFFF9FAFE);
  static const Color bgDark       = Color(0xFF0D0F14); // Deep Obsidian
  
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark  = Color(0xFF161922);
  
  // Text Tokens
  static const Color textPrimaryLight   = Color(0xFF1A1C24);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark    = Color(0xFFF8FAFC);
  static const Color textSecondaryDark  = Color(0xFF94A3B8);

  // Functional Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // Glassmorphism & Dividers
  static const glassWhite = Color(0xB3FFFFFF); 
  static const glassBlack = Color(0x1A000000); 

  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark  = Color(0xFF2D3748);

  // Severity Colors
  static const Color severityNormal   = success;
  static const Color severityModerate = warning;
  static const Color severitySevere   = error;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Surface Extensions
  static const Color cardLight = Colors.white;
  static const Color cardDark  = Color(0xFF1E222D);
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
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge  : GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w900,  color: textPri, letterSpacing: -0.5),
        displayMedium : GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w800,  color: textPri, letterSpacing: -0.5),
        displaySmall  : GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: textPri),
        headlineLarge : GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textPri, letterSpacing: -0.2),
        headlineMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textPri),
        bodyLarge  : GoogleFonts.inter(fontSize: 16, color: textPri, height: 1.5),
        bodyMedium : GoogleFonts.inter(fontSize: 14, color: textPri, height: 1.5),
        bodySmall  : GoogleFonts.inter(fontSize: 12, color: textSec),
        labelLarge : GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPri, letterSpacing: 0.1),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w800, color: textPri),
        iconTheme: IconThemeData(color: textPri, size: 20),
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
        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: divider.withOpacity(0.5), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primary, width: 2)),
        hintStyle: GoogleFonts.inter(color: textSec.withOpacity(0.6), fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        selectedColor: _primary,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
    );
  }
}

