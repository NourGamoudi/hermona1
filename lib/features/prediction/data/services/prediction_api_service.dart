import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:acneia/features/prediction/domain/entities/prediction_result.dart';
import 'package:acneia/features/prediction/domain/repositories/prediction_repository.dart';
import 'package:acneia/core/constants/app_constants.dart';

class PredictionApiService implements PredictionRepository {
  final Dio _dio;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  PredictionApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          headers: {'X-API-Key': AppConstants.apiKey},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  @override
  Future<PredictionResult> predict(Map<String, dynamic> answers) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Non connecté');

      // 1. Fetch User Profile
      final profileSnap = await _db.collection(AppConstants.colUsers).doc(uid).get();
      final profile = profileSnap.data() ?? {};

      // 2. Prepare Payload (Simplified - Backend handles the score)
      final payload = {
        'answers': _sanitizeMap({
          ...answers,
          'profile': profile,
        })
      };

      final response = await _dio.post<Map<String, dynamic>>(
        '/predict',
        data: payload,
      );
      
      if (response.data == null) throw Exception('Réponse vide du serveur');
      return PredictionResult.fromJson(response.data!);
    } catch (e) {
      debugPrint('DEBUG ERROR in predict: $e');
      throw Exception('Erreur de prédiction: $e');
    }
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _sanitizeMap(value));
      } else if (value is List) {
        return MapEntry(key, value.map((e) => e is Map<String, dynamic> ? _sanitizeMap(e) : e).toList());
      }
      return MapEntry(key, value);
    });
  }

  @override
  Future<void> saveResult(PredictionResult result, String userId) async {
    await _db
        .collection(AppConstants.colPredictions)
        .doc(result.id)
        .set({...result.toJson(), 'userId': userId});
  }

  @override
  Future<List<PredictionResult>> getHistory(String userId) async {
    final snap = await _db
        .collection(AppConstants.colPredictions)
        .where('userId', isEqualTo: userId)
        .get();

    final List<QueryDocumentSnapshot> docs = snap.docs.toList();
    docs.sort((a, b) {
      final ta = a.data() as Map<String, dynamic>;
      final tb = b.data() as Map<String, dynamic>;
      final da = ta['predictedAt'] ?? '';
      final db = tb['predictedAt'] ?? '';
      return db.compareTo(da);
    });

    return docs
        .map((d) => PredictionResult.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }
}
