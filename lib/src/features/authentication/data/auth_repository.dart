import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';

class AuthRepository {
  AuthRepository(this._auth, this._firestore);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> registerWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    
    // 1. Authenticate first so we have the UID and permissions
    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser != null) {
      // email variable is unused, removed
      
      bool profileExists = false;
      try {
        debugPrint('AuthRepository: Checking Firestore profile for email: $normalizedEmail');
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();
        profileExists = query.docs.isNotEmpty;
        
        if (!profileExists) {
          debugPrint('AuthRepository: No profile found by email, checking by UID: ${firebaseUser.uid}');
          final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
          profileExists = userDoc.exists;
        }
        
        debugPrint('AuthRepository: Profile exists: $profileExists');
      } catch (e) {
        debugPrint('AuthRepository: Firestore profile check error: $e');
        profileExists = false;
      }

      // 3. Update Session ID for single-session enforcement
      // Use set(merge: true) in case the document doesn't exist yet
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set({
        'sessionId': sessionId,
      }, SetOptions(merge: true));
    }
  }

  Future<bool> checkUserExists(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user existence (Firestore): $e');
      return false;
    }
  }

  // Secure Password Update (Requires Cloud Function)
  Future<void> updateUserPassword(String email, String newPassword) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('updateUserPassword');
      final result = await callable.call(<String, dynamic>{
        'email': email,
        'newPassword': newPassword,
      });

      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to update password');
      }
    } catch (e) {
      debugPrint('Error updating password via Cloud Function: $e');
      throw Exception('Failed to update password. Please try again or use the reset link.');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> signOut() async {
    // ออกจาก Google ด้วย (กันตอนสลับบัญชี)
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    // 1. Delete Firestore data
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete user document
      await firestore.collection('users').doc(uid).delete();
      
      // Delete associated events (if any)
      final events = await firestore.collection('users').doc(uid).collection('events').get();
      for (var doc in events.docs) {
        await doc.reference.delete();
      }

      // Delete associated notifications (if any)
      final notifications = await firestore.collection('users').doc(uid).collection('notifications').get();
      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting user data from Firestore: $e');
    }

    // 2. Delete Auth account
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('This action requires a recent login. Please log out and log in again to delete your account.');
      }
      rethrow;
    } catch (e) {
      debugPrint('Error deleting Auth account: $e');
      rethrow;
    }

    // 3. Final Sign Out
    await signOut();
  }

  // ✅ เพิ่มตัวนี้ (ทำให้ controller ไม่แดง)
  Future<void> signInWithGoogle({required bool isLogin}) async {
    // --- Web ---
    UserCredential? credential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      credential = await _auth.signInWithPopup(provider);
    } else {
      // --- Android/iOS ---
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('ยกเลิกการเข้าสู่ระบบด้วย Google');
      }

      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      credential = await _auth.signInWithCredential(cred);
    }

    // --- Strict Check ---
    final user = credential.user;
    if (user != null) {
      final email = user.email?.trim().toLowerCase();
      
      bool profileExists = false;
      try {
        if (email != null) {
          debugPrint('AuthRepository: Checking Firestore profile (Google) for email: $email');
          final query = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          profileExists = query.docs.isNotEmpty;
        }
        
        if (!profileExists) {
          debugPrint('AuthRepository: Checking by UID: ${user.uid}');
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          profileExists = userDoc.exists;
        }
        debugPrint('AuthRepository: Profile exists: $profileExists');
      } catch (e) {
        debugPrint('AuthRepository: Firestore profile check error (Google): $e');
        profileExists = false;
      }
      
      if (isLogin) {
        // Login Flow: Even if profile missing, we let them in. 
        // Redirection logic in router will guide them to complete profile.

        // Update Session ID
        final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
        await _firestore.collection('users').doc(user.uid).set({
          'sessionId': sessionId,
        }, SetOptions(merge: true));
      } else {
        // Register Flow: Must NOT have data already
        if (profileExists) {
          throw Exception('account-already-exists');
        }
      }
    }
  }

  Future<void> signInWithApple({required bool isLogin}) async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofRawNonce(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final OAuthCredential credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final authCredential = await _auth.signInWithCredential(credential);
    
    // --- Strict Check ---
    final user = authCredential.user;
    if (user != null) {
      final email = user.email?.trim().toLowerCase();
      
      bool profileExists = false;
      try {
        if (email != null) {
          debugPrint('AuthRepository: Checking Firestore profile (Apple) for email: $email');
          final query = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          profileExists = query.docs.isNotEmpty;
        }
        
        if (!profileExists) {
          debugPrint('AuthRepository: Checking by UID: ${user.uid}');
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          profileExists = userDoc.exists;
        }
        debugPrint('AuthRepository: Profile exists: $profileExists');
      } catch (e) {
        debugPrint('AuthRepository: Firestore profile check error (Apple): $e');
        profileExists = false;
      }
      
      if (isLogin) {
        // Login Flow: Let them in even if profile missing.
        
        // Update Session ID
        final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
        await _firestore.collection('users').doc(user.uid).set({
          'sessionId': sessionId,
        }, SetOptions(merge: true));
      } else {
        if (profileExists) {
          throw Exception('account-already-exists');
        }
      }
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofRawNonce(String rawNonce) {
    final bytes = utf8.encode(rawNonce);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
