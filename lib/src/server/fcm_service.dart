import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // ขอ permission
    await _messaging.requestPermission();

    // ดึง token
    String? token = await _messaging.getToken();
    print("🔥 DEVICE TOKEN: $token");

    // ✅ ตั้งค่า Local Notification (ห้ามใช้ const)
    final androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
    );

    // รับข้อความตอนแอปเปิดอยู่
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Channel for emergency alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    final details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: 0,
      title: message.notification?.title ?? "🚨 ALERT",
      body: message.notification?.body ?? "",
      notificationDetails: details,
    );
  }
}
