import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/health_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NirogXApp());
}

class NirogXApp extends StatelessWidget {
  const NirogXApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
      ],
      child: MaterialApp(
        title: 'NirogX Clinical AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00897B),
            primary: const Color(0xFF00897B),
            secondary: const Color(0xFF0284C7),
            surface: const Color(0xFFF8FAFC),
          ),
          fontFamily: 'Roboto',
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}
