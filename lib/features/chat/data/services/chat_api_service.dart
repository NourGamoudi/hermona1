import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';

import 'package:acneia/features/chat/domain/entities/chat_message.dart';
import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/features/questionnaire/domain/entities/user_profile.dart';
import 'package:acneia/features/prediction/domain/entities/prediction_result.dart';
import 'package:acneia/features/chat/domain/repositories/chat_repository.dart';

// import removed



class ChatApiService implements ChatRepository {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Dio _dio = Dio(BaseOptions(

    baseUrl: AppConstants.apiBaseUrl,
    headers: {'X-API-Key': AppConstants.apiKey},
    connectTimeout: const Duration(seconds: 30),

    receiveTimeout: const Duration(seconds: 60),

  ));



  @override

  Future<String> getChatResponse({
    required String userMessage,
    List<ChatMessage> history = const [],
    UserProfile? profile,
    PredictionResult? prediction,
    CancelToken? cancelToken,
  }) async {

    try {

      // Préparer le payload attendu par le backend FastAPI

      final payload = {
        "message": userMessage,
        "profile": {
          "age": profile?.age ?? 25,
          "pcos": profile?.sopk == true ? 1 : 0,
          "type_peau": profile?.skinType ?? "mixte",
          "imc": profile?.imc ?? 22.0,
        },
        "daily": {
          "stress": (prediction?.shapFactors['Stress'] ?? 0.5) * 10,
          "sommeil": (prediction?.shapFactors['Sommeil'] ?? 0.7) * 10,
          "hydratation_verres": 6, 
        },
        "hormonal": {
          "jour_cycle": prediction?.cycleDay ?? 14,
          "phase": prediction?.cyclePhase ?? "folliculaire",
        },
        "history": history
            .takeLast(6)
            .map((m) => {
                  "role": m.role,
                  "content": m.content,
                })
            .toList(),
      };



      

      final response = await _dio.post(

        '/chat', 

        data: payload,

        cancelToken: cancelToken,

      );

      return response.data['response'] ?? "Désolée, je n'ai pas pu répondre.";

    } catch (e) {

      if (e is DioException && e.type == DioExceptionType.cancel) {

        throw Exception("Annulé par l'utilisateur");

      }

      throw Exception('Erreur de connexion au serveur : $e');

    }

  }



  @override

  Future<List<ChatMessage>> loadHistory(String userId) async {

    try {

      final snap = await _db

          .collection(AppConstants.colChatHistory)

          .where('userId', isEqualTo: userId)

          .orderBy('timestamp')

          .limit(60)

          .get();

      return snap.docs.map((d) => ChatMessage.fromJson(d.data())).toList();

    } catch (e) {

      debugPrint('Chat history load failed: $e');

      return [];

    }

  }



  @override

  Future<void> saveMessage(ChatMessage msg, String userId) async {

    try {

      await _db

          .collection(AppConstants.colChatHistory)

          .doc(msg.id)

          .set({...msg.toJson(), 'userId': userId});

    } catch (e) {

      debugPrint('Chat message save failed: $e');

    }

  }



  @override

  Future<void> clearHistory(String userId) async {

    try {

      final snap = await _db

          .collection(AppConstants.colChatHistory)

          .where('userId', isEqualTo: userId)

          .get();

      final batch = _db.batch();

      for (final doc in snap.docs) {

        batch.delete(doc.reference);

      }

      await batch.commit();

    } catch (e) {

      debugPrint('Chat clear history failed: $e');

    }

  }



  @override

  Future<String> transcribeAudio(String path) async {

    try {

      final formData = FormData.fromMap({

        'file': await MultipartFile.fromFile(path, filename: 'audio.m4a'),

      });

      

      

      final response = await _dio.post('/transcribe', data: formData);

      return response.data['text'] ?? '';

    } catch (e) {

      throw Exception('Erreur de transcription : $e');

    }

  }

}



extension ListExtensions<T> on List<T> {

  List<T> takeLast(int n) {

    if (length <= n) return this;

    return sublist(length - n);

  }

}

