
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nirogx_app/screens/analyze_data_screen.dart';
import 'package:nirogx_app/screens/home_screen.dart';
import 'package:nirogx_app/screens/insights_screen.dart';
import 'package:nirogx_app/screens/login_screen.dart';
import 'package:nirogx_app/screens/ai_chat_screen.dart';
import 'package:nirogx_app/screens/profile_screen.dart';
import 'package:nirogx_app/screens/signup_screen.dart';
import 'package:nirogx_app/widgets/scaffold_with_bottom_nav_bar.dart';


final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  initialLocation: '/login',
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithBottomNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/analyze',
          builder: (context, state) => const AnalyzeDataScreen(),
        ),
        GoRoute(
          path: '/insights',
          builder: (context, state) => const InsightsScreen(),
        ),
        GoRoute(
          path: '/ai-chat',
          builder: (context, state) => const AiChatScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
