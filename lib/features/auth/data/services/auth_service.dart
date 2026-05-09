import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import 'package:acneia/features/auth/domain/entities/user_entity.dart';
import 'package:acneia/core/constants/app_constants.dart';
import 'package:acneia/core/errors/app_exception.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// DATA â€“ AuthService (Firebase Auth + Firestore)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _google = GoogleSignIn();

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // â”€â”€ Récupérer les données utilisateur â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<UserEntity?> fetchUser(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserEntity.fromJson(doc.data()!, doc.id);
  }

  // â”€â”€ Inscription â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<UserEntity> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String pseudonym,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user!;
      await user.updateDisplayName('$firstName $lastName');

      final entity = UserEntity(
        id: user.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        pseudonym: pseudonym,
        createdAt: DateTime.now(),
        termsAccepted: true,
      );

      await _db
          .collection(AppConstants.colUsers)
          .doc(user.uid)
          .set(entity.toJson(), SetOptions(merge: true));

      // Sync public profile
      await _db.collection(AppConstants.colPublicProfiles).doc(user.uid).set({
        'uid': user.uid,
        'pseudonym': pseudonym,
        'avatarIndex': 0, // Default for new users
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return entity;

    } on FirebaseAuthException catch (e) {
      debugPrint('🔥 Firebase register error: ${e.code} - ${e.message}');
      throw AuthException(
        '${_mapFirebaseError(e.code)} (code: ${e.code})',
      );
    } catch (e) {
      throw AuthException('Erreur inconnue: $e');
    }
  }

  // â”€â”€ Connexion email/mot de passe â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = await fetchUser(cred.user!.uid);

      // â— IMPORTANT : ne pas créer un faux user
      if (user == null) {
        throw const AuthException('Profil utilisateur introuvable');
      }

      return user;

    } on FirebaseAuthException catch (e) {
      debugPrint('🔥 Firebase login error: ${e.code} - ${e.message}');
      throw AuthException(
        '${_mapFirebaseError(e.code)} (code: ${e.code})',
      );
    } catch (e) {
      throw AuthException('Erreur inconnue: $e');
    }
  }

  // â”€â”€ Connexion Google â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<UserEntity> signInWithGoogle() async {
    try {
      final gUser = await _google.signIn();
      if (gUser == null) {
        throw const AuthException('Connexion Google annulée');
      }

      final gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user!;

      final existing = await fetchUser(user.uid);
      if (existing != null) return existing;

      final parts = (user.displayName ?? '').split(' ');

      final entity = UserEntity(
        id: user.uid,
        firstName: parts.isNotEmpty ? parts.first : '',
        lastName: parts.length > 1 ? parts.last : '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        pseudonym: user.displayName ?? 'Anonyme',
        createdAt: DateTime.now(),
        termsAccepted: true,
      );

      await _db
          .collection(AppConstants.colUsers)
          .doc(user.uid)
          .set(entity.toJson(), SetOptions(merge: true));

      // Sync public profile
      await _db.collection(AppConstants.colPublicProfiles).doc(user.uid).set({
        'uid': user.uid,
        'pseudonym': entity.pseudonym,
        'avatarIndex': 0, // Default
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return entity;

    } on FirebaseAuthException catch (e) {
      debugPrint('🔥 Google login error: ${e.code} - ${e.message}');
      throw AuthException(
        '${_mapFirebaseError(e.code)} (code: ${e.code})',
      );
    } catch (e) {
      throw AuthException('Erreur inconnue: $e');
    }
  }

  // â”€â”€ Déconnexion â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _google.signOut(),
    ]);
  }

  // â”€â”€ Mot de passe oublié â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        '${_mapFirebaseError(e.code)} (code: ${e.code})',
      );
    }
  }

  // â”€â”€ Mapper les codes d'erreur Firebase â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _mapFirebaseError(String code) {
    const map = {
      'email-already-in-use': 'Cet email est déjà utilisé',
      'user-not-found': 'Aucun compte trouvé',
      'wrong-password': 'Mot de passe incorrect',
      'invalid-credential': 'Email ou mot de passe incorrect',
      'weak-password': 'Mot de passe trop faible (min. 6 caractères)',
      'invalid-email': 'Email invalide',
      'too-many-requests': 'Trop de tentatives, réessayez plus tard',
      'network-request-failed': 'Erreur réseau',
    };

    return map[code] ?? 'Erreur d\'authentification';
  }
}
