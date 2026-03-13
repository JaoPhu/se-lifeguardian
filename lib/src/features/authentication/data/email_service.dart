import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class EmailService {
  static final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  // Generate 4-digit OTP
  static String generateOTP() {
    return (1000 + Random().nextInt(9000)).toString();
  }

  // Send OTP Email via Cloud Function
  static Future<bool> sendOTP(String recipientEmail, String otp, {bool isRegistration = false}) async {
    try {
      final callable = _functions.httpsCallable('sendOTPEmail');
      final result = await callable.call({
        'email': recipientEmail,
        'otp': otp,
        'isRegistration': isRegistration,
      });
      
      debugPrint('OTP email sent successfully: ${result.data}');
      return true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' && e.message == 'user-not-found') {
        throw Exception('user-not-found');
      }
      debugPrint('Firebase Functions Error sending OTP email: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error sending OTP email: $e');
      return false;
    }
  }
}
