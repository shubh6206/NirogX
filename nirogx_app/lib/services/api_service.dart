// lib/services/api_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:nirogx_app/models/symptom_log.dart';
import 'package:nirogx_app/models/health_data.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  // Backend URL (10.0.2.2 for Android Emulator, localhost for others)
  static String get _baseUrl => 
      (defaultTargetPlatform == TargetPlatform.android && !kIsWeb)
          ? 'http://10.0.2.2:8000/api/v1'
          : 'http://localhost:8000/api/v1';

  ApiService._internal();

  String? _jwtToken;

  // Call this when the app starts if a token is saved in SharedPreferences
  void setToken(String token) {
    _jwtToken = token;
  }

  // Helper to dynamically get headers with the Auth Token
  Map<String, String> get _authHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
    };
  }

  // --- Auth Methods ---
  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['detail']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['detail']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  // =========================================================================
  // 1. FREE-FORM AI CHAT (Routed through FastAPI for RAG)
  // =========================================================================
  
  // UPDATED: Now requires a sessionId (made optional for compatibility)
  Future<String> sendChatMessage(String prompt, {String? sessionId, Uint8List? imageBytes}) async {
    final uri = Uri.parse('$_baseUrl/chat');

    // If a screen didn't provide a sessionId, auto-generate a unique timestamp-based one
    final String effectiveSessionId = sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

    try {
      var request = http.MultipartRequest('POST', uri);
      
      // Add Authorization header if token exists
      if (_jwtToken != null) {
        request.headers['Authorization'] = 'Bearer $_jwtToken';
      }
      
      // Add text fields
      request.fields['prompt'] = prompt;
      request.fields['user_id'] = '1'; // Hardcoded for testing
      request.fields['session_id'] = effectiveSessionId; 

      // Add image if attached
      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'upload.jpg',
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      } else {
        return "Server Error: ${response.body}";
      }
    } catch (e) {
      return "AI Connection Error: Please check if your FastAPI server is running. Details: $e";
    }
  }

  // NEW: Fetch past chats
  Future<Map<String, dynamic>> fetchChatHistory() async {
    final uri = Uri.parse('$_baseUrl/chat/history/1'); // Hardcoded user_id 1
    try {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['sessions'];
      }
      return {};
    } catch (e) {
      debugPrint("Error fetching history: $e");
      return {};
    }
  }

  // =========================================================================
  // 2. STRUCTURED SYMPTOM ANALYSIS (To FastAPI Backend - Used in providers)
  // =========================================================================

  Future<ClinicalAssessment> analyzeSymptoms(SymptomPayload payload) async {
    final url = Uri.parse('$_baseUrl/analyze');

    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode(payload.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ClinicalAssessment.fromJson(data);
      } else {
        throw Exception('Server Error: ${response.body}');
      }
    } catch (e) {
      return ClinicalAssessment(
        assessment: 'Network error. Could not reach the NirogX backend.',
        redFlags: ['Connection Failed'],
        confidenceScore: 0.0,
      );
    }
  }

  // =========================================================================
  // 3. HEALTH SCORE CALCULATOR (To FastAPI Backend)
  // =========================================================================

  Future<HealthScoreResult> calculateHealthScore(UserVitalsPayload payload) async {
    final url = Uri.parse('$_baseUrl/health-score');

    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode(payload.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HealthScoreResult.fromJson(data);
      } else {
        throw Exception('Server Error: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =========================================================================
  // 4. MANUAL PROFILE DATA (To FastAPI Backend)
  // =========================================================================

  Future<bool> addMedicalHistory(String condition) async {
    final url = Uri.parse('$_baseUrl/profile/medical-history');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({"user_id": 1, "condition": condition}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error adding medical history: $e");
      return false;
    }
  }

  Future<bool> updateGoal(String goalType, double targetValue) async {
    final url = Uri.parse('$_baseUrl/profile/goals');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({"user_id": 1, "goal_type": goalType, "target_value": targetValue}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating goal: $e");
      return false;
    }
  }

  Future<bool> logManualVital(String type, double value, String unit) async {
    final url = Uri.parse('$_baseUrl/vitals/manual');
    try {
      final response = await http.post(
        url,
        headers: _authHeaders,
        body: jsonEncode({"user_id": 1, "type": type, "value": value, "unit": unit}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error logging vital: $e");
      return false;
    }
  }
}