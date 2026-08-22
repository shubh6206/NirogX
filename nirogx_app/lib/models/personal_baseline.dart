enum BaselineStatus {
  building,
  preliminary,
  ready,
  insufficient,
}

class MetricBaseline {
  final String metricKey;
  final String metricLabel;
  final double baselineValue; // rolling median or mean
  final double standardDeviation;
  final double lowerBound;
  final double upperBound;
  final int daysSampled;
  final double confidence; // 0.0 to 1.0
  final String unit;

  const MetricBaseline({
    required this.metricKey,
    required this.metricLabel,
    required this.baselineValue,
    required this.standardDeviation,
    required this.lowerBound,
    required this.upperBound,
    required this.daysSampled,
    this.confidence = 1.0,
    required this.unit,
  });

  bool get isReliable => daysSampled >= 7;

  Map<String, dynamic> toJson() {
    return {
      'metricKey': metricKey,
      'metricLabel': metricLabel,
      'baselineValue': baselineValue,
      'standardDeviation': standardDeviation,
      'lowerBound': lowerBound,
      'upperBound': upperBound,
      'daysSampled': daysSampled,
      'confidence': confidence,
      'unit': unit,
    };
  }

  factory MetricBaseline.fromJson(Map<String, dynamic> json) {
    return MetricBaseline(
      metricKey: json['metricKey'] ?? '',
      metricLabel: json['metricLabel'] ?? '',
      baselineValue: (json['baselineValue'] as num?)?.toDouble() ?? 0.0,
      standardDeviation: (json['standardDeviation'] as num?)?.toDouble() ?? 0.0,
      lowerBound: (json['lowerBound'] as num?)?.toDouble() ?? 0.0,
      upperBound: (json['upperBound'] as num?)?.toDouble() ?? 0.0,
      daysSampled: json['daysSampled'] ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] ?? '',
    );
  }
}

class UserPersonalBaseline {
  final int totalDaysOfData;
  final BaselineStatus status;
  final Map<String, MetricBaseline> baselines;
  final DateTime computedAt;

  const UserPersonalBaseline({
    required this.totalDaysOfData,
    required this.status,
    required this.baselines,
    required this.computedAt,
  });

  static UserPersonalBaseline empty() {
    return UserPersonalBaseline(
      totalDaysOfData: 0,
      status: BaselineStatus.building,
      baselines: {},
      computedAt: DateTime.now().toUtc(),
    );
  }

  String get statusDisplay {
    switch (status) {
      case BaselineStatus.building:
        if (totalDaysOfData == 0) {
          return 'No baseline data recorded yet (0 of 7 days)';
        }
        final needed = 7 - totalDaysOfData;
        return 'Building personal baseline (Day $totalDaysOfData of 7, $needed more needed)';
      case BaselineStatus.preliminary:
        return 'Preliminary baseline ($totalDaysOfData of 7 days recorded)';
      case BaselineStatus.ready:
        return 'Personal baseline active ($totalDaysOfData days of history)';
      case BaselineStatus.insufficient:
        return 'No baseline data available';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDaysOfData': totalDaysOfData,
      'status': status.name,
      'baselines': baselines.map((k, v) => MapEntry(k, v.toJson())),
      'computedAt': computedAt.toIso8601String(),
    };
  }

  factory UserPersonalBaseline.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'building';
    BaselineStatus parsedStatus;
    if (statusStr == 'ready') {
      parsedStatus = BaselineStatus.ready;
    } else if (statusStr == 'preliminary') {
      parsedStatus = BaselineStatus.preliminary;
    } else if (statusStr == 'insufficient') {
      parsedStatus = BaselineStatus.insufficient;
    } else {
      parsedStatus = BaselineStatus.building;
    }

    final rawBaselines = json['baselines'] as Map<String, dynamic>? ?? {};
    final parsedBaselines = rawBaselines.map(
      (k, v) => MapEntry(k, MetricBaseline.fromJson(Map<String, dynamic>.from(v))),
    );

    return UserPersonalBaseline(
      totalDaysOfData: json['totalDaysOfData'] ?? 0,
      status: parsedStatus,
      baselines: parsedBaselines,
      computedAt: json['computedAt'] != null ? DateTime.parse(json['computedAt']) : DateTime.now().toUtc(),
    );
  }
}
