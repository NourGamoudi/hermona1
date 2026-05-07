import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../prediction/domain/entities/prediction_result.dart';
import '../../../questionnaire/domain/entities/daily_survey.dart';
import '../../../detection/data/services/detection_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _firstName;
  final _detectionSvc = DetectionApiService();
  bool _isAnalyzing = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() => _firstName = doc.data()?['firstName']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFFDFBFA),
      body: Stack(
        children: [
          // Background Blobs for a premium feel
          Positioned(top: -100, right: -100, child: _Blob(size: 350, color: AppColors.primary.withOpacity(0.04))),
          Positioned(bottom: -50, left: -50, child: _Blob(size: 300, color: AppColors.secondary.withOpacity(0.04))),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    children: [
                      _buildHeader(context, isDark),
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle('Suivi & Bilans'),
                      const SizedBox(height: 16),
                      _buildSurveyHorizontalList(context),
                      
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle('Analyse de peau IA'),
                      const SizedBox(height: 16),
                      _buildAIAnalysisSection(context, isDark),

                      const SizedBox(height: 32),
                      
                      _buildSectionTitle('Quick Actions'),
                      const SizedBox(height: 16),
                      _buildQuickActions(context),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_isAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Center(
                  child: GlassCard(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 24),
                        Text(
                          'Analyse IA en cours...',
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Détection des zones et audit cutané',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                  ).animate().scale(begin: const Offset(0.9, 0.9)).fadeIn(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour,',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _firstName ?? 'Chargement...',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _logout(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.logout, color: AppColors.primary, size: 22),
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) context.go('/welcome');
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF332D2B),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSurveyHorizontalList(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildSurveyCard(
            context,
            'Profil',
            'Onboarding',
            Iconsax.user,
            const Color(0xFFFFF0F3),
            AppColors.primary,
            '/onboarding',
          ),
          _buildSurveyCard(
            context,
            'Bilan',
            'Quotidien',
            Iconsax.calendar_1,
            const Color(0xFFF0F4FF),
            const Color(0xFF5A78FF),
            '/daily-survey',
          ),
          _buildSurveyCard(
            context,
            'Bilan',
            'Hebdomadaire',
            Iconsax.status_up,
            const Color(0xFFF0FFF8),
            const Color(0xFF45D9B3),
            '/weekly-survey',
          ),
          _buildSurveyCard(
            context,
            'Ma',
            'Routine',
            Iconsax.magic_star,
            const Color(0xFFFFF8F0),
            const Color(0xFFFFB345),
            '/my-routine',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSurveyCard(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
    Color bg,
    Color iconCol,
    String route,
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        width: 120,
        height: 130,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: iconCol.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconCol, size: 26),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: iconCol.withOpacity(0.6), fontWeight: FontWeight.w800, fontSize: 12)),
                Text(sub, style: TextStyle(color: iconCol.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAnalysisSection(BuildContext context, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Iconsax.scan, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan 5-Zones', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text('Audit IA complet de votre peau', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(context, ImageSource.camera),
                  icon: const Icon(Iconsax.camera, size: 18),
                  label: const Text('CAMERA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(context, ImageSource.gallery),
                  icon: const Icon(Iconsax.gallery, size: 18),
                  label: const Text('GALERIE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionItem(context, 'Chat IA', Iconsax.message_text, const Color(0xFF6B5AE0), '/chat'),
        _buildActionItem(context, 'Historique', Iconsax.clock, const Color(0xFFE85886), '/history'),
        _buildActionItem(context, 'Forum', Iconsax.message_2, const Color(0xFF45D9B3), '/forum'),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildActionItem(BuildContext context, String label, IconData icon, Color color, String route) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.1)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _pickImage(BuildContext context, ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (xFile == null) return;

      setState(() => _isAnalyzing = true);

      final result = await _detectionSvc.analyzeImages([xFile]);
      
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _detectionSvc.saveResult(result, uid);
      }

      if (mounted) {
        setState(() => _isAnalyzing = false);
        context.push('/detection/result', extra: result.toJson());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'analyse: $e'), backgroundColor: AppColors.error),
        );
      }
    }
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
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}

