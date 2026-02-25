import 'package:flutter/material.dart';

class HealthScoreView extends StatelessWidget {
  const HealthScoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Score'),
      ),
      body: const Center(
        child: Text('Health Score functionality will be implemented here.'),
      ),
    );
  }
}
