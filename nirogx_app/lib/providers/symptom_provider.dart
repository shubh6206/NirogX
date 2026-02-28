import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:nirogx_app/data/health_repository.dart';
import 'package:nirogx_app/models/symptom_log.dart'; 
import 'package:nirogx_app/services/api_service.dart'; 

class SymptomProvider with ChangeNotifier {
  final HealthRepository _healthRepository;
  final ApiService _apiService; // Injecting your new Python backend service
  
  List<SymptomLog> _symptomLogs = [];
  bool _isLoading = false;
  String? _error;

  // Constructor now requires both the DB repo and the API service
  SymptomProvider(this._healthRepository, this._apiService);

  // --- Getters for the UI ---
  List<SymptomLog> get symptomLogs => _symptomLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  /// Fetches all saved symptom logs from the local database on app start
  Future<void> loadSymptomLogs() async {
    setLoading(true);
    setError(null);

    try {
      _symptomLogs = await _healthRepository.getAllSymptomLogs();
    } catch (e) {
      setError("Failed to load symptom history: $e");
    } finally {
      setLoading(false);
    }
  }

  /// The Core Function: Talks to the AI, then saves to the local DB
  Future<void> analyzeAndSaveSymptoms({
    required String text,
    required String duration,
    required int severity,
  }) async {
    setLoading(true);
    setError(null);

    try {
      // 1. Create the request payload for your FastAPI backend
      final payload = SymptomPayload(text: text, duration: duration);

      // 2. Call the backend API (which securely talks to Gemini)
      final aiAssessment = await _apiService.analyzeSymptoms(payload);

      // 3. Create a local log combining user input and AI output
      final newLog = SymptomLog(
        symptom: text,
        severity: severity,
        // If there are red flags, prepend them to the assessment text
        analysis: aiAssessment.redFlags.isNotEmpty 
            ? '⚠️ ${aiAssessment.redFlags.join(", ")}\n\n${aiAssessment.assessment}'
            : aiAssessment.assessment,
        timestamp: DateTime.now(),
      );

      // 4. Save to local SQLite database
      await _healthRepository.saveSymptomReport(newLog);
      
      // 5. Update UI State (add to the top of the list)
      _symptomLogs.insert(0, newLog); 
      
    } catch (e) {
      setError("Analysis failed: Make sure your server is running.");
      print("API Error: $e");
    } finally {
      setLoading(false);
    }
  }
  

  /// Fallback: Saves a manual log without AI analysis (if needed)
  Future<void> saveManualSymptomLog(SymptomLog symptomLog) async {
    setLoading(true); 
    try {
      await _healthRepository.saveSymptomReport(symptomLog);
      _symptomLogs.insert(0, symptomLog); 
      setError(null);
    } catch (e) {
      setError("Failed to save log: $e");
    } finally {
      setLoading(false);
    }
  }
  /// Analyzes a medical report image and saves the result
  Future<String?> analyzeAndSaveImage(Uint8List imageBytes) async {
    setLoading(true);
    setError(null);

    try {
      // Send image to the ApiService
      final analysisText = await _apiService.sendChatMessage(
        "Analyze this medical report and provide a brief summary of the key findings.",
        imageBytes: imageBytes,
      );

      // Create and save the log
      final newLog = SymptomLog(
        symptom: "Medical Scan Report",
        severity: 0, // 0 can denote an informational scan
        analysis: analysisText,
        timestamp: DateTime.now(),
      );

      await _healthRepository.saveSymptomReport(newLog);
      _symptomLogs.insert(0, newLog);
      
      return analysisText; // Return text to show in the UI dialog
    } catch (e) {
      setError("Image analysis failed. Please try again.");
      return null;
    } finally {
      setLoading(false);
    }
  }
}