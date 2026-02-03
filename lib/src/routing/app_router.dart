import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeguardian/src/routing/scaffold_with_nav_bar.dart';
import 'package:lifeguardian/src/features/dashboard/presentation/overview_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/splash_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/welcome_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/pre_login_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/login_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/register_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/forgot_password_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/otp_verification_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/reset_password_screen.dart';
import 'package:lifeguardian/src/features/settings/presentation/settings_screen.dart';
import 'package:lifeguardian/src/features/status/presentation/status_screen.dart';
import 'package:lifeguardian/src/features/group/presentation/group_management_screen.dart';
import 'package:lifeguardian/src/features/statistics/presentation/statistics_screen.dart';
import 'package:lifeguardian/src/features/profile/presentation/profile_screen.dart';
import 'package:lifeguardian/src/features/profile/presentation/edit_profile_screen.dart';
import 'package:lifeguardian/src/features/debug/presentation/ai_debug_screen.dart';
import 'package:lifeguardian/src/features/pose_detection/presentation/demo_setup_screen.dart';
import 'package:lifeguardian/src/features/notification/presentation/notification_screen.dart';
import 'package:lifeguardian/src/features/events/presentation/events_screen.dart';
import 'package:lifeguardian/src/features/pose_detection/presentation/pose_detector_view.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/pre-login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PreLoginScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/group',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GroupManagementScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/ai-debug',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AIDebugScreen(),
      ),
      GoRoute(
        path: '/demo-setup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DemoSetupScreen(),
      ),
      GoRoute(
        path: '/analysis',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final videoPath = state.extra as String?;
          return PoseDetectorView(videoPath: videoPath);
        },
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/events/:cameraId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final cameraId = state.pathParameters['cameraId']!;
          return EventsScreen(cameraId: cameraId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Overview
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/overview',
                builder: (context, state) => const OverviewScreen(),
              ),
            ],
          ),
          // Tab 2: Statistics
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          // Tab 3: Status
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/status',
                builder: (context, state) => const StatusScreen(),
              ),
            ],
          ),
          // Tab 4: Users/Group
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/users',
                builder: (context, state) => const GroupManagementScreen(),
              ),
            ],
          ),
          // Tab 5: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
