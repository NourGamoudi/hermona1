import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/features/questionnaire/data/services/questionnaire_service.dart';
import 'package:acneia/features/questionnaire/domain/entities/daily_survey.dart';
import 'package:acneia/features/prediction/data/services/prediction_api_service.dart';
import 'package:acneia/features/questionnaire/data/services/cycle_api_service.dart';
import 'package:acneia/core/localization/app_localizations.dart';

class DailyQuestionnaireScreen extends StatefulWidget {
  final DailySurvey? initialSurvey;
  final bool isOnboarding;
  const DailyQuestionnaireScreen({super.key, this.initialSurvey, this.isOnboarding = false});

  @override
  State<DailyQuestionnaireScreen> createState() => _DailyQuestionnaireScreenState();
}

class _DailyQuestionnaireScreenState extends State<DailyQuestionnaireScreen> {
  final _service = QuestionnaireService();
  final _predictionService = PredictionApiService();
  bool loading = false;
  String? error;

  // Form Data (Storing technical KEYS instead of translated strings)
  double stress = 5;
  double sleepDuration = 7;
  double sleepQuality = 5;
  int hydration = 4;
  List<String> food = []; // Stores keys: 'diet_balanced', 'diet_sugar', etc.
  List<String> symptoms = []; // Stores keys: 'symptom_none', 'symptom_cramps', etc.
  bool spfUsed = false;

  final List<String> foodOptionKeys = [
    'diet_balanced', 'diet_sugar', 'diet_dairy', 'diet_fastfood', 'diet_fruits'
  ];

  final List<String> symptomOptionKeys = [
    'symptom_none', 'symptom_cramps', 'symptom_bloating', 'symptom_mood', 
    'symptom_fatigue', 'symptom_breasts', 'symptom_headache'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSurvey != null) {
      final s = widget.initialSurvey!;
      stress = s.stress.toDouble();
      sleepDuration = s.sleepDuration;
      sleepQuality = s.sleepQuality.toDouble();
      hydration = s.hydration;
      food = List.from(s.food);
      symptoms = List.from(s.symptoms);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (food.isEmpty) {
      _showError(l.translate('error_diet_required'));
      return;
    }
    if (symptoms.isEmpty) {
      _showError(l.translate('error_symptoms_required'));
      return;
    }

    setState(() { loading = true; error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(l.translate('user_not_connected'));

      // 1. Resolve cycle state without blocking the daily save on the full ML pipeline.
      CycleStatus? cycleStatus;
      try {
        cycleStatus = await CycleApiService()
            .getCycleStatus()
            .timeout(const Duration(seconds: 3));
      } catch (cycleError) {
        debugPrint('Cycle status failed, using safe fallback: $cycleError');
      }

      // 2. Create and save the Daily Survey first. This is the user action.
      final survey = DailySurvey(
        id: '${user.uid}_${DateTime.now().toIso8601String().split('T')[0]}',
        userId: user.uid,
        date: DateTime.now(),
        stress: stress.toInt(),
        sleepDuration: sleepDuration,
        sleepQuality: sleepQuality.toInt(),
        hydration: hydration,
        food: food,
        symptoms: symptoms,
        cycleDay: cycleStatus?.day ?? 1,
        cyclePhase: cycleStatus?.phase ?? 'menstrual',
        lifestyleScore: _calculateLifestyleScore(),
      );

      await _service.saveDailySurvey(survey);

      // 3. Refresh the prediction snapshot in the background. A backend issue
      // should not prevent the daily questionnaire from being saved.
      unawaited(_refreshPredictionSnapshot(user.uid, l.locale.languageCode));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.translate('daily_saved'))),
        );
        if (widget.isOnboarding) {
          context.pushReplacement('/weekly-survey?onboarding=true');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() => error = '${l.translate('error_ia')} : $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  int _calculateLifestyleScore() {
    int score = 100;
    if (sleepDuration < 5) {
      score -= 25;
    } else if (sleepDuration < 6) {
      score -= 15;
    } else if (sleepDuration < 7) {
      score -= 10;
    }

    if (stress > 8) {
      score -= 25;
    } else if (stress > 6) {
      score -= 15;
    }

    if (hydration < 4) {
      score -= 20;
    } else if (hydration < 6) {
      score -= 10;
    }

    if (food.contains('diet_fastfood')) score -= 15;
    if (food.contains('diet_sugar')) score -= 10;
    if (food.contains('diet_dairy')) score -= 5;
    if (!spfUsed) score -= 10;

    return score.clamp(0, 100).toInt();
  }

  Future<void> _refreshPredictionSnapshot(String uid, String lang) async {
    try {
      final prediction = await _predictionService.predict({
        'stress': stress.toInt(),
        'sleep': sleepDuration,
        'sleep_quality': sleepQuality.toInt(),
        'hydration': hydration,
        'diet': food,
        'symptoms': symptoms,
        'spf_used': spfUsed,
      }, lang: lang);

      await _predictionService.saveResult(prediction, uid);
    } catch (predictError) {
      debugPrint('Background AI prediction failed: $predictError');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    debugPrint("DEBUG AUDIT: DailyQuestionnaireScreen REBUILDING with locale = ${l.locale.languageCode}");
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.translate('daily_title')),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_1),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _Blob(size: 250, color: AppTheme.primary.withValues(alpha: 0.12)),
          ),

          loading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 110, 24, 100),
              children: [
                _HeaderSection(title: l.translate('daily_header_title'), sub: l.translate('daily_header_sub')),
                const SizedBox(height: 32),

                _SliderCard(
                  label: l.translate('stress_level'),
                  icon: Iconsax.mask,
                  value: stress,
                  min: 1, max: 10,
                  onChanged: (v) => setState(() => stress = v),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                _SliderCard(
                  label: l.translate('sleep_hours'),
                  icon: Iconsax.moon,
                  value: sleepDuration,
                  min: 0, max: 14,
                  onChanged: (v) => setState(() => sleepDuration = v),
                  trailing: '${sleepDuration.toStringAsFixed(1)}h',
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                _SliderCard(
                  label: l.translate('hydration_glasses'),
                  icon: Iconsax.cup,
                  value: hydration.toDouble(),
                  min: 0, max: 15,
                  onChanged: (v) => setState(() => hydration = v.toInt()),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                _buildSwitch(l.translate('spf_protection'), spfUsed, (v) => setState(() => spfUsed = v)),
                const SizedBox(height: 32),

                _buildChipSection(l.translate('daily_diet'), foodOptionKeys, food, (v, s) {
                  setState(() => s ? food.add(v) : food.remove(v));
                }),
                const SizedBox(height: 24),

                _buildChipSection(l.translate('symptoms_felt'), symptomOptionKeys, symptoms, (v, s) {
                  setState(() => s ? symptoms.add(v) : symptoms.remove(v));
                }),

                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ),

                const SizedBox(height: 48),

                PrimaryButton(
                  label: l.translate('analyze_day'),
                  onTap: _save,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool val, Function(bool) onCh) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: SwitchListTile.adaptive(
        activeTrackColor: AppColors.primary,
        activeThumbColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        value: val,
        onChanged: onCh,
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildChipSection(String title, List<String> optionKeys, List<String> current, Function(String, bool) onSel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: optionKeys.map((key) {
            final sel = current.contains(key);
            final translatedLabel = l.translate(key);
            return GestureDetector(
              onTap: () => onSel(key, !sel),
              child: AnimatedContainer(
                duration: 300.ms,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.surfaceLight),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? Colors.transparent : (isDark ? Colors.white.withValues(alpha: 0.25) : AppColors.dividerLight)),
                ),
                child: Text(translatedLabel.toUpperCase(), style: TextStyle(color: sel ? Colors.white : AppColors.textMutedPink, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
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

class _SliderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min, max;
  final Function(double) onChanged;
  final String? trailing;

  const _SliderCard({required this.label, required this.icon, required this.value, required this.min, required this.max, required this.onChanged, this.trailing});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text(trailing ?? value.toInt().toString(), style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.25),
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withValues(alpha: 0.25),
              trackHeight: 4,
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
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
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])));
  }
}
