import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore, this._storage);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _storage;

  static const _passwordKey = 'user_password';

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> registerWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Save password securely for future re-auth (e.g. deletion)
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<void> signInWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    
    // 1. Authenticate first so we have the UID and permissions
    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    // Save password securely for future re-auth (e.g. deletion)
    await _storage.write(key: _passwordKey, value: password);

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
      // Use default instance (us-central1) which is standard for most Firebase projects
      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('updateUserPassword');
      final result = await callable.call(<String, dynamic>{
        'email': email,
        'newPassword': newPassword,
      });

      // Success - function returned normally
      if (result.data != null && result.data['success'] == true) {
        debugPrint('Password updated successfully');
        return;
      }
      
      throw Exception(result.data?['message'] ?? 'Failed to update password');
    } on FirebaseFunctionsException catch (e) {
      // Handle Cloud Function specific errors
      debugPrint('Cloud Function error: ${e.code} - ${e.message} - ${e.details}');
      throw Exception(e.message ?? 'Failed to update password');
    } catch (e) {
      debugPrint('Error updating password via Cloud Function: $e');
      throw Exception('Failed to update password. Please try again or use the reset link.');
    }
  }

  /// Reset password using Email OTP (Secure - verification on Server)
  Future<void> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('resetPasswordWithOTP');
      final result = await callable.call(<String, dynamic>{
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });

      if (result.data != null && result.data['success'] == true) {
        debugPrint('Password reset successfully with OTP');
        return;
      }
      
      throw Exception(result.data?['message'] ?? 'Failed to reset password');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function error: ${e.code} - ${e.message}');
      // Return the error message from the server (e.g. "OTP Invalid")
      throw Exception(e.message ?? 'เกิดข้อผิดพลาดในการรีเซ็ตรหัสผ่าน');
    } catch (e) {
      debugPrint('Error resetting password with OTP: $e');
      throw Exception('ไม่สามารถรีเซ็ตรหัสผ่านได้ กรุณาลองใหม่อีกครั้ง');
    }
  }

  /// Change password for currently logged-in user
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('No user logged in');

    try {
      // Re-authenticate user before allowing password change (Firebase requirement)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      debugPrint('Password changed successfully for logged-in user');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('รหัสผ่านเดิมไม่ถูกต้อง');
      } else if (e.code == 'weak-password') {
        throw Exception('รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 6 ตัวอักษร');
      }
      throw Exception('ไม่สามารถเปลี่ยนรหัสผ่านได้: ${e.message}');
    } catch (e) {
      debugPrint('Error changing password: $e');
      throw Exception('เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน');
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
    await _storage.delete(key: _passwordKey);
    await _auth.signOut();
  }

  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final email = user.email;

    String? targetPassword = password;
    
    // 💡 Try to retrieve stored password if not provided (Seamless flow)
    if (targetPassword == null || targetPassword.isEmpty) {
      targetPassword = await _storage.read(key: _passwordKey);
    }

    try {
      // 1. Re-authenticate if password available (for email/password accounts)
      if (email != null && targetPassword != null && targetPassword.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: targetPassword,
        );
        await user.reauthenticateWithCredential(credential);
        debugPrint('Email re-authentication successful');
      }

      // 2. Delete Firebase Auth account FIRST
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // 💡 If session is stale even with password (or no password), try social re-auth
          debugPrint('Session stale, trying social re-authentication...');
          await _reauthenticateSocial();
          await user.delete(); // Try again after re-auth
        } else {
          rethrow;
        }
      }
      
      debugPrint('Firebase Auth account deleted');

      // 3. Delete Firestore data (only after Auth deletion succeeds)
      await _deleteFirestoreData(uid);
      debugPrint('Firestore data deleted');
      
      // Clear stored password after successful deletion
      await _storage.delete(key: _passwordKey);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('เซสชันเน็ตหมดอายุ กรุณายืนยันตัวตนใหม่อีกครั้ง');
      } else if (e.code == 'wrong-password') {
        throw Exception('รหัสผ่านไม่ถูกต้อง');
      }
      debugPrint('Firebase Auth error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  /// Helper to trigger Social Re-authentication "on the fly"
  Future<void> _reauthenticateSocial() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final providers = user.providerData.map((p) => p.providerId).toList();

    if (providers.contains('google.com')) {
      // --- Google Re-auth ---
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw Exception('การยืนยันตัวตนถูกยกเลิก');
      
      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(cred);
    } else if (providers.contains('apple.com')) {
      // --- Apple Re-auth ---
      final rawNonce = _generateNonce();
      final nonce = _sha256ofRawNonce(rawNonce);
      
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final cred = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      await user.reauthenticateWithCredential(cred);
    }
  }

  Future<void> _deleteFirestoreData(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Delete user document
      await firestore.collection('users').doc(uid).delete();
      
      // Delete associated events
      final events = await firestore.collection('users').doc(uid).collection('events').get();
      for (var doc in events.docs) {
        await doc.reference.delete();
      }

      // Delete associated notifications
      final notifications = await firestore.collection('users').doc(uid).collection('notifications').get();
      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting Firestore data: $e');
      // Don't rethrow - Auth is already deleted
    }
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
