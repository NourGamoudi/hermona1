import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:acneia/core/widgets/common_widgets.dart';
import 'package:acneia/features/prediction/domain/entities/prediction_result.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection(AppConstants.colUsers).doc(uid).get()
        .then((d) { 
          if (d.exists && mounted) {
            setState(() => _firstName = d.data()?['firstName'] as String?);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, 
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100,
            right: -50,
            child: _Blob(size: 300, color: AppTheme.primary.withValues(alpha: 0.12)),
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
                  _buildScoreRow(uid),
                  const SizedBox(height: 12),
                  _buildCyclePhaseBar(uid),
                  const SizedBox(height: 12),
                  _buildLatestAnalysis(uid),
                  const SizedBox(height: 24),

                  // 2. À REMPLIR SECTION
                  const SectionHeader(title: 'À Remplir'),
                  const SizedBox(height: 12),
                  _buildToFillSection(context),
                  const SizedBox(height: 32),

                  // 3. EXPLORER SECTION
                  const SectionHeader(title: 'Explorer'),
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()},',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                '${_firstName ?? 'Chargement...'} ✨',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF2D2D2D)),
              ),
            ],
          ),
        ),
        _HeaderAction(icon: Iconsax.notification, onTap: () => context.push('/notifications')),
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

  Widget _buildScoreRow(String? uid) {
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
                score = data['hygieneScore'] as int?;
              }
              return _SquareScoreCard(
                title: 'Hygiène',
                value: score != null ? '$score%' : '--',
                subtitle: 'Score IA',
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
                title: 'Risque',
                value: result != null ? '${(result.riskScore * 100).toInt()}%' : '--',
                subtitle: result?.riskLevel.name.toUpperCase() ?? 'Inconnu',
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

  Widget _buildCyclePhaseBar(String? uid) {
    if (uid == null) return const SizedBox();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).snapshots(),
      builder: (context, snapshot) {
        String phase = 'Inconnue';
        int day = 0;
        int avgCycle = 28;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          // Calculate average cycle
          final lastCycles = (data['lastCyclesDuration'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [28, 28, 28];
          if (lastCycles.isNotEmpty) {
            avgCycle = (lastCycles.reduce((a, b) => a + b) / lastCycles.length).round();
          }

          if (data['lastPeriodsDate'] != null) {
            final lastDate = _parseDate(data['lastPeriodsDate']);
            final daysSinceLast = DateTime.now().difference(lastDate).inDays;
            day = (daysSinceLast % avgCycle) + 1;
            
            // Dynamic phase mapping based on cycle length (sync with Daily Survey)
            if (day <= 5) {
              phase = 'Menstruelle';
            } else if (day <= (avgCycle * 0.45).toInt()) {
              phase = 'Folliculaire';
            } else if (day <= (avgCycle * 0.55).toInt()) {
              phase = 'Ovulatoire';
            } else {
              phase = 'Lutéale';
            }
          }
        }
        return GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          onTap: () => _showCycleDetails(context, phase, day, avgCycle),
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
                    Text('Phase $phase', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('Jour $day du cycle • Moyenne: $avgCycle jours', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  void _showCycleDetails(BuildContext context, String currentPhase, int day, int avgCycle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        borderRadius: 30,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text('Votre Cycle Hormonal', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text('Jour $day • Moyenne habituelle: $avgCycle jours', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 24),
            if (currentPhase == 'Menstruelle')
              _buildPhaseInfo('Menstruelle', 'Jours 1-5', 'Hormones au plus bas. Focus sur le nettoyage doux.', true),
            if (currentPhase == 'Folliculaire')
              _buildPhaseInfo('Folliculaire', 'Jours 6-13', 'Peau plus éclatante et réceptive aux soins.', true),
            if (currentPhase == 'Ovulatoire')
              _buildPhaseInfo('Ovulatoire', 'Jours 14-15', 'Pic hormonal. Risque de pores obstrués.', true),
            if (currentPhase == 'Lutéale')
              _buildPhaseInfo('Lutéale', 'Jours 16-$avgCycle', 'Pic de sébum. Risque d\'acné élevé.', true),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseInfo(String title, String days, String desc, bool isCur) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isCur ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(isCur ? Icons.check_circle : Icons.circle_outlined, size: 18, color: isCur ? AppColors.primary : Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Phase $title ($days)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
        ],
      ),
    );
  }

  Widget _buildLatestAnalysis(String? uid) {
    if (uid == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.colDetections)
          .where('userId', isEqualTo: uid)
          .orderBy('analyzedAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
        
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final ta = a.data() as Map<String, dynamic>;
          final tb = b.data() as Map<String, dynamic>;
          final da = ta['analyzedAt'] is Timestamp ? (ta['analyzedAt'] as Timestamp).toDate() : DateTime.tryParse(ta['analyzedAt'].toString()) ?? DateTime(2000);
          final db = tb['analyzedAt'] is Timestamp ? (tb['analyzedAt'] as Timestamp).toDate() : DateTime.tryParse(tb['analyzedAt'].toString()) ?? DateTime(2000);
          return db.compareTo(da);
        });

        final data = docs.first.data() as Map<String, dynamic>;
        return GlassCard(
          onTap: () => context.push('/detection/result', extra: data),
          child: Row(
            children: [
              Container(width: 45, height: 45, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Iconsax.scan, color: AppTheme.primary, size: 20)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Sévérité : ${data['severityScore']}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text('Dernière analyse effectuée.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToFillSection(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return Column(
      children: [
        _RowAction(
          icon: Iconsax.user_edit, 
          title: 'Informations Personnelles', 
          subtitle: 'Profil & Cycle', 
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
              title: 'Questionnaire Quotidien', 
              subtitle: isDone ? '✓ Déjà rempli aujourd\'hui' : 'Suivi de vie', 
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
              title: 'Questionnaire Hebdomadaire', 
              subtitle: isDone ? '✓ Déjà rempli cette semaine' : 'Analyse Photo', 
              onTap: () => context.push('/weekly-survey'),
              isCompleted: isDone,
            );
          },
        ),
      ],
    );
  }

  Widget _buildExplorerSection(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.6,
      children: [
        _ExplorerCard(icon: Iconsax.message_notif, title: 'Assistant', color: AppTheme.primary, onTap: () => context.go('/chat')),
        _ExplorerCard(icon: Iconsax.chart, title: 'Historique', color: AppColors.info, onTap: () => context.push('/history')),
        _ExplorerCard(icon: Iconsax.people, title: 'Forum', color: AppColors.secondary, onTap: () => context.push('/forum')),
        _ExplorerCard(icon: Iconsax.message_text, title: 'Messagerie', color: AppColors.accent, onTap: () => context.push('/messages')),
        _ExplorerCard(icon: Iconsax.chart_21, title: 'Évolution', color: const Color(0xFF9C27B0), onTap: () => context.push('/evolution')),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Bonne nuit';
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
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
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle, border: Border.all(color: Colors.grey.withValues(alpha: 0.1))), child: Icon(icon, size: 20, color: Colors.grey.shade700)));
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
