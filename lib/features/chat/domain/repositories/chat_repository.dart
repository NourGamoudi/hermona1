import 'package:dio/dio.dart';
import '../entities/chat_message.dart';
import 'package:acneia/features/questionnaire/domain/entities/user_profile.dart';
import 'package:acneia/features/prediction/domain/entities/prediction_result.dart';
import 'package:acneia/features/questionnaire/data/services/cycle_api_service.dart';

abstract class ChatRepository {
  /// Envoie l'historique + le message de l'utilisateur au backend et retourne
  /// la réponse de l'assistante IA.
  Future<String> getChatResponse({
    required String userMessage,
    List<ChatMessage> history = const [],
    UserProfile? profile,
    PredictionResult? prediction,
    CancelToken? cancelToken,
    String? lang,
    CycleStatus? cycleStatus,
  });

  Future<List<ChatMessage>> loadHistory(String userId);
  Future<void> saveMessage(ChatMessage msg, String userId);
  Future<void> clearHistory(String userId);
  Future<String> transcribeAudio(String path, {String? lang});
}
