import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/core/localization/app_localizations.dart';
import 'package:acneia/features/auth/data/services/auth_service.dart';
import '../cubit/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l = AppLocalizations.of(context);

    return BlocProvider(
      create: (context) => AuthCubit(_auth),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.go('/home');
          } else if (state is AuthFailure) {
            _snack(state.message.replaceAll('Exception: ', ''));
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return Scaffold(
              body: Stack(
                children: [
                  // ───────────────────────────────────────────────────────────
                  // DYNAMIC BACKGROUND
                  // ───────────────────────────────────────────────────────────
                  Positioned(
                    top: -size.height * 0.1,
                    right: -size.width * 0.1,
                    child: _Blob(
                      size: size.width * 0.8,
                      color: AppTheme.primary.withValues(alpha: 0.12),
                    ).animate(onPlay: (c) => c.repeat()).moveY(begin: 0, end: 30, duration: 4.seconds, curve: Curves.easeInOut),
                  ),
                  Positioned(
                    bottom: -size.height * 0.05,
                    left: -size.width * 0.1,
                    child: _Blob(
                      size: size.width * 0.7,
                      color: AppColors.secondary.withValues(alpha: 0.08),
                    ).animate(onPlay: (c) => c.repeat()).moveX(begin: 0, end: 20, duration: 5.seconds, curve: Curves.easeInOut),
                  ),

                  // ───────────────────────────────────────────────────────────
                  // CONTENT
                  // ───────────────────────────────────────────────────────────
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back Button
                          _BackButton(onTap: () => context.go('/welcome')),
                          
                          SizedBox(height: size.height * 0.04),

                          // Brand Logo & Welcome
                          Center(
                            child: Column(
                              children: [
                                const _HeroIcon(),
                                const SizedBox(height: 18),
                                Text(
                                  'HERMONA',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                        letterSpacing: 4,
                                        fontSize: 28,
                                      ),
                                ).animate().fadeIn(duration: 800.ms),
                                const SizedBox(height: 6),
                                Text(
                                  l.translate('expert_subtitle').toUpperCase(),
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppColors.primary,
                                        letterSpacing: 2,
                                        fontSize: 10,
                                      ),
                                ).animate().fadeIn(delay: 200.ms),
                              ],
                            ),
                          ),

                          SizedBox(height: size.height * 0.07),

                          // Login Form in Glass Card
                          GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.translate('login'),
                                    style: Theme.of(context).textTheme.displaySmall,
                                  ).animate().fadeIn(delay: 300.ms),
                                  const SizedBox(height: 6),
                                  Text(
                                    l.translate('login_welcome'),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ).animate().fadeIn(delay: 400.ms),
                                  const SizedBox(height: 32),

                                  // Email Field
                                  _FieldLabel(label: l.translate('email')),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Iconsax.sms, size: 20),
                                      hintText: 'name@example.com',
                                    ),
                                    validator: (v) => (v == null || !v.contains('@')) ? l.translate('invalid_email') : null,
                                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                                  
                                  const SizedBox(height: 20),

                                  // Password Field
                                  _FieldLabel(label: l.translate('password')),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscure,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Iconsax.lock, size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscure ? Iconsax.eye_slash : Iconsax.eye, size: 18),
                                        onPressed: () => setState(() => _obscure = !_obscure),
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.length < 6) ? l.translate('min_password') : null,
                                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                                  
                                  const SizedBox(height: 12),

                                  // Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => _showForgotPassword(context),
                                      child: Text(
                                        l.translate('forgot_password'),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: 700.ms),

                                  const SizedBox(height: 24),

                                  // Login Button
                                  PrimaryButton(
                                    label: l.translate('login'),
                                    isLoading: isLoading,
                                    onTap: () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<AuthCubit>().login(_emailCtrl.text.trim(), _passCtrl.text);
                                      }
                                    },
                                  ).animate().fadeIn(delay: 800.ms),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Social Login
                          PremiumFadeIn(
                            delay: 900,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        l.translate('or').toUpperCase(),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _SocialButton(
                                  onTap: isLoading ? null : () => context.read<AuthCubit>().signInWithGoogle(),
                                  isLoading: isLoading,
                                  label: l.translate('google_continue'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l.translate('no_account'),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => context.go('/register'),
                                child: Text(
                                  l.translate('register'),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 1100.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(l.translate('reset_password'), style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.translate('reset_password_desc'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: l.translate('enter_email'),
                  prefixIcon: const Icon(Iconsax.sms),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.translate('cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.isNotEmpty) {
                  final cubit = context.read<AuthCubit>();
                  final navigator = Navigator.of(ctx);
                  await cubit.resetPassword(ctrl.text.trim());
                  if (mounted) {
                    navigator.pop();
                    _snack(l.translate('email_sent'), isError: false);
                  }
                }
              },
              child: Text(l.translate('send')),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// HELPER WIDGETS
/// ─────────────────────────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Iconsax.magic_star5, size: 42, color: Colors.white),
    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut);
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Icon(Iconsax.arrow_left_1, size: 20),
      ),
    ).animate().fadeIn().slideX(begin: -0.2);
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
        letterSpacing: 1.5,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final String label;

  const _SocialButton({required this.onTap, required this.isLoading, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 22, color: Colors.white),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
