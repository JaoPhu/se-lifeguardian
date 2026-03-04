import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


import 'src/common/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/features/notification/data/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Main: Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Main: Loading SharedPreferences...');
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize Notification Service
  debugPrint('Main: Setting up ProviderContainer...');
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Run initialization in background so it doesn't block UI (fixes white screen)
  unawaited(
    container.read(notificationServiceProvider).init().catchError((e) {
      debugPrint("Failed to initialize NotificationService: $e");
    }),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LifeguardianApp(),
    ),
  );
}
