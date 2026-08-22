import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../models/vital_model.dart';
import '../models/sync_status.dart';
import 'local_health_db.dart';
import 'telemetry_service.dart';

/// Production Health Synchronization Engine
/// Handles Android Health Connect & Apple HealthKit with transactional cursor safety,
/// interval deduplication, multi-device resolution, and canonical unit conversion.
class HealthSyncService {
  final Health _health = Health();
  final LocalHealthDatabase _db;
  final TelemetryService _telemetry = TelemetryService();

  HealthSyncService([LocalHealthDatabase? db]) : _db = db ?? LocalHealthDatabase();

  static const List<HealthDataType> _monitoredTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.WATER,
  ];

  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  /// Verifies platform availability and requests granular permissions
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      await _health.configure();

      final bool isAvailable = await _health.isHealthDataAvailable();
      if (!isAvailable) {
        _telemetry.logEvent('health_platform_unavailable');
        return false;
      }

      final bool authorized = await _health.requestAuthorization(
        _monitoredTypes,
        permissions: _permissions,
      );

      final platformStr = Platform.isAndroid ? 'health_connect' : 'healthkit';
      _telemetry.logPermissionChanged(platform: platformStr, granted: authorized);

      return authorized;
    } catch (e) {
      _telemetry.logSyncFailed(
        platform: kIsWeb ? 'web' : (Platform.isAndroid ? 'health_connect' : 'healthkit'),
        errorCode: 'PERMISSION_REQUEST_EXCEPTION',
      );
      return false;
    }
  }

  /// Checks if permissions are currently active
  Future<bool> hasActivePermissions() async {
    if (kIsWeb) return false;
    try {
      final bool? hasPerms = await _health.hasPermissions(
        _monitoredTypes,
        permissions: _permissions,
      );
      return hasPerms ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Performs robust transactional incremental synchronization
  /// CRITICAL: Advances cursor ONLY after local database transaction completes!
  Future<SyncMetadata> performIncrementalSync() async {
    final startTime = DateTime.now();
    final platformKey = kIsWeb ? 'web' : (Platform.isAndroid ? 'health_connect' : 'healthkit');
    final platformDisplayName = Platform.isAndroid ? 'Android Health Connect' : 'Apple HealthKit';
    await _db.init();

    final lastCursor = await _db.getLastSuccessfulSyncTime(platformKey);
    final changeToken = await _db.getChangeToken(platformKey);

    _telemetry.logSyncStarted(
      platform: platformDisplayName,
      isIncremental: lastCursor != null,
    );

    if (kIsWeb) {
      // In web preview environment, check database records
      return SyncMetadata(
        lastSuccessfulSyncTimeUtc: lastCursor ?? DateTime.now().toUtc(),
        state: SyncState.latestSynced,
        totalRecordsImported: 0,
        duplicatesSkipped: 0,
      );
    }

    try {
      final hasPerm = await hasActivePermissions();
      if (!hasPerm) {
        return const SyncMetadata(
          state: SyncState.permissionRequired,
          lastError: 'Health data permissions are required for synchronization.',
        );
      }

      final DateTime syncStartTime = DateTime.now().toUtc();
      // Incremental with 15-minute overlap window to capture delayed sync writes
      final DateTime fetchFrom = lastCursor != null
          ? lastCursor.subtract(const Duration(minutes: 15))
          : syncStartTime.subtract(const Duration(days: 7));

      // Fetch raw data points from native health platform
      final List<HealthDataPoint> rawData = await _health.getHealthDataFromTypes(
        types: _monitoredTypes,
        startTime: fetchFrom.toLocal(),
        endTime: syncStartTime.toLocal(),
      );

      // Extract and normalize records
      final List<VitalRecord> normalizedRecords = _normalizeAndDeduplicate(rawData, platformKey, platformDisplayName);

      // Perform multi-device resolution for overlapping interval metrics
      final List<VitalRecord> processedRecords = _resolveMultiDeviceIntervals(normalizedRecords);

      // Insert transactionally into SQLite database
      final int insertedCount = await _db.insertRecordsTransactional(
        processedRecords,
        platform: platformKey,
        newCursorUtc: syncStartTime,
        changeToken: changeToken,
      );

      final int duplicates = processedRecords.length - insertedCount;
      final int durationMs = DateTime.now().difference(startTime).inMilliseconds;

      _telemetry.logSyncCompleted(
        platform: platformDisplayName,
        recordsImported: insertedCount,
        duplicatesSkipped: duplicates >= 0 ? duplicates : 0,
        durationMs: durationMs,
      );

      return SyncMetadata(
        lastSuccessfulSyncTimeUtc: syncStartTime,
        state: SyncState.latestSynced,
        totalRecordsImported: insertedCount,
        duplicatesSkipped: duplicates >= 0 ? duplicates : 0,
      );
    } catch (e) {
      await _db.updateSyncError(platformKey, 'SYNC_EXECUTION_ERROR');
      _telemetry.logSyncFailed(
        platform: platformDisplayName,
        errorCode: 'SYNC_EXECUTION_ERROR',
      );
      return SyncMetadata(
        lastSuccessfulSyncTimeUtc: lastCursor,
        state: SyncState.error,
        lastError: 'Synchronization failed. Please retry.',
      );
    }
  }

  /// Normalizes heterogeneous HealthDataPoint objects into canonical VitalRecord representations
  List<VitalRecord> _normalizeAndDeduplicate(List<HealthDataPoint> points, String platformKey, String defaultPlatformName) {
    final List<VitalRecord> records = [];

    for (var point in points) {
      try {
        final extracted = _extractValueAndType(point);
        if (extracted == null) continue;

        final VitalMetricType metric = extracted['metric'] as VitalMetricType;
        final double numericVal = extracted['value'] as double;
        final String unit = extracted['unit'] as String;
        final String sourceAttribution = point.sourceName.isNotEmpty ? point.sourceName : defaultPlatformName;

        records.add(VitalRecord(
          platform: platformKey,
          nativeRecordId: point.uuid.isNotEmpty ? point.uuid : null,
          metricType: metric,
          value: numericVal,
          unit: unit,
          sourceId: point.sourceId.isNotEmpty ? point.sourceId : point.sourceName,
          sourceName: sourceAttribution,
          deviceId: point.sourceDeviceId.isNotEmpty ? point.sourceDeviceId : null,
          startTime: point.dateFrom,
          endTime: point.dateTo,
          isAggregate: metric == VitalMetricType.steps || metric == VitalMetricType.activeCalories,
        ));
      } catch (e) {
        // Skip corrupt record
      }
    }

    return records;
  }

  Map<String, dynamic>? _extractValueAndType(HealthDataPoint point) {
    double val = 0.0;
    final dynamic rawVal = point.value;

    if (rawVal is NumericHealthValue) {
      val = rawVal.numericValue.toDouble();
    } else {
      val = double.tryParse(rawVal.toString()) ?? 0.0;
    }

    switch (point.type) {
      case HealthDataType.STEPS:
        return {'metric': VitalMetricType.steps, 'value': val, 'unit': 'steps'};
      case HealthDataType.HEART_RATE:
        return {'metric': VitalMetricType.heartRate, 'value': val, 'unit': 'bpm'};
      case HealthDataType.RESTING_HEART_RATE:
        return {'metric': VitalMetricType.restingHeartRate, 'value': val, 'unit': 'bpm'};
      case HealthDataType.SLEEP_SESSION:
      case HealthDataType.SLEEP_ASLEEP:
      case HealthDataType.SLEEP_DEEP:
      case HealthDataType.SLEEP_REM:
        // Handle sleep sessions correctly including cross-midnight durations
        final durationMinutes = point.dateTo.difference(point.dateFrom).inMinutes.toDouble();
        return {'metric': VitalMetricType.sleep, 'value': durationMinutes > 0 ? durationMinutes : val, 'unit': 'minutes'};
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return {'metric': VitalMetricType.activeCalories, 'value': val, 'unit': 'kcal'};
      case HealthDataType.BLOOD_OXYGEN:
        // SpO2 percentage normalization (0.98 -> 98.0)
        final normalizedSpO2 = val <= 1.0 ? val * 100.0 : val;
        return {'metric': VitalMetricType.spO2, 'value': normalizedSpO2, 'unit': '%'};
      case HealthDataType.WATER:
        // Canonical unit is Milliliters (mL). If logged in Liters (<= 10), convert to mL
        final canonicalMl = val <= 10.0 ? val * 1000.0 : val;
        return {'metric': VitalMetricType.hydration, 'value': canonicalMl, 'unit': 'mL'};
      default:
        return null;
    }
  }

  /// Multi-Device Resolution Strategy for Interval Metrics
  /// Prevents double counting steps/calories when both phone and wearable record the same time slot
  List<VitalRecord> _resolveMultiDeviceIntervals(List<VitalRecord> rawList) {
    final Map<String, VitalRecord> dedupedIntervals = {};
    final List<VitalRecord> instantaneousRecords = [];

    for (var r in rawList) {
      // Preserve individual high-frequency biometric samples (Heart rate, SpO2)
      if (r.metricType == VitalMetricType.heartRate ||
          r.metricType == VitalMetricType.restingHeartRate ||
          r.metricType == VitalMetricType.spO2 ||
          r.metricType == VitalMetricType.hydration) {
        instantaneousRecords.add(r);
        continue;
      }

      // Interval metrics (Steps, Active Calories, Sleep)
      final intervalKey = '${r.metricType.keyName}_${r.startTimeUtc.year}_${r.startTimeUtc.month}_${r.startTimeUtc.day}_${r.startTimeUtc.hour}_${r.startTimeUtc.minute}';

      if (!dedupedIntervals.containsKey(intervalKey)) {
        dedupedIntervals[intervalKey] = r;
      } else {
        final existing = dedupedIntervals[intervalKey]!;
        // Prefer dedicated watch/wearable hardware over phone accelerometer
        final isNewWearable = r.sourceName.toLowerCase().contains('watch') || r.sourceName.toLowerCase().contains('garmin');
        final isOldWearable = existing.sourceName.toLowerCase().contains('watch') || existing.sourceName.toLowerCase().contains('garmin');

        if (isNewWearable && !isOldWearable) {
          dedupedIntervals[intervalKey] = r;
        }
      }
    }

    return [...instantaneousRecords, ...dedupedIntervals.values];
  }
}
