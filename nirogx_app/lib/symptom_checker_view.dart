import 'package:flutter/material.dart';
import 'api_models.dart';
import 'api_service.dart';

class SymptomCheckerView extends StatefulWidget {
  const SymptomCheckerView({super.key});

  @override
  _SymptomCheckerViewState createState() => _SymptomCheckerViewState();
}

class _SymptomCheckerViewState extends State<SymptomCheckerView> {
  final _symptomController = TextEditingController();
  final _durationController = TextEditingController();
  String _assessmentResult = '';
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  void _analyzeSymptoms() async {
    if (_symptomController.text.isEmpty || _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final payload = SymptomPayload(
        text: _symptomController.text,
        duration: _durationController.text,
      );
      final result = await _apiService.analyzeSymptoms(payload);
      setState(() {
        _assessmentResult = result.assessment;
      });
    } catch (e) {
      setState(() {
        _assessmentResult = 'Failed to get assessment. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _symptomController,
                decoration: const InputDecoration(
                  labelText: 'Describe your symptoms',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'How long have you had these symptoms?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _analyzeSymptoms,
                      child: const Text('Analyze Symptoms'),
                    ),
              const SizedBox(height: 16),
              if (_assessmentResult.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _assessmentResult,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
