import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:acneia/features/recommendation/domain/entities/recommendation_result.dart';
import 'package:acneia/features/recommendation/domain/repositories/recommendation_repository.dart';
import 'package:acneia/features/detection/domain/entities/detection_result.dart';
import 'package:acneia/core/constants/app_constants.dart';

class RecommendationApiService implements RecommendationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    headers: {'X-API-Key': AppConstants.apiKey},
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 60),
  ));

  @override
  Future<RecommendationResult> getRecommendations({
    required DetectionResult detection,
    required String userId,
  }) async {
    try {
      debugPrint('DEBUG: getRecommendations for $userId');

      final profileSnap = await _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .get();

      final profile = profileSnap.data() ?? {};

      final predSnap = await _db
          .collection(AppConstants.colPredictions)
          .where('userId', isEqualTo: userId)
          .get();

      final predictions = predSnap.docs.map((e) => e.data()).toList()
        ..sort((a, b) {
          final da = a['predictedAt'];
          final db = b['predictedAt'];
          final DateTime dateA = da is Timestamp ? da.toDate() : DateTime.tryParse(da.toString()) ?? DateTime(2000);
          final DateTime dateB = db is Timestamp ? db.toDate() : DateTime.tryParse(db.toString()) ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });

      final prediction = predictions.isNotEmpty ? predictions.first : {};

      final dailySnap = await _db
          .collection('daily_surveys')
          .where('userId', isEqualTo: userId)
          .get();

      final dailyDocs = dailySnap.docs.map((e) => e.data()).toList()
        ..sort((a, b) {
          final da = a['date'];
          final db = b['date'];
          final DateTime dateA = da is Timestamp ? da.toDate() : DateTime.tryParse(da.toString()) ?? DateTime(2000);
          final DateTime dateB = db is Timestamp ? db.toDate() : DateTime.tryParse(db.toString()) ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });

      final daily = dailyDocs.isNotEmpty ? dailyDocs.first : {};

      // SAFE extraction
      final double sleep = (daily['sleep_hours'] ?? 8).toDouble();
      final int water = (daily['water_glasses'] ?? 6);
      final int stress = (daily['stress_level'] ?? 5);

      final List<String> diet =
          (daily['diet_tags'] as List?)?.cast<String>() ?? [];

      // Use the hygiene score calculated by the AI prediction
      int hygieneScore = (prediction['hygieneScore'] ?? 70).toInt();

      final requestData = {
        'userId': userId,
        'detectionId': detection.id,
        'severity': detection.severityScore.toDouble(),
        'zones': detection.zoneCounts?.keys.toList() ?? [],
        'riskJ3': (prediction['riskJ3'] ?? 0).toDouble(),
        'top3_shap': (prediction['shapFactors'] as Map?)
                ?.keys
                .toList() ??
            [],
        'skin_type': profile['skinType'] ?? 'mixte',
        'allergies': (profile['cosmeticAllergies'] as List?)?.cast<String>() ?? [],
        'acne_treatment': profile['acneTreatment'] ?? 'aucun',
        'hormonal_treatment': profile['hormonalContraception'] ?? 'aucune',
        'smoker': profile['isSmoker'] ?? false,
        'alcohol': profile['alcoholConsumption'] ?? 'jamais',
        'phase': daily['cyclePhase'] ?? 'folliculaire',
        'stress': stress,
        'sleep': sleep,
        'hydration': water,
        'diet': diet,
        'symptoms': (daily['symptoms'] as List?)?.cast<String>() ?? [],
        'hygiene_score': hygieneScore,
      };

      final response = await _dio.post('/recommend', data: requestData);

      if (response.statusCode == 200) {
        return RecommendationResult.fromJson(
          Map<String, dynamic>.from(response.data),
        );
      }

      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      debugPrint('API ERROR: $e');
      return _buildFallbackResult(userId, detection.id, error: e.toString());
    }
  }

  // fallback safe
  RecommendationResult _buildFallbackResult(
    String userId,
    String detectionId, {
    String? error,
  }) {
    final errorMsg = error != null ? '\nErreur: $error' : '';

    return RecommendationResult(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      detectionId: detectionId,
      morningRoutine: const [],
      eveningRoutine: const [],
      actives: const ['Acide Hyaluronique'],
      avoid: const ['Acides forts'],
      lifestyle: const ['Dormir 8h'],
      nutrition: const ['Boire de l’eau'],
      habits: const ['Ne pas toucher le visage'],
      strategy: 'SAFE MODE',
      alternativeStrategy: '',
      variationIndex: 0,
      explanation:
          'Mode secours activé. Routine générique appliquée.$errorMsg',
      brands: 'CeraVe, La Roche-Posay',
      disclaimer: 'Fallback system',
      riskJ3: 0.5,
      hygieneScore: 70,
      severity: 0.5,
      createdAt: DateTime.now(),
      duration: '7 jours',
      whyThis: const ['Mode sécurité'],
      dietTips: const [],
    );
  }

  @override
  Future<void> saveResult(RecommendationResult result, String userId) async {
    try {
      await _db
          .collection(AppConstants.colRecommendations)
          .doc(result.id)
          .set({...result.toJson(), 'userId': userId});
    } catch (e) {
      debugPrint('SAVE ERROR: $e');
    }
  }

  @override
  Future<RecommendationResult?> getForDetection(String detectionId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colRecommendations)
          .where('detectionId', isEqualTo: detectionId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      return RecommendationResult.fromJson(snap.docs.first.data());
    } catch (e) {
      debugPrint('FETCH ERROR: $e');
      return null;
    }
  }
}
