import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import 'package:nirogx_app/models/health_data.dart';
import 'package:nirogx_app/services/api_service.dart';

class HealthScoreView extends StatefulWidget {
  const HealthScoreView({super.key});

  @override
  State<HealthScoreView> createState() => _HealthScoreViewState();
}

class _HealthScoreViewState extends State<HealthScoreView> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _hrController = TextEditingController();
  final TextEditingController _sleepController = TextEditingController();
  
  String _activityLevel = 'active'; // Default dropdown value

  // State Management
  bool _isEditing = true; // Shows the form first
  bool _isLoading = false;
  String? _errorMessage;
  HealthScoreResult? _scoreResult;
  UserVitalsPayload? _submittedVitals;

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _hrController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  // Mathematics: Calculate BMI from kg and cm
  // Formula: BMI = Weight (kg) / (Height (m))^2
  double _calculateBMI(double weightKg, double heightCm) {
    double heightMeters = heightCm / 100;
    return weightKg / (heightMeters * heightMeters);
  }

  Future<void> _calculateScore() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Extract values and calculate BMI
      final age = int.parse(_ageController.text);
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      final hr = int.parse(_hrController.text);
      final sleep = double.parse(_sleepController.text);
      
      final calculatedBmi = _calculateBMI(weight, height);

      // Create the exact payload your Python FastAPI expects
      final payload = UserVitalsPayload(
        age: age,
        bmi: double.parse(calculatedBmi.toStringAsFixed(1)), // Keep it to 1 decimal
        heartRate: hr,
        sleepHours: sleep,
        activityLevel: _activityLevel,
      );

      // Send to Backend
      final result = await _apiService.calculateHealthScore(payload);

      if (mounted) {
        setState(() {
          _submittedVitals = payload;
          _scoreResult = result;
          _isEditing = false; // Switch to the result view
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Network error: Make sure your FastAPI server is running.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color nirogTeal = Color(0xFF00C9B7);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Health Analysis',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isEditing) 
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, color: nirogTeal, size: 20),
              onPressed: () => setState(() => _isEditing = true), // Go back to form
              tooltip: "Recalculate",
            ),
        ],
      ),
      body: _isLoading 
        ? _buildLoadingState(nirogTeal)
        : _isEditing 
            ? _buildInputForm(nirogTeal) 
            : _buildResultView(nirogTeal),
    );
  }

  // --- 1. THE INPUT FORM ---
  Widget _buildInputForm(Color teal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter Your Vitals",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "We'll use this data to calculate your personalized health index.",
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.red, fontSize: 13)),
              ),

            Row(
              children: [
                Expanded(child: _buildTextField("Age", "Years", _ageController, LucideIcons.calendar)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Heart Rate", "BPM", _hrController, LucideIcons.heartPulse)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField("Weight", "kg", _weightController, LucideIcons.scale)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Height", "cm", _heightController, LucideIcons.ruler)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField("Sleep", "Hours per night", _sleepController, LucideIcons.moon),
            
            const SizedBox(height: 24),
            Text("Activity Level", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _activityLevel,
                  isExpanded: true,
                  icon: const Icon(LucideIcons.chevronDown, color: Colors.grey),
                  style: GoogleFonts.poppins(color: Colors.black87, fontSize: 15),
                  onChanged: (String? newValue) {
                    setState(() => _activityLevel = newValue!);
                  },
                  items: const [
                    DropdownMenuItem(value: 'sedentary', child: Text('Sedentary (Little to no exercise)')),
                    DropdownMenuItem(value: 'light', child: Text('Light (Exercise 1-3 days/week)')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate (Exercise 3-5 days/week)')),
                    DropdownMenuItem(value: 'active', child: Text('Active (Exercise 6-7 days/week)')),
                    DropdownMenuItem(value: 'very_active', child: Text('Very Active (Hard exercise daily)')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _calculateScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: Text("Calculate Health Score", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 18),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  // --- 2. THE RESULT VIEW ---
  Widget _buildResultView(Color teal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
      child: Column(
        children: [
          _buildGaugeCard(teal, _scoreResult!.score),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Vitals', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              _buildLiveBadge(),
            ],
          ),
          const SizedBox(height: 20),
          _buildMetricTile(LucideIcons.heart, 'Heart Rate', '${_submittedVitals!.heartRate} bpm', const Color(0xFFFF4B4B), true),
          _buildMetricTile(LucideIcons.flame, 'Activity', _submittedVitals!.activityLevel.toUpperCase(), const Color(0xFFFF9F0A), true),
          _buildMetricTile(LucideIcons.activity, 'BMI', _submittedVitals!.bmi.toString(), teal, false),
          _buildMetricTile(LucideIcons.moon, 'Sleep', '${_submittedVitals!.sleepHours} hrs', const Color(0xFF5856D6), false),
          const SizedBox(height: 24),
          _buildAISummaryCard(teal),
        ],
      ),
    );
  }

  // (Include _buildGaugeCard, _buildMetricTile, _buildLiveBadge, and _buildAISummaryCard exactly as they were in the previous code block here)
  
  // Example implementation of the gauge for completeness:
  Widget _buildGaugeCard(Color teal, double score) {
    final double progressValue = score / 100.0;
    Color statusColor = teal;
    String statusText = "Excellent";
    
    if (score < 50) {
      statusColor = Colors.redAccent;
      statusText = "Needs Attention";
    } else if (score < 75) {
      statusColor = Colors.orangeAccent;
      statusText = "Good";
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: statusColor.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(height: 210, width: 210, child: CircularProgressIndicator(value: 1.0, strokeWidth: 14, backgroundColor: Colors.transparent, color: Colors.grey[100])),
              SizedBox(
                height: 210, width: 210,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progressValue),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(value: value, strokeWidth: 14, backgroundColor: Colors.transparent, color: statusColor, strokeCap: StrokeCap.round),
                ),
              ),
              Column(
                children: [
                  Text(score.toInt().toString(), style: GoogleFonts.poppins(fontSize: 68, fontWeight: FontWeight.bold, height: 1.1)),
                  Text(statusText, style: GoogleFonts.poppins(fontSize: 18, color: statusColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text('Score calculated via NirogX backend\nbased on your provided vitals.', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String title, String value, Color color, bool isUp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.grey[700])), Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17))]),
          const Spacer(),
          Icon(isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown, color: isUp ? Colors.green : Colors.red, size: 18),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [const CircleAvatar(radius: 3, backgroundColor: Colors.red), const SizedBox(width: 6), Text('LIVE', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))]),
    );
  }

  Widget _buildAISummaryCard(Color teal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [teal, const Color(0xFF007AFF)]), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(LucideIcons.sparkles, color: Colors.white, size: 18), const SizedBox(width: 8), Text('AI Recommendation', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 10),
          Text('Based on your vitals, focus on maintaining your ${_submittedVitals!.activityLevel} lifestyle for optimal health.', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color teal) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: teal),
          const SizedBox(height: 16),
          Text("Crunching the numbers...", style: GoogleFonts.poppins(color: teal, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}