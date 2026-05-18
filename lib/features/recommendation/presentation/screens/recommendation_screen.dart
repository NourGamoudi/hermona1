import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:acneia/core/localization/app_localizations.dart';
import 'package:acneia/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
          onTap: () => _showProductDetails(context, s, l, i),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 12,
            child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
          title: Text(l.translate(s.product)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.translate(s.instruction)),
              if (s.productExamples.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    s.productExamples.join(', '),
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, size: 16),
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

  void _showProductDetails(BuildContext context, RoutineStep step, AppLocalizations l, int index) {
    final imageUrl = _getProductImageUrl(step.product, step.productExamples);
    final allEx = step.productExamples.join(' ').toLowerCase();
    
    String? brandLogoUrl;
    if (allEx.contains('avene') || allEx.contains('avène')) {
      brandLogoUrl = 'https://www.google.com/s2/favicons?domain=eau-thermale-avene.fr&sz=128';
    } else if (allEx.contains('la roche-posay') || allEx.contains('effaclar')) {
      brandLogoUrl = 'https://www.google.com/s2/favicons?domain=laroche-posay.fr&sz=128';
    } else if (allEx.contains('cerave')) {
      brandLogoUrl = 'https://www.google.com/s2/favicons?domain=cerave.com&sz=128';
    } else if (allEx.contains('bioderma') || allEx.contains('sensibio')) {
      brandLogoUrl = 'https://www.google.com/s2/favicons?domain=bioderma.fr&sz=128';
    }

    String? rationale;
    if (step.reason.isNotEmpty && step.reason != '...') {
      rationale = l.translate(step.reason);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[100], child: const Center(child: CircularProgressIndicator())),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (brandLogoUrl != null) 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CachedNetworkImage(
                        imageUrl: brandLogoUrl,
                        height: 30,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  Text(
                    l.translate(step.product).toUpperCase(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                  Text('${l.translate('step_label')} ${index + 1}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Text(l.translate('how_to_use').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(l.translate(step.instruction), style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  if (step.productExamples.isNotEmpty) ...[
                    Text(l.translate('recommended_products').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...step.productExamples.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $e', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    )),
                  ],
                  const SizedBox(height: 24),
                  if (rationale != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.primary.withAlpha(10), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.translate('why_this_choice').toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          Text(rationale, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProductImageUrl(String product, List<String> examples) {
    final p = product.toLowerCase();
    final allEx = examples.join(' ').toLowerCase();

    if (allEx.contains('la roche-posay') || allEx.contains('effaclar')) {
      if (p.contains('nettoyant') || p.contains('gel')) return 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&q=80&w=600';
      if (p.contains('hydratant') || p.contains('mat')) return 'https://images.unsplash.com/photo-1629732047847-50bad7558259?auto=format&fit=crop&q=80&w=600';
      return 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&q=80&w=600';
    }
    
    if (allEx.contains('cerave')) return 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&q=80&w=600';

    if (allEx.contains('bioderma') || allEx.contains('sebium')) {
      return 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&q=80&w=600';
    }

    if (p.contains('nettoyant') || p.contains('gel')) return 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&q=80&w=600';
    if (p.contains('hydratant') || p.contains('crème')) return 'https://images.unsplash.com/photo-1612817288484-6f916006741a?auto=format&fit=crop&q=80&w=600';
    if (p.contains('spf') || p.contains('solaire')) return 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?auto=format&fit=crop&q=80&w=600';
    if (p.contains('sérum')) return 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&q=80&w=600';
    return 'https://images.unsplash.com/photo-1556229167-da3ed2105a4d?auto=format&fit=crop&q=80&w=600';
  }
}
