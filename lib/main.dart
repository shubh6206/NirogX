
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const NirogXApp());
}

class NirogXApp extends StatelessWidget {
  const NirogXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NirogX Health Analyzer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HealthScorePage(title: 'NirogX Health Analysis'),
    );
  }
}

class HealthScorePage extends StatefulWidget {
  const HealthScorePage({super.key, required this.title});
  final String title;

  @override
  State<HealthScorePage> createState() => _HealthScorePageState();
}

class _HealthScorePageState extends State<HealthScorePage> {
  final TextEditingController _metricController = TextEditingController();
  String _healthStatus = "Enter your health metric to begin";
  bool _isLoading = false;

  // IMPORTANT: 10.0.2.2 is the address to reach your Python server 
  // from the Android Emulator.
  final String _apiUrl = "http://127.0.0.1:8000/health-score";

  Future<void> _getHealthScore() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"metric_value": _metricController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _healthStatus = "Health Score: ${data['score']}\nResult: ${data['status']}";
        });
      } else {
        setState(() => _healthStatus = "Error: Server returned ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _healthStatus = "Connection Failed: Check if Python API is running");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _metricController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Health Metric (e.g., Blood Sugar)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _getHealthScore,
                  child: const Text('Calculate NirogX Score'),
                ),
            const SizedBox(height: 30),
            Text(
              _healthStatus,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
