import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:acneia/features/notification/data/services/notification_service.dart';
import 'package:acneia/features/prediction/domain/entities/prediction_result.dart';

class SmartNotificationManager {
  static final SmartNotificationManager _instance = SmartNotificationManager._internal();
  factory SmartNotificationManager() => _instance;
  SmartNotificationManager._internal();

  final _service = NotificationService();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> checkAndNotify({PredictionResult? latestPrediction}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // 1. Charger les données utilisateur
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return;
      final userData = userDoc.data()!;

      // 2. Charger le dernier questionnaire quotidien
      final today = DateTime.now().toIso8601String().split('T')[0];
      final dailySnap = await _db.collection('daily_surveys')
          .where('userId', isEqualTo: uid)
          .where('date', isEqualTo: today)
          .limit(1)
          .get();
      
      final Map<String, dynamic> dailyData = dailySnap.docs.isNotEmpty 
          ? dailySnap.docs.first.data() 
          : {};

      // --- SYSTEME DE NOTIFICATIONS UNIFIÉ ---

      // A. ALERTE CLINIQUE ML (Source unique : riskJ3)
      // Une seule évaluation par prédiction pour éviter les doublons.
      await _checkMLRisk(uid, latestPrediction: latestPrediction);

      // B. CONSEILS ÉDUCATIFS (Heuristiques isolées)
      _checkLutealPhase(uid, userData);
      _showDailyTip(uid, userData, dailyData);

      // C. RAPPELS DE ROUTINE & BILANS
      await _scheduleReminders(uid);
      await _checkHydration(uid, dailyData);

    } catch (e) {
      debugPrint("❌ Error in SmartNotificationManager: $e");
    }
  }

  /// Single clinical trigger based on LightGBM prediction
  Future<void> _checkMLRisk(String uid, {PredictionResult? latestPrediction}) async {
    try {
      double riskJ3 = 0.0;
      String predictionId = "";

      if (latestPrediction != null) {
        riskJ3 = latestPrediction.riskJ3;
        predictionId = latestPrediction.id;
        debugPrint("⚡ [SMART NOTIF] Utilisation du résultat direct : $riskJ3");
      } else {
        final predSnap = await _db.collection('predictions')
            .where('userId', isEqualTo: uid)
            .orderBy('predictedAt', descending: true)
            .limit(1)
            .get();

        if (predSnap.docs.isNotEmpty) {
          final predDoc = predSnap.docs.first;
          final pred = predDoc.data();
          riskJ3 = ((pred['riskJ3'] ?? 0.0) as num).toDouble();
          predictionId = predDoc.id;
        }
      }

      if (predictionId.isNotEmpty) {

        // Seuil clinique unifié : 60%
        debugPrint("🔍 [SMART NOTIF] Evaluation risque pour $uid: riskJ3=$riskJ3 (predictionId=$predictionId)");
        
        if (riskJ3 >= 0.60) {
          debugPrint("🚨 [SMART NOTIF] Seuil dépassé! Envoi alerte...");
          final isHigh = riskJ3 > 0.70;
          
          await _showAndSave(
            uid: uid,
            id: 102,
            title: isHigh ? "🚨 Alerte Risque Élevé" : "🔮 Risque de Poussée",
            body: isHigh 
                ? "Risque très important détecté. Appliquez immédiatement la stratégie PROTECTION."
                : "Hausse du risque prévue d'ici 3 jours. Anticipez avec votre routine !",
            type: "RISK_ALERT",
            predictionId: predictionId, // CRITICAL: Link to specific ML event
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Error in _checkMLRisk: $e");
    }
  }

  /// EDUCATIONAL: Cycle-based tip (Non-ML)
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
    final dayInCycle = (diff % 28) + 1;

    // J-16 = Début théorique de la phase lutéale
    if (dayInCycle == 16) {
      _showAndSave(
        uid: uid,
        id: 101,
        title: "🧴 Conseil Phase Lutéale",
        body: "Votre cycle entre en phase lutéale. C'est le moment de surveiller l'inflammation.",
        type: "EDUCATIONAL_TIP",
      );
    }
  }

  /// Standard helper to show notification and save to Firestore
  /// Includes global idempotent deduplication
  Future<void> _showAndSave({
    required String uid,
    required int id,
    required String title,
    required String body,
    required String type,
    String? predictionId,
  }) async {
    // Delegate to NotificationService for Idempotent Logic + Dispatch
    await _service.sendNotification(
      userId: uid,
      predictionId: predictionId,
      title: title,
      body: body,
      type: type,
    );
  }

  Future<void> _scheduleReminders(String uid) async {
    // Les rappels sont gérés par NotificationService.scheduleDailyReminder()
    // On s'assure qu'ils sont synchronisés.
    await _service.scheduleDailyReminder();
    if (DateTime.now().weekday == DateTime.sunday) {
      await _service.scheduleWeeklyReminder();
    }
  }

  Future<void> _checkHydration(String uid, Map<String, dynamic> dailyData) async {
    final water = (dailyData['water_glasses'] ?? 8).toInt();
    
    // Alerte si moins de 4 verres d'eau
    if (water < 4) {
      await _showAndSave(
        uid: uid,
        id: 302,
        title: "💧 Hydratation Insuffisante",
        body: "Vous n'avez bu que $water verres d'eau aujourd'hui. Buvez maintenant pour aider votre peau !",
        type: "WATER_REMINDER",
      );
    }
  }

  void _showDailyTip(String uid, Map<String, dynamic> userData, Map<String, dynamic> dailyData) {
    final skinType = (userData['skinType'] ?? 'mixte').toString().toLowerCase();
    final spfUsed = dailyData['spf_used'] ?? true;

    // Priorité : Alerte SPF si oubli
    if (!spfUsed) {
      _showAndSave(
        uid: uid,
        id: 402,
        title: "☀️ Protection Solaire",
        body: "Attention ! Vous n'avez pas appliqué de SPF. Les UV aggravent les cicatrices d'acné.",
        type: "SPF_REMINDER",
      );
      return;
    }

    // Sinon, conseil basé sur le type de peau
    String tip = "N'oubliez pas votre SPF aujourd'hui !";
    if (skinType.contains('grasse')) {
      tip = "Privilégiez un nettoyage doux pour ne pas exciter les glandes sébacées.";
    } else if (skinType.contains('seche')) {
      tip = "Une hydratation riche est essentielle pour restaurer votre barrière cutanée.";
    }

    _showAndSave(
      uid: uid,
      id: 401,
      title: "💡 Conseil du jour",
      body: tip,
      type: "DAILY_TIP",
    );
  }
}
