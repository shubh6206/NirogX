import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../providers/auth_provider.dart';
import '../models/vital_model.dart';
import '../widgets/sync_status_badge.dart';
import '../widgets/health_score_card.dart';
import '../widgets/vital_summary_card.dart';
import '../widgets/personal_baseline_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final health = Provider.of<HealthProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    final hr = health.getLatestVital(VitalMetricType.heartRate);
    final steps = health.getTodayTotal(VitalMetricType.steps);
    final sleep = health.getLatestVital(VitalMetricType.sleep);
    final spO2 = health.getLatestVital(VitalMetricType.spO2);
    final hydration = health.getTodayTotal(VitalMetricType.hydration);
    final activeCals = health.getTodayTotal(VitalMetricType.activeCalories);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NirogX Clinical AI',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Patient: ${user?.name ?? "Alex Mercer"}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: SyncStatusBadge(
                metadata: health.syncMetadata,
                onSyncTap: () => health.syncNow(),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => health.syncNow(),
        color: const Color(0xFF00897B),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Baseline progress banner
            PersonalBaselineBanner(baseline: health.personalBaseline),
            const SizedBox(height: 16),

            // Main Deterministic Health Score Card
            if (health.healthScore != null)
              HealthScoreCard(
                scoreResult: health.healthScore!,
                onRefreshTap: () => health.syncNow(),
              ),

            const SizedBox(height: 20),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Synchronized Vitals',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showManualEntrySheet(context, health),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF00897B)),
                  label: const Text(
                    'Manual Log',
                    style: TextStyle(fontSize: 12, color: Color(0xFF00897B), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 2x2 Grid of Vital Summary Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                VitalSummaryCard(
                  title: 'Heart Rate',
                  valueDisplay: hr != null ? '${hr.value.toInt()}' : '--',
                  unit: 'bpm',
                  source: hr?.sourceName ?? 'No data',
                  timeAgo: hr != null ? _formatMinutesAgo(hr.timestamp) : 'No data',
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFE11D48),
                  iconBgColor: const Color(0xFFFFE4E6),
                ),
                VitalSummaryCard(
                  title: 'Daily Steps',
                  valueDisplay: steps > 0 ? '${steps.toInt()}' : '--',
                  unit: 'steps',
                  source: steps > 0 ? 'Health Platform' : 'No data',
                  timeAgo: steps > 0 ? 'Today' : 'No data',
                  icon: Icons.directions_walk_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBgColor: const Color(0xFFE0F2FE),
                ),
                VitalSummaryCard(
                  title: 'Sleep Duration',
                  valueDisplay: sleep != null ? (sleep.value / 60.0).toStringAsFixed(1) : '--',
                  unit: 'hrs',
                  source: sleep?.sourceName ?? 'No data',
                  timeAgo: sleep != null ? 'Last recorded' : 'No data',
                  icon: Icons.bedtime_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  iconBgColor: const Color(0xFFEDE9FE),
                ),
                VitalSummaryCard(
                  title: 'Blood Oxygen (SpO2)',
                  valueDisplay: spO2 != null ? spO2.value.toStringAsFixed(1) : '--',
                  unit: '%',
                  source: spO2?.sourceName ?? 'No data',
                  timeAgo: spO2 != null ? _formatMinutesAgo(spO2.timestamp) : 'No data',
                  icon: Icons.air_rounded,
                  iconColor: const Color(0xFF0D9488),
                  iconBgColor: const Color(0xFFCCFBF1),
                ),
                VitalSummaryCard(
                  title: 'Hydration Intake',
                  valueDisplay: hydration > 0 ? (hydration / 1000.0).toStringAsFixed(2) : '--',
                  unit: 'L',
                  source: hydration > 0 ? 'Logged' : 'No data',
                  timeAgo: hydration > 0 ? 'Today' : 'No data',
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFDBEAFE),
                ),
                VitalSummaryCard(
                  title: 'Active Energy',
                  valueDisplay: activeCals > 0 ? '${activeCals.toInt()}' : '--',
                  unit: 'kcal',
                  source: activeCals > 0 ? 'Health Platform' : 'No data',
                  timeAgo: activeCals > 0 ? 'Today' : 'No data',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFEA580C),
                  iconBgColor: const Color(0xFFFFEDD5),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Connected Platform Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.sensors_rounded, color: Color(0xFF00897B), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Multi-Platform Synchronization',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          health.isConnected ? 'Android Health Connect / HealthKit Active' : 'Permissions needed',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => health.connectHealthPlatform(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                    ),
                    child: Text(
                      health.isConnected ? 'Sync' : 'Connect',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static String _formatMinutesAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showManualEntrySheet(BuildContext context, HealthProvider health) {
    final valController = TextEditingController();
    VitalMetricType selectedType = VitalMetricType.heartRate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manual Vital Entry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<VitalMetricType>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Metric Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: VitalMetricType.heartRate, child: Text('Heart Rate (bpm)')),
                  DropdownMenuItem(value: VitalMetricType.hydration, child: Text('Hydration (mL)')),
                  DropdownMenuItem(value: VitalMetricType.steps, child: Text('Steps (count)')),
                  DropdownMenuItem(value: VitalMetricType.weight, child: Text('Body Weight (kg)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: valController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Value (${selectedType.canonicalUnit})',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(valController.text);
                    if (val != null && val > 0) {
                      health.logManualVital(selectedType, val, selectedType.canonicalUnit);
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
