// --- LOCAL DATABASE MODEL ---
class SymptomLog {
  final int? id;
  final String symptom;
  final int severity;
  final String analysis;
  final DateTime timestamp;

  SymptomLog({
    this.id,
    required this.symptom,
    required this.severity,
    required this.analysis,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symptom': symptom,
      'severity': severity,
      'analysis': analysis,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SymptomLog.fromMap(Map<String, dynamic> map) {
    return SymptomLog(
      id: map['id'],
      symptom: map['symptom'],
      severity: map['severity'],
      analysis: map['analysis'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

// --- NETWORK REQUEST MODEL ---
class SymptomPayload {
  final String text;
  final String duration;
  final String? userId;

  SymptomPayload({required this.text, required this.duration, this.userId});

  Map<String, dynamic> toJson() => {
        'text': text,
        'duration': duration,
        if (userId != null) 'user_id': userId,
      };
}

// --- NETWORK RESPONSE MODEL ---
class ClinicalAssessment {
  final String assessment;
  final List<String> redFlags;
  final double confidenceScore;

  ClinicalAssessment({
    required this.assessment,
    required this.redFlags,
    required this.confidenceScore,
  });

  factory ClinicalAssessment.fromJson(Map<String, dynamic> json) {
    return ClinicalAssessment(
      assessment: json['assessment'] ?? 'No assessment provided.',
      redFlags: List<String>.from(json['red_flags'] ?? []),
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
    );
  }
}