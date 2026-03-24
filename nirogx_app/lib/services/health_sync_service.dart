import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:health/health.dart';

class HealthSyncService {
  final String _apiUrl = 'http://10.0.2.2:8000/api/vitals/sync'; // Using 10.0.2.2 for Android Emulator to access localhost

  Future<void> formatAndSyncData(List<HealthDataPoint> rawData) async {
    List<Map<String, dynamic>> standardVitals = [];
    List<Map<String, dynamic>> sleepSessions = [];
    
    // Temporary map to group BP readings by their exact timestamp
    Map<String, Map<String, dynamic>> bpReadings = {};

    for (var point in rawData) {
      // Safely extract the numeric value
      double value = 0.0;
      if (point.value is NumericHealthValue) {
        value = (point.value as NumericHealthValue).numericValue.toDouble();
      }

      String type = point.typeString;
      String timestamp = point.dateFrom.toUtc().toIso8601String();

      // 1. Handle Sleep (Duration based)
      if (type.contains("SLEEP")) {
        int durationMins = point.dateTo.difference(point.dateFrom).inMinutes;
        sleepSessions.add({
          "stage": type,
          "duration_minutes": durationMins,
          "start_time": timestamp,
          "end_time": point.dateTo.toUtc().toIso8601String(),
        });
      } 
      // 2. Handle Blood Pressure (Needs pairing)
      else if (type.contains("BLOOD_PRESSURE")) {
        bpReadings.putIfAbsent(timestamp, () => {"recorded_at": timestamp});
        
        if (type == "BLOOD_PRESSURE_SYSTOLIC") {
          bpReadings[timestamp]!["systolic"] = value;
        } else if (type == "BLOOD_PRESSURE_DIASTOLIC") {
          bpReadings[timestamp]!["diastolic"] = value;
        }
      } 
      // 3. Handle Standard Vitals (Heart rate, SpO2, Temp, Respiration)
      else {
        standardVitals.add({
          "type": type,
          "value": value,
          "unit": point.unitString,
          "recorded_at": timestamp,
        });
      }
    }

    // Filter out incomplete BP readings (e.g., missing systolic or diastolic)
    List<Map<String, dynamic>> validBpReadings = bpReadings.values
        .where((bp) => bp.containsKey('systolic') && bp.containsKey('diastolic'))
        .toList();

    // Construct the final payload
    final Map<String, dynamic> payload = {
      "sync_timestamp": DateTime.now().toUtc().toIso8601String(),
      "device_os": "android",
      "vitals": standardVitals,
      "blood_pressure": validBpReadings,
      "sleep_sessions": sleepSessions,
    };

    // Send to FastAPI
    debugPrint("Syncing health data to backend...");
    await _sendToBackend(payload);
  }

  Future<void> _sendToBackend(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer YOUR_TOKEN'
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint("Data synced successfully: ${response.body}");
      } else {
        debugPrint("Sync failed with status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      debugPrint("Network error during sync: $e");
    }
  }
}
