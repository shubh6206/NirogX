import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/vital_model.dart';
import '../models/health_score_model.dart';

class ApiService {
  // Configurable base URL: Android emulator uses 10.0.2.2, iOS uses localhost
  static String baseUrl = 'http://10.0.2.2:3000/api';
  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _authToken = data['access_token'];
      return data;
    }
    throw Exception('Login failed: ${res.body}');
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _authToken = data['access_token'];
      return data;
    }
    throw Exception('Registration failed: ${res.body}');
  }

  // Health Score
  static Future<HealthScoreResult> calculateHealthScore(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$baseUrl/health-score'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (res.statusCode == 200) {
      return HealthScoreResult.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to calculate health score: ${res.body}');
  }

  // Symptom Analysis
  static Future<Map<String, dynamic>> analyzeSymptoms(String symptoms, Map<String, dynamic>? context) async {
    final res = await http.post(
      Uri.parse('$baseUrl/analyze-symptoms'),
      headers: _headers,
      body: jsonEncode({'symptoms': symptoms, 'patient_context': context}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Symptom analysis failed: ${res.body}');
  }

  // AI Chat
  static Future<String> sendChatMessage(List<Map<String, String>> messages, Map<String, dynamic>? vitalsContext) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: _headers,
      body: jsonEncode({'messages': messages, 'vitals_context': vitalsContext}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['content'] ?? '';
    }
    throw Exception('Chat request failed: ${res.body}');
  }

  // Vitals Logging
  static Future<void> logVital(VitalRecord record) async {
    await http.post(
      Uri.parse('$baseUrl/vitals'),
      headers: _headers,
      body: jsonEncode(record.toJson()),
    );
  }
}
