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
import 'package:lifeguardian/src/features/pose_detection/presentation/analysis_loading_screen.dart';
import 'package:lifeguardian/src/features/notification/presentation/notification_screen.dart';
import 'package:lifeguardian/src/features/events/presentation/events_screen.dart';
import 'package:lifeguardian/src/features/pose_detection/presentation/pose_detector_view.dart';
import 'package:lifeguardian/src/features/subscription/data/trial_provider.dart';
import 'package:lifeguardian/src/features/subscription/presentation/expired_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// Global flag to track first launch/restart
bool _isFirstLaunch = true;

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
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ForgotPasswordScreen(email: extra?['email'] as String?);
        },
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
          // If profile is incomplete, force fromRegistration to true
          final user = ref.read(userProvider);
          final fromRegistration = extra?['fromRegistration'] as bool? ?? !user.isProfileComplete;
          return EditProfileScreen(fromRegistration: fromRegistration);
        },
      ),
      GoRoute(
        path: '/settings-forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ForgotPasswordScreen(email: extra?['email'] as String?);
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
          final extra = state.extra as Map<String, dynamic>; // We expect map now
          return AnalysisLoadingScreen(extras: extra);
        },
      ),
      GoRoute(
        path: '/simulation-view',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return PoseDetectorView(
              videoPath: extra['videoPath'] as String?,
              displayCameraName: extra['cameraName'] as String?,
              startTime: extra['startTime'] as TimeOfDay?,
              date: extra['date'] as DateTime?,
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
      // Force Splash Screen on First Launch / Hot Restart
      if (_isFirstLaunch) {
        _isFirstLaunch = false;
        // If we are already at splash, allow it. If not, redirect to splash.
        if (state.matchedLocation != '/splash') {
          return '/splash';
        }
      }

      final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
      final user = ref.read(userProvider);
      
      final isGuestRoute = state.matchedLocation == '/login' || 
                        state.matchedLocation == '/register' || 
                        state.matchedLocation == '/welcome' ||
                        state.matchedLocation == '/pre-login';

      final isPublicRoute = state.matchedLocation == '/forgot-password' ||
                        state.matchedLocation == '/otp-verification' ||
                        state.matchedLocation == '/reset-password' ||
                        state.matchedLocation == '/splash';

      // 1. Not logged in -> Must go to /welcome or auth pages (or public pages)
      if (firebaseUser == null) {
        return (isGuestRoute || isPublicRoute) ? null : '/welcome';
      }

      // Check profile completeness (Force onboarding)
      if (user.id.isNotEmpty && !user.isProfileComplete) {
        // If they are on edit-profile, or splash, let them be
        if (state.matchedLocation == '/edit-profile' || state.matchedLocation == '/splash') {
          return null;
        }
        // Redirect to edit-profile for any other route
        return '/edit-profile';
      }

      // 3. Subscription/Trial check
      final trialState = ref.read(trialProvider);
      if (trialState.isExpired && state.matchedLocation != '/expired') {
        return '/expired';
      }

      // 4. Logged in and has profile
      
      // If user tries to access Guest-Only routes, redirect to Overview
      // We exclude '/login' from this forced redirect to avoid conflict with LoginScreen's manual navigation
      // or race conditions during the login process.
      if (isGuestRoute && state.matchedLocation != '/login') {
         return '/overview';
      }

      // If specifically on /login and logged in, we let the LoginScreen handle the push to /overview
      // or let the user manually navigate if they somehow got here.
      // But typically, LoginScreen will push /overview upon success.
      
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
    // Also listen to user profile changes
    // Optimization: Only notify if routing-critical fields change to avoid "Router working too hard"
    _userSubscription = ref.listen(userProvider, (prev, next) {
      if (prev == null) return;
      
      // Critical Check 1: ID changed (Login/Logout)
      if (prev.id != next.id) {
        notifyListeners();
        return;
      }

      // Critical Check 2: Profile Completeness Status changed
      if (prev.isProfileComplete != next.isProfileComplete) {
        notifyListeners();
        return;
      }
      
      // Critical Check 3: Name changed from empty to non-empty (or vice-versa) - affects redirect
      if ((prev.name.isEmpty && next.name.isNotEmpty) || (prev.name.isNotEmpty && next.name.isEmpty)) {
        notifyListeners();
        return;
      }

      // Ignore other changes (weight, height, etc.) to keep Router lightweight
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
