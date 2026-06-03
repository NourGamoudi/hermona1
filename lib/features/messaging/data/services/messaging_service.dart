import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acneia/core/constants/app_constants.dart';

class MessagingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<QuerySnapshot> getConversations() {
    return _db
        .collection(AppConstants.colConversations)
        .where('participants', arrayContains: _uid)
        .where('visible', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Future<String> getOrCreateConversation(String otherUid) async {
    final snap = await _db
        .collection(AppConstants.colConversations)
        .where('participants', arrayContains: _uid)
        .get();
    for (final doc in snap.docs) {
      final parts = List<String>.from(doc.data()['participants'] ?? []);
      if (parts.contains(otherUid)) return doc.id;
    }
    final id = _uuid.v4();
    await _db.collection(AppConstants.colConversations).doc(id).set({
      'id': id,
      'participants': [_uid, otherUid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'visible': true,
    });
    return id;
  }

  Future<void> deleteConversation(String convId) async {
    await _db.collection(AppConstants.colConversations)
        .doc(convId).update({'visible': false});
  }

  Stream<QuerySnapshot> getMessages(String convId) {
    return _db
        .collection(AppConstants.colMessages)
        .where('conversationId', isEqualTo: convId)
        .where('visible', isEqualTo: true)
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> sendMessage({
    required String convId,
    required String content,
  }) async {
    final msgId = _uuid.v4();
    final batch = _db.batch();
    
    // 1. Préparation du message
    batch.set(_db.collection(AppConstants.colMessages).doc(msgId), {
      'id': msgId,
      'conversationId': convId,
      'senderId': _uid,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'visible': true,
    });

    final preview = content.length > 50 ? '${content.substring(0, 50)}...' : content;
    
    batch.update(_db.collection(AppConstants.colConversations).doc(convId), {
      'lastMessage': preview,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    // 2. Envoi immédiat du message (pour la rapidité)
    await batch.commit();
    debugPrint('✅ Message envoyé avec succès: $msgId');

    // 3. Création de la notification en arrière-plan (ne bloque plus l'UI)
    _createNotification(convId, preview);
  }

  void _createNotification(String convId, String preview) async {
    try {
      final convDoc = await _db.collection(AppConstants.colConversations).doc(convId).get();
      final participants = List<String>.from(convDoc.data()?['participants'] ?? []);
      final recipientId = participants.firstWhere((id) => id != _uid, orElse: () => '');

      if (recipientId.isNotEmpty) {
        debugPrint('🔔 Création notification pour: $recipientId');
        
        // Translation for the title
        String title = 'Nouveau message';
        try {
          final prefs = await SharedPreferences.getInstance();
          final lang = prefs.getString('selected_language') ?? 'fr';
          if (lang == 'en') {
            title = 'New message';
          }
        } catch (_) {}

        final notifId = _uuid.v4();
        await _db.collection(AppConstants.colNotifications).doc(notifId).set({
          'id': notifId,
          'userId': recipientId,
          'type': 'MESSAGE',
          'title': title,
          'body': preview,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'metadata': {
            'conversationId': convId,
            'senderId': _uid,
          }
        });
        debugPrint('🚀 Notification Firestore créée: $notifId');
      } else {
        debugPrint('⚠️ Aucun destinataire trouvé (test sur le même compte ?)');
      }
    } catch (e) {
      debugPrint('❌ Erreur création notification: $e');
    }
  }

  Future<void> deleteMessage(String msgId) async {
    final doc = await _db.collection(AppConstants.colMessages).doc(msgId).get();
    if (doc.data()?['senderId'] == _uid) {
      await _db.collection(AppConstants.colMessages)
          .doc(msgId).update({'visible': false});
    }
  }
}
