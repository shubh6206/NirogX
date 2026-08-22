import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../models/vital_model.dart';
import '../models/personal_baseline.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final health = Provider.of<HealthProvider>(context);
    final baseline = health.personalBaseline;
    final hr = health.getLatestVital(VitalMetricType.heartRate);
    final sleep = health.getLatestVital(VitalMetricType.sleep);
    final steps = health.getTodayTotal(VitalMetricType.steps);

    final hrBase = baseline.baselines['resting_heart_rate'];
    final sleepBase = baseline.baselines['sleep'];
    final stepsBase = baseline.baselines['steps'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Longitudinal Analytics & Baseline',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Personal Baseline Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Personal Baseline Analysis',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${baseline.totalDaysOfData} Days Recorded',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  baseline.statusDisplay,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // Biometric comparisons
                _buildBaselineRow(
                  label: 'Resting Heart Rate',
                  current: hr != null ? '${hr.value.toInt()} bpm' : '--',
                  baseline: hrBase != null ? '${hrBase.baselineValue.toInt()} bpm (±${hrBase.standardDeviation.toInt()})' : 'Building...',
                  status: hrBase != null ? 'Computed from ${hrBase.daysSampled} valid days' : 'Requires historical records',
                  isGood: hrBase != null,
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildBaselineRow(
                  label: 'Sleep Duration',
                  current: sleep != null ? '${(sleep.value / 60.0).toStringAsFixed(1)} hrs' : '--',
                  baseline: sleepBase != null ? '${sleepBase.baselineValue.toStringAsFixed(1)} hrs (±${sleepBase.standardDeviation.toStringAsFixed(1)})' : 'Building...',
                  status: sleepBase != null ? 'Computed from ${sleepBase.daysSampled} valid days' : 'Requires historical records',
                  isGood: sleepBase != null,
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildBaselineRow(
                  label: 'Daily Movement Volume',
                  current: steps > 0 ? '${steps.toInt()} steps' : '--',
                  baseline: stepsBase != null ? '${stepsBase.baselineValue.toInt()} steps' : 'Building...',
                  status: stepsBase != null ? 'Computed from ${stepsBase.daysSampled} valid days' : 'Requires historical records',
                  isGood: stepsBase != null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 7-Day Trend Visualizer
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health Score Status & Evaluation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  health.healthScore?.explanation ?? 'Synchronize data to view multi-pillar composite evaluations.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                if (health.healthScore != null && health.healthScore!.hasSufficientData)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall: ${health.healthScore!.score.toStringAsFixed(1)}/100',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
                      ),
                      Text(
                        'Tier: ${health.healthScore!.status}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'No health score calculated yet. Tap Sync on Home.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Source Attribution Breakdown
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Source Attribution Breakdown',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                _buildSourceItem(
                  'Android Health Connect / HealthKit',
                  health.isConnected ? 'Heart Rate, Steps, SpO2, Sleep' : 'Disconnected',
                  health.isConnected ? 'Active' : 'Idle',
                ),
                const SizedBox(height: 8),
                _buildSourceItem(
                  'Manual Patient Entry',
                  'Hydration, Blood Pressure, Manual Vitals',
                  'Available',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineRow({
    required String label,
    required String current,
    required String baseline,
    required String status,
    required bool isGood,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(status, style: TextStyle(fontSize: 10, color: isGood ? const Color(0xFF059669) : const Color(0xFFD97706))),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(current, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            Text('Base: $baseline', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }

  Widget _buildSourceItem(String name, String metrics, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            Text(metrics, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
        Text(status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
      ],
    );
  }
}
