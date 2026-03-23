// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  bool _isDemoMode = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized; // Prevents routing before storage is checked
  bool get isDemoMode => _isDemoMode;

  AuthProvider() {
    _checkAuthStatus();
  }

  // Reads the device's local storage when the app opens
  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _isInitialized = true;
    notifyListeners(); // Tells the router to run its check
  }

  void setDemoMode(bool value) {
    _isDemoMode = value;
    notifyListeners();
  }

  // Call this when the user clicks "Log Out" on the profile screen
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    _isLoggedIn = false;
    _isDemoMode = false;
    notifyListeners(); // Tells the router to kick them to the login screen
  }
}