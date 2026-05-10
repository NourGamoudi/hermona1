import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dio/dio.dart';



import 'package:flutter/foundation.dart';
import 'package:acneia/features/detection/domain/entities/detection_result.dart';
import 'package:acneia/features/detection/domain/repositories/detection_repository.dart';
import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/core/errors/app_exception.dart';



class DetectionApiService implements DetectionRepository {



  // Configuration de Dio

  final Dio _dio;

  

  DetectionApiService()
      : _dio = Dio(BaseOptions(
          baseUrl        : AppConstants.apiBaseUrl,
          headers        : {'X-API-Key': AppConstants.apiKey},
          connectTimeout : const Duration(seconds: 60),
          receiveTimeout : const Duration(seconds: 60),
        ));



  final FirebaseFirestore _db = FirebaseFirestore.instance;



  @override

  Future<DetectionResult> analyzeImages(List<File> images) async {

    try {

      final formData = FormData();

      for (int i = 0; i < images.length; i++) {

        formData.files.add(MapEntry(

          'files', // Doit correspondre à `files: List[UploadFile]` dans FastAPI

          await MultipartFile.fromFile(

            images[i].path,

            filename: 'image_$i.jpg',

            contentType: DioMediaType('image', 'jpeg'),

          ),

        ));

      }



      debugPrint('DEBUG: Calling Detection API at: ${AppConstants.apiBaseUrl}/detect');
      final response = await _dio.post<Map<String, dynamic>>(
        '/detect',
        data: formData,
      ).timeout(const Duration(seconds: 90));



      return DetectionResult.fromJson(response.data!);



    } on DioException catch (e) {

      final errorDetail = e.response?.data;

      final msg = e.response != null 

          ? 'Erreur Serveur (${e.response?.statusCode}): $errorDetail'

          : 'Erreur Réseau: ${e.message}';

      throw ApiException(

        msg,

        statusCode: e.response?.statusCode,

      );

    } catch (e) {

      throw ApiException('Erreur inattendue: $e');

    }

  }



  // ——————————————————————————————————————————————————————————————————————————————

  @override
  Future<List<DetectionResult>> getHistory(String userId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colDetections)
          .where('userId', isEqualTo: userId)
          .orderBy('analyzedAt', descending: true)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 5));

      final List<QueryDocumentSnapshot> docs = snap.docs.toList();
      docs.sort((a, b) {
        final ta = a.data() as Map<String, dynamic>;
        final tb = b.data() as Map<String, dynamic>;
        final da = ta['analyzedAt'] is Timestamp ? (ta['analyzedAt'] as Timestamp).toDate() : DateTime.tryParse(ta['analyzedAt'].toString()) ?? DateTime(2000);
        final db = tb['analyzedAt'] is Timestamp ? (tb['analyzedAt'] as Timestamp).toDate() : DateTime.tryParse(tb['analyzedAt'].toString()) ?? DateTime(2000);
        return db.compareTo(da);
      });

      return docs
          .map((d) => DetectionResult.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching detection history: $e');
      return [];
    }
  }



  // ——————————————————————————————————————————————————————————————————————————————

  @override
  Future<void> saveResult(DetectionResult result, String userId) async {
    // We store everything in a single document to comply with the user's Firestore rules
    // (which only allow writes to /detections/{id} and not sub-collections).
    final metadata = {
      'id': result.id,
      'severityScore': result.severityScore,
      'severityLevel': result.severityLevel.name,
      'classifications': result.classifications.map((c) => c.toJson()).toList(),
      'analyzedAt': result.analyzedAt.toIso8601String(),
      'imageUrls': result.imageUrls,
      'hasImages': result.imageUrls.isNotEmpty,
      'zoneCounts': result.zoneCounts,
      'zoneRisks': result.zoneRisks,
      'userId': userId,
    };

    await _db.collection(AppConstants.colDetections).doc(result.id).set(metadata);
  }

}



