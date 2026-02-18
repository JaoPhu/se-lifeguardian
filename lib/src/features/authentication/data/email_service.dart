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
  static Future<bool> sendOTP(String recipientEmail, String otp) async {
    try {
      final callable = _functions.httpsCallable('sendOTPEmail');
      final result = await callable.call({
        'email': recipientEmail,
        'otp': otp,
      });
      
      debugPrint('OTP email sent successfully: ${result.data}');
      return result.data['success'] == true;
    } catch (e) {
      debugPrint('Error sending OTP email: $e');
      return false;
    }
  }
}
