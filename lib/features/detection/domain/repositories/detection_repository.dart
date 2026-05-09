import 'dart:io';
import '../entities/detection_result.dart';

abstract class DetectionRepository {
  Future<DetectionResult> analyzeImages(List<File> images);
  Future<List<DetectionResult>> getHistory(String userId);
  Future<void> saveResult(DetectionResult result, String userId);
}
