import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/features/prediction/data/services/prediction_api_service.dart';
import 'package:acneia/features/prediction/domain/entities/prediction_result.dart';
import 'package:acneia/core/localization/app_localizations.dart';
import 'package:acneia/features/recommendation/domain/entities/recommendation_result.dart';
import 'package:acneia/features/recommendation/data/services/recommendation_api_service.dart';
import 'package:acneia/features/detection/domain/entities/detection_result.dart';
import 'package:acneia/features/questionnaire/domain/entities/weekly_survey.dart';
import 'package:acneia/core/services/smart_notification_manager.dart';
import 'package:acneia/features/questionnaire/data/services/cycle_api_service.dart';

class PredictionScreen extends StatefulWidget {
  final PredictionResult? initialResult;
  const PredictionScreen({super.key, this.initialResult});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  bool _loading = false;
  PredictionResult? _result;
  RecommendationResult? _recommendation;
  WeeklySurvey? _weeklySurvey;
  bool _missingSurveys = false;
  
  final _predictSvc = PredictionApiService();
  final _recommendSvc = RecommendationApiService();

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      _result = widget.initialResult;
    } else {
      // Auto-trigger prediction on load
      WidgetsBinding.instance.addPostFrameCallback((_) => _predict());
    }
  }

  Future<void> _predict() async {
    setState(() { _loading = true; _result = null; _recommendation = null; _missingSurveys = false; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        final l = AppLocalizations.of(context);
        throw Exception(l.translate('user_not_connected'));
      }

      Map<String, dynamic> answers = {};

      String normalizeValue(dynamic val) {
        if (val == null) return '';
        final v = val.toString().toLowerCase().trim();
        final map = {
          'lutéale': 'phase_luteal',
          'folliculaire': 'phase_follicular',
          'menstruelle': 'phase_menstrual',
          'ovulatoire': 'phase_ovulatory',
          '2x/jour': 'cleans_twice',
          '1x/jour': 'cleans_once',
          'rarement': 'cleans_rarely',
          'tous les jours': 'freq_daily',
          'parfois': 'freq_sometimes',
          'oui': 'routine_full',
          'non': 'routine_none',
          'laitages': 'diet_dairy',
          'sucre': 'diet_sugar',
          'fast-food': 'diet_fastfood',
        };
        return map[v] ?? v;
      }

      try {
        // 1. Fetch Latest Daily Survey (Optimized with index)
        final dailySnap = await FirebaseFirestore.instance
            .collection('daily_surveys')
            .where('userId', isEqualTo: uid)
            .orderBy('date', descending: true)
            .limit(1)
            .get();

        // Fetch Real-time Cycle Phase instead of using stale daily survey data
        final cycleSvc = CycleApiService();
        final cycleStatus = await cycleSvc.getCycleStatus();
        final realPhase = cycleStatus.phase;
        final realDay = cycleStatus.day;

        if (dailySnap.docs.isNotEmpty) {
          final d = dailySnap.docs.first.data();
          final List<dynamic> food = d['food'] ?? [];
          answers.addAll({
            'stress': d['stress'],
            'sleep': d['sleepDuration'],
            'sleep_quality': d['sleepQuality'],
            'hydration': d['hydration'],
            'diet': food.map((f) => normalizeValue(f)).toList(),
            'cycle_day': realDay > 0 ? realDay : d['cycleDay'],
            'cycle_phase': normalizeValue(realPhase.isNotEmpty ? realPhase : d['cyclePhase']),
          });
          debugPrint('DEBUG: Daily data found via index: ${dailySnap.docs.first.id}');
        }

        // 2. Fetch Latest Weekly Survey (Optimized with index)
        final weeklySnap = await FirebaseFirestore.instance
            .collection('weekly_surveys')
            .where('userId', isEqualTo: uid)
            .orderBy('year', descending: true)
            .orderBy('weekNumber', descending: true)
            .limit(1)
            .get();

        if (weeklySnap.docs.isNotEmpty) {
          final w = weeklySnap.docs.first.data();
          answers.addAll({
            'cleansing': normalizeValue(w['cleansingFrequency']),
            'spf_used': w['spfThisWeek'] != 'Jamais' && w['spfThisWeek'] != 'spf_never',
            'makeup_frequency': normalizeValue(w['makeupFrequency']),
            'routine_followed': normalizeValue(w['routineFollowed']),
          });
          _weeklySurvey = WeeklySurvey.fromJson(w, weeklySnap.docs.first.id);
          debugPrint('DEBUG: Weekly data found via index: ${weeklySnap.docs.first.id}');
        }

        bool isValid = false;

        if (dailySnap.docs.isNotEmpty && weeklySnap.docs.isNotEmpty) {
          final d = dailySnap.docs.first.data();
          
          final dateVal = d['date'];
          DateTime? dt;
          if (dateVal is Timestamp) {
            dt = dateVal.toDate();
          } else if (dateVal is String) {
            dt = DateTime.tryParse(dateVal);
          }
          
          bool isRecent = false;
          if (dt != null) {
            isRecent = DateTime.now().difference(dt).inHours.abs() < 36;
          }

          // Use the real-time phase fetched earlier, fallback to daily survey if empty
          final phaseToCheck = realPhase.isNotEmpty ? realPhase : (d['cyclePhase']?.toString() ?? '');
          bool hasPhase = phaseToCheck.isNotEmpty && phaseToCheck.toLowerCase() != 'unknown' && phaseToCheck.toLowerCase() != 'inconnu';

          if (isRecent && hasPhase) {
            isValid = true;
          } else {
            debugPrint('DEBUG: Invalid surveys - isRecent: $isRecent, hasPhase: $hasPhase');
          }
        }

        if (!isValid) {
          if (mounted) {
            setState(() {
              _loading = false;
              _missingSurveys = true;
            });
          }
          return;
        }

      } catch (e) {
        debugPrint('DEBUG: Survey fetch error: $e');
        if (mounted) {
          setState(() {
            _loading = false;
            _missingSurveys = true;
          });
        }
        return;
      }

      if (!mounted) return;
      final l = AppLocalizations.of(context);
      debugPrint('DEBUG: Final payload to API: $answers');

      // 3. Fetch Prediction (Risk & Hygiene)
      final res = await _predictSvc.predict(answers, lang: l.locale.languageCode); 
      await _predictSvc.saveResult(res, uid);

      // Trigger Smart Notification check immediately after new prediction
      await SmartNotificationManager().checkAndNotify(latestPrediction: res);

      // 3. Fetch Latest Detection Result
      final detSnap = await FirebaseFirestore.instance
          .collection('detections')
          .where('userId', isEqualTo: uid)
          .orderBy('analyzedAt', descending: true)
          .limit(1)
          .get();

      DetectionResult latestDetection;
      if (detSnap.docs.isNotEmpty) {
        latestDetection = DetectionResult.fromJson(detSnap.docs.first.data());
      } else {
        // Fallback if no detection found
        latestDetection = DetectionResult(
          id: 'fallback',
          severityScore: 0.5,
          severityLevel: SeverityLevel.moderate,
          classifications: const [],
          analyzedAt: DateTime.now(),
          imageUrls: const [],
          zoneCounts: const {},
          zoneRisks: const {},
        );
      }

      // 4. Fetch Recommendations based on real detection + answers
      final rec = await _recommendSvc.getRecommendations(
        detection: latestDetection, 
        userId: uid,
        lang: l.locale.languageCode,
      );
      await _recommendSvc.saveResult(rec, uid);

      if (mounted) {
        setState(() { 
          _result = res; 
          _recommendation = rec;
          _loading = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.translate('error_ia')} : $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_result != null) {
      return _ResultView(
        result: _result!, 
        recommendation: _recommendation,
        weeklySurvey: _weeklySurvey,
        onRetry: () {
          setState(() { _result = null; _recommendation = null; _weeklySurvey = null; });
          _predict();
        }
      );
    }

    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ScanIcon(),
              const SizedBox(height: 32),
              Text(
                l.translate('skin_analysis_progress'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
              const SizedBox(height: 12),
              Text(
                l.translate('ai_working_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.translate('predictive_report_title')),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_1),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned(
            top: -100,
            right: -50,
            child: _Blob(size: 300, color: AppTheme.primary.withAlpha(12)),
          ),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _missingSurveys 
                ? _buildMissingSurveysUI(l)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _ScanIcon(),
                      const SizedBox(height: 32),
                      Text(l.translate('predictive_analysis'), style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 12),
                      Text(
                        l.translate('predictive_desc'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondaryDark, height: 1.5),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingSurveysUI(AppLocalizations l) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.document_text_1, size: 64, color: AppColors.error),
        ),
        const SizedBox(height: 32),
        Text(
          l.translate('incomplete_surveys_title'),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          l.translate('incomplete_surveys_desc'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondaryDark, height: 1.5),
        ),
        const SizedBox(height: 40),
        PrimaryButton(
          label: l.translate('daily_bilan_btn'),
          onTap: () => context.push('/daily-survey'),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: l.translate('weekly_bilan_btn'),
          onTap: () => context.push('/weekly-survey'),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final PredictionResult result;
  final RecommendationResult? recommendation;
  final WeeklySurvey? weeklySurvey;
  final VoidCallback onRetry;
  const _ResultView({required this.result, this.recommendation, this.weeklySurvey, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = result.riskLevel == RiskLevel.low ? AppColors.success 
                : result.riskLevel == RiskLevel.medium ? AppColors.warning 
                : AppColors.error;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(l.translate('hermona_report')),
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.bgDark.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7),
          surfaceTintColor: Colors.transparent,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left_1),
            onPressed: () => context.pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(12)),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondaryDark,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                tabs: [
                  Tab(text: l.translate('analysis_tab_upper')),
                  Tab(text: l.translate('routine_tab')),
                  Tab(text: l.translate('lifestyle_tab')),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _AnalysisTab(result: result, color: color, weeklySurvey: weeklySurvey),
                  _RoutineTab(recommendation: recommendation),
                  _LifestyleTab(recommendation: recommendation),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0, left: 16, right: 16, top: 8),
              child: Text(
                AppLocalizations.of(context).translate('medical_disclaimer'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.textMutedPink, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: onRetry,
          label: Text(l.translate('new_scan'), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          icon: const Icon(Iconsax.refresh, size: 20),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  final PredictionResult result;
  final Color color;
  final WeeklySurvey? weeklySurvey;
  const _AnalysisTab({required this.result, required this.color, this.weeklySurvey});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 160, 24, 100),
      children: [
        // Main Risk Card
        GlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.translate('estimated_risk'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  StatusBadge(
                    text: l.translate('risk_${result.riskLevel.name.toLowerCase()}').toUpperCase(),
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CircularPercentIndicator(
                radius: 80.0,
                lineWidth: 14.0,
                percent: result.riskJ3,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(result.riskJ3 * 100).toInt()}%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
                    Text(l.translate('risk_j3_label'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ],
                ),
                progressColor: color,
                backgroundColor: color.withAlpha(25),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 1200,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _InfoBox(label: l.translate('trend'), value: result.trend == TrendDirection.increasing ? l.translate('increasing') : l.translate('stable'), color: color)),
                  _VerticalDivider(),
                  Expanded(child: _InfoBox(label: l.translate('cycle_phase'), value: l.translate('phase_${result.cyclePhase.toLowerCase()}').toUpperCase(), color: AppColors.secondary)),
                  _VerticalDivider(),
                  Expanded(child: _InfoBox(label: l.translate('hygiene'), value: '${result.hygieneScore}%', color: AppColors.success)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

        // Weekly Alerts & Clinical Priority
        if ((weeklySurvey != null && (weeklySurvey!.spfAlert || weeklySurvey!.autoCorrection || weeklySurvey!.routineFollowed == 'Non')) || 
            (result.riskLevel == RiskLevel.high)) ...[
          const SizedBox(height: 32),
          SectionHeader(title: l.translate('alerts_vigilance')),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 1. High Priority: Risk J+3 Breakout Prediction
                if (result.riskLevel == RiskLevel.high)
                  _AlertItem(
                    title: l.translate('alert_j3_title'),
                    body: l.translate('alert_j3_desc'),
                    icon: Iconsax.warning_2,
                    color: AppColors.error,
                  ),
                // 2. Priority: SPF absence
                if (weeklySurvey?.spfAlert ?? false)
                  _AlertItem(
                    title: l.translate('alert_spf_title'),
                    body: l.translate('alert_spf_desc'),
                    icon: Iconsax.sun_1,
                    color: AppColors.error,
                  ),
                // 3. Priority: Routine observance
                if (weeklySurvey?.routineFollowed == 'Non')
                  _AlertItem(
                    title: l.translate('alert_routine_title'),
                    body: l.translate('alert_routine_desc'),
                    icon: Iconsax.task_square,
                    color: AppColors.primary,
                  ),
                // 4. Priority: Cleansing frequency
                if (weeklySurvey?.autoCorrection ?? false)
                  _AlertItem(
                    title: l.translate('alert_cleansing_title'),
                    body: l.translate('alert_cleansing_desc'),
                    icon: Iconsax.brush_1,
                    color: AppColors.warning,
                  ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
        ],

        const SizedBox(height: 32),

        // SHAP Factors
        SectionHeader(title: l.translate('influence_factors')),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: result.shapFactors.entries.map((e) {
              final rawKey = e.key.toLowerCase().replaceAll(' ', '_');
              return _ShapIndicator(
                label: l.translate(rawKey), // On utilise la clé brute (ex: 'pcos', 'stress')
                value: e.value,
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }
}

class _RoutineTab extends StatelessWidget {
  final RecommendationResult? recommendation;
  const _RoutineTab({this.recommendation});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (recommendation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 160, 24, 100),
      children: [
        if (recommendation!.morningRoutine.isNotEmpty) ...[
          SectionHeader(title: l.translate('morning_routine')),
          const SizedBox(height: 12),
          ...recommendation!.morningRoutine.asMap().entries.map((e) => PremiumFadeIn(
            delay: e.key * 100,
            child: _TipCard(
              text: '${l.translate(e.value.product)}: ${l.translate(e.value.instruction)}', 
              icon: Iconsax.sun_1, 
              color: AppColors.primary
            ),
          )),
        ],
        const SizedBox(height: 24),
        if (recommendation!.eveningRoutine.isNotEmpty) ...[
          SectionHeader(title: l.translate('evening_routine')),
          const SizedBox(height: 12),
          ...recommendation!.eveningRoutine.asMap().entries.map((e) => PremiumFadeIn(
            delay: (e.key + 5) * 100,
            child: _TipCard(
              text: '${l.translate(e.value.product)}: ${l.translate(e.value.instruction)}', 
              icon: Iconsax.moon, 
              color: const Color(0xFF6366F1)
            ),
          )),
        ],
        const SizedBox(height: 24),
        if (recommendation!.avoid.isNotEmpty) ...[
          SectionHeader(title: l.translate('avoid')),
          const SizedBox(height: 12),
          ...recommendation!.avoid.asMap().entries.map((e) => PremiumFadeIn(
            delay: (e.key + 10) * 100,
            child: _TipCard(text: l.translate(e.value), icon: Iconsax.close_circle, color: AppColors.error),
          )),
        ],
      ],
    );
  }
}

class _LifestyleTab extends StatelessWidget {
  final RecommendationResult? recommendation;
  const _LifestyleTab({this.recommendation});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (recommendation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final combinedLifestyle = [
      ...recommendation!.lifestyle,
      ...recommendation!.habits,
      ...recommendation!.nutrition,
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 160, 24, 100),
      children: [
        SectionHeader(title: l.translate('habits_hygiene')),
        const SizedBox(height: 12),
        if (combinedLifestyle.isEmpty)
          _TipCard(text: l.translate('follow_usual_routine'), icon: Iconsax.info_circle, color: AppColors.info)
        else
          ...combinedLifestyle.asMap().entries.map((e) => PremiumFadeIn(
            delay: e.key * 100,
            child: _TipCard(text: l.translate(e.value), icon: Iconsax.heart5, color: AppColors.info),
          )),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// COMPONENTS
/// ─────────────────────────────────────────────────────────────────────────────

class _ScanIcon extends StatelessWidget {
  const _ScanIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Iconsax.magic_star, size: 80, color: AppColors.primary),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withAlpha(75), width: 2),
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds).fadeIn(duration: 1.seconds).fadeOut(delay: 1.seconds),
        ],
      ),
    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut);
  }
}

class _InfoBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondaryDark, letterSpacing: 1)),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: Colors.white.withAlpha(25));
  }
}

class _ShapIndicator extends StatelessWidget {
  final String label;
  final double value;
  const _ShapIndicator({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text('+${(value * 100).toInt()}%', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 6,
            percent: value.clamp(0, 1),
            progressColor: AppColors.error,
            backgroundColor: AppColors.error.withAlpha(25),
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 1000,
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _TipCard({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String title, body;
  final IconData icon;
  final Color color;
  const _AlertItem({required this.title, required this.body, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.3)),
              ],
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
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withAlpha(0)])),
    );
  }
}
