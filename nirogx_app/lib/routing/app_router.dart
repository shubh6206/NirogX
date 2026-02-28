import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  static final GoRouter router = GoRouter(
    initialLocation: '/login', // Force login on startup
    navigatorKey: _rootNavigatorKey,
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
              GoRoute(
                path: '/chat',
                builder: (context, state) => const AiChatScreen(),
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