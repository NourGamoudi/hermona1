import '../entities/recommendation_result.dart';

import 'package:acneia/features/detection/domain/entities/detection_result.dart';

abstract class RecommendationRepository {

  Future<RecommendationResult> getRecommendations({

    required DetectionResult detection,

    required String userId,

  });



  Future<void> saveResult(RecommendationResult result, String userId);

  Future<RecommendationResult?> getForDetection(String detectionId);

}



