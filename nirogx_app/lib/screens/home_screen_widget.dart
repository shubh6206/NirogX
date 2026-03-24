import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

// Import your repository to fetch the real initial data safely
// import 'package:nirogx_app/data/health_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final HealthRepository _healthRepository = HealthRepository();
  
  double _liveScore = 0.0; // Changed to double for smoother gauge animation
  String _insightText = "Loading insights...";
  Timer? _wearableSimulator;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataAndStartStream();
  }

  Future<void> _loadDataAndStartStream() async {
    // Simulated network/db fetch
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      setState(() {
        _liveScore = 84.0; // Initial score
        _insightText = "Your sleep quality improved by 15% this week. Keep maintaining a consistent bedtime.";
        _isLoading = false;
      });
      _startWearableSimulation();
    }
  }

  // Simulates a Bluetooth wearable stream updating the score in real-time
  void _startWearableSimulation() {
    _wearableSimulator = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && !_isLoading) {
        setState(() {
          // Fluctuate the score slightly (+0.5, -0.5, or 0)
          double change = (DateTime.now().second % 3 == 0) ? 0.5 : (DateTime.now().second % 2 == 0 ? -0.5 : 0.0);
          _liveScore = (_liveScore + change).clamp(0.0, 100.0);
        });
      }
    });
  }

  // Dynamic color logic based on the HealthScoreCalculator parameters
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.greenAccent.shade400; // Optimal
    if (score >= 60) return Colors.orangeAccent;         // Good
    if (score >= 40) return Colors.deepOrangeAccent;     // Caution
    return Colors.redAccent;                             // Critical
  }

  @override
  void dispose() {
    _wearableSimulator?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandTeal = Color(0xFF00C9B7);
    const Color bgTeal = Color(0xFFE0F7F5);
    final Color scoreColor = _getScoreColor(_liveScore);

    return Scaffold(
      backgroundColor: bgTeal,
      body: SafeArea(
        child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: brandTeal))
        : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. App Bar Area
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.activity, color: brandTeal, size: 30),
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
              ),
              const SizedBox(height: 24),

              // 2. Animated Gauge Health Score Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Overall Health', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Icon(LucideIcons.refreshCw, color: Colors.grey.shade400, size: 18), // Sync indicator
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // The beautiful Syncfusion Gauge
                    SizedBox(
                      height: 220,
                      child: SfRadialGauge(
                        enableLoadingAnimation: true,
                        animationDuration: 1500,
                        axes: <RadialAxis>[
                          RadialAxis(
                            minimum: 0,
                            maximum: 100,
                            showLabels: false,
                            showTicks: false,
                            axisLineStyle: AxisLineStyle(
                              thickness: 18,
                              cornerStyle: CornerStyle.bothCurve,
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                            pointers: <GaugePointer>[
                              RangePointer(
                                value: _liveScore,
                                cornerStyle: CornerStyle.bothCurve,
                                width: 18,
                                sizeUnit: GaugeSizeUnit.logicalPixel,
                                color: scoreColor,
                                enableAnimation: true,
                                animationDuration: 800,
                                animationType: AnimationType.easeOutBack,
                              )
                            ],
                            annotations: <GaugeAnnotation>[
                              GaugeAnnotation(
                                positionFactor: 0.1,
                                angle: 90,
                                widget: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _liveScore.toStringAsFixed(0),
                                      style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    Text(
                                      'Score',
                                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    // Mini Stats below the gauge
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildGaugeMiniStat(LucideIcons.flame, 'Energy', 'High', Colors.orange),
                          Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2)),
                          _buildGaugeMiniStat(LucideIcons.activity, 'Status', scoreColor == Colors.greenAccent.shade400 ? 'Optimal' : 'Caution', scoreColor),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. AI Insights Section (Retained from original)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('AI Insights', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const Icon(Icons.more_horiz, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_insightText, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700], height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Quick Vitals Snapshot (Replaced redundant Goal Tracker)
              Text('Recent Vitals', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildVitalCard(LucideIcons.heartPulse, 'Heart Rate', '72', 'bpm', Colors.redAccent)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildVitalCard(LucideIcons.droplets, 'Blood Pressure', '120/80', 'mmHg', Colors.blueAccent)),
                ],
              ),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildGaugeMiniStat(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
            Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalCard(IconData icon, String title, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(width: 2),
              Text(unit, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}