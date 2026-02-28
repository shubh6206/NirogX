import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // Use a string constant to avoid typos
  static const String _themeKey = "user_theme_mode";
  
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Constructor that loads the saved theme immediately
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Optimized toggle: specifically handles the transition from system to manual
  void toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    _saveThemeToPrefs();
    notifyListeners();
  }

  void setSystemTheme() async {
    _themeMode = ThemeMode.system;
    _saveThemeToPrefs();
    notifyListeners();
  }

  // --- Persistence Logic ---

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Save the index of the enum (0: system, 1: light, 2: dark)
    await prefs.setInt(_themeKey, _themeMode.index);
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    }
  }
}
