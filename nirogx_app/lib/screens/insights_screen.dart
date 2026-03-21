import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandTeal = Color(0xFF00C9B7);
    const Color darkTeal = Color(0xFF00897B);

    return Scaffold(
      // The background is a soft gradient matching the image
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              brandTeal.withValues(alpha: 0.3), // Light minty top
              const Color(0xFFF8FAFC),          // Fades to soft gray-white
              const Color(0xFFF8FAFC),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Bottom padding for the floating bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Custom Header (Logo & Avatar)
                    _buildHeader(brandTeal),
                    const SizedBox(height: 30),

                    // 2. Title Section
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Your Health Trends',
                            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          // Pagination dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDot(brandTeal, true),
                              _buildDot(brandTeal, false),
                              _buildDot(brandTeal, false),
                              _buildDot(brandTeal, false),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 3. Main Hero Chart (Heart Rate)
                    _buildMainChartCard(brandTeal),
                    const SizedBox(height: 20),

                    // 4. The 2x2 Grid of Insight Cards
                    Row(
                      children: [
                        Expanded(child: _buildSleepQualityCard(darkTeal)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildNutrientCard(darkTeal)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildImprovementCard(darkTeal)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildAlertCard(darkTeal)),
                      ],
                    ),
                  ],
                ),
              ),

              // 5. Floating Chat Input at the bottom
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildFloatingInputBar(brandTeal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeader(Color teal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(LucideIcons.activity, color: teal, size: 32),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: 'Nirog', style: GoogleFonts.poppins(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)),
                  TextSpan(text: 'X', style: GoogleFonts.poppins(color: const Color(0xFF2D88FF), fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'), // Placeholder avatar
          onBackgroundImageError: (_, __) => const Icon(Icons.person),
        ),
      ],
    );
  }

  Widget _buildDot(Color color, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: 6,
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMainChartCard(Color color) {
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text('Heart Rate Variability', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Last 30 Days', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(_getHrvChartData(color)),
          ),
        ],
      ),
    );
  }

  // --- 2x2 Grid Card Builders ---

  Widget _buildSleepQualityCard(Color color) {
    return _buildGridCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sleep Quality', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(height: 60, child: BarChart(_getSleepChartData(color))),
          const SizedBox(height: 12),
          Text('Deep Sleep 7 hours', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(Color color) {
    return _buildGridCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nutrient\nAnalysis', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 12),
          Text(
            'Your Vitamin D levels low. Recommended daily intake +800 IU',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementCard(Color color) {
    return _buildGridCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(LucideIcons.users, color: color, size: 24),
              Icon(LucideIcons.arrowUpCircle, color: color, size: 20),
            ],
          ),
          const Spacer(),
          Text('Improved by 15%', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
          Text('Improved by week.', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Color color) {
    return _buildGridCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Predictive Alert', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Icon(LucideIcons.alertTriangle, color: Colors.orangeAccent, size: 16),
          const SizedBox(height: 8),
          Text(
            'Based on recent activity, risk of fatigue is high.\nSuggestion: Prioritize rest.',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700], height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard({required Widget child}) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: child,
    );
  }

  Widget _buildFloatingInputBar(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(LucideIcons.camera, color: Colors.grey), onPressed: () {}),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type your health question...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(icon: const Icon(LucideIcons.mic, color: Colors.grey), onPressed: () {}),
          CircleAvatar(
            backgroundColor: color,
            child: IconButton(icon: const Icon(LucideIcons.send, color: Colors.white, size: 18), onPressed: () {}),
          ),
        ],
      ),
    );
  }

  // --- Chart Data Generators ---

  LineChartData _getHrvChartData(Color color) {
    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1)),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: 165,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 25), FlSpot(1, 40), FlSpot(2, 35), FlSpot(3, 85),
            FlSpot(4, 25), FlSpot(5, 80), FlSpot(6, 45), FlSpot(7, 95),
            FlSpot(8, 40), FlSpot(9, 90), FlSpot(10, 105),
          ],
          isCurved: true,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  BarChartData _getSleepChartData(Color color) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 10,
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: [
        _makeSleepGroup(0, 4, color), _makeSleepGroup(1, 8, color),
        _makeSleepGroup(2, 5, color.withValues(alpha: 0.5)), _makeSleepGroup(3, 9, color),
        _makeSleepGroup(4, 6, color), _makeSleepGroup(5, 5, color.withValues(alpha: 0.5)),
      ],
    );
  }

  BarChartGroupData _makeSleepGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 8,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}