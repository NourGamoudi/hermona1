import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../main.dart';
import '../../../../core/widgets/common_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final size = MediaQuery.of(context).size;
    
    const brandPink = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background image — top 70%
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.7,
            child: Hero(
              tag: 'welcome_bg',
              child: Image.asset(
                'assets/images/hermona_bg.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.2),
              ),
            ),
          ),

          // 2. Glassy Overlay at top for logo
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                ),
              ),
            ),
          ),

          // 3. Gradient: image fades to white
          Positioned(
            top: size.height * 0.4,
            left: 0, right: 0,
            height: size.height * 0.3,
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

          // 4. White background from 70% down
          Positioned(
            top: size.height * 0.7,
            left: 0, right: 0, bottom: 0,
            child: Container(color: Colors.white),
          ),

          // 5. Content overlay
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        borderRadius: 50,
                        child: Row(
                          children: [
                            const Icon(Iconsax.magic_star5, size: 18, color: brandPink),
                            const SizedBox(width: 8),
                            Text(
                              'HERMONA',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                                fontSize: 13,
                                color: brandPink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _LanguageToggle(
                        isFr: isFr,
                        brandColor: brandPink,
                        onToggle: (code) => _updateLang(context, code),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),

                const Spacer(flex: 8),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        isFr ? 'Révélez l\'Éclat' : 'Reveal Your',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF332D2B),
                          height: 1.0,
                        ),
                      ),
                      Text(
                        isFr ? 'de votre Peau' : 'Skin\'s Glow',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: brandPink,
                          height: 1.0,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),

                const SizedBox(height: 20),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Text(
                    isFr
                        ? 'L\'intelligence artificielle au service de votre beauté et de votre bien-être.'
                        : 'Artificial intelligence at the service of your beauty and well-being.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const Spacer(flex: 3),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: isFr ? 'SE CONNECTER' : 'LOG IN',
                        onTap: () => context.push('/login'),
                      ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: brandPink.withOpacity(0.3), width: 1.5),
                          ),
                          child: Text(
                            isFr ? 'CRÉER UN COMPTE' : 'CREATE ACCOUNT',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: brandPink,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 850.ms).slideY(begin: 0.2),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
                // Privacy Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.shield_tick, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      'SECURE & ANONYMOUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[400],
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1000.ms),

                const SizedBox(height: 24),
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

class _LanguageToggle extends StatelessWidget {
  final bool isFr;
  final Color brandColor;
  final Function(String) onToggle;

  const _LanguageToggle({required this.isFr, required this.brandColor, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      borderRadius: 50,
      child: Row(
        children: [
          _btn('FR', isFr, () => onToggle('fr')),
          _btn('EN', !isFr, () => onToggle('en')),
        ],
      ),
    );
  }

  Widget _btn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? brandColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
