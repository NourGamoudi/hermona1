import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

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
        setState(() {
          _error = "Utilisateur non connecté";
          _loading = false;
        });
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

      final result = await _recSvc.getRecommendations(
        detection: detection,
        userId: user.uid,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1F1),
      appBar: AppBar(
        title: const Text("Recommandations"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _result == null
                  ? const Center(child: Text("Aucune donnée"))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final r = _result!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Analyse IA"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _box("Sévérité", "${r.severity}%"),
                  _box("Risque", "${r.riskScore}%"),
                  _box("Hygiène", "${r.hygieneScore}%"),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _list(r.morningRoutine),
              _list(r.eveningRoutine),
              const Center(child: Text("Vie")),
            ],
          ),
        )
      ],
    );
  }

  Widget _box(String t, String v) {
    return Column(
      children: [
        Text(t),
        Text(v),
      ],
    );
  }

  Widget _list(List<RoutineStep> steps) {
    return ListView.builder(
      itemCount: steps.length,
      itemBuilder: (_, i) {
        final s = steps[i];
        return ListTile(
          title: Text(s.product),
          subtitle: Text(s.instruction),
        );
      },
    );
  }
}
