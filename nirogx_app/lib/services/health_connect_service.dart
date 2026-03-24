import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nirogx_app/services/health_sync_service.dart';

class HealthConnectService {
  final Health _health = Health();

  // The expanded list of essential health parameters
  final List<HealthDataType> _types = [
    HealthDataType.HEART_RATE,                 // Pulse Rate
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,    // BP (Upper)
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,   // BP (Lower)
    HealthDataType.RESPIRATORY_RATE,           // Respiration (Breaths per min)
    HealthDataType.BODY_TEMPERATURE,           // Body Temp
    HealthDataType.BLOOD_OXYGEN,               // SpO2
    HealthDataType.SLEEP_ASLEEP,               // Sleep Insights
    HealthDataType.SLEEP_AWAKE,                // Sleep Insights
    HealthDataType.STEPS,                      // Steps
  ];

  Future<bool> connectAndFetchData() async {
    try {
      // 1. Check permissions
      bool? hasPermissions = await _health.hasPermissions(_types);
      bool isAuthorized = hasPermissions ?? false;

      // 2. Request permissions
      if (!isAuthorized) {
        // Activity recognition is often required as a base permission on Android for steps
        await Permission.activityRecognition.request(); 
        
        try {
          isAuthorized = await _health.requestAuthorization(_types);
        } catch (e) {
          debugPrint("Exception in authorization: $e");
          return false;
        }
      }

      // 3. Fetch the data
      if (isAuthorized) {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1)); // Fetch last 24 hours

        try {
          List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
            types: _types,
            startTime: yesterday,
            endTime: now,
          );

          List<HealthDataPoint> cleanData = Health().removeDuplicates(healthData);

          // Print to console to verify the data is coming through
          for (var dataPoint in cleanData) {
            debugPrint("Type: ${dataPoint.typeString}");
            debugPrint("Value: ${dataPoint.value}");
            debugPrint("Unit: ${dataPoint.unitString}");
            debugPrint("Time: ${dataPoint.dateFrom} to ${dataPoint.dateTo}");
            debugPrint("-----------------------");
          }
          
          // 4. Sync to Backend
          final syncService = HealthSyncService();
          await syncService.formatAndSyncData(cleanData);
          
          return true; 

        } catch (e) {
          debugPrint("Caught exception in fetching data: $e");
          return false;
        }
      } else {
        debugPrint("Authorization not granted - user denied.");
        return false;
      }
    } catch (e) {
      debugPrint("Health Connect plugin error: $e");
      return false;
    }
  }
}
