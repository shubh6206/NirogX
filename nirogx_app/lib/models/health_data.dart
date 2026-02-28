// --- LOCAL DATABASE MODEL ---
class HealthData {
  final int? id;
  final int score;
  final String insightText;
  final DateTime date;

  HealthData({
    this.id,
    required this.score,
    required this.insightText,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'score': score,
      'insight_text': insightText,
      'date': date.toIso8601String(),
    };
  }

  factory HealthData.fromMap(Map<String, dynamic> map) {
    return HealthData(
      id: map['id'],
      score: map['score'],
      insightText: map['insight_text'],
      date: DateTime.parse(map['date']),
    );
  }
}

// --- NETWORK REQUEST MODEL ---
class UserVitalsPayload {
  final int age;
  final double bmi;
  final int heartRate;
  final double sleepHours;
  final String activityLevel;

  UserVitalsPayload({
    required this.age,
    required this.bmi,
    required this.heartRate,
    required this.sleepHours,
    required this.activityLevel,
  });

  Map<String, dynamic> toJson() => {
        'age': age,
        'bmi': bmi,
        'heart_rate': heartRate,
        'sleep_hours': sleepHours,
        'activity_level': activityLevel,
      };
}

// --- NETWORK RESPONSE MODEL ---
class HealthScoreResult {
  final double score;
  final String status;

  HealthScoreResult({required this.score, required this.status});

  factory HealthScoreResult.fromJson(Map<String, dynamic> json) {
    return HealthScoreResult(
      score: (json['score'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'unknown',
    );
  }
}