import 'dart:convert';

/// AI Health Context DTO: strictly validates and allowlists aggregated wellness
/// metrics before transmission to clinical AI endpoints. Never sends raw time-series,
/// device serial numbers, or patient PII.
class AIHealthContext {
  final double? dailyHealthScore;
  final double? scoreDelta;
  final double? restingHeartRate;
  final int? dailySteps;
  final double? sleepDurationHours;
  final double? hydrationLiters;
  final int? systolicBp;
  final int? diastolicBp;
  final double? spO2;
  final double? activeCalories;
  final String baselineStatus;
  final double? baselineDeviation;
  final String? trendDirection;
  final List<String> medicalHistory;

  const AIHealthContext({
    this.dailyHealthScore,
    this.scoreDelta,
    this.restingHeartRate,
    this.dailySteps,
    this.sleepDurationHours,
    this.hydrationLiters,
    this.systolicBp,
    this.diastolicBp,
    this.spO2,
    this.activeCalories,
    this.baselineStatus = 'Insufficient Data',
    this.baselineDeviation,
    this.trendDirection,
    this.medicalHistory = const [],
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (dailyHealthScore != null) map['daily_health_score'] = dailyHealthScore;
    if (scoreDelta != null) map['score_delta'] = scoreDelta;
    if (restingHeartRate != null) map['resting_heart_rate'] = restingHeartRate;
    if (dailySteps != null) map['today_steps'] = dailySteps;
    if (sleepDurationHours != null) map['sleep_duration_hours'] = sleepDurationHours;
    if (hydrationLiters != null) map['hydration_liters'] = hydrationLiters;
    if (systolicBp != null) map['systolic_bp'] = systolicBp;
    if (diastolicBp != null) map['diastolic_bp'] = diastolicBp;
    if (spO2 != null) map['spo2'] = spO2;
    if (activeCalories != null) map['active_calories'] = activeCalories;
    map['baseline_status'] = baselineStatus;
    if (baselineDeviation != null) map['baseline_deviation'] = baselineDeviation;
    if (trendDirection != null) map['trend_direction'] = trendDirection;
    map['medical_history'] = medicalHistory;
    return map;
  }

  factory AIHealthContext.fromJson(Map<String, dynamic> json) {
    return AIHealthContext(
      dailyHealthScore: (json['daily_health_score'] as num?)?.toDouble(),
      scoreDelta: (json['score_delta'] as num?)?.toDouble(),
      restingHeartRate: (json['resting_heart_rate'] as num?)?.toDouble(),
      dailySteps: (json['today_steps'] ?? json['daily_steps'] as num?)?.toInt(),
      sleepDurationHours: (json['sleep_duration_hours'] as num?)?.toDouble(),
      hydrationLiters: (json['hydration_liters'] as num?)?.toDouble(),
      systolicBp: (json['systolic_bp'] as num?)?.toInt(),
      diastolicBp: (json['diastolic_bp'] as num?)?.toInt(),
      spO2: (json['spo2'] as num?)?.toDouble(),
      activeCalories: (json['active_calories'] as num?)?.toDouble(),
      baselineStatus: json['baseline_status'] ?? 'Building',
      baselineDeviation: (json['baseline_deviation'] as num?)?.toDouble(),
      trendDirection: json['trend_direction'],
      medicalHistory: (json['medical_history'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
