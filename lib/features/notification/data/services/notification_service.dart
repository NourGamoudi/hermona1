import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:acneia/core/router/app_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final _uuid = const Uuid();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // Demander la permission sur Android 13+
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

        debugPrint('🔔 Système Notification cliquée: $payload');
        
        // Redirection intelligente selon le type de notification
        if (payload == 'SURVEY_DAILY') {
          appRouter.push('/daily-survey');
        } else if (payload == 'SURVEY_WEEKLY') {
          appRouter.push('/weekly-survey');
        } else if (payload == 'MESSAGE') {
          appRouter.push('/notifications'); // Ou vers /messages s'il y a un ID
        } else if (payload == 'CYCLE') {
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
      channelDescription: 'Notifications for messages and reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(id, title, body, platformDetails, payload: payload);
  }

  /// Send a local notification AND save it to Firestore Alert center
  Future<void> sendAlert({
    required String title,
    required String body,
    required String type, // e.g., 'CYCLE', 'SURVEY', 'RISK'
    Map<String, dynamic>? metadata,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final notifId = _uuid.v4();
    
    try {
      // 1. Save to Firestore (so it appears in the Alerts list)
      debugPrint('⏳ Tentative d\'écriture Firestore pour l\'alerte: $type');
      await FirebaseFirestore.instance.collection('notifications').doc(notifId).set({
        'id': notifId,
        'userId': uid,
        'type': type,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'metadata': metadata ?? {},
      });
      debugPrint('✅ Alerte enregistrée dans Firestore: $notifId');

      // 2. Show Local Notification
      await showLocalNotification(
        id: notifId.hashCode,
        title: title,
        body: body,
        payload: type,
      );
      debugPrint('🚀 Notification locale déclenchée !');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi de l\'alerte ($type): $e');
    }
  }

  /// Schedule a daily reminder (e.g. at 20:00) for the daily survey
  Future<void> scheduleDailyReminder() async {
    try {
      await _plugin.zonedSchedule(
        100, // ID for daily reminder
        'Bilan Quotidien',
        'N\'oubliez pas de remplir votre bilan pour suivre votre peau !',
        _nextInstanceOfTime(20, 0), // 8 PM
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder', 
            'Daily Reminders', 
            importance: Importance.max, 
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact, // Plus stable
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  /// Schedule a weekly reminder (e.g. Sunday at 10:00)
  Future<void> scheduleWeeklyReminder() async {
    try {
      await _plugin.zonedSchedule(
        200, // ID for weekly reminder
        'Bilan Hebdomadaire',
        'Il est temps de faire votre analyse photo hebdomadaire !',
        _nextInstanceOfDayAndTime(DateTime.sunday, 10, 0), // Sunday 10 AM
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_reminder', 
            'Weekly Reminders', 
            importance: Importance.max, 
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact, // Plus stable
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Error scheduling weekly reminder: $e');
    }
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

  /// Check if an alert of a certain type was already sent today
  Future<bool> _hasAlertToday(String uid, String type) async {
    try {
      // On récupère la toute dernière notification de ce type pour cet utilisateur
      // Cette requête correspond exactement à ton INDEX N°2
      final snap = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('type', isEqualTo: type)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
          
      if (snap.docs.isEmpty) return false;

      // On vérifie en Dart si elle date d'aujourd'hui
      final lastNotif = snap.docs.first.data();
      final ts = lastNotif['timestamp'] as Timestamp?;
      if (ts == null) return false;

      final lastDate = ts.toDate();
      final now = DateTime.now();
      return lastDate.year == now.year && lastDate.month == now.month && lastDate.day == now.day;
    } catch (e) {
      debugPrint('❌ Erreur _hasAlertToday ($type): $e');
      return true; 
    }
  }

  /// Automatically sync and send missing alerts (Daily, Weekly, Phase)
  Future<void> syncAutomaticAlerts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('ℹ️ Sync Alertes: Utilisateur non connecté.');
      return;
    }

    debugPrint('🔄 Synchronisation des alertes automatiques (FORCÉE)...');

    try {
      // 1. Check Daily Survey Reminder - FORCÉ POUR TEST
      debugPrint('🔔 Envoi alerte Quotidienne automatique...');
      await sendAlert(
        title: 'Bilan Quotidien',
        body: 'N\'oubliez pas de remplir votre bilan de peau ce soir ! ✨',
        type: 'SURVEY_DAILY',
      );

      // 2. Check Weekly Reminder (Only on Sundays)
      if (DateTime.now().weekday == DateTime.sunday) {
        debugPrint('🔔 Envoi alerte Hebdomadaire automatique...');
        await sendAlert(
          title: 'Analyse Hebdomadaire',
          body: 'C\'est le moment de prendre vos photos pour l\'analyse IA ! 📸',
          type: 'SURVEY_WEEKLY',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur générale syncAutomaticAlerts: $e');
    }
  }

  /// Listen to Firestore notifications and show local alerts
  void listenToNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final ts = data['timestamp'] as Timestamp?;
          if (ts != null && DateTime.now().difference(ts.toDate()).inSeconds < 15) {
            showLocalNotification(
              id: change.doc.id.hashCode,
              title: data['title'] ?? 'Hermona',
              body: data['body'] ?? '',
              payload: data['type'],
            );
          }
        }
      }
    });
  }
}
