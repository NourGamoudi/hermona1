import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/features/questionnaire/data/services/questionnaire_service.dart';
import 'package:acneia/features/questionnaire/domain/entities/weekly_survey.dart';
import 'package:acneia/features/detection/data/services/detection_api_service.dart';
import 'package:acneia/features/prediction/data/services/prediction_api_service.dart';
import 'package:acneia/features/recommendation/data/services/recommendation_api_service.dart';
import 'package:acneia/features/detection/presentation/screens/face_capture_screen.dart';
import 'package:acneia/core/localization/app_localizations.dart';

class WeeklyQuestionnaireScreen extends StatefulWidget {
  final WeeklySurvey? initialSurvey;
  final bool isOnboarding;
  const WeeklyQuestionnaireScreen({super.key, this.initialSurvey, this.isOnboarding = false});

  @override
  State<WeeklyQuestionnaireScreen> createState() => _WeeklyQuestionnaireScreenState();
}

class _WeeklyQuestionnaireScreenState extends State<WeeklyQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = QuestionnaireService();
  final _picker = ImagePicker();

  bool loading = false;
  String? error;

  // Data (Storing technical KEYS)
  Map<String, String> photos = {};
  String makeupFrequency = 'freq_daily';
  String makeupType = 'makeup_medium';
  String makeupRemoval = 'removal_partial';
  String cleansingFrequency = 'cleans_once';
  String routineFollowed = 'routine_rarely';
  String spfThisWeek = 'spf_sometimes';

  // Option Mappings
  final List<String> makeupFreqKeys = ['freq_daily', 'freq_4_6j', 'freq_2_3j', 'freq_1j', 'freq_rarely', 'freq_never'];
  final List<String> makeupTypeKeys = ['makeup_full', 'makeup_medium', 'makeup_light', 'makeup_natural', 'makeup_none'];
  final List<String> removalKeys = ['removal_full', 'removal_simple', 'removal_partial', 'removal_rarely', 'freq_never'];
  final List<String> cleansFreqKeys = ['cleans_twice', 'cleans_once', 'cleans_rarely', 'freq_never'];
  final List<String> routineFollowKeys = ['routine_full', 'routine_partial', 'routine_rarely'];
  final List<String> spfKeys = ['spf_always', 'spf_sometimes', 'spf_never'];

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
    if (source == ImageSource.camera && key == 'face') {
      final path = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const FaceCaptureScreen()),
      );
      if (path != null) setState(() => photos[key] = path);
      return;
    }
    
    final xFile = await _picker.pickImage(source: source, imageQuality: 85);
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
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('Prendre une photo de face', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
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
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      _showError(l.translate('complete_all_fields'));
      return;
    }
    if (photos['face'] == null) {
      _showError(l.translate('photo_required'));
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
        autoCorrection: cleansingFrequency == 'cleans_rarely' || cleansingFrequency == 'freq_never',
        reminderSent: routineFollowed == 'routine_rarely',
        spfAlert: spfThisWeek == 'spf_never',
      );
      
      await _service.saveWeeklySurvey(survey);
      
      // 1. Detection (IA Photo)
      final detectionService = DetectionApiService();
      final detectionResult = await detectionService.analyzeImages([File(photos['face']!)]);
      await detectionService.saveResult(detectionResult, user.uid);

      // 2. Prediction (Risque & Hygiène)
      final predictService = PredictionApiService();
      Map<String, dynamic> answers = {
        'spf_used': spfThisWeek != 'spf_never',
        'cleansing': cleansingFrequency,
        'makeup': makeupFrequency,
        'routine_followed': routineFollowed,
      };

      try {
        final dailySnap = await FirebaseFirestore.instance
            .collection('daily_surveys')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (dailySnap.docs.isNotEmpty) {
          final docs = dailySnap.docs.toList();
          docs.sort((a, b) => (b.data()['date'] as Timestamp).compareTo(a.data()['date'] as Timestamp));
          final d = docs.first.data();
          answers.addAll({
            'stress': d['stress'],
            'sleep': d['sleepDuration'],
            'sleep_quality': d['sleepQuality'],
            'hydration': d['hydration'],
            'diet': d['food'],
          });
        }

        final predictionResult = await predictService.predict(answers, lang: l.locale.languageCode);
        await predictService.saveResult(predictionResult, user.uid);

        // 3. Recommendation (Routine)
        final recommendService = RecommendationApiService();
        final recommendation = await recommendService.getRecommendations(
          detection: detectionResult,
          userId: user.uid,
          lang: l.locale.languageCode,
        );
        await recommendService.saveResult(recommendation, user.uid);
      } catch (e) {
        debugPrint('Erreur lors de la prédiction/recommandation: $e');
      }
      
      if (mounted) {
        context.go('/detection/result', extra: detectionResult.toJson());
      }
    } catch (e) {
      setState(() => error = e.toString());
      _showError('Erreur lors de l\'analyse : $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(l.translate('weekly_title'))),
      body: Stack(
        children: [
          Positioned(top: -50, left: -50, child: _Blob(size: 250, color: AppColors.secondary.withValues(alpha: 0.05))),
          loading 
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 24), Text(l.translate('error_ia'), style: const TextStyle(fontWeight: FontWeight.bold))]))
          : Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 110, 24, 100),
                children: [
                  _HeaderSection(title: l.translate('cutaneous_audit'), sub: l.translate('audit_desc')),
                  const SizedBox(height: 32),
                  
                  // Photo Section
                  SectionHeader(title: l.translate('visual_analysis')),
                  const SizedBox(height: 16),
                  Center(child: _PhotoUploadBox(path: photos['face'], onTap: () => _showPhotoSourceDialog('face'))),
                  const SizedBox(height: 32),

                  // Questions
                  SectionHeader(title: l.translate('makeup_cleansing')),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildDropdown(l.translate('makeup_freq_label'), makeupFrequency, makeupFreqKeys, (v) => setState(() => makeupFrequency = v!)),
                        const SizedBox(height: 20),
                        _buildDropdown(l.translate('makeup_type_label'), makeupType, makeupTypeKeys, (v) => setState(() => makeupType = v!)),
                        const SizedBox(height: 20),
                        _buildDropdown(l.translate('cleansing_label'), makeupRemoval, removalKeys, (v) => setState(() => makeupRemoval = v!)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  SectionHeader(title: l.translate('routine_observance')),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildDropdown(l.translate('cleansing_freq_label'), cleansingFrequency, cleansFreqKeys, (v) => setState(() => cleansingFrequency = v!)),
                        const SizedBox(height: 20),
                        _buildDropdown(l.translate('routine_followed_label'), routineFollowed, routineFollowKeys, (v) => setState(() => routineFollowed = v!)),
                        const SizedBox(height: 20),
                        _buildDropdown(l.translate('spf_label'), spfThisWeek, spfKeys, (v) => setState(() => spfThisWeek = v!)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  PrimaryButton(label: l.translate('finish').toUpperCase(), onTap: _save),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, Function(String?) onChanged) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondaryDark, letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white,
          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.w600),
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(l.translate(e).toUpperCase()))).toList(),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.displaySmall), const SizedBox(height: 8), Text(sub, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14))]);
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
        width: 220, height: 280,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2)),
        child: path != null 
            ? ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.file(File(path!), fit: BoxFit.cover))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Iconsax.camera, color: AppTheme.primary, size: 40)),
                const SizedBox(height: 16),
                Text('FACE FRONTALE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.primary)),
                const SizedBox(height: 8),
                const Text('Cliquez pour capturer', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
              ]),
      ),
    ).animate().scale();
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _SourceOption({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Column(children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: AppTheme.primary, size: 28)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))]));
  }
}

class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])));
  }
}