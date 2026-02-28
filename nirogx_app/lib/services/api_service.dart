// lib/services/api_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Adjust these imports based on your actual models
import 'package:nirogx_app/models/symptom_log.dart';
import 'package:nirogx_app/models/health_data.dart';

class ApiService {
  // Singleton Pattern: Ensures we only initialize the AI model once
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final GenerativeModel _chatModel;
  
  // Backend URL (Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS)
  static const String _baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  ApiService._internal() {
    // 1. Load the key securely
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('CRITICAL: GEMINI_API_KEY is missing from .env file.');
    }

    // 2. Initialize the Chat Model with a strict Medical Persona
    _chatModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        "You are NirogX, an AI medical assistant. Your job is to analyze user queries, "
        "symptoms, and medical images (like prescriptions or reports). "
        "Provide helpful, empathetic, and factual preliminary information. "
        "CRITICAL: Always include a disclaimer that you are an AI and the user "
        "must consult a certified doctor for an official diagnosis."
      ),
    );
  }

  // =========================================================================
  // 1. FREE-FORM AI CHAT (Direct to Gemini API - Used in ai_chat_screen.dart)
  // =========================================================================
  
  Future<String> sendChatMessage(String prompt, {Uint8List? imageBytes}) async {
    try {
      final content = imageBytes != null
          ? [Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])]
          : [Content.text(prompt)];

      final response = await _chatModel.generateContent(content);
      return response.text?.trim() ?? "No response generated.";
      
    } catch (e) {
      return "AI Connection Error: Please check your network. Details: $e";
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