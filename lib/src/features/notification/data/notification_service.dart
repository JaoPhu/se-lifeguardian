import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/data/user_repository.dart';
import '../../authentication/providers/auth_providers.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Ref _ref;
  
  // Stream for navigation events
  final _navigationStreamController = StreamController<String>.broadcast();
  Stream<String> get navigationStream => _navigationStreamController.stream;

  NotificationService(this._ref) {
    // Automatically save token when user logs in
    _ref.listen(authStateProvider, (previous, next) async {
      final user = next.valueOrNull;
      if (user != null) {
        final token = await _fcm.getToken();
        if (token != null) {
          _saveTokenToBackend(user.uid, token);
        }
      }
    });
  }

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      
      // Update token once at init if user already logged in
      final user = _ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        String? token = await _fcm.getToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        );
        if (token != null) {
          _saveTokenToBackend(user.uid, token);
        }
      }
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Setup Local Notifications for Foreground
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click when app is in foreground
        if (details.payload != null) {
          _navigationStreamController.add(details.payload!);
        }
      },
    );

    // 2.5 Handle Background/Terminated Click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened from background: ${message.data}');
      final type = message.data['type'];
      if (type != null) {
        _navigationStreamController.add(type as String);
      }
    });

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification: ${initialMessage.data}');
      final type = initialMessage.data['type'];
      if (type != null) {
        _navigationStreamController.add(type as String);
      }
    }

    // 3. Listen for Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification?.title}');
        _showLocalNotification(message);
      }
    });
  }

  Future<void> _saveTokenToBackend(String uid, String token) async {
     try {
       await _ref.read(userRepositoryProvider).saveFcmToken(uid, token);
       debugPrint("FCM Token saved to Firestore for $uid");
     } catch (e) {
       debugPrint("Error saving FCM token: $e");
     }
  }

  void _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data['type'],
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
