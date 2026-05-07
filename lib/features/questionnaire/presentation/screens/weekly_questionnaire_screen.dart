import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/questionnaire_service.dart';
import '../../domain/entities/weekly_survey.dart';

class WeeklyQuestionnaireScreen extends StatefulWidget {
  final WeeklySurvey? initialSurvey;
  const WeeklyQuestionnaireScreen({super.key, this.initialSurvey});

  @override
  State<WeeklyQuestionnaireScreen> createState() => _WeeklyQuestionnaireScreenState();
}

class _WeeklyQuestionnaireScreenState extends State<WeeklyQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = QuestionnaireService();
  final _picker = ImagePicker();

  bool loading = false;
  String? error;

  // Data
  Map<String, String> photos = {};
  String makeupFrequency = '';
  String makeupType = '';
  String makeupRemoval = '';
  String cleansingFrequency = '';
  String routineFollowed = '';
  String spfThisWeek = '';
  bool autoCorrection = false;
  bool reminderSent = false;
  bool spfAlert = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSurvey != null) {
      final s = widget.initialSurvey!;
      photos = Map.from(s.photos);
      makeupFrequency = s.makeupFrequency;
      makeupType = s.makeupType;
      makeupRemoval = s.makeupRemoval;
      cleansingFrequency = s.cleansingFrequency;
      routineFollowed = s.routineFollowed;
      spfThisWeek = s.spfThisWeek;
    }
  }

  Future<void> _pickImage(String key, ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (xFile != null) setState(() => photos[key] = xFile.path);
  }

  void _showPhotoSourceDialog(String key) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('Source de la photo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SourceOption(icon: Iconsax.camera, label: 'Caméra', onTap: () { Navigator.pop(ctx); _pickImage(key, ImageSource.camera); }),
                  _SourceOption(icon: Iconsax.gallery, label: 'Galerie', onTap: () { Navigator.pop(ctx); _pickImage(key, ImageSource.gallery); }),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (photos['face'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez ajouter une photo de face.')));
      return;
    }

    setState(() { loading = true; error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final now = DateTime.now();
      final weekNumber = ((int.parse(DateFormat("D").format(now)) - now.weekday + 10) / 7).floor();
      
      final survey = WeeklySurvey(
        id: '${user.uid}_${weekNumber}_${now.year}',
        userId: user.uid,
        weekNumber: weekNumber,
        year: now.year,
        photos: photos,
        makeupFrequency: makeupFrequency,
        makeupType: makeupType,
        makeupRemoval: makeupRemoval,
        cleansingFrequency: cleansingFrequency,
        routineFollowed: routineFollowed,
        spfThisWeek: spfThisWeek,
        autoCorrection: cleansingFrequency == 'rarement',
        reminderSent: routineFollowed == 'Non',
        spfAlert: spfThisWeek == 'Jamais',
      );
      
      await _service.saveWeeklySurvey(survey);
      if (mounted) context.go('/daily-survey');
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Bilan Hebdomadaire')),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -50,
            left: -50,
            child: _Blob(size: 250, color: AppColors.secondary.withOpacity(0.05)),
          ),

          loading 
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 110, 24, 100),
                children: [
                  _HeaderSection(title: 'Audit Cutané', sub: 'Évaluons les progrès et l\'observance de ta routine.'),
                  const SizedBox(height: 32),

                  // Photo Section
                  const SectionHeader(title: 'Analyse Visuelle'),
                  const SizedBox(height: 16),
                  Center(
                    child: _PhotoUploadBox(
                      path: photos['face'],
                      onTap: () => _showPhotoSourceDialog('face'),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Makeup Section
                  const SectionHeader(title: 'Maquillage & Nettoyage'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildDropdown('Fréquence (Semaine)', makeupFrequency, ['tous les jours', '4-6j', '2-3j', '1j', 'jamais'], (v) => setState(() => makeupFrequency = v!)),
                        const SizedBox(height: 20),
                        _buildDropdown('Type de Maquillage', makeupType, ['complet', 'modéré', 'léger', 'naturel', 'aucun'], (v) => setState(() => makeupType = v!)),
                        const SizedBox(height: 20),
                        _buildDropdown('Démaquillage', makeupRemoval, ['complet', 'simple', 'partiel', 'rarement'], (v) => setState(() => makeupRemoval = v!)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // Routine Section
                  const SectionHeader(title: 'Observance Routine'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildDropdown('Fréquence Nettoyage', cleansingFrequency, ['2x/jour', '1x/jour', 'rarement'], (v) => setState(() => cleansingFrequency = v!)),
                        const SizedBox(height: 20),
                        _buildDropdown('Routine Suivie ?', routineFollowed, ['Oui', 'Partiellement', 'Non'], (v) => setState(() => routineFollowed = v!)),
                        const SizedBox(height: 20),
                        _buildDropdown('Protection Solaire', spfThisWeek, ['Tous les jours', 'Parfois', 'Jamais'], (v) => setState(() => spfThisWeek = v!)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    ),

                  const SizedBox(height: 48),

                  PrimaryButton(
                    label: 'VALIDER LE BILAN SEMAINE',
                    onTap: _save,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondaryDark, letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          dropdownColor: AppColors.cardDark,
          decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero),
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Requis' : null,
          icon: const Icon(Iconsax.arrow_down_1, size: 16),
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String title, sub;
  const _HeaderSection({required this.title, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(sub, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14)),
      ],
    );
  }
}

class _PhotoUploadBox extends StatelessWidget {
  final String? path;
  final VoidCallback onTap;
  const _PhotoUploadBox({this.path, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
        ),
        child: path != null 
            ? ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.file(File(path!), fit: BoxFit.cover))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Iconsax.camera, color: AppColors.primary, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('FACE FRONTALE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  const Text('Cliquez pour capturer', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                ],
              ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])));
  }
}
