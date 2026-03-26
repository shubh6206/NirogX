import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
// import 'package:http/http.dart' as http; // Uncomment when ready to connect

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const Color brandTeal = Color(0xFF00C9B7);
  static const Color darkTeal = Color(0xFF00897B);

  bool _isLoading = true;
  String _selectedVital = 'Heart Rate'; // Controls which main chart is showing

  // Dynamic Data Holders
  List<FlSpot> _activeChartData = [];
  Map<String, List<FlSpot>> _vitalsData = {};
  List<BarChartGroupData> _sleepData = [];
  
  // Dynamic AI Insights
  String _sleepInsightText = "Analyzing sleep patterns...";
  String _generalInsightTitle = "Analysis";
  String _generalInsightText = "Loading personalized insights...";
  String _improvementText = "Calculating trends...";
  String _alertText = "Checking for anomalies...";
  bool _hasAlert = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    // TODO: Replace this simulated delay with your actual FastAPI GET request
    // final response = await http.get(Uri.parse('https://your-api.com/api/v1/insights/user/1'));
    // final data = jsonDecode(response.body);

    await Future.delayed(const Duration(seconds: 2)); // Simulating network latency

    // Simulated parsed response from your ML pipeline
    setState(() {
      _vitalsData = {
        'Heart Rate': const [FlSpot(0, 65), FlSpot(1, 70), FlSpot(2, 68), FlSpot(3, 75), FlSpot(4, 72), FlSpot(5, 80), FlSpot(6, 74)],
        'Temperature': const [FlSpot(0, 36.5), FlSpot(1, 36.6), FlSpot(2, 36.6), FlSpot(3, 36.8), FlSpot(4, 37.0), FlSpot(5, 36.7), FlSpot(6, 36.6)],
        'SpO2': const [FlSpot(0, 98), FlSpot(1, 99), FlSpot(2, 98), FlSpot(3, 97), FlSpot(4, 98), FlSpot(5, 99), FlSpot(6, 98)],
        'Blood Pressure': const [FlSpot(0, 120), FlSpot(1, 118), FlSpot(2, 122), FlSpot(3, 125), FlSpot(4, 119), FlSpot(5, 121), FlSpot(6, 120)], // Mapping Systolic for simplicity
      };
      
      _activeChartData = _vitalsData['Heart Rate']!;

      _sleepData = [
        _makeSleepGroup(0, 6.5, brandTeal),
        _makeSleepGroup(1, 7.2, brandTeal),
        _makeSleepGroup(2, 5.0, Colors.redAccent.withValues(alpha: 0.6)), // Highlight bad sleep
        _makeSleepGroup(3, 8.1, brandTeal),
        _makeSleepGroup(4, 7.5, brandTeal),
      ];

      // Injecting the AI-generated responses
      _sleepInsightText = "Avg 6.8 hrs. Deep sleep dropped on Wednesday.";
      _generalInsightTitle = "Vitals Stable";
      _generalInsightText = "Your resting heart rate has normalized after last week's spike. Keep up the hydration.";
      _improvementText = "Cardio recovery improved by 12% this week.";
      _hasAlert = true;
      _alertText = "SpO2 dipped slightly during sleep. Ensure your room is well-ventilated.";

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              brandTeal.withOpacity(0.3),
              const Color(0xFFF8FAFC),
              const Color(0xFFF8FAFC),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: brandTeal))
            : Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(brandTeal),
                    const SizedBox(height: 30),

                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Your Health Trends',
                            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 16),
                          // Dynamic Vital Selector
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _vitalsData.keys.map((key) {
                                final isSelected = _selectedVital == key;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: ChoiceChip(
                                    label: Text(key),
                                    selected: isSelected,
                                    selectedColor: brandTeal,
                                    labelStyle: GoogleFonts.poppins(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedVital = key;
                                          _activeChartData = _vitalsData[key]!;
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildMainChartCard(brandTeal),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: _buildSleepQualityCard(darkTeal)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDynamicInsightCard(darkTeal, _generalInsightTitle, _generalInsightText)),
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
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
        ),
      ],
    );
  }

  Widget _buildMainChartCard(Color color) {
    // Determine Y-axis bounds dynamically based on the selected vital
    double minY = _activeChartData.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.9;
    double maxY = _activeChartData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.1;

    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text('$_selectedVital Trend', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Last 7 Days', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
                titlesData: const FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: _activeChartData,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepQualityCard(Color color) {
    return _buildGridCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sleep Quality', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 50, 
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _sleepData,
              )
            )
          ),
          const SizedBox(height: 12),
          Text(_sleepInsightText, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600], height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis,),
        ],
      ),
    );
  }

  Widget _buildDynamicInsightCard(Color color, String title, String insight) {
    return _buildGridCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 12),
          Text(
            insight,
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
              Icon(LucideIcons.trendingUp, color: color, size: 24),
              Icon(LucideIcons.checkCircle, color: color, size: 20),
            ],
          ),
          const Spacer(),
          Text('Positive Trend', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
          Text(_improvementText, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
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
          Icon(LucideIcons.alertTriangle, color: _hasAlert ? Colors.orangeAccent : Colors.green, size: 16),
          const SizedBox(height: 8),
          Text(
            _hasAlert ? _alertText : "No critical alerts. You are doing great!",
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700], height: 1.3),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
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
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
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

  BarChartGroupData _makeSleepGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y, color: color, width: 8, borderRadius: BorderRadius.circular(2)),
      ],
    );
  }
}