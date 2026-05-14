import 'dart:ui';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:acneia/features/notification/data/services/notification_service.dart';
import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/firebase_options.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      DartPluginRegistrant.ensureInitialized();
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      final db = FirebaseFirestore.instance;
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      if (uid == null) return true;

      // 1. Anti-spam isolate-level: 1h minimum between backend checks
      final lastCheckEpoch = prefs.getInt('last_notif_check_epoch') ?? 0;
      final now = DateTime.now();
      if (now.millisecondsSinceEpoch - lastCheckEpoch < 3600000) return true;

      // 2. Fetch Latest Prediction from Firestore
      final predSnap = await db
          .collection(AppConstants.colPredictions)
          .where('userId', isEqualTo: uid)
          .orderBy('predictedAt', descending: true)
          .limit(1)
          .get();

      Map<String, dynamic>? latestPred;
      if (predSnap.docs.isNotEmpty) {
        latestPred = predSnap.docs.first.data();
      }

      // 3. Call Unified Backend Notification Check (SSOT)
      final notifService = NotificationService();
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        headers: {'X-API-Key': AppConstants.apiKey},
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      try {
        final response = await dio.post('/notifications/check', data: {
          'uid': uid,
          'latestPrediction': latestPred,
        });

        if (response.data is Map<String, dynamic>) {
          final List notifications = response.data['notifications'] ?? [];
          for (final n in notifications) {
            // [IDEMPOTENT] Use deterministic deduplication gateway
            // userId + predictionId + type ensures NO double-trigger with foreground
            await notifService.sendNotification(
              userId: uid,
              predictionId: n['predictionId'] as String?,
              title: n['title'] as String,
              body: n['body'] as String,
              type: n['type'] as String,
            );
          }
        }
      } catch (e) {
        debugPrint("⚠️ Backend unreachable in background, skipping smart check: $e");
      }

      await prefs.setInt('last_notif_check_epoch', now.millisecondsSinceEpoch);
      return true;
    } catch (e) {
      debugPrint("❌ Background Task Critical Error: $e");
      return false;
    }
  });
}

class BackgroundService {
  static Future<void> init() async {
    if (kIsWeb) return;
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> startPolling() async {
    if (kIsWeb) return;
    await Workmanager().registerPeriodicTask(
      "hermona_notif_task",
      "check_smart_notifications",
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
