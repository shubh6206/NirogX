import 'package:flutter/material.dart';
import 'package:nirogx_app/data/health_repository.dart';
import 'package:nirogx_app/models/health_data.dart';

class HealthDataProvider with ChangeNotifier {
  final HealthRepository _healthRepository;
  
  HealthData? _healthData;
  bool _isLoading = false;
  String? _error;

  HealthDataProvider(this._healthRepository);

  // Getters
  HealthData? get healthData => _healthData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads the most recent health data from the repository
  Future<void> loadHealthData() async {
    _setLoading(true);
    _error = null;

    try {
     _healthData = await _healthRepository.getLatestHealthStatus(); 
    } catch (e) {
      _error = "Failed to load health statistics: $e";
    } finally {
      _setLoading(false);
    }
  }

  /// Saves new health metrics and refreshes the local state
Future<void> saveHealthData(HealthData newData) async {
  _setLoading(true);
  try {
    // This call will now work because it matches the repository method
    await _healthRepository.saveHealthData(newData);
    _healthData = newData; 
    _error = null;
  } catch (e) {
    _error = "Failed to save data: $e";
  } finally {
    _setLoading(false);
  }
}

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}