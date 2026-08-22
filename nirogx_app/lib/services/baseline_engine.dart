import 'dart:math';
import '../models/personal_baseline.dart';
import '../models/vital_model.dart';
import 'local_health_db.dart';

class BaselineEngine {
  /// Computes true personal baseline across past 30 days from SQLite database
  static Future<UserPersonalBaseline> computeBaseline(LocalHealthDatabase db) async {
    final nowUtc = DateTime.now().toUtc();
    final thirtyDaysAgoUtc = nowUtc.subtract(const Duration(days: 30));

    final distinctDays = await db.getDistinctDaysCount();

    if (distinctDays == 0) {
      return UserPersonalBaseline.empty();
    }

    final baselines = <String, MetricBaseline>{};

    // 1. Resting Heart Rate
    final rhrAggregates = await db.getDailyAggregates(
      VitalMetricType.restingHeartRate,
      thirtyDaysAgoUtc,
      nowUtc,
    );
    final hrAggregates = await db.getDailyAggregates(
      VitalMetricType.heartRate,
      thirtyDaysAgoUtc,
      nowUtc,
    );

    final hrValues = rhrAggregates.isNotEmpty ? rhrAggregates.values.toList() : hrAggregates.values.toList();
    if (hrValues.isNotEmpty) {
      baselines['resting_heart_rate'] = _computeSingleMetricBaseline(
        metricKey: 'resting_heart_rate',
        metricLabel: 'Resting Heart Rate',
        unit: 'bpm',
        values: hrValues,
      );
    }

    // 2. Sleep Duration
    final sleepAggregates = await db.getDailyAggregates(
      VitalMetricType.sleep,
      thirtyDaysAgoUtc,
      nowUtc,
    );
    if (sleepAggregates.isNotEmpty) {
      baselines['sleep'] = _computeSingleMetricBaseline(
        metricKey: 'sleep',
        metricLabel: 'Sleep Duration',
        unit: 'hrs',
        values: sleepAggregates.values.map((v) => v / 60.0).toList(), // convert to hours
      );
    }

    // 3. Daily Steps
    final stepAggregates = await db.getDailyAggregates(
      VitalMetricType.steps,
      thirtyDaysAgoUtc,
      nowUtc,
    );
    if (stepAggregates.isNotEmpty) {
      baselines['steps'] = _computeSingleMetricBaseline(
        metricKey: 'steps',
        metricLabel: 'Daily Steps',
        unit: 'steps',
        values: stepAggregates.values.toList(),
      );
    }

    // Determine baseline status based on distinct valid observation days
    BaselineStatus status;
    if (distinctDays >= 7) {
      status = BaselineStatus.ready;
    } else if (distinctDays >= 3) {
      status = BaselineStatus.preliminary;
    } else {
      status = BaselineStatus.building;
    }

    return UserPersonalBaseline(
      totalDaysOfData: distinctDays,
      status: status,
      baselines: baselines,
      computedAt: nowUtc,
    );
  }

  static MetricBaseline _computeSingleMetricBaseline({
    required String metricKey,
    required String metricLabel,
    required String unit,
    required List<double> values,
  }) {
    if (values.isEmpty) {
      return MetricBaseline(
        metricKey: metricKey,
        metricLabel: metricLabel,
        baselineValue: 0.0,
        standardDeviation: 0.0,
        lowerBound: 0.0,
        upperBound: 0.0,
        daysSampled: 0,
        confidence: 0.0,
        unit: unit,
      );
    }

    final sorted = List<double>.from(values)..sort();
    final median = sorted[sorted.length ~/ 2];

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = sqrt(variance);

    final confidence = (values.length / 7.0).clamp(0.1, 1.0);

    return MetricBaseline(
      metricKey: metricKey,
      metricLabel: metricLabel,
      baselineValue: double.parse(median.toStringAsFixed(1)),
      standardDeviation: double.parse(stdDev.toStringAsFixed(1)),
      lowerBound: double.parse((median - stdDev).clamp(0.0, double.infinity).toStringAsFixed(1)),
      upperBound: double.parse((median + stdDev).toStringAsFixed(1)),
      daysSampled: values.length,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      unit: unit,
    );
  }
}
