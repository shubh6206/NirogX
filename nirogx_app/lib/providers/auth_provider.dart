import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user = UserModel(
    id: 'usr_default_001',
    email: 'user@example.com',
    name: 'Alex Mercer',
    age: 28,
    gender: 'Male',
    height: 175.0,
    weight: 70.0,
  );

  bool _isAuthenticated = true;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.login(email, password);
      if (res['user'] != null) {
        _user = UserModel.fromJson(res['user']);
        _isAuthenticated = true;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    required String name,
    required int age,
    required String gender,
    required double height,
    required double weight,
  }) async {
    if (_user != null) {
      _user = _user!.copyWith(
        name: name,
        age: age,
        gender: gender,
        height: height,
        weight: weight,
      );
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    _isAuthenticated = false;
    ApiService.setAuthToken(null);
    notifyListeners();
  }
}
