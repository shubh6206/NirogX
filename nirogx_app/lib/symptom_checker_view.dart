import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:nirogx_app/providers/symptom_provider.dart';

class SymptomCheckerView extends StatefulWidget {
  const SymptomCheckerView({super.key});

  @override
  State<SymptomCheckerView> createState() => _SymptomCheckerViewState();
}

class _SymptomCheckerViewState extends State<SymptomCheckerView> {
  final TextEditingController _symptomController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(); // Added for backend requirement
  
  // No need for ApiService here; the Provider handles it!
  String _latestAnalysis = '';

  @override
  void initState() {
    super.initState();
    // Ensure logs are loaded when the view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SymptomProvider>().loadSymptomLogs();
    });
  }

  Future<void> _checkSymptoms() async {
    final text = _symptomController.text.trim();
    final duration = _durationController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please describe your symptoms.")),
      );
      return;
    }

    // Default duration if the user doesn't provide one
    final finalDuration = duration.isEmpty ? "Unknown" : duration;

    final provider = context.read<SymptomProvider>();

    // Call the unified provider method that hits FastAPI and saves to SQLite
    await provider.analyzeAndSaveSymptoms(
      text: text,
      duration: finalDuration,
      severity: 0, // Defaulting severity, could be a slider in the UI later
    );

    if (mounted) {
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!)),
        );
      } else {
        // The provider automatically added the new log to index 0 of the list
        setState(() {
          _latestAnalysis = provider.symptomLogs.first.analysis;
        });
        _symptomController.clear();
        _durationController.clear();
        FocusScope.of(context).unfocus(); // Dismiss keyboard
      }
    }
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color nirogTeal = Color(0xFF00C9B7);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Symptom Analysis',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<SymptomProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "How are you feeling?",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Symptoms Input
                    TextField(
                      controller: _symptomController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g., Mild headache and fatigue...',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Duration Input (Required by your FastAPI Contract)
                    TextField(
                      controller: _durationController,
                      decoration: InputDecoration(
                        hintText: 'Duration (e.g., 2 days, since morning)',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: const Icon(LucideIcons.clock, color: Colors.grey),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Analyze Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : _checkSymptoms,
                        icon: const Icon(LucideIcons.activity, size: 20, color: Colors.white),
                        label: Text(
                          provider.isLoading ? 'Analyzing...' : 'Analyze Symptoms',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nirogTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// Result
                    if (_latestAnalysis.isNotEmpty && !provider.isLoading) 
                      _buildResultCard(),

                    const SizedBox(height: 20),

                    /// History
                    if (provider.symptomLogs.isNotEmpty) ...[
                      Text(
                        "Recent Logs",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      ...provider.symptomLogs.take(3).map((log) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE0F7F5),
                              child: Icon(LucideIcons.stethoscope, color: nirogTeal, size: 18),
                            ),
                            title: Text(
                              log.symptom, 
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                            subtitle: Text(
                              log.analysis,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              /// Global Loader
              if (provider.isLoading)
                Container(
                  color: Colors.white.withValues(alpha: 0.6),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: nirogTeal,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00C9B7).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.info, color: Color(0xFF00C9B7), size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Analysis',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            _latestAnalysis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}