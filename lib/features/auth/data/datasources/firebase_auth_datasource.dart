import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/auth_user.dart';

class FirebaseAuthDatasource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDatasource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.userChanges().map(_mapFirebaseUser);
  }

  AuthUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  Future<AuthUser> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw Exception('Authentication failed');
    }
    final mapped = _mapFirebaseUser(user)!;
    unawaited(_ensureFirestoreProfile(mapped));
    return mapped;
  }

  Future<AuthUser> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw Exception('Registration failed');
    }
    await user.sendEmailVerification();
    final mapped = _mapFirebaseUser(user)!;
    unawaited(_ensureFirestoreProfile(mapped, isNewRegistration: true));
    return mapped;
  }

  Future<AuthUser> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final userCredential = await _firebaseAuth.signInWithPopup(provider);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Google authentication failed');
      }
      final mapped = _mapFirebaseUser(user)!;
      unawaited(_ensureFirestoreProfile(mapped));
      return mapped;
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw Exception('Google authentication failed');
    }

    final mapped = _mapFirebaseUser(user)!;
    unawaited(_ensureFirestoreProfile(mapped));
    return mapped;
  }

  Future<void> _ensureFirestoreProfile(
    AuthUser user, {
    bool isNewRegistration = false,
  }) async {
    if (Firebase.apps.isEmpty || user.id.isEmpty) return;
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.id);
      final snap = await docRef.get();
      final fallbackName = user.displayName.isNotEmpty
          ? user.displayName
          : user.email.split('@').first;

      if (!snap.exists || isNewRegistration) {
        await docRef.set({
          'email': user.email,
          'displayName': fallbackName,
          'photoUrl': user.photoUrl,
          'role': user.isAdmin ? 'admin' : 'player',
          'status': 'active',
          'totalPawPoints': 0,
          'totalSnaps': 0,
          'distanceKm': 0.0,
          'mythicPaws': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await docRef.set({
          'email': user.email,
          if (user.displayName.isNotEmpty) 'displayName': user.displayName,
          if (user.photoUrl.isNotEmpty) 'photoUrl': user.photoUrl,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Ensure Firestore profile skipped: $e');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No signed-in user to verify');
    }
    await user.sendEmailVerification();
  }

  Future<void> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No signed-in user to refresh');
    }
    await user.reload();
  }

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      if (!kIsWeb) _googleSignIn.signOut(),
    ]);
  }

  AuthUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    final email = (user.email ?? '').toLowerCase();
    final isPreVerifiedDomain =
        email.endsWith('@pokeiring.app') || email.endsWith('@iring.ph');
    final isAdmin =
        email == 'admin@pokeiring.app' ||
        email == 'admin@iring.ph' ||
        email.endsWith('@iring.ph');
    return AuthUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
      emailVerified: user.emailVerified || isPreVerifiedDomain,
      isAdmin: isAdmin,
    );
  }
}
