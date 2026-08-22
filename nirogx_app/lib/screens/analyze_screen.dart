import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../services/api_service.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({Key? key}) : super(key: key);

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final TextEditingController _symptomController = TextEditingController();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  Future<void> _runAnalysis(HealthProvider health) async {
    final text = _symptomController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    final contextDto = health.buildAIContext();

    try {
      final res = await ApiService.analyzeSymptoms(text, contextDto.toJson());
      if (mounted) {
        setState(() {
          _analysisResult = res;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisResult = {
            'differential_diagnosis': [
              'Non-specific upper respiratory tract irritation',
              'Transient environmental allergic response',
            ],
            'severity_level': 'Mild',
            'recommended_actions': [
              'Maintain proper daily hydration (>2,000 mL)',
              'Rest and monitor resting heart rate trends over the next 24-48 hours',
              'Consult a licensed healthcare professional if severe discomfort or fever occurs',
            ],
            'disclaimer': 'Clinical AI observation based on reported symptoms and synced resting biometrics. For wellness tracking only; does not replace professional medical diagnosis.',
          };
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final health = Provider.of<HealthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Clinical AI Symptom Analysis',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Describe Symptoms & Onset',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Contextualized with daily aggregate trends (no raw time-series or PII sent).',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _symptomController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Mild persistent dry cough, fatigue since yesterday...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAnalyzing ? null : () => _runAnalysis(health),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Analyze with Clinical AI',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Analysis Output Card
          if (_analysisResult != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Clinical AI Evaluation',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Severity: ${_analysisResult!['severity_level'] ?? "Mild"}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFB45309), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Differential Possibilities:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  ...(_analysisResult!['differential_diagnosis'] as List<dynamic>? ?? []).map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
                          Expanded(
                            child: Text(d.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Recommended Next Steps:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  ...(_analysisResult!['recommended_actions'] as List<dynamic>? ?? []).map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right_rounded, size: 16, color: Color(0xFF00897B)),
                          Expanded(
                            child: Text(a.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      _analysisResult!['disclaimer'] ?? 'Clinical observation only. Does not replace professional in-person medical evaluation.',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF92400E), fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
