import 'package:nirogx_app/models/health_data.dart';
import 'package:nirogx_app/models/symptom_log.dart';
import 'package:nirogx_app/data/database_helper.dart';

class HealthRepository {
  static final HealthRepository _instance = HealthRepository._internal();
  factory HealthRepository() => _instance;
  HealthRepository._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // FIX: Name this 'getLatestHealthData' to match HealthDataProvider
  Future<HealthData?> getLatestHealthData() async {
    return await _dbHelper.getLatestHealthData();
  }

  // This supports the Home Screen widget call
  Future<HealthData> getLatestHealthStatus() async {
    final data = await getLatestHealthData();
    return data ?? HealthData(score: 0, insightText: "No data", date: DateTime.now());
  }

  // FIX: Name these to match SymptomProvider
  Future<void> saveSymptomReport(SymptomLog log) async {
    await _dbHelper.saveSymptomLog(log);
  }

  Future<List<SymptomLog>> getAllSymptomLogs() async {
    return await _dbHelper.getAllSymptomLogs();
  }

  Future<void> saveHealthData(HealthData data) async {
    await _dbHelper.saveHealthData(data);
  }
}