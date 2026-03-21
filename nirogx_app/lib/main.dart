import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

// Routing
import 'package:nirogx_app/routing/app_router.dart';

// Theme
import 'package:nirogx_app/theme/app_theme.dart';

// Data Layer
import 'package:nirogx_app/data/health_repository.dart';
import 'package:nirogx_app/data/database_helper.dart';

// Providers
import 'package:nirogx_app/providers/auth_provider.dart'; // ✅ Added missing import
import 'package:nirogx_app/providers/health_data_provider.dart';
import 'package:nirogx_app/providers/symptom_provider.dart';

// Services
import 'package:nirogx_app/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Load env variables securely
  await dotenv.load(fileName: ".env"); 

  // ✅ Initialize DB
  await DatabaseHelper.instance.database;

  // ✅ Initialize AuthProvider and inject it into the Router
  final authProvider = AuthProvider();
  final appRouter = AppRouter(authProvider);

  // ✅ Create ONE shared repository instance
  final healthRepository = HealthRepository();

  runApp(
    MultiProvider(
      providers: [
        // ✅ Make the AuthProvider available so the ProfileScreen can call logout()
        ChangeNotifierProvider.value(
          value: authProvider,
        ),

        ChangeNotifierProvider(
          create: (_) => HealthDataProvider(healthRepository),
        ),

        // ✅ Passed the shared healthRepository instead of creating a new one
        ChangeNotifierProvider(
          create: (_) => SymptomProvider(
            healthRepository,
            ApiService(),
          ),
        ),
      ],
      // ✅ Pass the fully initialized router into MyApp
      child: MyApp(appRouter: appRouter.router),
    ),
  );
}

class MyApp extends StatelessWidget {
  // ✅ Require the router to be passed in
  final GoRouter appRouter; 

  const MyApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NirogX',
      debugShowCheckedModeBanner: false,

      // Themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // Optional: make dynamic later
      themeMode: ThemeMode.light,

      // ✅ Use the injected router instance
      routerConfig: appRouter,
    );
  }
}