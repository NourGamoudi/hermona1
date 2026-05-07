import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _pseudoCtrl = TextEditingController();
  final _auth = AuthService();
  
  bool _obscure = true;
  bool _obscureC = true;
  bool _terms = false;
  bool _loading = false;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _pseudoCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_terms) {
      _snack(AppLocalizations.of(context).translate('accept_terms'));
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        pseudonym: _pseudoCtrl.text.trim(),
      );
      if (mounted) context.go('/onboarding');
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(20),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.15,
            child: _Blob(
              size: size.width * 0.9,
              color: AppColors.secondary.withOpacity(0.08),
            ).animate(onPlay: (c) => c.repeat()).moveX(begin: 0, end: 40, duration: 6.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            child: _Blob(
              size: size.width * 0.8,
              color: AppTheme.primary.withOpacity(0.12),
            ).animate(onPlay: (c) => c.repeat()).moveY(begin: 0, end: 30, duration: 4.seconds, curve: Curves.easeInOut),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  _BackButton(onTap: () => context.go('/login')),

                  SizedBox(height: size.height * 0.03),

                  Text(
                    l.translate('register'),
                    style: Theme.of(context).textTheme.displayMedium,
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                  const SizedBox(height: 6),
                  Text(
                    l.translate('register_welcome'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),

                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FieldLabel(label: l.translate('first_name')),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _firstCtrl,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Iconsax.user, size: 20),
                                      ),
                                      validator: (v) => (v == null || v.isEmpty) ? l.translate('required') : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FieldLabel(label: l.translate('last_name')),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _lastCtrl,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Iconsax.user, size: 20),
                                      ),
                                      validator: (v) => (v == null || v.isEmpty) ? l.translate('required') : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                          const SizedBox(height: 20),

                          _FieldLabel(label: 'Pseudonyme (anonyme)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _pseudoCtrl,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Iconsax.mask, size: 20),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? l.translate('required') : null,
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                          const SizedBox(height: 20),

                          _FieldLabel(label: l.translate('email')),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Iconsax.sms, size: 20),
                            ),
                            validator: (v) => (v == null || !v.contains('@')) ? l.translate('invalid_email') : null,
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                          const SizedBox(height: 20),

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
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                          const SizedBox(height: 20),

                          _FieldLabel(label: l.translate('confirm_password')),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscureC,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Iconsax.lock_1, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureC ? Iconsax.eye_slash : Iconsax.eye, size: 18),
                                onPressed: () => setState(() => _obscureC = !_obscureC),
                              ),
                            ),
                            validator: (v) => v != _passCtrl.text ? l.translate('passwords_dont_match') : null,
                          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),

                          const SizedBox(height: 24),

                          // Terms
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _terms,
                                activeColor: AppTheme.primary,
                                checkColor: Colors.white,
                                side: BorderSide(color: AppColors.textSecondaryDark.withOpacity(0.5)),
                                onChanged: (v) => setState(() => _terms = v ?? false),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                                    children: [
                                      TextSpan(text: l.translate('i_accept')),
                                      TextSpan(
                                        text: l.translate('terms'),
                                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                                        recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 800.ms),

                          const SizedBox(height: 32),

                          PrimaryButton(
                            label: l.translate('signup'),
                            onTap: _register,
                            isLoading: _loading,
                          ).animate().fadeIn(delay: 900.ms),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l.translate('already_account'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          l.translate('login'),
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1100.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
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
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
        color: AppColors.textSecondaryDark.withOpacity(0.8),
        letterSpacing: 1.5,
      ),
    );
  }
}
