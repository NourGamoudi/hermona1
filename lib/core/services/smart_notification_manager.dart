import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

import 'notification_service.dart';



class SmartNotificationManager {

  static final SmartNotificationManager _instance = SmartNotificationManager._internal();

  factory SmartNotificationManager() => _instance;

  SmartNotificationManager._internal();



  final _service = NotificationService();

  final _db = FirebaseFirestore.instance;

  final _auth = FirebaseAuth.instance;



  Future<void> checkAndNotify() async {

    try {

      final uid = _auth.currentUser?.uid;

      if (uid == null) return;



      // 1. Charger les données utilisateur

      final userDoc = await _db.collection('users').doc(uid).get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;



      // 2. Alert J-3 Phase Lutéale

      _checkLutealPhase(uid, userData);



      // 3. Alert Risk > 0.7

      await _checkHighRisk(uid);



      // 4. Rappels (Quotidien & Hebdomadaire intelligent)

      await _scheduleReminders(uid);

      

      // 5. Conseil du jour

      _showDailyTip(uid, userData);



    } catch (e) {

      debugPrint("âŒ Error in SmartNotificationManager: $e");

    }

  }



  void _checkLutealPhase(String uid, Map<String, dynamic> data) {

    if (data['lastPeriodsDate'] == null) return;

    

    DateTime lastDate;

    final ts = data['lastPeriodsDate'];

    if (ts is Timestamp) {
      lastDate = ts.toDate();
    } else {
      lastDate = DateTime.tryParse(ts.toString()) ?? DateTime.now();
    }



    final diff = DateTime.now().difference(lastDate).inDays;

    const cycleLen = 28; 

    final dayInCycle = (diff % cycleLen) + 1;



    // J-3 avant la phase lutéale (J-19 - 3 = J-16)

    if (dayInCycle == 16) {

      _showAndSave(

        uid: uid,

        id: 101,

        title: "🧴”” Alerte Phase Lutéale",

        body: "Risque hormonal dans 3 jours — préparez votre routine !",

        type: "CYCLE",

      );

    }

  }



  Future<void> _showAndSave({

    required String uid,

    required int id,

    required String title,

    required String body,

    required String type,

  }) async {

    // 1. Show Push

    _service.showNotification(id: id, title: title, body: body);



    // 2. Save to Firestore (History)

    if (uid.isNotEmpty) {

      await _db.collection(AppConstants.colNotifications).add({

        'userId': uid,

        'title': title,

        'body': body,

        'type': type,

        'timestamp': FieldValue.serverTimestamp(),

      });

    }

  }



  Future<void> _checkHighRisk(String uid) async {

    try {

      final predSnap = await _db.collection('predictions')

          .where('userId', isEqualTo: uid)

          .orderBy('predictedAt', descending: true)

          .limit(1)

          .get();



      if (predSnap.docs.isNotEmpty) {

        final pred = predSnap.docs.first.data();

        final risk = pred['riskScore'] ?? 0.0;

        if (risk >= 0.70) {

          await _showAndSave(

            uid: uid,

            id: 102,

            title: "âš ï¸ Risque Élevé Détecté",

            body: "Votre peau est à risque cette semaine. Appliquez la stratégie PROTECTION.",

            type: "RISK",

          );

        }

      }

    } catch (e) {

      if (e.toString().contains('requires an index')) {

        debugPrint("🧴—ï¸ Firestore Index Required: Go to the Firebase Console via the link in the logs to create the index for 'predictions' (userId: ASC, predictedAt: DESC).");

      } else {

        debugPrint("âŒ Error in _checkHighRisk: $e");

      }

    }

  }



  Future<void> _scheduleReminders(String uid) async {

    final now = DateTime.now();

    

    // 1. Rappel Quotidien (Toujours à 20h00 pour le bilan du jour)

    final dailyTime = DateTime(now.year, now.month, now.day, 20, 0);

    _service.scheduleNotification(

      id: 201,

      title: "🌍¸ Bilan Quotidien",

      body: "Comment va votre peau ce soir ? N'oubliez pas de remplir votre suivi.",

      scheduledDate: dailyTime.isBefore(now) ? dailyTime.add(const Duration(days: 1)) : dailyTime,

    );



    // 2. Rappel Hebdomadaire (7 jours après le dernier questionnaire)

    final weeklySnap = await _db.collection('weekly_surveys')

        .where('userId', isEqualTo: uid)

        .orderBy('weekNumber', descending: true) // On prend le dernier

        .limit(1)

        .get();



    if (weeklySnap.docs.isNotEmpty) {

      // On a déjà un questionnaire, on planifie +7 jours

      final lastData = weeklySnap.docs.first.data();

      // On suppose qu'on a un champ 'createdAt' ou 'date'

      final lastTs = lastData['date'] ?? lastData['timestamp'];

      DateTime lastDate;

      if (lastTs is Timestamp) {
        lastDate = lastTs.toDate();
      } else if (lastTs is String) {
        lastDate = DateTime.tryParse(lastTs) ?? now;
      } else {
        lastDate = now;
      }



      final nextWeekly = lastDate.add(const Duration(days: 7));

      if (nextWeekly.isAfter(now)) {

        _service.scheduleNotification(

          id: 202,

          title: "🧴“¸ Bilan Hebdomadaire",

          body: "C'est l'heure de votre analyse IA hebdomadaire ! Voyons l'évolution.",

          scheduledDate: nextWeekly,

        );

      }

    } else {

      // Pas encore de questionnaire hebdomadaire, on propose d'en faire un

      final nextWeekly = now.add(const Duration(days: 1)); // Demain si jamais

      _service.scheduleNotification(

        id: 202,

        title: "✨ Premier Bilan Hebdomadaire",

        body: "Commencez votre suivi d'évolution aujourd'hui !",

        scheduledDate: nextWeekly,

      );

    }



    // 3. Rappels de routine matin (8h00)

    final morningTime = DateTime(now.year, now.month, now.day, 8, 0);

    _service.scheduleNotification(

      id: 203,

      title: "â˜€ï¸ Routine du Matin",

      body: "Bonjour ! N'oubliez pas votre routine de soin pour protéger votre peau aujourd'hui.",

      scheduledDate: morningTime.isBefore(now) ? morningTime.add(const Duration(days: 1)) : morningTime,

      isDaily: true,

    );



    // 4. Rappels de routine soir (21h00)

    final eveningTime = DateTime(now.year, now.month, now.day, 21, 0);

    _service.scheduleNotification(

      id: 204,

      title: "🌙 Routine du Soir",

      body: "Bonsoir ! Prenez soin de votre peau avant de vous coucher.",

      scheduledDate: eveningTime.isBefore(now) ? eveningTime.add(const Duration(days: 1)) : eveningTime,

      isDaily: true,

    );

  }



  void _showDailyTip(String uid, Map<String, dynamic> data) {

    if (data['lastPeriodsDate'] == null) return;

    

    DateTime lastDate;

    final ts = data['lastPeriodsDate'];

    if (ts is Timestamp) {
      lastDate = ts.toDate();
    } else {
      lastDate = DateTime.tryParse(ts.toString()) ?? DateTime.now();
    }



    final diff = DateTime.now().difference(lastDate).inDays;

    final dayInCycle = (diff % 28) + 1;



    String tip = "Buvez de l'eau pour une peau éclatante !";

    if (dayInCycle >= 1 && dayInCycle <= 5) {

      tip = "Phase Menstruelle : Hydratez intensément, la barrière cutanée est plus fragile.";

    } else if (dayInCycle >= 6 && dayInCycle <= 13) {

      tip = "Phase Folliculaire : C'est le moment idéal pour exfolier en douceur.";

    } else if (dayInCycle >= 14 && dayInCycle <= 16) {

      tip = "Phase Ovulatoire : Le sébum augmente, privilégiez un nettoyage double.";

    } else if (dayInCycle >= 17) {

      tip = "Phase Lutéale : Évitez les sucres pour limiter les poussées inflammatoires.";

    }



    _showAndSave(

      uid: uid,

      id: 301,

      title: "🧴’¡ Conseil du Jour",

      body: tip,

      type: "INFO",

    );

  }



  Future<void> sendTestNotification() async {

    final uid = _auth.currentUser?.uid;

    if (uid == null) return;



    await _showAndSave(

      uid: uid,

      id: 999,

      title: "🧴š€ Test de Notification",

      body: "Bravo ! Le système de notifications Hermona fonctionne parfaitement. ✨",

      type: "INFO",

    );

  }



  /// Sends a notification to another user by writing to their Firestore notifications collection.

  /// Note: This won't trigger a push notification unless we use FCM, 

  /// but it will appear in their Notification Center.

  Future<void> notifyRemoteUser({

    required String targetUid,

    required String title,

    required String body,

    required String type,

    Map<String, dynamic>? metadata,

  }) async {

    try {

      if (targetUid.isEmpty) return;

      await _db.collection(AppConstants.colNotifications).add({

        'userId': targetUid,

        'title': title,

        'body': body,

        'type': type,

        'metadata': metadata,

        'timestamp': FieldValue.serverTimestamp(),

        'isRead': false,

      });

    } catch (e) {

      debugPrint("âš ï¸ Could not send remote notification: $e");

    }

  }

}







































