import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_models.dart';

class ApiService {
  final String _baseUrl = "http://localhost:8000/api/v1"; // Replace with your actual backend URL

  Future<ClinicalAssessment> analyzeSymptoms(SymptomPayload payload) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      return ClinicalAssessment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to analyze symptoms');
    }
  }

  Future<HealthScore> calculateHealthScore(UserVitalsPayload payload) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/health-score'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload.toJson()),
    );

    if (response.statusCode == 200) {
      return HealthScore.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to calculate health score');
    }
  }
}
