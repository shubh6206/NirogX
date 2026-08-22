import 'dart:convert';
import 'package:crypto/crypto.dart';

enum VitalMetricType {
  heartRate,
  restingHeartRate,
  spO2,
  bloodPressure,
  sleep,
  steps,
  activeCalories,
  totalCalories,
  hydration,
  distance,
  weight,
}

extension VitalMetricTypeExtension on VitalMetricType {
  String get keyName {
    switch (this) {
      case VitalMetricType.heartRate:
        return 'heart_rate';
      case VitalMetricType.restingHeartRate:
        return 'resting_heart_rate';
      case VitalMetricType.spO2:
        return 'SpO2';
      case VitalMetricType.bloodPressure:
        return 'blood_pressure';
      case VitalMetricType.sleep:
        return 'sleep';
      case VitalMetricType.steps:
        return 'steps';
      case VitalMetricType.activeCalories:
        return 'active_calories';
      case VitalMetricType.totalCalories:
        return 'total_calories';
      case VitalMetricType.hydration:
        return 'hydration';
      case VitalMetricType.distance:
        return 'distance';
      case VitalMetricType.weight:
        return 'weight';
    }
  }

  String get displayName {
    switch (this) {
      case VitalMetricType.heartRate:
        return 'Heart Rate';
      case VitalMetricType.restingHeartRate:
        return 'Resting Heart Rate';
      case VitalMetricType.spO2:
        return 'Blood Oxygen (SpO2)';
      case VitalMetricType.bloodPressure:
        return 'Blood Pressure';
      case VitalMetricType.sleep:
        return 'Sleep Duration';
      case VitalMetricType.steps:
        return 'Daily Steps';
      case VitalMetricType.activeCalories:
        return 'Active Calories';
      case VitalMetricType.totalCalories:
        return 'Total Calories';
      case VitalMetricType.hydration:
        return 'Hydration Volume';
      case VitalMetricType.distance:
        return 'Walking Distance';
      case VitalMetricType.weight:
        return 'Body Weight';
    }
  }

  String get canonicalUnit {
    switch (this) {
      case VitalMetricType.heartRate:
      case VitalMetricType.restingHeartRate:
        return 'bpm';
      case VitalMetricType.spO2:
        return '%';
      case VitalMetricType.bloodPressure:
        return 'mmHg';
      case VitalMetricType.sleep:
        return 'minutes';
      case VitalMetricType.steps:
        return 'steps';
      case VitalMetricType.activeCalories:
      case VitalMetricType.totalCalories:
        return 'kcal';
      case VitalMetricType.hydration:
        return 'mL';
      case VitalMetricType.distance:
        return 'meters';
      case VitalMetricType.weight:
        return 'kg';
    }
  }

  static VitalMetricType fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'heart_rate':
      case 'heartrate':
        return VitalMetricType.heartRate;
      case 'resting_heart_rate':
      case 'restingheartrate':
        return VitalMetricType.restingHeartRate;
      case 'spo2':
      case 'blood_oxygen':
        return VitalMetricType.spO2;
      case 'blood_pressure':
      case 'bloodpressure':
        return VitalMetricType.bloodPressure;
      case 'sleep':
        return VitalMetricType.sleep;
      case 'steps':
        return VitalMetricType.steps;
      case 'active_calories':
      case 'activecalories':
        return VitalMetricType.activeCalories;
      case 'total_calories':
      case 'totalcalories':
        return VitalMetricType.totalCalories;
      case 'hydration':
      case 'water':
        return VitalMetricType.hydration;
      case 'distance':
        return VitalMetricType.distance;
      case 'weight':
        return VitalMetricType.weight;
      default:
        return VitalMetricType.heartRate;
    }
  }
}

class VitalRecord {
  final String id;
  final String platform; // 'health_connect', 'healthkit', 'manual'
  final String? nativeRecordId;
  final VitalMetricType metricType;
  final double value;
  final double? valueSecondary; // e.g. diastolic BP
  final String unit;
  final DateTime startTimeUtc;
  final DateTime endTimeUtc;
  final String sourceId;
  final String sourceName;
  final String? deviceId;
  final String? deviceName;
  final bool isAggregate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final String contentHash;

  VitalRecord({
    String? id,
    String? platform,
    this.nativeRecordId,
    required this.metricType,
    required this.value,
    this.valueSecondary,
    String? unit,
    required DateTime startTime,
    DateTime? endTime,
    String? sourceId,
    String? sourceName,
    this.deviceId,
    this.deviceName,
    this.isAggregate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.metadata = const {},
    String? contentHash,
  })  : platform = platform ?? (sourceName?.toLowerCase().contains('apple') == true ? 'healthkit' : 'health_connect'),
        startTimeUtc = startTime.toUtc(),
        endTimeUtc = (endTime ?? startTime).toUtc(),
        unit = unit ?? metricType.canonicalUnit,
        sourceId = sourceId ?? (sourceName ?? 'manual'),
        sourceName = sourceName ?? 'Health Platform',
        createdAt = (createdAt ?? DateTime.now()).toUtc(),
        updatedAt = (updatedAt ?? DateTime.now()).toUtc(),
        contentHash = contentHash ??
            _calculateContentHash(
              metricType: metricType,
              startTimeUtc: startTime.toUtc(),
              endTimeUtc: (endTime ?? startTime).toUtc(),
              value: value,
              valueSecondary: valueSecondary,
              sourceId: sourceId ?? sourceName ?? 'manual',
              deviceId: deviceId,
            ),
        id = id ??
            _generateId(
              platform: platform ?? 'health_platform',
              nativeRecordId: nativeRecordId,
              metricType: metricType,
              startTimeUtc: startTime.toUtc(),
              endTimeUtc: (endTime ?? startTime).toUtc(),
              value: value,
              valueSecondary: valueSecondary,
              sourceId: sourceId ?? sourceName ?? 'manual',
              deviceId: deviceId,
            );

  static String _calculateContentHash({
    required VitalMetricType metricType,
    required DateTime startTimeUtc,
    required DateTime endTimeUtc,
    required double value,
    double? valueSecondary,
    required String sourceId,
    String? deviceId,
  }) {
    final raw = '${metricType.keyName}|${startTimeUtc.millisecondsSinceEpoch}|${endTimeUtc.millisecondsSinceEpoch}|'
        '${value.toStringAsFixed(3)}|${valueSecondary?.toStringAsFixed(3) ?? ""}|${sourceId.trim()}|${deviceId?.trim() ?? ""}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  static String _generateId({
    required String platform,
    String? nativeRecordId,
    required VitalMetricType metricType,
    required DateTime startTimeUtc,
    required DateTime endTimeUtc,
    required double value,
    double? valueSecondary,
    required String sourceId,
    String? deviceId,
  }) {
    if (nativeRecordId != null && nativeRecordId.isNotEmpty) {
      final key = '${platform}_${nativeRecordId}_${metricType.keyName}';
      return sha256.convert(utf8.encode(key)).toString().substring(0, 32);
    }
    final raw = '${platform}_${metricType.keyName}_${startTimeUtc.millisecondsSinceEpoch}_'
        '${endTimeUtc.millisecondsSinceEpoch}_${value.toStringAsFixed(2)}_${sourceId}_${deviceId ?? "nodevice"}';
    return sha256.convert(utf8.encode(raw)).toString().substring(0, 32);
  }

  String get type => metricType.keyName;
  String get source => sourceName;
  DateTime get timestamp => startTimeUtc.toLocal();

  factory VitalRecord.fromJson(Map<String, dynamic> json) {
    return VitalRecord(
      id: json['id'],
      platform: json['platform'] ?? 'health_platform',
      nativeRecordId: json['native_record_id'],
      metricType: VitalMetricTypeExtension.fromKey(json['type'] ?? json['metric_type'] ?? 'heart_rate'),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      valueSecondary: (json['value_secondary'] as num?)?.toDouble(),
      unit: json['unit'],
      startTime: DateTime.parse(json['start_time_utc'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()),
      endTime: json['end_time_utc'] != null ? DateTime.parse(json['end_time_utc']) : null,
      sourceId: json['source_id'],
      sourceName: json['source_name'] ?? json['source'] ?? 'Health Platform',
      deviceId: json['device_id'] ?? json['source_device_id'],
      deviceName: json['device_name'],
      isAggregate: json['is_aggregate'] is int ? (json['is_aggregate'] == 1) : (json['is_aggregate'] ?? false),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      metadata: json['metadata_json'] != null
          ? (json['metadata_json'] is String ? jsonDecode(json['metadata_json']) : Map<String, dynamic>.from(json['metadata_json']))
          : (json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : {}),
      contentHash: json['content_hash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'native_record_id': nativeRecordId,
      'metric_type': metricType.keyName,
      'type': metricType.keyName,
      'value': value,
      'value_secondary': valueSecondary,
      'unit': unit,
      'start_time_utc': startTimeUtc.toIso8601String(),
      'end_time_utc': endTimeUtc.toIso8601String(),
      'source_id': sourceId,
      'source_name': sourceName,
      'source': sourceName,
      'device_id': deviceId,
      'device_name': deviceName,
      'is_aggregate': isAggregate ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata_json': jsonEncode(metadata),
      'content_hash': contentHash,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'platform': platform,
      'native_record_id': nativeRecordId,
      'metric_type': metricType.keyName,
      'value': value,
      'value_secondary': valueSecondary,
      'unit': unit,
      'start_time_utc': startTimeUtc.toIso8601String(),
      'end_time_utc': endTimeUtc.toIso8601String(),
      'source_id': sourceId,
      'source_name': sourceName,
      'device_id': deviceId,
      'device_name': deviceName,
      'is_aggregate': isAggregate ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata_json': jsonEncode(metadata),
      'content_hash': contentHash,
    };
  }
}

class BloodPressureRecord {
  final String id;
  final int systolic;
  final int diastolic;
  final int? pulse;
  final String source;
  final DateTime timestampUtc;

  BloodPressureRecord({
    String? id,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    this.source = 'Manual Entry',
    DateTime? timestamp,
  })  : timestampUtc = (timestamp ?? DateTime.now()).toUtc(),
        id = id ??
            sha256
                .convert(utf8.encode(
                    'bp_${(timestamp ?? DateTime.now()).toUtc().millisecondsSinceEpoch}_${systolic}_${diastolic}'))
                .toString()
                .substring(0, 16);

  DateTime get timestamp => timestampUtc.toLocal();

  factory BloodPressureRecord.fromJson(Map<String, dynamic> json) {
    return BloodPressureRecord(
      id: json['id'],
      systolic: json['systolic'] ?? 120,
      diastolic: json['diastolic'] ?? 80,
      pulse: json['pulse'],
      source: json['source'] ?? 'Manual Entry',
      timestamp: json['timestamp_utc'] != null
          ? DateTime.parse(json['timestamp_utc'])
          : json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'source': source,
      'timestamp_utc': timestampUtc.toIso8601String(),
    };
  }
}
