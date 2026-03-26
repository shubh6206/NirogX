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
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  ApiService._internal();

  // =========================================================================
  // 1. FREE-FORM AI CHAT (Routed through FastAPI for RAG)
  // =========================================================================
  
  // --- UPDATED: Added history parameter ---
  Future<String> sendChatMessage(String prompt, {Uint8List? imageBytes, List<Map<String, String>> history = const []}) async {
    final uri = Uri.parse('$_baseUrl/chat');

    try {
      var request = http.MultipartRequest('POST', uri);
      
      // Add text fields
      request.fields['prompt'] = prompt;
      request.fields['user_id'] = '1'; // Hardcoded for testing

      // --- NEW: Attach the JSON encoded history ---
      request.fields['history'] = jsonEncode(history);

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

  // =========================================================================
  // 2. STRUCTURED SYMPTOM ANALYSIS (To FastAPI Backend - Used in providers)
  // =========================================================================

  Future<ClinicalAssessment> analyzeSymptoms(SymptomPayload payload) async {
    final url = Uri.parse('$_baseUrl/analyze');

    try {
      final response = await http.post(
        url,
        headers: _headers,
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
        headers: _headers,
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
}