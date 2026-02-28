import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color nirogTeal = Color(0xFF00C9B7);
    const Color nirogBlue = Color(0xFF007AFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Soft gray-white background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Health Insights',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartCard(
              title: 'Your Weekly Progress',
              subtitle: 'Average Health Score: 85%',
              chart: LineChart(_getWeeklyProgressData(nirogTeal)),
            ),
            const SizedBox(height: 25),
            _buildChartCard(
              title: 'Symptom Trends',
              subtitle: 'Frequency of reported alerts',
              chart: BarChart(_getSymptomTrendData(nirogBlue)),
            ),
          ],
        ),
      ),
    );
  }

  // Wrapper to give charts a "Dashboard" feel
  Widget _buildChartCard({required String title, required String subtitle, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 25),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  // --- Chart Data Logic remains the same as your input ---
  LineChartData _getWeeklyProgressData(Color color) {
     return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false), // Add SideTitles here for dates/values
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 3.5), FlSpot(1, 1.5), FlSpot(2, 4.2),
            FlSpot(3, 2.8), FlSpot(4, 5.0), FlSpot(5, 3.2), FlSpot(6, 4.0),
          ],
          isCurved: true,
          curveSmoothness: 0.5,
          color: color,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
        ),
      ],
    );
  }

  BarChartData _getSymptomTrendData(Color color) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 16,
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: [
        _makeGroupData(0, 4, color), _makeGroupData(1, 8, color),
        _makeGroupData(2, 12, color), _makeGroupData(3, 13, color),
        _makeGroupData(4, 10, color), _makeGroupData(5, 5, color),
      ],
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}