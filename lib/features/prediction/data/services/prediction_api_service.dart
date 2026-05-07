import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/prediction_result.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../../../../core/constants/app_constants.dart';

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

      // 2. Fetch Latest Daily Survey for hygiene context
      final dailySnap = await _db.collection('daily_surveys')
          .where('userId', isEqualTo: uid)
          .get();
      
      final List<QueryDocumentSnapshot> dailyDocs = dailySnap.docs.toList();
      dailyDocs.sort((a, b) {
        final ta = a.data() as Map<String, dynamic>;
        final tb = b.data() as Map<String, dynamic>;
        final da = ta['date'] ?? '';
        final db = tb['date'] ?? '';
        return db.compareTo(da);
      });
      
      Map<String, dynamic> daily = {};
      if (dailyDocs.isNotEmpty) {
        daily = dailyDocs.first.data() as Map<String, dynamic>;
      }

      // 3. Calculate Hygiene Score
      int hygieneScore = 70;
      if (daily.isNotEmpty) {
         hygieneScore = 100;
         if ((daily['sleep_hours'] ?? 8) < 7) hygieneScore -= 15;
         if ((daily['water_glasses'] ?? 8) < 6) hygieneScore -= 10;
         if ((daily['stress_level'] ?? 5) > 7) hygieneScore -= 20;
         final List diet = daily['diet_tags'] ?? [];
         if (diet.contains('sucre') || diet.contains('produits_laitiers')) hygieneScore -= 15;
         if (hygieneScore < 0) hygieneScore = 0;
      }

      // 4. Prepare Payload
      final payload = {
        'answers': _sanitizeMap({
          ...answers,
          'hygieneScore': hygieneScore,
          'hormonal_cycle': daily['cyclePhase'] ?? 'folliculaire',
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
      print('DEBUG ERROR in predict: $e');
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
