import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/prediction_result.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../../../../core/constants/app_constants.dart';

class PredictionApiService implements PredictionRepository {

  final Dio _dio;

  PredictionApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          headers: {'X-API-Key': AppConstants.apiKey},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<PredictionResult> predict(Map<String, dynamic> answers) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Non connecté');

      // 1. Fetch Latest Context
      final profileSnap = await _db.collection('users').doc(uid).get();
      final dailySnap = await _db.collection('daily_surveys')
          .where('userId', isEqualTo: uid)
          .get();

      final profile = profileSnap.data() ?? {};
      Map<String, dynamic> daily = {};
      
      if (dailySnap.docs.isNotEmpty) {
        final docs = dailySnap.docs.toList();
        docs.sort((a, b) {
          DateTime dateA = a['date'] is Timestamp ? (a['date'] as Timestamp).toDate() : DateTime.tryParse(a['date'].toString()) ?? DateTime(2000);
          DateTime dateB = b['date'] is Timestamp ? (b['date'] as Timestamp).toDate() : DateTime.tryParse(b['date'].toString()) ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
        daily = docs.first.data();
      }

      // 2. Prepare Payload
      final payload = {
        'answers': _sanitizeMap({
          ...answers,
          'hygieneScore': daily['lifestyleScore'] ?? 70,
          'hormonal_cycle': daily['cyclePhase'] ?? 'folliculaire',
          'profile': profile,
        })
      };

      final response = await _dio.post<Map<String, dynamic>>(
        '/predict',
        data: payload,
      );
      return PredictionResult.fromJson(response.data!);
    } catch (e) {
      throw Exception('Erreur de prédiction: $e');
    }
  }

  /// Convertit récursivement les Timestamps en String ISO pour le JSON
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

    final docs = snap.docs.toList();
    docs.sort((a, b) {
      DateTime dateA = a['predictedAt'] is Timestamp ? (a['predictedAt'] as Timestamp).toDate() : DateTime.tryParse(a['predictedAt'].toString()) ?? DateTime(2000);
      DateTime dateB = b['predictedAt'] is Timestamp ? (b['predictedAt'] as Timestamp).toDate() : DateTime.tryParse(b['predictedAt'].toString()) ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    return docs.map((d) => PredictionResult.fromJson(d.data() as Map<String, dynamic>)).toList();
  }
}
