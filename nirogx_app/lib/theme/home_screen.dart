import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Ensure version ^0.257.0
import 'package:nirogx_app/health_score_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with User Profile
              _buildHeader(),
              const SizedBox(height: 25),

              // 2. Main Health Score Card (Gradient)
              _buildHealthScoreCard(context),
              const SizedBox(height: 30),

              // 3. Quick Actions Row
              Text(
                "Quick Actions",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildQuickActions(context),
              const SizedBox(height: 30),

              // 4. Recent AI Insight
              Text(
                "AI Insights",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildInsightCard(),
            ],
          ),
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
              "Hello, User!",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "Track your health progress today",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFFF1F4F8),
          child: Icon(LucideIcons.user, color: Color(0xFF00C9B7)),
        ),
      ],
    );
  }

  Widget _buildHealthScoreCard(BuildContext context) {
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Overall Health Score",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  SizedBox(height: 8),
                  Text("85%",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Looking Great! Keep it up.",
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
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

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.lightbulb, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "Your heart rate has been stable this week. Great consistency!",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}