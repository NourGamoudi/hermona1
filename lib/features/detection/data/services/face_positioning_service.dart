import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum FaceValidationState {
  neutral, // No face or waiting
  warning, // Face present but needs adjustment
  ready    // Perfect for backend crops
}

class FaceValidationResult {
  final FaceValidationState state;
  final String message;
  final bool isReady;

  FaceValidationResult(this.state, this.message, this.isReady);
}

class FacePositioningService {
  late FaceDetector _faceDetector;

  FacePositioningService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true, // Crucial for forehead/chin precision
        enableClassification: false,
        performanceMode: FaceDetectorMode.fast, // Better for real-time preview
      ),
    );
  }

  Future<List<Face>> detectFaces(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  FaceValidationResult validateFace(Face? face, Size imageSize, {double brightness = 0.5, double variance = 0.02}) {
    if (face == null) {
      return FaceValidationResult(FaceValidationState.neutral, 'Placez votre visage au centre', false);
    }

    // PRIORITY 0: ADVANCED LIGHTING (Avg + Variance)
    if (brightness < 0.20) {
      return FaceValidationResult(FaceValidationState.warning, 'Améliorez l\'éclairage', false);
    }
    if (brightness > 0.85) {
      return FaceValidationResult(FaceValidationState.warning, 'Lumière trop vive', false);
    }
    if (variance > 0.08) {
      return FaceValidationResult(FaceValidationState.warning, 'Évitez les ombres marquées', false);
    }

    final rect = face.boundingBox;
    final x = rect.left;
    final y = rect.top;
    final w = rect.width;
    final h = rect.height;

    // PRIORITY 1: Distance (Targeting 0.68 face ratio)
    final faceRatio = w / imageSize.width;
    if (faceRatio > 0.78) return FaceValidationResult(FaceValidationState.warning, 'Éloignez-vous légèrement', false);
    if (faceRatio < 0.55) return FaceValidationResult(FaceValidationState.warning, 'Approchez-vous doucement', false);

    // PRIORITY 2: Centering (Targeting screen center & 0.44 vertical)
    final centerX = x + w / 2;
    final centerY = y + h / 2;
    final imgCenterX = imageSize.width / 2;
    final imgCenterY = imageSize.height * 0.44; // Matching our fixed silhouette

    if ((centerX - imgCenterX).abs() > imageSize.width * 0.08) {
      return FaceValidationResult(FaceValidationState.warning, 'Centrez votre visage', false);
    }
    if ((centerY - imgCenterY).abs() > imageSize.height * 0.08) {
      if (centerY < imgCenterY) return FaceValidationResult(FaceValidationState.warning, 'Baissez légèrement le visage', false);
      return FaceValidationResult(FaceValidationState.warning, 'Levez légèrement le visage', false);
    }

    // PRIORITY 3: Pose & Tilt
    final tilt = face.headEulerAngleY ?? 0;
    final roll = face.headEulerAngleZ ?? 0;
    if (tilt.abs() > 12 || roll.abs() > 10) {
      return FaceValidationResult(FaceValidationState.warning, 'Regardez bien l\'objectif', false);
    }

    // PRIORITY 4: Crop safety (Enhanced with landmarks if available)
    final frontTop = y - (h * 0.1);
    final chinBottom = y + (h * 1.15);
    
    if (frontTop < 0) {
      return FaceValidationResult(FaceValidationState.warning, 'Baissez légèrement le visage', false);
    }
    if (chinBottom > imageSize.height) {
      return FaceValidationResult(FaceValidationState.warning, 'Levez légèrement le visage', false);
    }

    return FaceValidationResult(FaceValidationState.ready, 'Parfait — gardez cette position', true);
  }

  void dispose() {
    _faceDetector.close();
  }
}
