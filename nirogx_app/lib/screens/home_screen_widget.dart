
import 'package:flutter/material.dart';
import 'package:nirogx_app/data/health_repository.dart';
import 'package:nirogx_app/models/health_data.dart';

class HomeScreenWidget extends StatefulWidget {
  const HomeScreenWidget({super.key});

  @override
  State<HomeScreenWidget> createState() => _HomeScreenWidgetState();
}

class _HomeScreenWidgetState extends State<HomeScreenWidget> {
  final HealthRepository _healthRepository = HealthRepository();
  late Future<HealthData> _latestHealthData;

  @override
  void initState() {
    super.initState();
    _latestHealthData = _healthRepository.getLatestHealthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: FutureBuilder<HealthData>(
        future: _latestHealthData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No health data available.'));
          }

          final latestData = snapshot.data!;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Health Score: ${latestData.score}%',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                _buildInsightCard(latestData.insightText),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(String description) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Latest Insight', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8.0),
            Text(description),
          ],
        ),
      ),
    );
  }
}
