import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:acneia/core/router/app_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload == null) return;
        
        if (payload == 'SURVEY_DAILY') {
          appRouter.push('/daily-survey');
        } else if (payload == 'SURVEY_WEEKLY') {
          appRouter.push('/weekly-survey');
        } else {
          appRouter.push('/notifications');
        }
      },
    );
    debugPrint('✅ NotificationService Initialisé');
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'hermona_channel',
      'Hermona Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(
      android: androidDetails, 
      iOS: DarwinNotificationDetails()
    );

    await _plugin.show(id, title, body, platformDetails, payload: payload);
  }

  /// [PFE DESIGN: IDEMPOTENT ATOMIC GATEWAY]
  /// Single entry point for all notifications (Foreground & Background).
  /// notificationId = uid + "_" + (predictionId or date) + "_" + type
  Future<void> sendNotification({
    required String title,
    required String body,
    required String type,
    String? predictionId,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final scope = predictionId ?? today;
    final notificationId = "${uid}_${scope}_$type";
    
    debugPrint('🔔 [GATEWAY] Tentative d\'envoi : type=$type, scope=$scope');
    
    final docRef = FirebaseFirestore.instance.collection('notifications').doc(notificationId);

    try {
      // ATOMIC CHECK & WRITE
      // We use a transaction to ensure that the "isNew" decision is distributed-safe.
      final bool isNew = await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) return false;

        transaction.set(docRef, {
          'id': notificationId,
          'userId': uid,
          'predictionId': predictionId,
          'type': type,
          'title': title,
          'body': body,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'metadata': metadata ?? {},
        });
        return true;
      });

      if (isNew) {
        // Only trigger local alert if the document was successfully created now
        await showLocalNotification(
          id: notificationId.hashCode,
          title: title,
          body: body,
          payload: type,
        );
        debugPrint('🚀 [GATEWAY] Notification envoyée : $notificationId');
      } else {
        debugPrint('🛡️ [GATEWAY] Doublon détecté et bloqué : $notificationId');
      }
    } catch (e) {
      debugPrint('❌ [GATEWAY] Erreur lors du traitement : $e');
    }
  }

  /// Legacy compatibility for existing calls
  Future<void> sendAtomicAlert({
    required String title,
    required String body,
    required String type,
    String? predictionId,
    String? userId,
    Map<String, dynamic>? metadata,
  }) => sendNotification(
    title: title,
    body: body,
    type: type,
    predictionId: predictionId,
    userId: userId,
    metadata: metadata,
  );

  Future<void> scheduleDailyReminder() async {
    try {
      // Rappel du soir (20:00)
      await _plugin.zonedSchedule(
        100,
        'Bilan Quotidien',
        'N\'oubliez pas de remplir votre bilan pour suivre votre peau !',
        _nextInstanceOfTime(20, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails('daily_reminder', 'Daily Reminders'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'SURVEY_DAILY',
      );

      // Rappel du matin (10:00)
      await _plugin.zonedSchedule(
        101,
        'Bilan Quotidien',
        'C\'est l\'heure de votre suivi quotidien pour une belle peau !',
        _nextInstanceOfTime(10, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails('daily_reminder', 'Daily Reminders'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'SURVEY_DAILY',
      );
    } catch (e) { debugPrint('Error scheduling daily reminder: $e'); }
  }

  Future<void> scheduleWeeklyReminder() async {
    try {
      await _plugin.zonedSchedule(
        200,
        'Bilan Hebdomadaire',
        'Il est temps de faire votre analyse photo hebdomadaire !',
        _nextInstanceOfDayAndTime(DateTime.sunday, 10, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails('weekly_reminder', 'Weekly Reminders'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'SURVEY_WEEKLY',
      );
    } catch (e) { debugPrint('Error scheduling weekly reminder: $e'); }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// [DEPRECATED] No longer needed as dispatch is handled by the gateway
  void listenToNotifications() {}

  /// [DEPRECATED] Handled by gateway idempotency
  Future<bool> hasAlertToday(String uid, String type) async => false;
}
