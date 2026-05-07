import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/services/questionnaire_service.dart';
import '../../domain/entities/daily_survey.dart';
import '../../../prediction/data/services/prediction_api_service.dart';
import '../../../prediction/domain/entities/prediction_result.dart';

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

  final List<String> foodOptions = ['sucre', 'laitages', 'fast-food', 'fruits', 'équilibrée'];
  final List<String> symptomsOptions = ['crampes', 'ballonnements', 'sautes d\'humeur', 'fatigue', 'seins sensibles', 'maux de tête'];

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
    setState(() { loading = true; error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final profile = await _service.fetchUserProfile(user.uid);
      int cycleDay = 0;
      String cyclePhase = 'inconnue';
      
      if (profile != null) {
        cycleDay = DateTime.now().difference(profile.lastPeriodsDate).inDays + 1;
        if (cycleDay <= 5) cyclePhase = 'menstruelle';
        else if (cycleDay <= 13) cyclePhase = 'folliculaire';
        else if (cycleDay <= 15) cyclePhase = 'ovulatoire';
        else cyclePhase = 'lutéale';
      }

      int score = 100;
      if (sleepDuration < 7) score -= 15;
      if (hydration < 6) score -= 10;
      if (stress > 7) score -= 20;
      if (food.contains('sucre') || food.contains('laitages')) score -= 15;
      if (food.contains('fast-food')) score -= 10;
      score = score.clamp(0, 100);

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
        lifestyleScore: score,
      );

      await _service.saveDailySurvey(survey);
      final prediction = await _predictionService.predict({
        'stress': stress > 7 ? 'high' : stress > 4 ? 'medium' : 'low',
        'sleep': sleepDuration < 6 ? 'poor' : 'good',
        'diet': (food.contains('sucre') || food.contains('laitages')) ? 'bad' : 'good',
        'hormonal_cycle': cyclePhase,
        'hygieneScore': score,
      });

      await _predictionService.saveResult(prediction, user.uid);
      if (mounted) context.go('/prediction', extra: prediction);
    } catch (e) {
      setState(() => error = 'Erreur d\'analyse : $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Bilan Quotidien')),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: _Blob(size: 300, color: AppColors.primary.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _Blob(size: 250, color: AppColors.secondary.withOpacity(0.08)),
          ),

          loading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 100),
              children: [
                _HeaderSection(
                  title: 'Suivi Bien-être', 
                  sub: 'Tes données permettent à l\'IA d\'affiner ses prédictions et d\'adapter ta routine.',
                ),
                const SizedBox(height: 40),

                _SliderCard(
                  label: 'Niveau de Stress',
                  icon: Iconsax.mask,
                  value: stress,
                  min: 1, max: 10,
                  onChanged: (v) => setState(() => stress = v),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

                const SizedBox(height: 20),

                _SliderCard(
                  label: 'Heures de Sommeil',
                  icon: Iconsax.moon,
                  value: sleepDuration,
                  min: 0, max: 14,
                  onChanged: (v) => setState(() => sleepDuration = v),
                  trailing: '${sleepDuration.toStringAsFixed(1)}h',
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

                const SizedBox(height: 20),

                _SliderCard(
                  label: 'Hydratation (Verres)',
                  icon: Iconsax.cup,
                  value: hydration.toDouble(),
                  min: 0, max: 15,
                  onChanged: (v) => setState(() => hydration = v.toInt()),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

                const SizedBox(height: 32),

                _buildSwitch('Protection SPF appliquée', spfUsed, (v) => setState(() => spfUsed = v)),
                const SizedBox(height: 32),

                _buildChipSection('Alimentation du jour', foodOptions, food, (v, s) {
                  setState(() => s ? food.add(v) : food.remove(v));
                }, delay: 500),
                const SizedBox(height: 24),

                _buildChipSection('Symptômes ressentis', symptomsOptions, symptoms, (v, s) {
                  setState(() => s ? symptoms.add(v) : symptoms.remove(v));
                }, delay: 600),

                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: GlassCard(
                      borderColor: AppColors.error.withOpacity(0.3),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Iconsax.danger, color: AppColors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 48),

                PrimaryButton(
                  label: 'ANALYSER MA JOURNÉE',
                  onTap: _save,
                  icon: Iconsax.computing,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool val, Function(bool) onCh) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SwitchListTile.adaptive(
        activeColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        value: val,
        onChanged: onCh,
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildChipSection(String title, List<String> options, List<String> current, Function(String, bool) onSel, {int delay = 0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(), 
          style: TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.5, 
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((o) {
            final sel = current.contains(o);
            return GestureDetector(
              onTap: () => onSel(o, !sel),
              child: AnimatedContainer(
                duration: 300.ms,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.primaryGradient : null,
                  color: sel ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))),
                  boxShadow: sel ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
                child: Text(
                  o.toUpperCase(), 
                  style: TextStyle(
                    color: sel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight), 
                    fontSize: 10, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: delay.ms);
  }
}

class _HeaderSection extends StatelessWidget {
  final String title, sub;
  const _HeaderSection({required this.title, required this.sub});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32)),
        const SizedBox(height: 12),
        Text(
          sub, 
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, 
            fontSize: 15, 
            height: 1.5
          ),
        ),
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
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  trailing ?? value.toInt().toString(), 
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.12),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 4),
              overlayColor: AppColors.primary.withOpacity(0.1),
              trackHeight: 6,
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
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])));
  }
}
