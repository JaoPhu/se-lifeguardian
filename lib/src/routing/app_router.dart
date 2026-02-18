import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:lifeguardian/src/features/profile/data/user_repository.dart';
import 'package:lifeguardian/src/features/authentication/providers/auth_providers.dart';
import 'dart:async';

import 'package:lifeguardian/src/routing/scaffold_with_nav_bar.dart';
import 'package:lifeguardian/src/features/dashboard/presentation/overview_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/splash_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/welcome_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/pre_login_screen.dart';

// ✅ เหลือแค่ alias เท่านั้น (ลบ import แบบธรรมดาออก)
import 'package:lifeguardian/src/features/authentication/presentation/login_screen.dart' as login;
import 'package:lifeguardian/src/features/authentication/presentation/register_screen.dart' as reg;

import 'package:lifeguardian/src/features/authentication/presentation/forgot_password_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/otp_verification_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/reset_password_screen.dart';
import 'package:lifeguardian/src/features/authentication/presentation/change_password_screen.dart';

import 'package:lifeguardian/src/features/settings/presentation/settings_screen.dart';
import 'package:lifeguardian/src/features/status/presentation/status_screen.dart';
import 'package:lifeguardian/src/features/group/presentation/group_management_screen.dart';
import 'package:lifeguardian/src/features/statistics/presentation/statistics_screen.dart';
import 'package:lifeguardian/src/features/history/presentation/pages/history_list_page.dart';
import 'package:lifeguardian/src/features/history/presentation/pages/history_detail_page.dart';
import 'package:lifeguardian/src/features/history/domain/history_model.dart';
import 'package:lifeguardian/src/features/profile/presentation/profile_screen.dart';
import 'package:lifeguardian/src/features/profile/presentation/edit_profile_screen.dart';
import 'package:lifeguardian/src/features/pose_detection/presentation/demo_setup_screen.dart';
import 'package:lifeguardian/src/features/notification/presentation/notification_screen.dart';
import 'package:lifeguardian/src/features/events/presentation/events_screen.dart';
import 'package:lifeguardian/src/features/pose_detection/presentation/pose_detector_view.dart';
import 'package:lifeguardian/src/features/subscription/data/trial_provider.dart';
import 'package:lifeguardian/src/features/subscription/presentation/expired_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _AuthRefreshListenable(ref),
    routes: [
      // ... (routes stay same)
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
        builder: (context, state) => const login.LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
       builder: (context, state) => const reg.RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpVerificationScreen(
            email: extra['email'] as String,
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ResetPasswordScreen(
            email: extra['email'] as String,
            otp: extra['otp'] as String,
          );
        },
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
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fromRegistration = extra?['fromRegistration'] as bool? ?? false;
          return EditProfileScreen(fromRegistration: fromRegistration);
        },
      ),
      GoRoute(
        path: '/change-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChangePasswordScreen(),
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
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return PoseDetectorView(
              videoPath: extra['videoPath'] as String?,
              displayCameraName: extra['cameraName'] as String?,
            );
          } else if (extra is Map) {
             // Handle _Map<String, String?> or other Map variants
             return PoseDetectorView(
               videoPath: extra['videoPath']?.toString(),
               displayCameraName: extra['cameraName']?.toString(),
             );
          }
          return const PoseDetectorView();
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
      GoRoute(
        path: '/expired',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpiredScreen(),
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
      GoRoute(
        path: '/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HistoryListPage(),
      ),
      GoRoute(
        path: '/history-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final history = state.extra as DailyHistory;
          return HistoryDetailPage(history: history);
        },
      ),
    ],
    redirect: (context, state) {
      final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
      final user = ref.read(userProvider);
      final loggingIn = state.matchedLocation == '/login' || 
                        state.matchedLocation == '/register' || 
                        state.matchedLocation == '/welcome' ||
                        state.matchedLocation == '/splash' ||
                        state.matchedLocation == '/pre-login' ||
                        state.matchedLocation == '/forgot-password' ||
                        state.matchedLocation == '/otp-verification' ||
                        state.matchedLocation == '/reset-password';

      // 1. Not logged in -> Must go to /welcome or auth pages
      if (firebaseUser == null) {
        return loggingIn ? null : '/welcome';
      }

      // 2. Logged in -> Check profile completeness
      // IMPORTANT: Only redirect to edit-profile for NEW users who haven't completed registration
      // user.name is our primary indicator for a "completed" basic profile.
      if (user.id.isNotEmpty && user.name.isEmpty) {
        // If they are already on edit-profile, or splash, let them be
        if (state.matchedLocation == '/edit-profile' || state.matchedLocation == '/splash') {
          return null;
        }

        // If they are on ANY auth route or the welcome screen, they MUST go to edit-profile
        // This covers Email registration, Social sign-in, and generic "stuck" states
        return '/edit-profile';
      }

      // 3. Subscription/Trial check
      final trialState = ref.read(trialProvider);
      if (trialState.isExpired && state.matchedLocation != '/expired') {
        return '/expired';
      }

      // 4. Logged in and has profile -> Don't show login pages
      if (loggingIn && user.name.isNotEmpty) {
        return '/overview';
      }

      return null;
    },
  );
});

/// A Listenable that notifies GoRouter when the Auth state changes.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    _subscription = ref.read(firebaseAuthProvider).authStateChanges().listen((_) {
      notifyListeners();
    });
    // Also listen to user profile changes (any change, e.g. ID, name, etc.)
    _userSubscription = ref.listen(userProvider, (prev, next) {
      if (prev != next) {
        notifyListeners();
      }
    }, fireImmediately: true);
  }

  late final StreamSubscription<auth.User?> _subscription;
  late final ProviderSubscription _userSubscription;

  @override
  void dispose() {
    _subscription.cancel();
    _userSubscription.close();
    super.dispose();
  }
}
