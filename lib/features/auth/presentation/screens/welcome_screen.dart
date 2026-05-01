import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Icon / Logo
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Text('🌸', style: TextStyle(fontSize: 64)),
                ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 48),
                
                Text(
                  'Bienvenue sur\nHERMONA',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, duration: 800.ms, curve: Curves.easeOut),
                
                const SizedBox(height: 16),
                
                Text(
                  'Ton assistant IA dédié à l\'acné hormonale',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 1000.ms),
                
                const SizedBox(height: 24),
                
                // Description
                Text(
                  'Comprenez votre cycle, analysez votre peau et recevez des recommandations expertes pour une routine sereine.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: Colors.grey[600],
                  ),
                ).animate().fadeIn(delay: 1500.ms, duration: 800.ms),
                
                const Spacer(),
                
                // Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GradientButton(
                      text: 'Se connecter',
                      onPressed: () => context.push('/login'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => context.push('/register'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50), // Plus arrondi pour le look premium
                        ),
                        side: BorderSide(color: AppTheme.primary, width: 2),
                      ),
                      child: Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 2000.ms, duration: 800.ms).slideY(begin: 0.2),
                
                const SizedBox(height: 32),
                
                // Liens discrets
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text('Mentions légales', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ),
                    Text(' • ', style: TextStyle(color: Colors.grey[400])),
                    TextButton(
                      onPressed: () {},
                      child: Text('Politique de confidentialité', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ),
                  ],
                ).animate().fadeIn(delay: 2500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
