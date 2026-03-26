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
  String _userName = "User";
  String? _profilePhotoPath;

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

                  // 3. Quick Actions Row
                  Text(
                    "Quick Actions",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildQuickActions(context),
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionItem(context, LucideIcons.search, "Analyze", const Color(0xFFE0F7F5)),
        _actionItem(context, LucideIcons.messageCircle, "AI Chat", const Color(0xFFE3F2FD)),
        _actionItem(context, LucideIcons.calendar, "Reports", const Color(0xFFFFF3E0)),
      ],
    );
  }

  Widget _actionItem(BuildContext context, IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: Colors.black87, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
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