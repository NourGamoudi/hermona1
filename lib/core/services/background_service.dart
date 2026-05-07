import 'dart:ui';

import 'package:workmanager/workmanager.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:dio/dio.dart';

import 'notification_service.dart';

import '../constants/app_constants.dart';

import '../../../firebase_options.dart';



// FirebaseAuth intentionally not imported:

// currentUser is unreliable in WorkManager isolates.

// UID is stored in SharedPreferences at login time.



@pragma('vm:entry-point')

void callbackDispatcher() {

  Workmanager().executeTask((task, inputData) async {

    try {

      // Required before any Flutter plugin in a background isolate

      DartPluginRegistrant.ensureInitialized();



      // 1. Init Firebase

      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);



      final db = FirebaseFirestore.instance;

      final prefs = await SharedPreferences.getInstance();



      // UID: SharedPreferences is primary cache. Firestore validates existence.

      final uid = prefs.getString('uid');

      if (uid == null) return true; // Not logged in



      // 2. Anti-spam: 1h minimum between backend checks

      final lastCheckEpoch = prefs.getInt('last_notif_check_epoch') ?? 0;

      final now = DateTime.now();

      if (now.millisecondsSinceEpoch - lastCheckEpoch < 3600000) return true;



      // 3. Collect data (Firestore also validates that the uid actually exists)

      final userDoc = await db.collection(AppConstants.colUsers).doc(uid).get();

      if (!userDoc.exists) {

        // UID in prefs is stale — clear it

        await prefs.remove('uid');

        return true;

      }



      // 3. Fetch only last prediction — backend fetches user profile itself

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



      // 4. Call backend — single source of intelligence

      // Flutter sends uid + latestPrediction only.

      // Backend fetches and owns the full user profile from Firestore.

      final notifService = NotificationService();

      final dio = Dio(BaseOptions(

        baseUrl: AppConstants.apiBaseUrl,

        connectTimeout: const Duration(seconds: 10),

        receiveTimeout: const Duration(seconds: 10),

      ));



      try {

        final response = await dio.post('/notifications/check', data: {

          'uid': uid,

          'latestPrediction': latestPred,

        });



        // Safety cast: backend may return HTML on error or middleware may wrap

        if (response.data is! Map<String, dynamic>) return true;

        final data = response.data as Map<String, dynamic>;

        final List notifications = data['notifications'] ?? [];

        for (final n in notifications) {

          await _processNotification(n, prefs, notifService);

        }

      } catch (e) {

        // Backend unreachable: minimal risk-only fallback (no cycle logic)

        await _runOfflineFallback(latestPred, prefs, notifService);

      }



      await prefs.setInt('last_notif_check_epoch', now.millisecondsSinceEpoch);

      return true;

    } catch (e) {

      print("âŒ Background Task Error: $e");

      return false;

    }

  });

}



Future<void> _processNotification(

  Map n,

  SharedPreferences prefs,

  NotificationService service,

) async {

  final notifId = n['id'] as String;

  final today = DateTime.now().toIso8601String().substring(0, 10);



  // Bounded key: one string entry per notifId — no key explosion over time

  // Stores only the last sent date, overwrites each day automatically.

  final lastSent = prefs.getString('notif_last_sent_$notifId') ?? '';



  if (lastSent != today) {

    await service.showNotification(

      id: notifId.hashCode,

      title: n['title'] as String,

      body: n['body'] as String,

      payload: notifId,

    );

    await prefs.setString('notif_last_sent_$notifId', today);

  }

}



/// Minimal offline fallback — UX only, no scoring logic.

/// Backend is the single source of intelligence for all clinical decisions.

Future<void> _runOfflineFallback(

  Map<String, dynamic>? latestPred,

  SharedPreferences prefs,

  NotificationService service,

) async {

  await _processNotification({

    "id":    "sync_required",

    "title": "🧴“¡ Synchronisation Requise",

    "body":  "Hermona n'a pas pu joindre le serveur. Reconnectez-vous pour recevoir vos alertes personnalisées.",

  }, prefs, service);

}



class BackgroundService {

  static Future<void> init() async {

    if (kIsWeb) return;

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

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







































