import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Import your repository to fetch the real initial data safely
import 'package:nirogx_app/data/health_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HealthRepository _healthRepository = HealthRepository();
  
  int _liveScore = 0; // Starts at 0 for the entry animation
  String _insightText = "Loading insights...";
  Timer? _wearableSimulator;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataAndStartStream();
  }

  Future<void> _loadDataAndStartStream() async {
    try {
      // 1. Fetch real data from your SQLite DB (same as your original code)
      final data = await _healthRepository.getLatestHealthStatus();
      if (mounted) {
        setState(() {
          _liveScore = data.score;
          _insightText = data.insightText;
          _isLoading = false;
        });
        _startWearableSimulation();
      }
    } catch (e) {
      // 2. Fallback if the database is currently empty
      if (mounted) {
        setState(() {
          _liveScore = 88;
          _insightText = "Your sleep quality improved 15%.";
          _isLoading = false;
        });
        _startWearableSimulation();
      }
    }
  }

  // Simulates a Bluetooth wearable stream updating the score in real-time
  void _startWearableSimulation() {
    _wearableSimulator = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          // Fluctuate the score slightly (+1, -1, or 0)
          int change = (DateTime.now().second % 3 == 0) ? 1 : (DateTime.now().second % 2 == 0 ? -1 : 0);
          _liveScore = (_liveScore + change).clamp(0, 100);
        });
      }
    });
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

    final double progressValue = _liveScore / 100.0;

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

              // 2. Live Health Score Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7F0EC), 
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Live Health Score', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const Icon(Icons.more_vert, color: Colors.black54),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Animated Circular Gauge
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 140, width: 140,
                          child: CircularProgressIndicator(
                            value: 1.0, 
                            strokeWidth: 12,
                            backgroundColor: Colors.transparent,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(
                          height: 140, width: 140,
                          // Animates smoothly when the local timer updates the score
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: progressValue),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => CircularProgressIndicator(
                              value: value,
                              strokeWidth: 12,
                              backgroundColor: Colors.transparent,
                              color: const Color(0xFF2D88FF), 
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        ),
                        Text('$_liveScore%', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat(LucideIcons.zap, 'Energy', 0.7, brandTeal),
                        _buildMiniStat(LucideIcons.footprints, 'Step Activity', 0.4, brandTeal),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Daily Insights Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daily Insights', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const Icon(Icons.more_horiz, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Uses the insight fetched from your database
                    Text(_insightText, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildInsightSquare(LucideIcons.flame, 'Heart Health', const Color(0xFFFF8A65)),
                          _buildInsightSquare(LucideIcons.apple, 'Nutrition\nAnalysis', const Color(0xFF9575CD)),
                          _buildInsightSquare(LucideIcons.brainCircuit, 'Stress\nIndex', const Color(0xFFE57373)),
                          _buildInsightSquare(LucideIcons.moon, 'Sleep\nCycles', const Color(0xFF4FC3F7)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Goal Tracker Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Goal Tracker', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const Icon(Icons.more_horiz, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Personalized Reports', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildGoalChip(LucideIcons.droplets, 'Drink 1.32L water', const Color(0xFF4FC3F7))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildGoalChip(LucideIcons.user, 'Meditate 10 min', const Color(0xFFE57373))),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets remain unchanged ---
  Widget _buildMiniStat(IconData icon, String title, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white,
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightSquare(IconData icon, String title, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildGoalChip(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}