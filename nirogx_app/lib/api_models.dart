class SymptomPayload {
  final String text;
  final String duration;

  SymptomPayload({required this.text, required this.duration});

  Map<String, dynamic> toJson() => {
        'text': text,
        'duration': duration,
      };
}

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

class ClinicalAssessment {
  final String assessment;

  ClinicalAssessment({required this.assessment});

  factory ClinicalAssessment.fromJson(Map<String, dynamic> json) {
    return ClinicalAssessment(assessment: json['assessment']);
  }
}

class HealthScore {
  final double score;

  HealthScore({required this.score});

  factory HealthScore.fromJson(Map<String, dynamic> json) {
    return HealthScore(score: json['score']);
  }
}

class AnalysisHistory {
  final SymptomPayload symptomPayload;
  final ClinicalAssessment clinicalAssessment;

  AnalysisHistory({required this.symptomPayload, required this.clinicalAssessment});

  factory AnalysisHistory.fromJson(Map<String, dynamic> json) {
    return AnalysisHistory(
      symptomPayload: SymptomPayload.fromJson(json['symptom_payload']),
      clinicalAssessment: ClinicalAssessment.fromJson(json['clinical_assessment']),
    );
  }
}
