import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:nirogx_app/providers/symptom_provider.dart';

class AnalyzeDataScreen extends StatefulWidget {
  const AnalyzeDataScreen({super.key});

  @override
  State<AnalyzeDataScreen> createState() => _AnalyzeDataScreenState();
}

class _AnalyzeDataScreenState extends State<AnalyzeDataScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SymptomProvider>().loadSymptomLogs();
    });
  }

  Future<void> _handleScan() async {
    // Show options to pick from Camera or Gallery
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
      imageQuality: 80, // Compress for faster upload
    );

    if (photo == null || !mounted) return;

    final provider = context.read<SymptomProvider>();
    final bytes = await photo.readAsBytes();

    // Delegate the complex API and DB work to the provider
    final analysisResult = await provider.analyzeAndSaveImage(bytes);

    if (mounted) {
      if (analysisResult != null) {
        _showResultDialog(analysisResult);
      } else if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showResultDialog(String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(LucideIcons.fileSearch, color: Color(0xFF00C9B7)),
            const SizedBox(width: 8),
            Text(
              "Scan Analysis",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
          ),
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

  @override
  Widget build(BuildContext context) {
    const Color nirogTeal = Color(0xFF00C9B7);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Slightly off-white for depth
      appBar: AppBar(
        title: Text(
          "Analyze Health Data",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
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

                  /// 📸 Scan Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _handleScan,
                      icon: const Icon(LucideIcons.scanLine, color: Colors.white),
                      label: Text(
                        "Scan Medical Report",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nirogTeal,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recent Analysis",
                        style: GoogleFonts.poppins(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
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
                                Text(
                                  "No scans analyzed yet",
                                  style: GoogleFonts.poppins(color: Colors.grey),
                                ),
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
                                                log.symptom == "Medical Scan Report" 
                                                    ? LucideIcons.fileText 
                                                    : LucideIcons.activity,
                                                color: nirogTeal,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                log.symptom,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            _formatDate(log.timestamp),
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        log.analysis,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: Colors.black54,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
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
                        Text(
                          "Analyzing report...",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: nirogTeal,
                          ),
                        ),
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

  // Helper to format the timestamp cleanly
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}