
import 'package:flutter/material.dart';
import 'package:nirogx_app/routing/app_router.dart';
import 'package:nirogx_app/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NirogX',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
