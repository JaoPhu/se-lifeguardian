import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class EmailService {
  // Credentials
  static const String _username = 'lifeguardian.service@gmail.com';
  static const String _password = 'ujnr fgtc pdvw itcj'; // App Password
  static const String _senderName = 'LifeGuardian Support';

  // Generate 4-digit OTP
  static String generateOTP() {
    return (1000 + Random().nextInt(9000)).toString();
  }

  // Send OTP Email
  static Future<bool> sendOTP(String recipientEmail, String otp) async {
    final smtpServer = gmail(_username, _password);

    // Create the message
    final message = Message()
      ..from = Address(_username, _senderName)
      ..recipients.add(recipientEmail)
      ..subject = 'รหัสยืนยันตัวตน LifeGuardian ของคุณ: $otp'
      ..html = '''
        <div style="font-family: 'Sarabun', sans-serif; padding: 20px; background-color: #f4f4f4;">
          <div style="max-width: 500px; margin: 0 auto; background-color: #ffffff; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
            <h2 style="color: #0D9488; text-align: center;">รหัสยืนยันตัวตน (OTP)</h2>
            <p style="font-size: 16px; color: #333;">สวัสดีครับ,</p>
            <p style="font-size: 16px; color: #333;">
              ใช้รหัสอ้างอิงด้านล่างนี้เพื่อยืนยันตัวตนและรีเซ็ตรหัสผ่านของคุณในแอปพลิเคชัน <strong>LifeGuardian</strong>
            </p>
            <div style="text-align: center; margin: 30px 0;">
              <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #0D9488; background-color: #f0fdfa; padding: 10px 20px; border-radius: 5px; border: 1px solid #ccfbf1;">
                $otp
              </span>
            </div>
            <p style="font-size: 14px; color: #666; text-align: center;">
              รหัสนี้จะหมดอายุภายใน 10 นาที<br>
              หากคุณไม่ได้เป็นผู้ร้องขอ กรุณาเพิกเฉยต่ออีเมลฉบับนี้
            </p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
            <p style="font-size: 12px; color: #999; text-align: center;">
              © 2026 LifeGuardian. All rights reserved.
            </p>
          </div>
        </div>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Message sent: ${sendReport.toString()}');
      return true;
    } catch (e) {
      debugPrint('Message not sent. \n$e');
      return false;
    }
  }
}
