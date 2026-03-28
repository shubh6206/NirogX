import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nirogx_app/models/action_goal.dart';

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

  bool _isLoading = true;
  double _liveScore = 0.0;
  List<ActionGoal> _dailyGoals = [];

  // Helper to calculate how many goals are fully completed
  int get _completedHabitsCount => _dailyGoals.where((g) => g.isCompleted).length;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDataAndStartStream();
    // Fetch the latest database logs the moment the Home Screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SymptomProvider>().loadSymptomLogs();
    });
  }

  Future<void> _loadDataAndStartStream() async {
    // Simulate fetching the personalized goals from your FastAPI backend
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      setState(() {
        _liveScore = 92.0; 
        
        // This list would come from your backend based on AI analysis!
        _dailyGoals = [
          ActionGoal(
            id: 'g1',
            title: 'Hydration Recovery',
            unit: 'L',
            iconName: 'droplets',
            color: Colors.blueAccent,
            currentValue: 1.2,
            targetValue: 2.5, // AI suggested more water due to recent high temp
            isManual: true, // User must log this
          ),
          ActionGoal(
            id: 'g2',
            title: 'Wind Down Routine',
            unit: 'Sessions',
            iconName: 'moon',
            color: Colors.indigoAccent,
            currentValue: 1.0,
            targetValue: 1.0,
            isManual: true,
          ),
          ActionGoal(
            id: 'g3',
            title: 'Active Minutes',
            unit: 'mins',
            iconName: 'footprints',
            color: Colors.greenAccent.shade700,
            currentValue: 25.0,
            targetValue: 30.0,
            isManual: false, // Pulled automatically from Google Health Connect
          ),
        ];
        _isLoading = false;
      });
    }
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

  void _showManualEntrySheet(ActionGoal goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text('Log ${goal.title}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Minus Button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (goal.currentValue > 0) goal.currentValue -= 0.5; // Adjust increment based on your needs
                      });
                      Navigator.pop(context);
                      _showManualEntrySheet(goal); // Refresh sheet
                    },
                    icon: const Icon(LucideIcons.minusCircle, size: 40, color: Colors.grey),
                  ),
                  
                  // Current Value Display
                  Text(
                    '${goal.currentValue.toStringAsFixed(1)}\n${goal.unit}', 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: goal.color),
                  ),
                  
                  // Plus Button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (!goal.isCompleted) goal.currentValue += 0.5;
                      });
                      Navigator.pop(context);
                      _showManualEntrySheet(goal); // Refresh sheet
                    },
                    icon: Icon(LucideIcons.plusCircle, size: 40, color: goal.color),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goal.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Save Progress', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForName(String name) {
    switch (name) {
      case 'droplets': return LucideIcons.droplets;
      case 'moon': return LucideIcons.moon;
      case 'footprints': return LucideIcons.footprints;
      case 'pill': return LucideIcons.pill;
      default: return LucideIcons.activity;
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

                  // --- Dynamic Action Plan ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Today\'s Action Plan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text('$_completedHabitsCount/${_dailyGoals.length} Done', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: brandTeal)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Generate cards dynamically
                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: brandTeal),
                    ))
                  else
                    ..._dailyGoals.map((goal) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildActionCard(
                          icon: _getIconForName(goal.iconName),
                          title: goal.title,
                          subtitle: goal.subtitle,
                          progress: goal.progress,
                          color: goal.color,
                          isCompleted: goal.isCompleted,
                          onTap: () {
                            if (goal.isManual) {
                              _showManualEntrySheet(goal);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${goal.title} updates automatically via Health Connect.")),
                              );
                            }
                          },
                        ),
                      );
                    }),
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