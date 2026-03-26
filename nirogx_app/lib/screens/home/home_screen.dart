import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nirogx_app/providers/symptom_provider.dart';
import 'package:nirogx_app/health_score_view.dart'; // Ensure this exists or remove the route

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color brandTeal = Color(0xFF00C9B7);

  String _userName = "User";
  String? _profilePhotoPath;

  // --- Habit Tracking State ---
  int _waterGlasses = 6; // 1 glass = 0.2L. 6 glasses = 1.2L. Target = 10 (2.0L)
  bool _windDownCompleted = false;
  int _activeMinutes = 25; // Target = 30 mins

  // Helper to calculate how many goals are fully completed
  int get _completedHabitsCount {
    int count = 0;
    if (_waterGlasses >= 10) count++;
    if (_windDownCompleted) count++;
    if (_activeMinutes >= 30) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Fetch the latest database logs the moment the Home Screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SymptomProvider>().loadSymptomLogs();
    });
  }

  // Fetch the data saved from the Profile Screen
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        // Grab the name, but just use the first name for a friendly greeting
        String fullName = prefs.getString('userName') ?? "User";
        _userName = fullName.split(' ')[0]; 
        
        _profilePhotoPath = prefs.getString('profilePhotoPath');
      });
    }
  }

  // --- Core Health Score Algorithm ---
  // Calculates score dynamically based on severity of recent logs
  int _calculateHealthScore(SymptomProvider provider) {
    int baseScore = 100;
    
    if (provider.symptomLogs.isEmpty) return baseScore;

    for (var log in provider.symptomLogs) {
      // Deduct points for logs within the last 24 hours
      if (DateTime.now().difference(log.timestamp).inHours < 24) {
        baseScore -= (log.severity * 2); 
      }
    }
    return baseScore.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // The Consumer listens for updates from your AI Analyze screen
        child: Consumer<SymptomProvider>(
          builder: (context, provider, child) {
            // Calculate dynamic values
            final int healthScore = _calculateHealthScore(provider);
            
            // Get the latest insight or use a default message
            final String latestInsight = provider.symptomLogs.isNotEmpty
                ? provider.symptomLogs.first.analysis
                : "Log a symptom or scan a report to get your first AI insight!";

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header with User Profile
                  _buildHeader(),
                  const SizedBox(height: 25),

                  // 2. Main Health Score Card (Gradient) - NOW DYNAMIC
                  _buildHealthScoreCard(context, healthScore),
                  const SizedBox(height: 30),

                  // --- Interactive Daily Action Plan ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Today\'s Action Plan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text('$_completedHabitsCount/3 Done', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: brandTeal)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 1. Hydration Goal (Tap to add 0.2L)
                  _buildActionCard(
                    icon: LucideIcons.droplets,
                    title: 'Hydration Goal',
                    subtitle: '${(_waterGlasses * 0.2).toStringAsFixed(1)}L / 2.0L completed',
                    progress: (_waterGlasses / 10.0).clamp(0.0, 1.0),
                    color: Colors.blueAccent,
                    isCompleted: _waterGlasses >= 10,
                    onTap: () {
                      setState(() {
                        if (_waterGlasses < 10) {
                          _waterGlasses++;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // 2. Wind Down Routine (Tap to toggle complete/incomplete)
                  _buildActionCard(
                    icon: LucideIcons.moon,
                    title: 'Wind Down Routine',
                    subtitle: _windDownCompleted ? 'Great job!' : 'No screens after 10 PM',
                    progress: _windDownCompleted ? 1.0 : 0.0,
                    color: Colors.indigoAccent,
                    isCompleted: _windDownCompleted,
                    onTap: () {
                      setState(() {
                        _windDownCompleted = !_windDownCompleted;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // 3. Active Minutes (Tap to add 5 minutes of activity)
                  _buildActionCard(
                    icon: LucideIcons.footprints,
                    title: 'Active Minutes',
                    subtitle: '$_activeMinutes / 30 mins',
                    progress: (_activeMinutes / 30.0).clamp(0.0, 1.0),
                    color: Colors.greenAccent.shade700,
                    isCompleted: _activeMinutes >= 30,
                    onTap: () {
                      setState(() {
                        if (_activeMinutes < 30) {
                          _activeMinutes += 5;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 30),

                  // 4. Recent AI Insight - NOW DYNAMIC
                  Text(
                    "AI Insights",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildInsightCard(latestInsight),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, $_userName!",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "Track your health progress today",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFF1F4F8),
          backgroundImage: _profilePhotoPath != null 
              ? FileImage(File(_profilePhotoPath!)) 
              : null,
          child: _profilePhotoPath == null 
              ? const Icon(LucideIcons.user, color: Color(0xFF00C9B7)) 
              : null,
        ),
      ],
    );
  }

  Widget _buildHealthScoreCard(BuildContext context, int score) {
    // Dynamic text based on score
    String statusText = "Looking Great! Keep it up.";
    if (score < 80) statusText = "Needs attention. Stay consistent.";
    if (score < 50) statusText = "Please monitor your symptoms closely.";

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HealthScoreView()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF00C9B7), Color(0xFF007AFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C9B7).withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Overall Health Score",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  // DYNAMIC SCORE HERE
                  Text("$score%",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(statusText,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Container(
              height: 80, width: 80,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.activity, color: Colors.white, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted ? color.withValues(alpha: 0.3) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? color : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isCompleted ? LucideIcons.check : icon,
                  color: isCompleted ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Text and Progress Bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    
                    // Animated Progress Line
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedTheme(
                        data: Theme.of(context),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade100,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(String insightText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align top for longer text
        children: [
          const Icon(LucideIcons.lightbulb, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              // DYNAMIC AI TEXT HERE
              insightText,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}