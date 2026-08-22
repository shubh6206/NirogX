import 'dart:math';
import '../models/health_score_model.dart';
import '../models/vital_model.dart';
import '../models/personal_baseline.dart';
import 'local_health_db.dart';

/// Production Deterministic Health Score Engine
/// Computes explainable wellness scores using dynamic weight normalization,
/// personal historical baselines, and strict non-diagnostic clinical language.
class HealthScoreEngine {
  static const double _wActivity = 0.25;
  static const double _wSleep = 0.25;
  static const double _wHeart = 0.25;
  static const double _wRecovery = 0.15;
  static const double _wHydration = 0.10;

  /// Evaluates the complete Health Score for the current user state
  static Future<HealthScoreResult> evaluate(
    LocalHealthDatabase db, {
    UserPersonalBaseline? baseline,
    DateTime? targetDate,
  }) async {
    final now = targetDate ?? DateTime.now();

    // 1. Physical Activity Pillar (25%)
    final dailySteps = await db.getTodayTotal(VitalMetricType.steps, targetDate: now);
    final activeCals = await db.getTodayTotal(VitalMetricType.activeCalories, targetDate: now);
    final HealthScoreComponent? activityComp = _evalActivity(dailySteps, activeCals);

    // 2. Sleep Architecture Pillar (25%)
    final sleepRecord = await db.getLatestVital(VitalMetricType.sleep);
    final HealthScoreComponent? sleepComp = _evalSleep(sleepRecord);

    // 3. Cardiovascular Health Pillar (25%)
    final hrRecord = await db.getLatestVital(VitalMetricType.heartRate);
    final rhrRecord = await db.getLatestVital(VitalMetricType.restingHeartRate);
    final HealthScoreComponent? heartComp = _evalHeart(hrRecord, rhrRecord, baseline);

    // 4. Recovery Index Pillar (15%)
    HealthScoreComponent? recoveryComp;
    if (sleepComp != null && heartComp != null) {
      recoveryComp = _evalRecovery(sleepComp.score, heartComp.score);
    }

    // 5. Hydration Pillar (10%)
    final hydrationMl = await db.getTodayTotal(VitalMetricType.hydration, targetDate: now);
    final HealthScoreComponent? hydrationComp = _evalHydration(hydrationMl);

    // Collect available components
    final Map<String, HealthScoreComponent> rawComponents = {};
    if (activityComp != null) rawComponents['activity'] = activityComp;
    if (sleepComp != null) rawComponents['sleep'] = sleepComp;
    if (heartComp != null) rawComponents['heartHealth'] = heartComp;
    if (recoveryComp != null) rawComponents['recovery'] = recoveryComp;
    if (hydrationComp != null) rawComponents['hydration'] = hydrationComp;

    if (rawComponents.isEmpty) {
      return HealthScoreResult.insufficientData();
    }

    // Dynamic Normalization: sum(w_i * score_i) / sum(w_i)
    double availableWeightSum = 0.0;
    double weightedScoreSum = 0.0;

    for (var comp in rawComponents.values) {
      availableWeightSum += comp.rawWeight;
      weightedScoreSum += comp.score * comp.rawWeight;
    }

    if (availableWeightSum <= 0.0) {
      return HealthScoreResult.insufficientData();
    }

    final double rawOverallScore = weightedScoreSum / availableWeightSum;
    final double finalScore = double.parse(rawOverallScore.clamp(0.0, 100.0).toStringAsFixed(1));

    // Normalize component weights for UI display
    final Map<String, HealthScoreComponent> normalizedComponents = {};
    rawComponents.forEach((key, comp) {
      final normalizedWeight = double.parse((comp.rawWeight / availableWeightSum).toStringAsFixed(2));
      normalizedComponents[key] = HealthScoreComponent(
        score: comp.score,
        rawWeight: comp.rawWeight,
        normalizedWeight: normalizedWeight,
        isAvailable: true,
        label: comp.label,
        currentDisplay: comp.currentDisplay,
        benchmarkDisplay: comp.benchmarkDisplay,
        status: comp.status,
        categoryKey: key,
      );
    });

    // Determine status tier
    String statusTier = 'Good';
    if (finalScore >= 80.0) {
      statusTier = 'Optimal';
    } else if (finalScore >= 65.0) {
      statusTier = 'Good';
    } else if (finalScore >= 50.0) {
      statusTier = 'Caution';
    } else {
      statusTier = 'Alert';
    }

    // Calculate real comparative delta vs yesterday
    double calculatedDelta = 0.0;
    try {
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdaySteps = await db.getTodayTotal(VitalMetricType.steps, targetDate: yesterday);
      if (yesterdaySteps > 0 && dailySteps > 0) {
        final stepDelta = (dailySteps - yesterdaySteps) / yesterdaySteps;
        calculatedDelta = double.parse((stepDelta * 5.0).clamp(-10.0, 10.0).toStringAsFixed(1));
      }
    } catch (_) {}

    // Explainable Insights
    final List<String> helping = [];
    final List<String> opportunities = [];

    if (heartComp != null && heartComp.score >= 85.0) {
      helping.add('Resting heart rate demonstrates balanced autonomic regulation.');
    } else if (heartComp != null && heartComp.score < 70.0) {
      opportunities.add('Elevated resting heart rate observed relative to standard target range.');
    }

    if (sleepComp != null && sleepComp.score >= 80.0) {
      helping.add('Sleep duration aligns with restorative physiological targets.');
    } else if (sleepComp != null && sleepComp.score < 70.0) {
      opportunities.add('Sleep duration was shorter than recommended 7.0-9.0 hour window.');
    }

    if (activityComp != null && activityComp.score >= 80.0) {
      helping.add('Physical movement volume meets healthy cardiovascular activity targets.');
    } else if (activityComp != null && activityComp.score < 65.0) {
      opportunities.add('Increasing daily step volume supports cardiovascular conditioning.');
    }

    if (hydrationComp != null && hydrationComp.score < 75.0) {
      opportunities.add('Daily hydration intake is below the 2,500 mL recommended target.');
    }

    return HealthScoreResult(
      score: finalScore,
      status: statusTier,
      evaluatedCategories: normalizedComponents.length,
      totalCategories: 5,
      components: normalizedComponents,
      helpingFactors: helping,
      improvementOpportunities: opportunities,
      explanation: 'Dynamic composite normalized across ${normalizedComponents.length} active wellness pillars.',
      changeDelta: calculatedDelta,
      calculatedAt: now,
      hasSufficientData: true,
    );
  }

  static HealthScoreComponent? _evalActivity(double steps, double activeCals) {
    if (steps <= 0 && activeCals <= 0) return null;

    double score = 50.0;
    if (steps >= 10000) {
      score = 98.0;
    } else if (steps >= 8000) {
      score = 90.0;
    } else if (steps >= 6000) {
      score = 78.0;
    } else if (steps >= 4000) {
      score = 65.0;
    } else {
      score = 45.0;
    }

    return HealthScoreComponent(
      score: score,
      rawWeight: _wActivity,
      normalizedWeight: _wActivity,
      isAvailable: true,
      label: 'Physical Activity',
      currentDisplay: '${steps.toInt()} steps',
      benchmarkDisplay: '8,000+ steps/day',
      status: score >= 80 ? 'optimal' : score >= 60 ? 'good' : 'needs_attention',
      categoryKey: 'activity',
    );
  }

  static HealthScoreComponent? _evalSleep(VitalRecord? record) {
    if (record == null) return null;

    final double totalHours = record.value / 60.0;
    double score = 50.0;

    if (totalHours >= 7.0 && totalHours <= 9.0) {
      score = 95.0;
    } else if ((totalHours >= 6.0 && totalHours < 7.0) || (totalHours > 9.0 && totalHours <= 10.0)) {
      score = 80.0;
    } else if (totalHours >= 5.0 && totalHours < 6.0) {
      score = 65.0;
    } else {
      score = 45.0;
    }

    return HealthScoreComponent(
      score: score,
      rawWeight: _wSleep,
      normalizedWeight: _wSleep,
      isAvailable: true,
      label: 'Sleep Architecture',
      currentDisplay: '${totalHours.toStringAsFixed(1)} hrs',
      benchmarkDisplay: '7.0 - 9.0 hrs / night',
      status: score >= 80 ? 'optimal' : score >= 60 ? 'good' : 'needs_attention',
      categoryKey: 'sleep',
    );
  }

  static HealthScoreComponent? _evalHeart(VitalRecord? hr, VitalRecord? rhr, UserPersonalBaseline? baseline) {
    if (hr == null && rhr == null) return null;

    final double effectiveHr = (rhr != null && rhr.value > 0) ? rhr.value : (hr?.value ?? 70.0);
    double score = 50.0;

    // Check if personal baseline exists
    final hrBaseline = baseline?.baselines['resting_heart_rate'] ?? baseline?.baselines['heart_rate'];
    if (hrBaseline != null && hrBaseline.isReliable) {
      final diff = (effectiveHr - hrBaseline.baselineValue).abs();
      if (diff <= hrBaseline.standardDeviation) {
        score = 95.0;
      } else if (diff <= hrBaseline.standardDeviation * 2) {
        score = 80.0;
      } else {
        score = 60.0;
      }
    } else {
      // Standard physiological population targets
      if (effectiveHr >= 55.0 && effectiveHr <= 72.0) {
        score = 95.0;
      } else if (effectiveHr > 72.0 && effectiveHr <= 82.0) {
        score = 82.0;
      } else if (effectiveHr > 82.0 && effectiveHr <= 92.0) {
        score = 65.0;
      } else {
        score = 45.0;
      }
    }

    return HealthScoreComponent(
      score: score,
      rawWeight: _wHeart,
      normalizedWeight: _wHeart,
      isAvailable: true,
      label: 'Cardiovascular Health',
      currentDisplay: '${effectiveHr.toInt()} bpm',
      benchmarkDisplay: '60 - 75 bpm resting',
      status: score >= 80 ? 'optimal' : score >= 60 ? 'good' : 'needs_attention',
      categoryKey: 'heartHealth',
    );
  }

  static HealthScoreComponent _evalRecovery(double sleepScore, double heartScore) {
    final recoveryVal = (sleepScore * 0.55) + (heartScore * 0.45);
    final clamped = recoveryVal.clamp(0.0, 100.0);

    return HealthScoreComponent(
      score: double.parse(clamped.toStringAsFixed(1)),
      rawWeight: _wRecovery,
      normalizedWeight: _wRecovery,
      isAvailable: true,
      label: 'Recovery Index',
      currentDisplay: '${clamped.toInt()}/100',
      benchmarkDisplay: '75+ balanced recovery',
      status: clamped >= 80 ? 'optimal' : clamped >= 60 ? 'good' : 'needs_attention',
      categoryKey: 'recovery',
    );
  }

  static HealthScoreComponent? _evalHydration(double ml) {
    if (ml <= 0) return null;

    double score = 50.0;
    if (ml >= 2500.0) {
      score = 95.0;
    } else if (ml >= 2000.0) {
      score = 85.0;
    } else if (ml >= 1500.0) {
      score = 70.0;
    } else {
      score = 50.0;
    }

    final litersDisplay = (ml / 1000.0).toStringAsFixed(2);

    return HealthScoreComponent(
      score: score,
      rawWeight: _wHydration,
      normalizedWeight: _wHydration,
      isAvailable: true,
      label: 'Hydration Intake',
      currentDisplay: '$litersDisplay L',
      benchmarkDisplay: '2.50 L / day target',
      status: score >= 80 ? 'optimal' : score >= 60 ? 'good' : 'needs_attention',
      categoryKey: 'hydration',
    );
  }
}
