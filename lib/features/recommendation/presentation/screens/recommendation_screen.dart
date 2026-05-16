import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:acneia/core/localization/app_localizations.dart';
import 'package:acneia/core/theme/app_theme.dart';

import 'package:acneia/features/detection/domain/entities/detection_result.dart';
import 'package:acneia/features/recommendation/data/services/recommendation_api_service.dart';
import 'package:acneia/features/recommendation/domain/entities/recommendation_result.dart';

class RecommendationScreen extends StatefulWidget {
  final String detectionId;
  final Map<String, dynamic>? detectionData;

  const RecommendationScreen({
    super.key,
    required this.detectionId,
    this.detectionData,
  });

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  RecommendationResult? _result;
  bool _loading = true;
  String? _error;

  final _recSvc = RecommendationApiService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          final l = AppLocalizations.of(context);
          setState(() {
            _error = l.translate('user_not_connected');
            _loading = false;
          });
        }
        return;
      }

      final detection = widget.detectionData != null
          ? DetectionResult.fromJson(widget.detectionData!)
          : DetectionResult(
              id: widget.detectionId,
              severityScore: 0,
              severityLevel: SeverityLevel.normal,
              classifications: const [],
              analyzedAt: DateTime.now(),
              imageUrls: const [],
            );

      final l = AppLocalizations.of(context);
      final result = await _recSvc.getRecommendations(
        detection: detection,
        userId: user.uid,
        lang: l.locale.languageCode,
      );

      await _recSvc.saveResult(result, user.uid);

      if (!mounted) return;

      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.translate('recommendations_title')),
        centerTitle: true,
        backgroundColor: Colors.white.withAlpha(180),
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgLight,
              AppColors.bgLight.withAlpha(204),
              AppColors.surfaceLight,
            ],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _result == null
                    ? Center(child: Text(l.translate('no_data')))
                    : Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: _buildContent(),
                      ),
      ),
    );
  }

  Widget _buildContent() {
    final r = _result!;
    final l = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 8),
          child: Column(
            children: [
              Text(l.translate('ai_analysis'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _box(l.translate('severity'), "${r.severity.toInt()}%"),
                  _box(l.translate('risk_j3_label'), "${(r.riskJ3 * 100).toInt()}%"),
                  _box(l.translate('hygiene'), "${r.hygieneScore.toInt()}%"),
                ],
              ),
            ],
          ),
        ),
        _buildStrategySection(r, l),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _list(r.morningRoutine, l),
              _list(r.eveningRoutine, l),
              Center(child: Text(l.translate('lifestyle_tab'))),
            ],
          ),
        )
      ],
    );
  }

  Widget _box(String t, String v) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _list(List<RoutineStep> steps, AppLocalizations l) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: steps.length,
      itemBuilder: (_, i) {
        final s = steps[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 12,
            child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
          title: Text(l.translate(s.product)),
          subtitle: Text(l.translate(s.instruction)),
        );
      },
    );
  }

  Widget _buildStrategySection(RecommendationResult r, AppLocalizations l) {
    final strategy = _computeStrategy(r.strategy, l);
    final Color stratColor = strategy == l.translate('strategy_protection')
        ? AppColors.error
        : strategy == l.translate('strategy_equilibrium')
            ? AppColors.warning
            : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: stratColor.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stratColor.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: stratColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.translate('adopted_strategy').toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: stratColor, letterSpacing: 1)),
                  Text(strategy, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stratColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _computeStrategy(String backendStrategy, AppLocalizations l) {
    if (backendStrategy.isEmpty || backendStrategy == 'SAFE MODE') {
      return l.translate('strategy_equilibrium');
    }
    final s = backendStrategy.toUpperCase();
    if (s.contains('PROTECTION') || s.contains('REPAIR')) return l.translate('strategy_protection');
    if (s.contains('EQUILIBRE') || s.contains('BALANCE') || s.contains('ÉQUILIBRE')) return l.translate('strategy_equilibrium');
    if (s.contains('PREVENTION') || s.contains('PRÉVENTION') || s.contains('PREVENT')) return l.translate('strategy_prevention');
    return backendStrategy;
  }
}
