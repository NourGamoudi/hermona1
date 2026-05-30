import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:acneia/features/notification/data/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:acneia/core/localization/app_localizations.dart';


import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/features/questionnaire/data/services/cycle_api_service.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/features/prediction/domain/entities/prediction_result.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _firstName;
  CycleStatus? _cycleStatus;
  bool _loadingCycle = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    final notifSvc = NotificationService();
    notifSvc.listenToNotifications();
  }

  void _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    // 1. Load basic user info and local cycle status immediately
    final d = await FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).get();
    if (d.exists && mounted) {
      CycleStatus? localCycle;
      try {
        localCycle = _cycleStatusFromProfile(d.data() ?? {});
      } catch (e) {
        debugPrint('Error parsing local cycle: $e');
      }
      
      setState(() {
        _firstName = d.data()?['firstName'] as String?;
        _cycleStatus = localCycle;
      });
    }

    // 2. Load cycle status from API (Source of Truth) in background
    if (_cycleStatus == null) {
      setState(() => _loadingCycle = true);
    }
    
    try {
      final cycleSvc = CycleApiService();
      final status = await cycleSvc.getCycleStatus();
      if (mounted) {
        setState(() {
          _cycleStatus = status;
          _loadingCycle = false;
        });
        _checkPhaseAlert();
      }
    } catch (e) {
      debugPrint('Error loading cycle status: $e');
      if (mounted) {
        setState(() {
          _loadingCycle = false;
        });
        _checkPhaseAlert();
      }
    }
  }

  CycleStatus? _cycleStatusFromProfile(Map<String, dynamic> profile) {
    final lastPeriodValue = profile['lastPeriodsDate'] ??
        profile['lastPeriodDate'] ??
        profile['last_period_date'];
    if (lastPeriodValue == null) return null;

    final lastPeriod = _parseProfileDate(lastPeriodValue);
    if (lastPeriod == null) return null;

    final durationsRaw = profile['lastCyclesDuration'] ??
        profile['cycleDuration'] ??
        profile['cycleLength'];
    final durations = durationsRaw is List
        ? durationsRaw.map((v) => _parseInt(v, 28).clamp(15, 120).toInt()).toList()
        : <int>[_parseInt(durationsRaw, 28).clamp(15, 120).toInt()];
    final cycleLength = durations.isEmpty
        ? 28
        : (durations.reduce((a, b) => a + b) / durations.length)
            .round()
            .clamp(15, 120)
            .toInt();
    final menstruationDuration =
        _parseInt(profile['menstruationDuration'] ?? profile['periodDuration'], 5)
            .clamp(1, 10)
            .toInt();

    final today = DateTime.now();
    final start = DateTime(lastPeriod.year, lastPeriod.month, lastPeriod.day);
    final current = DateTime(today.year, today.month, today.day);
    final day = (current.difference(start).inDays % cycleLength) + 1;
    final ovulationDay = (cycleLength - 14)
        .clamp(menstruationDuration + 1, cycleLength)
        .toInt();

    String phase;
    if (day <= menstruationDuration) {
      phase = 'menstrual';
    } else if (day < ovulationDay) {
      phase = 'follicular';
    } else if (day <= ovulationDay + 1) {
      phase = 'ovulatory';
    } else {
      phase = 'luteal';
    }

    return CycleStatus(
      day: day,
      phase: phase,
      ovulationDay: ovulationDay,
      cycleLength: cycleLength,
      menstruationDuration: menstruationDuration,
    );
  }

  DateTime? _parseProfileDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      return (value as dynamic).toDate();
    } catch (_) {
      return null;
    }
  }

  int _parseInt(dynamic value, int fallback) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  void _checkPhaseAlert() {
    if (_cycleStatus == null) return;
    
    final l = AppLocalizations.of(context);
    final phase = _cycleStatus!.phase;
    
    String title = '';
    String body = '';

    if (phase == 'menstrual') {
      title = l.translate('phase_menstrual');
      body = l.translate('menstrual_notif_body');
    } else if (phase == 'follicular') {
      title = l.translate('phase_follicular');
      body = l.translate('follicular_notif_body');
    } else if (phase == 'ovulatory') {
      title = l.translate('phase_ovulatory');
      body = l.translate('ovulatory_notif_body');
    } else if (phase == 'luteal') {
      title = l.translate('phase_luteal');
      body = l.translate('luteal_notif_body');
    }

    if (title.isNotEmpty && title != 'phase_unknown') {
      Future.delayed(const Duration(seconds: 15), () {
        debugPrint('🔔 Phase $phase détectée (après 15 sec) !');
        NotificationService().sendNotification(
          title: title,
          body: body,
          type: 'CYCLE_ALERT_TEST',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      body: Stack(
        children: [
          // Background Blobs - Mesh Gradient Effect
          Positioned(
            top: -100,
            right: -50,
            child: _Blob(size: 300, color: AppTheme.primary.withValues(alpha: 0.15)),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: _Blob(size: 400, color: const Color(0xFFC084FC).withValues(alpha: 0.1)), // Soft Lavender
          ),
          Positioned(
            bottom: 100,
            right: -150,
            child: _Blob(size: 350, color: const Color(0xFFFDBA74).withValues(alpha: 0.1)), // Soft Peach
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _Blob(size: 250, color: AppTheme.primary.withValues(alpha: 0.08)),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _loadUser(),
              color: AppTheme.primary,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  
                  // 1. DASHBOARD SECTION (Hygiene & Risk)
                  _buildScoreRow(context, uid),
                  const SizedBox(height: 12),
                  _buildCyclePhaseBar(context, uid),
                  const SizedBox(height: 12),
                  _buildLatestAnalysis(context, uid),
                  const SizedBox(height: 24),

                  // 2. À REMPLIR SECTION
                  SectionHeader(title: l.translate('section_tracking')),
                  const SizedBox(height: 12),
                  _buildToFillSection(context),
                  const SizedBox(height: 32),

                  // 3. EXPLORER SECTION
                  SectionHeader(title: l.translate('section_community')),
                  const SizedBox(height: 12),
                  _buildExplorerSection(context),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HERMONA',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                '${_firstName ?? l.translate('unknown')} ✨',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.colNotifications)
              .where('userId', isEqualTo: uid)
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, snap) {
            final hasNotif = snap.hasData && snap.data!.docs.isNotEmpty;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _HeaderAction(icon: Iconsax.notification, onTap: () => context.push('/notifications')),
                if (hasNotif)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 45, height: 45,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🌸', style: TextStyle(fontSize: 20))),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1);
  }

  Widget _buildScoreRow(BuildContext context, String? uid) {
    final l = AppLocalizations.of(context);
    if (uid == null) return const SizedBox();
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.colPredictions)
                .where('userId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              int? score;
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final da = _parseDate(a['predictedAt']);
                  final db = _parseDate(b['predictedAt']);
                  return db.compareTo(da);
                });
                final data = docs.first.data() as Map<String, dynamic>;
                score = (data['hygieneScore'] as num?)?.toInt();
              }
              return _SquareScoreCard(
                title: l.translate('hygiene'),
                value: score != null ? '$score%' : '--',
                subtitle: l.translate('score_ia'),
                icon: Iconsax.heart5,
                color: AppColors.info,
                onTap: () => context.push('/daily-survey'),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection(AppConstants.colPredictions).where('userId', isEqualTo: uid).snapshots(),
            builder: (context, snapshot) {
              PredictionResult? result;
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final da = _parseDate(a['predictedAt']);
                  final db = _parseDate(b['predictedAt']);
                  return db.compareTo(da);
                });
                result = PredictionResult.fromJson(docs.first.data() as Map<String, dynamic>);
              }
              return _SquareScoreCard(
                title: l.translate('risk'),
                value: result != null ? '${(result.riskJ3 * 100).toInt()}%' : '--',
                subtitle: result != null ? l.translate('risk_${result.riskLevel.name.toLowerCase()}') : l.translate('unknown'),
                icon: Iconsax.status_up,
                color: result?.riskLevel == RiskLevel.low ? AppColors.success : (result?.riskLevel == RiskLevel.medium ? AppColors.warning : AppColors.error),
                onTap: () => context.push('/prediction'),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildCyclePhaseBar(BuildContext context, String? uid) {
    final l = AppLocalizations.of(context);
    if (_loadingCycle) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    final day = _cycleStatus?.day ?? 0;
    final avgCycle = _cycleStatus?.cycleLength ?? 28;
    final phase = _cycleStatus?.phase ?? 'unknown';

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      onTap: () => _showCycleDetails(context, l.translate('phase_$phase'), day, avgCycle),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.waves, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.translate('phase_$phase').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text('${l.translate('day_label')} $day • ${l.translate('average_cycle')}: $avgCycle ${l.translate('days_label')}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  void _showCycleDetails(BuildContext context, String currentPhase, int day, int avgCycle) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 45, height: 5, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Text(l.translate('cycle_details'), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('${l.translate('day_in_cycle')} $day • ${l.translate('average_cycle')}: $avgCycle ${l.translate('days')}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 24),
            if (currentPhase == l.translate('phase_menstrual'))
              _buildPhaseInfo(context, l.translate('phase_menstrual'), l.translate('phase_menstrual_range'), l.translate('phase_menstrual_desc'), true, [const Color(0xFFFF2D55), const Color(0xFFFF5E3A)]),
            if (currentPhase == l.translate('phase_follicular'))
              _buildPhaseInfo(context, l.translate('phase_follicular'), l.translate('phase_follicular_range'), l.translate('phase_follicular_desc'), true, [const Color(0xFFF472B6), const Color(0xFFDB2777)]), // Nouveau Rose
            if (currentPhase == l.translate('phase_ovulatory'))
              _buildPhaseInfo(context, l.translate('phase_ovulatory'), l.translate('phase_ovulatory_range'), l.translate('phase_ovulatory_desc'), true, [const Color(0xFFAF52DE), const Color(0xFFFF2D55)]),
            if (currentPhase == l.translate('phase_luteal'))
              _buildPhaseInfo(context, l.translate('phase_luteal'), '${l.translate('phase_luteal_range').split('-')[0]}-$avgCycle', l.translate('phase_luteal_desc'), true, [const Color(0xFFFF9500), const Color(0xFFFFCC00)]),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseInfo(BuildContext context, String title, String days, String desc, bool isCur, List<Color> colors) {
    final l = AppLocalizations.of(context);
    final accentColor = colors.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: isCur ? [
          BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isCur ? LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            color: isCur ? null : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6)),
            border: Border.all(color: isCur ? Colors.white.withValues(alpha: 0.2) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCur ? Colors.white.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(isCur ? Icons.auto_awesome : Icons.circle_outlined, size: 20, color: isCur ? Colors.white : accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${l.translate('phase')} $title ($days)'.toUpperCase(), 
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 13, 
                    letterSpacing: 0.5,
                    color: isCur ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  desc, 
                  style: TextStyle(
                    fontSize: 12, 
                    height: 1.6, 
                    color: isCur ? Colors.white.withValues(alpha: 0.9) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: isCur ? FontWeight.w500 : FontWeight.normal,
                  )
                ),
              ])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestAnalysis(BuildContext context, String? uid) {
    final l = AppLocalizations.of(context);
    if (uid == null) return const SizedBox();
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection(AppConstants.colDetections)
          .where('userId', isEqualTo: uid)
          .orderBy('analyzedAt', descending: true)
          .limit(1)
          .get(const GetOptions(source: Source.server)),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
        
        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        return GlassCard(
          onTap: () => context.push('/detection/result', extra: data),
          child: Row(
            children: [
              Container(
                width: 45, 
                height: 45, 
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle), 
                child: Icon(Iconsax.scan, color: AppTheme.primary, size: 20)
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${l.translate('severity_score')} : ${(data['severityScore'] as num?)?.toInt() ?? 0}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(l.translate('latest_photo_analysis'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToFillSection(BuildContext context) {
    final l = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return Column(
      children: [
        _RowAction(
          icon: Iconsax.user_edit, 
          title: l.translate('personal_info'), 
          subtitle: l.translate('personal_info_sub'), 
          onTap: () => context.push('/onboarding')
        ),
        const SizedBox(height: 12),
        
        // Daily Survey Status
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('daily_surveys')
              .where('userId', isEqualTo: uid)
              .orderBy('date', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            bool isDone = false;
            if (snapshot.hasData) {
              final today = DateTime.now();
              final todayStr = '${today.year}-${today.month}-${today.day}';
              isDone = snapshot.data!.docs.any((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final date = d['date'] is Timestamp ? (d['date'] as Timestamp).toDate() : DateTime.tryParse(d['date'].toString()) ?? DateTime(2000);
                return '${date.year}-${date.month}-${date.day}' == todayStr;
              });
            }
            return _RowAction(
              icon: Iconsax.edit, 
              title: l.translate('daily_q'), 
              subtitle: isDone ? l.translate('daily_q_done') : l.translate('daily_tracking_subtitle'), 
              onTap: () => context.push('/daily-survey'),
              isCompleted: isDone,
            );
          },
        ),
        const SizedBox(height: 12),

        // Weekly Survey Status
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('weekly_surveys')
              .where('userId', isEqualTo: uid)
              .where('year', isEqualTo: DateTime.now().year)
              .where('weekNumber', isEqualTo: ((int.parse(DateFormat("D").format(DateTime.now())) - DateTime.now().weekday + 10) / 7).floor())
              .snapshots(),
          builder: (context, snapshot) {
            final isDone = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
            return _RowAction(
              icon: Iconsax.calendar_tick, 
              title: l.translate('weekly_q'), 
              subtitle: isDone ? l.translate('weekly_q_done') : l.translate('weekly_review_subtitle'), 
              onTap: () => context.push('/weekly-survey'),
              isCompleted: isDone,
            );
          },
        ),
      ],
    );
  }

  Widget _buildExplorerSection(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.6,
      children: [
        _ExplorerCard(icon: Iconsax.message_notif, title: l.translate('assistant'), color: AppTheme.primary, onTap: () => context.go('/chat')),
        _ExplorerCard(icon: Iconsax.chart, title: l.translate('history'), color: AppColors.info, onTap: () => context.push('/history')),
        _ExplorerCard(icon: Iconsax.people, title: l.translate('forum'), color: AppColors.secondary, onTap: () => context.push('/forum')),
        _ExplorerCard(icon: Iconsax.message_text, title: l.translate('messages'), color: AppColors.accent, onTap: () => context.push('/messages')),
        _ExplorerCard(icon: Iconsax.chart_21, title: l.translate('acne_evolution'), color: const Color(0xFF9C27B0), onTap: () => context.push('/evolution')),
      ],
    );
  }

  DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (val is String) return DateTime.tryParse(val) ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (val is Timestamp) return val.toDate();
    try { return (val as dynamic).toDate(); } catch (_) { return DateTime.fromMillisecondsSinceEpoch(0); }
  }
}



class _SquareScoreCard extends StatelessWidget {
  final String title, value, subtitle; final IconData icon; final Color color; final VoidCallback onTap;
  const _SquareScoreCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GlassCard(onTap: onTap, padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
      const SizedBox(height: 2),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]));
  }
}

class _RowAction extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap; final bool isCompleted;
  const _RowAction({required this.icon, required this.title, required this.subtitle, required this.onTap, this.isCompleted = false});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap, 
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), 
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10), 
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1), 
            borderRadius: BorderRadius.circular(12)
          ), 
          child: Icon(icon, color: isCompleted ? Colors.green : AppTheme.primary, size: 20)
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: isCompleted ? Colors.green : Colors.grey)),
        ])),
        Icon(isCompleted ? Icons.check_circle : Iconsax.arrow_right_3, size: 16, color: isCompleted ? Colors.green : Colors.grey),
      ]));
  }
}

class _ExplorerCard extends StatelessWidget {
  final IconData icon; final String title; final Color color; final VoidCallback onTap;
  const _ExplorerCard({required this.icon, required this.title, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GlassCard(onTap: onTap, padding: const EdgeInsets.all(12), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    ]));
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle, border: Border.all(color: Colors.grey.withValues(alpha: 0.1))), child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))));
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
