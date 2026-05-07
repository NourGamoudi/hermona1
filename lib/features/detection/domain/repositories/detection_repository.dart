import 'package:image_picker/image_picker.dart';
import '../entities/detection_result.dart';

abstract class DetectionRepository {
  /// Envoie les images au backend Python et retourne le résultat de détection.
  Future<DetectionResult> analyzeImages(List<XFile> images);

  /// Récupère l'historique des détections de l'utilisateur depuis Firestore.
  Future<List<DetectionResult>> getHistory(String userId);

  /// Sauvegarde un résultat dans Firestore.
  Future<void> saveResult(DetectionResult result, String userId);
}
