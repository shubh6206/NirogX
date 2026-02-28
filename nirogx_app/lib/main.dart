import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Routing
import 'package:nirogx_app/routing/app_router.dart';

// Theme
import 'package:nirogx_app/theme/app_theme.dart';

// Data Layer
import 'package:nirogx_app/data/health_repository.dart';
import 'package:nirogx_app/data/database_helper.dart';

// Providers
import 'package:nirogx_app/providers/health_data_provider.dart';
import 'package:nirogx_app/providers/symptom_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nirogx_app/services/api_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); 
  // ✅ Initialize DB
  await DatabaseHelper.instance.database;

  // ✅ Create ONE shared repository instance (important)
  final healthRepository = HealthRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HealthDataProvider(healthRepository),
        ),

        // ✅ This is used by AnalyzeDataScreen
        ChangeNotifierProvider(
          create: (_) => SymptomProvider(
            HealthRepository(),
            ApiService(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NirogX',
      debugShowCheckedModeBanner: false,

      // ✅ Themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // 💡 Optional: make dynamic later
      themeMode: ThemeMode.light,

      // ✅ Routing
      routerConfig: AppRouter.router,
    );
  }
}