class HealthScoreComponent {
  final double score; // 0 - 100
  final double rawWeight; // e.g. 0.25
  final double normalizedWeight; // dynamically adjusted if other pillars are missing
  final bool isAvailable;
  final String label;
  final String currentDisplay;
  final String benchmarkDisplay;
  final String status; // optimal, good, needs_attention, unavailable
  final String categoryKey;

  const HealthScoreComponent({
    required this.score,
    required this.rawWeight,
    required this.normalizedWeight,
    required this.isAvailable,
    required this.label,
    required this.currentDisplay,
    required this.benchmarkDisplay,
    required this.status,
    required this.categoryKey,
  });

  factory HealthScoreComponent.fromJson(Map<String, dynamic> json) {
    return HealthScoreComponent(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      rawWeight: (json['rawWeight'] as num?)?.toDouble() ?? 0.2,
      normalizedWeight: (json['normalizedWeight'] as num?)?.toDouble() ?? 0.2,
      isAvailable: json['isAvailable'] ?? true,
      label: json['label'] ?? '',
      currentDisplay: json['currentDisplay'] ?? '',
      benchmarkDisplay: json['benchmarkDisplay'] ?? '',
      status: json['status'] ?? 'good',
      categoryKey: json['categoryKey'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'rawWeight': rawWeight,
      'normalizedWeight': normalizedWeight,
      'isAvailable': isAvailable,
      'label': label,
      'currentDisplay': currentDisplay,
      'benchmarkDisplay': benchmarkDisplay,
      'status': status,
      'categoryKey': categoryKey,
    };
  }
}

class HealthScoreResult {
  final double score; // 0.0 to 100.0
  final String status; // Optimal (>=80), Good (65-79), Caution (50-64), Alert (<50), Insufficient Data
  final int evaluatedCategories;
  final int totalCategories; // 5
  final Map<String, HealthScoreComponent> components;
  final List<String> helpingFactors;
  final List<String> improvementOpportunities;
  final String explanation;
  final double changeDelta; // e.g. +3.5 vs 7-day baseline
  final DateTime calculatedAt;
  final bool hasSufficientData;

  const HealthScoreResult({
    required this.score,
    required this.status,
    required this.evaluatedCategories,
    this.totalCategories = 5,
    required this.components,
    required this.helpingFactors,
    required this.improvementOpportunities,
    required this.explanation,
    this.changeDelta = 0.0,
    required this.calculatedAt,
    this.hasSufficientData = true,
  });

  static HealthScoreResult insufficientData() {
    return HealthScoreResult(
      score: 0.0,
      status: 'Insufficient Data',
      evaluatedCategories: 0,
      totalCategories: 5,
      components: {},
      helpingFactors: [],
      improvementOpportunities: [
        'Connect Android Health Connect or Apple HealthKit to begin generating your personalized score.',
      ],
      explanation: 'No biometric data has been synchronized for the current window.',
      changeDelta: 0.0,
      calculatedAt: DateTime.now(),
      hasSufficientData: false,
    );
  }

  factory HealthScoreResult.fromJson(Map<String, dynamic> json) {
    final comps = <String, HealthScoreComponent>{};
    if (json['components'] != null) {
      (json['components'] as Map<String, dynamic>).forEach((key, val) {
        comps[key] = HealthScoreComponent.fromJson(val);
      });
    }

    return HealthScoreResult(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Optimal',
      evaluatedCategories: json['evaluatedCategories'] ?? 0,
      totalCategories: json['totalCategories'] ?? 5,
      components: comps,
      helpingFactors: (json['helpingFactors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      improvementOpportunities: (json['improvementOpportunities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      explanation: json['explanation'] ?? '',
      changeDelta: (json['changeDelta'] as num?)?.toDouble() ?? 0.0,
      calculatedAt: json['calculatedAt'] != null ? DateTime.parse(json['calculatedAt']) : DateTime.now(),
      hasSufficientData: json['hasSufficientData'] ?? (json['evaluatedCategories'] != null && json['evaluatedCategories'] > 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'status': status,
      'evaluatedCategories': evaluatedCategories,
      'totalCategories': totalCategories,
      'components': components.map((k, v) => MapEntry(k, v.toJson())),
      'helpingFactors': helpingFactors,
      'improvementOpportunities': improvementOpportunities,
      'explanation': explanation,
      'changeDelta': changeDelta,
      'calculatedAt': calculatedAt.toIso8601String(),
      'hasSufficientData': hasSufficientData,
    };
  }
}
