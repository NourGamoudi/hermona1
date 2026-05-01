import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/prediction_result.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../../../../core/constants/app_constants.dart';
// import '../../../../core/errors/app_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA – Implémentation du PredictionRepository
//
// ✅ MOCK ACTIF  – calcul local basé sur les réponses
// 🔌 API RÉELLE  – commentée, endpoint : POST /predict
//
// Pour passer à l'API réelle :
//   1. Décommentez les imports Dio et ApiException
//   2. Décommentez le bloc [API RÉELLE] dans predict()
//   3. Supprimez le bloc [MOCK – À SUPPRIMER]
// ─────────────────────────────────────────────────────────────────────────────
class PredictionApiService implements PredictionRepository {

  final Dio _dio;
  PredictionApiService()
      : _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<PredictionResult> predict(Map<String, dynamic> answers) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Non connecté');

      // 1. Fetch Latest Context
      final profileSnap = await _db.collection('users').doc(uid).get();
      final dailySnap = await _db.collection('daily_surveys')
          .where('userId', isEqualTo: uid)
          .orderBy('date', descending: true)
          .limit(1).get();

      final profile = profileSnap.data() ?? {};
      final daily = dailySnap.docs.isNotEmpty ? dailySnap.docs.first.data() : {};

      // 2. Prepare Payload
      final payload = {
        'answers': {
          ...answers,
          'hygieneScore': daily['lifestyleScore'] ?? 70,
          'hormonal_cycle': daily['cyclePhase'] ?? 'folliculaire',
          'profile': profile,
        }
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

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<void> saveResult(PredictionResult result, String userId) async {
    await _db
        .collection(AppConstants.colPredictions)
        .doc(result.id)
        .set({...result.toJson(), 'userId': userId});
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<List<PredictionResult>> getHistory(String userId) async {
    final snap = await _db
        .collection(AppConstants.colPredictions)
        .where('userId', isEqualTo: userId)
        .orderBy('predictedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => PredictionResult.fromJson(d.data()))
        .toList();
  }
}
