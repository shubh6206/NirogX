import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryTeal = Color(0xFF00C9B7);
  static const Color secondaryBlue = Color(0xFF007AFF);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surfaceGray = Color(0xFFF1F4F8);
  static const Color backgroundBlack = Color(0xFF121212);
  static const Color surfaceBlack = Color(0xFF1E1E1E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
    cardTheme: const CardThemeData(
  elevation: 0,
  color: surfaceGray,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),
     cardTheme: const CardThemeData(
  elevation: 0,
  color: surfaceBlack,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
