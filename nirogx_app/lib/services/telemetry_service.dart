import 'package:flutter/foundation.dart';

/// Production telemetry service that enforces privacy guarantees.
/// PRIVACY INVARIANT:
/// - Never logs or sends raw health metrics (heart rate values, step counts, sleep durations, BP, PII).
/// - Tracks only operational lifecycle events (sync_started, sync_completed, count_imported, error_code).
class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  TelemetryService._internal();

  final List<Map<String, dynamic>> _operationalEvents = [];

  void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    final sanitizedParams = <String, dynamic>{};

    if (parameters != null) {
      parameters.forEach((key, value) {
        // Block sensitive keys from ever entering logs
        final lower = key.toLowerCase();
        if (lower.contains('heart') ||
            lower.contains('step') ||
            lower.contains('sleep') ||
            lower.contains('spo2') ||
            lower.contains('bp') ||
            lower.contains('blood') ||
            lower.contains('water') ||
            lower.contains('email') ||
            lower.contains('name') ||
            lower.contains('password')) {
          return; // omit
        }
        sanitizedParams[key] = value;
      });
    }

    final entry = {
      'event': eventName,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'params': sanitizedParams,
    };

    _operationalEvents.add(entry);

    // Bounded in-memory telemetry buffer
    if (_operationalEvents.length > 200) {
      _operationalEvents.removeRange(0, 50);
    }

    if (kDebugMode) {
      // Safe debug print showing only event name and non-sensitive metadata
      debugPrint('[Telemetry] $eventName: $sanitizedParams');
    }
  }

  void logSyncStarted({required String platform, required bool isIncremental}) {
    logEvent('sync_started', parameters: {
      'platform': platform,
      'is_incremental': isIncremental,
    });
  }

  void logSyncCompleted({
    required String platform,
    required int recordsImported,
    required int duplicatesSkipped,
    required int durationMs,
  }) {
    logEvent('sync_completed', parameters: {
      'platform': platform,
      'records_count': recordsImported,
      'duplicates_skipped': duplicatesSkipped,
      'duration_ms': durationMs,
    });
  }

  void logSyncFailed({required String platform, required String errorCode}) {
    logEvent('sync_failed', parameters: {
      'platform': platform,
      'error_code': errorCode,
    });
  }

  void logPermissionChanged({required String platform, required bool granted}) {
    logEvent('permission_status_changed', parameters: {
      'platform': platform,
      'granted': granted,
    });
  }

  List<Map<String, dynamic>> getOperationalAuditLog() => List.unmodifiable(_operationalEvents);
}
