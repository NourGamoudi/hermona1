import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:acneia/features/detection/data/services/face_positioning_service.dart';

class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _controller;
  final _positioningService = FacePositioningService();
  
  FaceValidationResult _validation = FaceValidationResult(FaceValidationState.neutral, 'Placez votre visage au centre', false);
  
  bool _isBusy = false;
  bool _isCapturing = false;
  
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _isCountingDown = false;
  int _stableFrames = 0;
  static const int requiredStableFrames = 15; // Require 15 consecutive good frames

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    
    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    _controller!.startImageStream(_processCameraImage);
    if (mounted) setState(() {});
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy || _isCapturing || _controller == null) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _positioningService.detectFaces(inputImage);
      
      // 1. PICK LARGEST FACE (Robustness)
      final mainFace = faces.isNotEmpty
          ? faces.reduce((a, b) => 
              (a.boundingBox.width * a.boundingBox.height) > (b.boundingBox.width * b.boundingBox.height) ? a : b)
          : null;

      // 2. ADVANCED BRIGHTNESS (Average + Variance)
      final stats = _calculateLuminanceStats(image);
      
      final previewSize = _controller!.value.previewSize!;
      // Note: previewSize is usually (height, width) for portrait sensors
      final effectiveSize = Size(previewSize.height, previewSize.width);
      
      final result = _positioningService.validateFace(
        mainFace, 
        effectiveSize, 
        brightness: stats.average,
        variance: stats.variance,
      );
      
      _updateValidation(result, mainFace);
    } finally {
      _isBusy = false;
    }
  }

  ({double average, double variance}) _calculateLuminanceStats(CameraImage image) {
    final Uint8List bytes = image.planes[0].bytes;
    int total = 0;
    int squareTotal = 0;
    int count = 0;

    // Sample pixels for performance
    for (int i = 0; i < bytes.length; i += 200) {
      final val = bytes[i];
      total += val;
      squareTotal += val * val;
      count++;
    }

    final avg = total / count;
    final avgSq = squareTotal / count;
    final varVal = avgSq - (avg * avg);

    return (average: avg / 255.0, variance: varVal / (255 * 255));
  }

  void _updateValidation(FaceValidationResult result, Face? face) {
    if (!mounted) return;
    setState(() {
      _validation = result;
      
      if (result.isReady) {
        _stableFrames++;
        if (_stableFrames >= requiredStableFrames && !_isCountingDown) {
          _startCountdown();
        }
      } else {
        _stableFrames = 0;
        _stopCountdown();
      }
    });
  }

  void _startCountdown() {
    _isCountingDown = true;
    _countdown = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          timer.cancel();
          _captureImage();
        }
      });
    });
  }

  void _stopCountdown() {
    _isCountingDown = false;
    _countdownTimer?.cancel();
    _countdown = 3;
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final sensorOrientation = _controller!.description.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationValue = 0;
      if (sensorOrientation == 90) rotationValue = 90;
      if (sensorOrientation == 180) rotationValue = 180;
      if (sensorOrientation == 270) rotationValue = 270;
      rotation = InputImageRotationValue.fromRawValue(rotationValue);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;
    _isCapturing = true;
    
    try {
      final xFile = await _controller!.takePicture();
      if (mounted) Navigator.pop(context, xFile.path);
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      _isCapturing = false;
    }
  }

  @override
  void dispose() {
    _stopCountdown();
    _controller?.dispose();
    _positioningService.dispose();
    super.dispose();
  }

  Color _getStateColor() {
    switch (_validation.state) {
      case FaceValidationState.neutral: return Colors.white.withValues(alpha: 0.9);
      case FaceValidationState.warning: return const Color(0xFFEAB308); // Gold 500
      case FaceValidationState.ready: return const Color(0xFF10B981); // Emerald 500
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    final stateColor = _getStateColor();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          
          _FaceSilhouetteOverlay(
            color: stateColor, 
            isReady: _validation.isReady,
          ),

          // Message Banner
          Positioned(
            top: 80, left: 30, right: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: stateColor.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _validation.message, 
                        textAlign: TextAlign.center, 
                        style: TextStyle(
                          color: stateColor, 
                          fontWeight: FontWeight.w600, 
                          fontSize: 15, 
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (_isCountingDown) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Capture dans ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('$_countdown...', style: TextStyle(color: stateColor, fontWeight: FontWeight.w900, fontSize: 20)),
                          ],
                        ).animate().fadeIn().scale(),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ).animate(key: ValueKey(_validation.message)).fadeIn(duration: 400.ms).slideY(begin: -0.05),

          // Action Button
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Center(
              child: Container(
                width: 80, height: 80,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: stateColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _validation.isReady ? stateColor : Colors.white10,
                    boxShadow: [
                      if (_validation.isReady)
                        BoxShadow(color: stateColor.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2),
                    ],
                  ),
                  child: Icon(
                    _validation.isReady ? Iconsax.tick_circle : Iconsax.camera,
                    color: _validation.isReady ? Colors.white : Colors.white24,
                    size: 30,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1200.ms, curve: Curves.easeInOut),
            ),
          ),

          Positioned(
            top: 40, left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 26),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceSilhouetteOverlay extends StatelessWidget {
  final Color color;
  final bool isReady;

  const _FaceSilhouetteOverlay({
    required this.color, 
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AnatomicalPainter(color: color, isReady: isReady),
    );
  }
}

class _AnatomicalPainter extends CustomPainter {
  final Color color;
  final bool isReady;

  _AnatomicalPainter({required this.color, required this.isReady});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Softer Neutral Overlay
    final bgPaint = Paint()..color = const Color(0xFF1A1A1A).withValues(alpha: 0.2);
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 2. FIXED ANATOMICAL TARGET (Dermatology Standard)
    final targetRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.44),
      width: size.width * 0.68,
      height: size.height * 0.52,
    );

    final silhouettePath = _getFaceSilhouettePath(targetRect);
    
    // 3. Punch out effect
    final combined = Path.combine(PathOperation.difference, path, silhouettePath);
    canvas.drawPath(combined, bgPaint);

    // 4. Glowing Silhouette border
    final glowPaint = Paint()
      ..color = color.withValues(alpha: isReady ? 0.8 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, isReady ? 12 : 4);
    
    canvas.drawPath(silhouettePath, glowPaint);
    
    // 5. Subtle Nose & Center Calibration (Fixed)
    final calibrationPaint = Paint()..color = color.withValues(alpha: 0.2)..strokeWidth = 1.0;
    final center = targetRect.center;
    canvas.drawLine(Offset(center.dx - 10, center.dy), Offset(center.dx + 10, center.dy), calibrationPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 10), Offset(center.dx, center.dy + 10), calibrationPaint);
  }

  Path _getFaceSilhouettePath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;
    final top = rect.top;
    final bottom = rect.bottom;
    final cx = rect.center.dx;
    final left = rect.left;
    final right = rect.right;

    path.moveTo(cx, top);
    path.quadraticBezierTo(right, top, right, top + h * 0.35);
    path.cubicTo(right, top + h * 0.7, cx + w * 0.35, bottom, cx, bottom);
    path.cubicTo(cx - w * 0.35, bottom, left, top + h * 0.7, left, top + h * 0.35);
    path.quadraticBezierTo(left, top, cx, top);
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
