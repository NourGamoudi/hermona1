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

class DailyQuestionnaireScreen extends StatefulWidget {
  final DailySurvey? initialSurvey;
  const DailyQuestionnaireScreen({super.key, this.initialSurvey});

  @override
  State<DailyQuestionnaireScreen> createState() => _DailyQuestionnaireScreenState();
}

class _DailyQuestionnaireScreenState extends State<DailyQuestionnaireScreen> {
  final _service = QuestionnaireService();
  final _predictionService = PredictionApiService();
  bool loading = false;
  String? error;

  // Form Data
  double stress = 5;
  double sleepDuration = 7;
  double sleepQuality = 5;
  int hydration = 4;
  List<String> food = [];
  List<String> symptoms = [];
  bool spfUsed = false;

  final List<String> foodOptions = ['équilibrée', 'sucre', 'laitages', 'fast-food', 'fruits'];
  final List<String> symptomsOptions = ['aucun', 'crampes', 'ballonnements', 'sautes d\'humeur', 'fatigue', 'seins sensibles', 'maux de tête'];

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
    if (food.isEmpty) {
      _showError('Veuillez sélectionner votre alimentation du jour.');
      return;
    }
    if (symptoms.isEmpty) {
      _showError('Veuillez sélectionner vos symptômes (ou "aucun").');
      return;
    }

    setState(() { loading = true; error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final profile = await _service.fetchUserProfile(user.uid);
      int cycleDay = 0;
      String cyclePhase = 'inconnue';
      
      if (profile != null) {
        final avgCycle = profile.lastCyclesDuration.isNotEmpty 
            ? profile.lastCyclesDuration.reduce((a, b) => a + b) / profile.lastCyclesDuration.length 
            : 28.0;
        
        final daysSinceLast = DateTime.now().difference(profile.lastPeriodsDate).inDays;
        cycleDay = (daysSinceLast % avgCycle.toInt()) + 1;
        
        // Dynamic phase mapping based on cycle length
        if (cycleDay <= 5) {
          cyclePhase = 'menstruelle';
        } else if (cycleDay <= (avgCycle * 0.45).toInt()) {
          cyclePhase = 'folliculaire';
        } else if (cycleDay <= (avgCycle * 0.55).toInt()) {
          cyclePhase = 'ovulatoire';
        } else {
          cyclePhase = 'lutéale';
        }
      }

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
        cycleDay: cycleDay,
        cyclePhase: cyclePhase,
        lifestyleScore: 70, // Default or placeholder
      );

      // 1. Save the survey data locally (Firestore) first so progress is never lost
      await _service.saveDailySurvey(survey);

      try {
        // 2. Attempt AI prediction
        final prediction = await _predictionService.predict({
          'stress': stress > 7 ? 'high' : stress > 4 ? 'medium' : 'low',
          'sleep': sleepDuration < 6 ? 'poor' : 'good',
          'diet': (food.contains('sucre') || food.contains('laitages')) ? 'bad' : 'good',
          'hormonal_cycle': cyclePhase,
          'hydration': hydration,
          'spf_used': spfUsed,
        });

        await _predictionService.saveResult(prediction, user.uid);
      } catch (predictError) {
        debugPrint('AI Prediction failed (offline or server error): $predictError');
        // We don't block the user here, they can still proceed
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilan quotidien enregistré !')),
        );
        // Move to the next page regardless of AI success
        context.pushReplacement('/weekly-survey');
      }
    } catch (e) {
      setState(() => error = 'Erreur lors de l\'enregistrement : $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Bilan Quotidien'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_1),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background
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
                const _HeaderSection(title: 'Suivi Bien-être', sub: 'Tes données permettent à l\'IA d\'affiner ses prédictions.'),
                const SizedBox(height: 32),

                _SliderCard(
                  label: 'Niveau de Stress',
                  icon: Iconsax.mask,
                  value: stress,
                  min: 1, max: 10,
                  onChanged: (v) => setState(() => stress = v),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                _SliderCard(
                  label: 'Heures de Sommeil',
                  icon: Iconsax.moon,
                  value: sleepDuration,
                  min: 0, max: 14,
                  onChanged: (v) => setState(() => sleepDuration = v),
                  trailing: '${sleepDuration.toStringAsFixed(1)}h',
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                _SliderCard(
                  label: 'Hydratation (Verres)',
                  icon: Iconsax.cup,
                  value: hydration.toDouble(),
                  min: 0, max: 15,
                  onChanged: (v) => setState(() => hydration = v.toInt()),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                _buildSwitch('Protection SPF appliquée', spfUsed, (v) => setState(() => spfUsed = v)),
                const SizedBox(height: 32),

                _buildChipSection('Alimentation du jour', foodOptions, food, (v, s) {
                  setState(() => s ? food.add(v) : food.remove(v));
                }),
                const SizedBox(height: 24),

                _buildChipSection('Symptômes ressentis', symptomsOptions, symptoms, (v, s) {
                  setState(() => s ? symptoms.add(v) : symptoms.remove(v));
                }),

                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ),

                const SizedBox(height: 48),

                PrimaryButton(
                  label: 'ANALYSER MA JOURNÉE',
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

  Widget _buildChipSection(String title, List<String> options, List<String> current, Function(String, bool) onSel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((o) {
            final sel = current.contains(o);
            return GestureDetector(
              onTap: () => onSel(o, !sel),
              child: AnimatedContainer(
                duration: 300.ms,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.surfaceLight),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? Colors.transparent : (isDark ? Colors.white.withValues(alpha: 0.25) : AppColors.dividerLight)),
                ),
                child: Text(o.toUpperCase(), style: TextStyle(color: sel ? Colors.white : AppColors.textMutedPink, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      )
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
              Text(trailing ?? value.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
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
