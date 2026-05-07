import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/recommendation_result.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../../../detection/domain/entities/detection_result.dart';
import '../../../../core/constants/app_constants.dart';

class RecommendationApiService implements RecommendationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    headers: {'X-API-Key': AppConstants.apiKey},
    connectTimeout: const Duration(seconds: 15), // NEW: Added Timeout
    receiveTimeout: const Duration(seconds: 15), // NEW: Added Timeout
    sendTimeout: const Duration(seconds: 15),    // NEW: Added Timeout
  ));

  @override
  Future<RecommendationResult> getRecommendations({
    required DetectionResult detection,
    required String userId,
  }) async {
    try {
      debugPrint('DEBUG: Starting getRecommendations for user: $userId');
      
      final profileSnap = await _db.collection(AppConstants.colUsers).doc(userId).get();
      final profile = profileSnap.data() ?? {};

      final predSnap = await _db
          .collection(AppConstants.colPredictions)
          .where('userId', isEqualTo: userId)
          .get();
      
      final List<QueryDocumentSnapshot> predDocs = predSnap.docs.toList();
      predDocs.sort((a, b) {
        final ta = a.data() as Map<String, dynamic>;
        final tb = b.data() as Map<String, dynamic>;
        final da = ta['predictedAt'] ?? '';
        final db = tb['predictedAt'] ?? '';
        return db.compareTo(da);
      });
      final prediction = predDocs.isNotEmpty ? predDocs.first.data() as Map<String, dynamic> : {};

      final dailySnap = await _db
          .collection('daily_surveys')
          .where('userId', isEqualTo: userId)
          .get();

      final List<QueryDocumentSnapshot> dailyDocs = dailySnap.docs.toList();
      dailyDocs.sort((a, b) {
        final ta = a.data() as Map<String, dynamic>;
        final tb = b.data() as Map<String, dynamic>;
        final da = ta['date'] ?? '';
        final db = tb['date'] ?? '';
        return db.compareTo(da);
      });
      final daily = dailyDocs.isNotEmpty ? dailyDocs.first.data() as Map<String, dynamic> : {};

      int hygieneScore = 100;
      final double sleep = (daily['sleep_hours'] ?? 8.0).toDouble();
      final int water = (daily['water_glasses'] ?? 8);
      final int stress = (daily['stress_level'] ?? 5);
      final List diet = daily['diet_tags'] ?? [];

      if (sleep < 7) hygieneScore -= 15;
      if (water < 6) hygieneScore -= 10;
      if (stress > 7) hygieneScore -= 20;
      if (diet.contains('sucre') || diet.contains('produits_laitiers') || diet.contains('fast_food')) hygieneScore -= 15;
      if (hygieneScore < 0) hygieneScore = 0;

      final requestData = {
        'userId': userId,
        'detectionId': detection.id,
        'severity': (detection.severityScore).toDouble(),
        'zones': detection.zoneCounts?.keys.toList() ?? [],
        'risk_today': (prediction['riskScore'] ?? 0.0).toDouble(),
        'risk_j3': (prediction['riskScoreJ3'] ?? 0.0).toDouble(),
        'top3_shap': (prediction['shapFactors'] as Map?)?.keys.toList() ?? [],
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
        'diet': diet.cast<String>(),
        'symptoms': (daily['symptoms'] as List?)?.cast<String>() ?? [],
        'hygiene_score': hygieneScore,
      };
      
      final response = await _dio.post('/recommend', data: requestData);

      if (response.statusCode == 200) {
        final Map<String, dynamic> resultData = Map<String, dynamic>.from(response.data);
        return RecommendationResult.fromJson(resultData);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('CRITICAL ERROR in getRecommendations: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveResult(RecommendationResult result, String userId) async {
    try {
      await _db
          .collection(AppConstants.colRecommendations)
          .doc(result.id)
          .set({...result.toJson(), 'userId': userId});
    } catch (e) {
      debugPrint('Error saving recommendation: $e');
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
      debugPrint('Error fetching cached recommendation: $e');
      return null;
    }
  }
}
