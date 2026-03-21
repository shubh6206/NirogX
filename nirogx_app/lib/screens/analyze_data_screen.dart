import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:nirogx_app/providers/symptom_provider.dart';
// FIX: Imported the new ApiService
import 'package:nirogx_app/services/api_service.dart'; 
import 'package:nirogx_app/models/symptom_log.dart';

class AnalyzeDataScreen extends StatefulWidget {
  const AnalyzeDataScreen({super.key});

  @override
  State<AnalyzeDataScreen> createState() => _AnalyzeDataScreenState();
}

class _AnalyzeDataScreenState extends State<AnalyzeDataScreen> {
  final ImagePicker _picker = ImagePicker();
  // FIX: Instantiated the new ApiService
  final ApiService _apiService = ApiService(); 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SymptomProvider>().loadSymptomLogs();
    });
  }

  // --- Image Scanning Logic ---
  Future<void> _handleScan() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? photo = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (photo == null || !mounted) return;

    final provider = context.read<SymptomProvider>();
    final bytes = await photo.readAsBytes();

    provider.setLoading(true);

    try {
      // FIX: Call the API Service directly for image analysis
      final analysisResult = await _apiService.sendChatMessage(
        "Analyze this medical report and provide a brief summary of findings. Include a disclaimer.",
        imageBytes: bytes,
      );

      final newLog = SymptomLog(
        symptom: "Medical Scan Report",
        severity: 0,
        analysis: analysisResult,
        timestamp: DateTime.now(),
      );
      await provider.saveManualSymptomLog(newLog);

      if (mounted) {
        _showResultDialog(analysisResult, "Scan Analysis");
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar("Scan failed: $e");
    } finally {
      provider.setLoading(false);
    }
  }

  // --- Manual Entry Logic ---
  void _showManualEntryDialog() {
    final TextEditingController symptomController = TextEditingController();
    double severity = 5.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Manual Entry", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: symptomController,
                decoration: InputDecoration(
                  hintText: "E.g., Severe headache and nausea",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C9B7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00C9B7), width: 2),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Text(
                "Severity: ${severity.toInt()}/10",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: severity,
                min: 1,
                max: 10,
                activeColor: const Color(0xFF00C9B7),
                inactiveColor: const Color(0xFF00C9B7).withOpacity(0.2),
                onChanged: (val) => setDialogState(() => severity = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9B7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (symptomController.text.trim().isNotEmpty) {
                  Navigator.pop(context); 
                  await _processManualEntry(symptomController.text.trim(), severity.toInt());
                }
              },
              child: Text("Save & Analyze", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processManualEntry(String symptomText, int severity) async {
    final provider = context.read<SymptomProvider>();
    provider.setLoading(true);

    try {
      // FIX: Use new ApiService and sendChatMessage
      final aiInsight = await _apiService.sendChatMessage(
        "You are a medical AI assistant. The user has logged the following symptom: '$symptomText' with a severity of $severity/10. Provide a brief, 2-sentence safe health tip or insight. Always end with a disclaimer to consult a doctor.",
      );

      final newLog = SymptomLog(
        symptom: symptomText,
        severity: severity,
        analysis: aiInsight,
        timestamp: DateTime.now(),
      );
      
      await provider.saveManualSymptomLog(newLog);

      if (mounted) {
        _showResultDialog(aiInsight, "Symptom Insight");
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar("Failed to analyze symptom: $e");
    } finally {
      provider.setLoading(false);
    }
  }

  // --- UI Helpers ---
  void _showResultDialog(String text, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.activity, color: Color(0xFF00C9B7)),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(text, style: GoogleFonts.poppins(fontSize: 14, height: 1.5)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9B7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text("Done", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color nirogTeal = Color(0xFF00C9B7);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Analyze Health Data",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<SymptomProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 20),

                  /// 📸 Interactive Buttons Row (Scan & Manual)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: provider.isLoading ? null : _handleScan,
                            icon: const Icon(LucideIcons.scanLine, color: Colors.white, size: 20),
                            label: Text("Scan", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: nirogTeal,
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: provider.isLoading ? null : _showManualEntryDialog,
                            icon: const Icon(LucideIcons.edit3, color: nirogTeal, size: 20),
                            label: Text("Manual", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: nirogTeal)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: const BorderSide(color: nirogTeal, width: 2),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Recent Analysis", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 📋 Logs List
                  Expanded(
                    child: provider.symptomLogs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.folderSearch, size: 50, color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                Text("No logs found", style: GoogleFonts.poppins(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: provider.symptomLogs.length,
                            itemBuilder: (context, index) {
                              final log = provider.symptomLogs[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                log.symptom == "Medical Scan Report" ? LucideIcons.fileText : LucideIcons.activity,
                                                color: nirogTeal,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(log.symptom, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                                            ],
                                          ),
                                          Text(_formatDate(log.timestamp), style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        log.analysis,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),

              /// 🔄 Loading Overlay
              if (provider.isLoading)
                Container(
                  color: Colors.white.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: nirogTeal),
                        const SizedBox(height: 16),
                        Text("Processing...", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: nirogTeal)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}