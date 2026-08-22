import 'package:flutter/material.dart';
import '../models/health_score_model.dart';

class HealthScoreCard extends StatelessWidget {
  final HealthScoreResult scoreResult;
  final VoidCallback? onRefreshTap;

  const HealthScoreCard({
    Key? key,
    required this.scoreResult,
    this.onRefreshTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final score = scoreResult.score;
    Color statusColor;

    if (score >= 80) {
      statusColor = const Color(0xFF0D9488); // Teal
    } else if (score >= 65) {
      statusColor = const Color(0xFF0284C7); // Blue
    } else if (score >= 50) {
      statusColor = const Color(0xFFD97706); // Amber
    } else {
      statusColor = const Color(0xFFDC2626); // Red
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Health Score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Evaluated across ${scoreResult.evaluatedCategories} of 5 wellness pillars',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  scoreResult.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Main Score Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score > 0 ? score.toStringAsFixed(1) : '--',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                  letterSpacing: -1.5,
                  height: 1.0,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  '/ 100',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (scoreResult.changeDelta != 0.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        scoreResult.changeDelta > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 14,
                        color: const Color(0xFF059669),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${scoreResult.changeDelta > 0 ? "+" : ""}${scoreResult.changeDelta.toStringAsFixed(1)} vs 7d',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          // Pillars breakdown
          const Text(
            'Wellness Pillar Breakdown',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),

          ...scoreResult.components.entries.map((entry) {
            final comp = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        comp.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${comp.currentDisplay} (${(comp.normalizedWeight * 100).toInt()}% wt)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: comp.score / 100.0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        comp.score >= 80
                            ? const Color(0xFF0D9488)
                            : comp.score >= 60
                                ? const Color(0xFF0284C7)
                                : const Color(0xFFF59E0B),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          if (scoreResult.helpingFactors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 6),
                      Text(
                        'Helping Factors',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...scoreResult.helpingFactors.map(
                    (f) => Text(
                      '• $f',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Disclaimer
          const Text(
            'Wellness indicator only; does not provide clinical diagnosis or medical assessment.',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
