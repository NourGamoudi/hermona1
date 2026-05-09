import 'package:acneia/features/prediction/domain/entities/prediction_result.dart';

abstract class PredictionRepository {
  Future<PredictionResult> predict(Map<String, dynamic> answers);
  Future<void> saveResult(PredictionResult result, String userId);
  Future<List<PredictionResult>> getHistory(String userId);
}
