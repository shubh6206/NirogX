import 'package:flutter/material.dart';
import '../models/personal_baseline.dart';

class PersonalBaselineBanner extends StatelessWidget {
  final UserPersonalBaseline baseline;

  const PersonalBaselineBanner({
    Key? key,
    required this.baseline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (baseline.status == BaselineStatus.ready) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                baseline.statusDisplay,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166534),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  baseline.statusDisplay,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: baseline.totalDaysOfData / 7.0,
              backgroundColor: const Color(0xFFDBEAFE),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
