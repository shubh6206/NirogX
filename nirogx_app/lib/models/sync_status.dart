import 'package:flutter/foundation.dart';

enum SyncState {
  idle,
  syncing,
  latestSynced,
  stale,
  permissionRequired,
  unavailable,
  error,
}

enum DataFreshness {
  realTime,
  latestSynced,
  syncing,
  stale,
  unavailable,
  insufficientData,
}

enum HealthDataSource {
  healthConnect,
  healthKit,
  galaxyWatch,
  appleWatch,
  pixelWatch,
  fitbit,
  garmin,
  manualEntry,
  aggregatedPlatform,
  unknown,
}

extension HealthDataSourceExtension on HealthDataSource {
  String get displayName {
    switch (this) {
      case HealthDataSource.healthConnect:
        return 'Android Health Connect';
      case HealthDataSource.healthKit:
        return 'Apple HealthKit';
      case HealthDataSource.galaxyWatch:
        return 'Samsung Galaxy Watch';
      case HealthDataSource.appleWatch:
        return 'Apple Watch';
      case HealthDataSource.pixelWatch:
        return 'Google Pixel Watch';
      case HealthDataSource.fitbit:
        return 'Fitbit Tracker';
      case HealthDataSource.garmin:
        return 'Garmin Connect';
      case HealthDataSource.manualEntry:
        return 'Manual Entry';
      case HealthDataSource.aggregatedPlatform:
        return 'Health Platform Aggregate';
      case HealthDataSource.unknown:
        return 'Connected Device';
    }
  }

  static HealthDataSource fromString(String? source) {
    if (source == null) return HealthDataSource.unknown;
    final lower = source.toLowerCase();
    if (lower.contains('galaxy') || lower.contains('samsung')) return HealthDataSource.galaxyWatch;
    if (lower.contains('apple watch')) return HealthDataSource.appleWatch;
    if (lower.contains('apple') || lower.contains('healthkit')) return HealthDataSource.healthKit;
    if (lower.contains('health connect') || lower.contains('google fit')) return HealthDataSource.healthConnect;
    if (lower.contains('pixel')) return HealthDataSource.pixelWatch;
    if (lower.contains('fitbit')) return HealthDataSource.fitbit;
    if (lower.contains('garmin')) return HealthDataSource.garmin;
    if (lower.contains('manual')) return HealthDataSource.manualEntry;
    return HealthDataSource.aggregatedPlatform;
  }
}

class SyncMetadata {
  final DateTime? lastSuccessfulSyncTimeUtc;
  final SyncState state;
  final String? lastError;
  final int totalRecordsImported;
  final int duplicatesSkipped;
  final bool isBackgroundSyncEnabled;

  const SyncMetadata({
    this.lastSuccessfulSyncTimeUtc,
    this.state = SyncState.idle,
    this.lastError,
    this.totalRecordsImported = 0,
    this.duplicatesSkipped = 0,
    this.isBackgroundSyncEnabled = true,
  });

  DataFreshness get dataFreshness {
    if (state == SyncState.permissionRequired || state == SyncState.unavailable) {
      return DataFreshness.unavailable;
    }
    if (state == SyncState.syncing) {
      return DataFreshness.syncing;
    }
    if (lastSuccessfulSyncTimeUtc == null) {
      return DataFreshness.insufficientData;
    }
    final difference = DateTime.now().toUtc().difference(lastSuccessfulSyncTimeUtc!);
    if (difference.inHours >= 4) {
      return DataFreshness.stale;
    }
    return DataFreshness.latestSynced;
  }

  String get formattedLastSyncTime {
    if (lastSuccessfulSyncTimeUtc == null) {
      return 'Never synchronized';
    }
    final localTime = lastSuccessfulSyncTimeUtc!.toLocal();
    final difference = DateTime.now().difference(localTime);
    if (difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr${difference.inHours > 1 ? "s" : ""} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? "s" : ""} ago';
    }
  }

  SyncMetadata copyWith({
    DateTime? lastSuccessfulSyncTimeUtc,
    SyncState? state,
    String? lastError,
    int? totalRecordsImported,
    int? duplicatesSkipped,
    bool? isBackgroundSyncEnabled,
  }) {
    return SyncMetadata(
      lastSuccessfulSyncTimeUtc: lastSuccessfulSyncTimeUtc ?? this.lastSuccessfulSyncTimeUtc,
      state: state ?? this.state,
      lastError: lastError,
      totalRecordsImported: totalRecordsImported ?? this.totalRecordsImported,
      duplicatesSkipped: duplicatesSkipped ?? this.duplicatesSkipped,
      isBackgroundSyncEnabled: isBackgroundSyncEnabled ?? this.isBackgroundSyncEnabled,
    );
  }
}
