import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:nirogx_app/providers/auth_provider.dart';

// Feature Screens
import 'package:nirogx_app/screens/auth/login_screen.dart';
import 'package:nirogx_app/screens/auth/signup_screen.dart';
import 'package:nirogx_app/screens/home/home_screen.dart';
import 'package:nirogx_app/screens/profile/profile_screen.dart';

// Feature Widgets (used as screens)
import 'package:nirogx_app/screens/ai_chat_screen.dart';
import 'package:nirogx_app/screens/analyze_data_screen.dart';
import 'package:nirogx_app/screens/insights_screen.dart';
import 'package:nirogx_app/widgets/scaffold_with_bottom_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  final AuthProvider authProvider;

  // Pass the provider into the router so it can listen for changes
  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    // We can default to '/' now, because the redirect guard will catch unauthenticated users
    initialLocation: '/', 
    navigatorKey: _rootNavigatorKey,
    
    // 1. Tell the router to rebuild whenever AuthProvider calls notifyListeners()
    refreshListenable: authProvider,

    // 2. THE AUTH GUARD
    redirect: (context, state) {
      // Wait for SharedPreferences to load from local storage
      if (!authProvider.isInitialized) return null;

      final bool isLoggedIn = authProvider.isLoggedIn;
      final bool isDemoMode = authProvider.isDemoMode;
      final bool isGoingToAuth = state.uri.path == '/login' || state.uri.path == '/signup';

      // Rule A: If NOT logged in AND NOT in demo mode, and trying to go anywhere else -> Login
      if (!isLoggedIn && !isDemoMode && !isGoingToAuth) {
        return '/login';
      }

      // Rule B: If LOGGED IN OR in demo mode, and trying to view the Login/Signup screen -> Home
      if ((isLoggedIn || isDemoMode) && isGoingToAuth) {
        return '/';
      }

      // Rule C: Otherwise, let them proceed normally
      return null;
    },

    routes: [
      // 1. Auth Routes: No Bottom Bar here
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // 2. Main Application Shell: Bottom Bar stays visible
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/', // The Home branch
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analyze',
                builder: (context, state) => const AnalyzeDataScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // FIXED: Cleaned up the builder method for the Chat route
              GoRoute(
                path: '/chat',
                builder: (context, state) {
                  final incomingMessage = state.extra as String?;
                  return AiChatScreen(initialMessage: incomingMessage);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}