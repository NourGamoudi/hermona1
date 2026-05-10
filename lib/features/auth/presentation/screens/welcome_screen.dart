import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:acneia/core/services/language_service.dart';
import 'package:acneia/main.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final size = MediaQuery.of(context).size;
    
    // The exact vibrant pink from the screenshot
    const brandPink = Color(0xFFFF5D8F);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background image — Reversion temporaire pour éviter l'erreur
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.75,
            child: Image.asset(
              'assets/images/hermona_bg.jpg', // On utilise l'image qui existe déjà
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. Gradient: image fades to white more smoothly
          Positioned(
            top: size.height * 0.45,
            left: 0, right: 0,
            height: size.height * 0.35,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                ),
              ),
            ),
          ),

          // 3. Content overlay
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      const _LogoBadge(brandColor: brandPink),
                      const Spacer(),
                      _LanguageToggle(
                        isFr: isFr,
                        brandColor: brandPink,
                        onToggle: (code) => _updateLang(context, code),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms),

                // Push title to match screenshot
                const Spacer(flex: 5),

                // Title — "Reveal Your Skin's Glow"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    isFr ? 'Révèle l\'Éclat\nde ta Peau' : 'Reveal Your\nSkin\'s Glow',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFF5D8F), // Ton code précis #ff5d8f
                      height: 1.0,
                      letterSpacing: -1.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    isFr
                        ? 'Analyse faciale 5 zones, suivi du cycle, et routines expertes personnalisées.'
                        : '5-zone facial analysis, cycle tracking, and personalized expert routines.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, // Encore plus grand pour le style
                      color: const Color(0xFFDD2D4A), // Ton code précis #dd2d4a
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const Spacer(flex: 2),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _OutlinedPillButton(
                        label: isFr ? 'Se connecter' : 'Log In',
                        brandColor: brandPink,
                        onTap: () => context.push('/login'),
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 16),

                      _OutlinedPillButton(
                        label: isFr ? 'Créer un compte' : 'Create Account',
                        brandColor: brandPink,
                        onTap: () => context.push('/register'),
                      ).animate().fadeIn(delay: 750.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Security text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.shield_tick, size: 10, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      'SCIENCE-DRIVEN • ANONYMOUS • SECURE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 900.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateLang(BuildContext context, String code) async {
    final service = LanguageService();
    await service.setLanguage(code);
    if (context.mounted) {
      HermonaApp.of(context)?.setLocale(Locale(code));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _LogoBadge extends StatelessWidget {
  final Color brandColor;
  const _LogoBadge({required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.magic_star5, size: 16, color: brandColor),
          const SizedBox(width: 8),
          Text(
            'HERMONA',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              fontSize: 12,
              color: brandColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _LanguageToggle extends StatelessWidget {
  final bool isFr;
  final Color brandColor;
  final Function(String) onToggle;

  const _LanguageToggle({required this.isFr, required this.brandColor, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _btn(context, 'FR', isFr, () => onToggle('fr')),
          _btn(context, 'EN', !isFr, () => onToggle('en')),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? brandColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _OutlinedPillButton extends StatelessWidget {
  final String label;
  final Color brandColor;
  final VoidCallback onTap;

  const _OutlinedPillButton({required this.label, required this.brandColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: brandColor, width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: brandColor,
          ),
        ),
      ),
    );
  }
}
