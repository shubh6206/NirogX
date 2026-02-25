
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color primaryColor = Color(0xFF00C853); // A vibrant green
const Color accentColor = Color(0xFF64FFDA); // A lighter green for accents
const Color backgroundColor = Color(0xFFFFFFFF); // White background
const Color textColor = Color(0xFF000000); // Black text

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  primaryColor: primaryColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    secondary: accentColor,
    background: backgroundColor,
    onBackground: textColor,
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.roboto(
      fontSize: 57,
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
    titleLarge: GoogleFonts.roboto(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: textColor,
    ),
    bodyMedium: GoogleFonts.openSans(
      fontSize: 14,
      color: textColor,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: primaryColor,
    unselectedItemColor: Colors.grey,
  ),
);
