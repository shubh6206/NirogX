import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/health_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final health = Provider.of<HealthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Clinical Profile & Sync Controls',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF00897B),
                  child: Text(
                    user?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Alex Mercer',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        user?.email ?? 'user@example.com',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age: ${user?.age} • BMI: ${user?.bmi} • Height: ${user?.height}cm',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF00897B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Medical History
          Container(
            padding: const EdgeInsets.all(16),
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
                      'Medical History & Chronic Conditions',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF00897B), size: 20),
                      onPressed: () => _showAddConditionDialog(context, health),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: health.medicalHistory.map((cond) {
                    final idx = health.medicalHistory.indexOf(cond);
                    return Chip(
                      label: Text(cond, style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFF1F5F9),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => health.removeMedicalCondition(idx),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Platform Connections
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connected Health Platforms',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sensors_rounded, color: Color(0xFF00897B)),
                  ),
                  title: const Text('Android Health Connect / HealthKit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    health.isConnected ? 'Active & Synchronized' : 'Permissions needed',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => health.connectHealthPlatform(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      health.isConnected ? 'Resync' : 'Connect',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Privacy, Disconnect & Purge Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Sovereignty & Privacy Controls',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),

                // Disconnect Platform
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link_off_rounded, color: Color(0xFF64748B)),
                  title: const Text('Disconnect Health Sync', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Halts ongoing synchronization while retaining existing logs.', style: TextStyle(fontSize: 11)),
                  trailing: OutlinedButton(
                    onPressed: () => health.disconnectPlatform(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Disconnect', style: TextStyle(fontSize: 11)),
                  ),
                ),

                const Divider(height: 16, color: Color(0xFFF1F5F9)),

                // Purge Local Data
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
                  title: const Text('Purge Local Health Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                  subtitle: const Text('Wipes cached records and resets cursor from this device.', style: TextStyle(fontSize: 11)),
                  trailing: ElevatedButton(
                    onPressed: () => _showPurgeConfirmation(context, health),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      foregroundColor: const Color(0xFFDC2626),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Purge', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showAddConditionDialog(BuildContext context, HealthProvider health) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Clinical Condition', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Type 2 Diabetes, Hypertension'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                health.addMedicalCondition(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPurgeConfirmation(BuildContext context, HealthProvider health) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purge Local Records?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: const Text(
          'This will permanently delete all imported health records stored locally in NirogX. It does NOT delete records from Apple Health or Health Connect.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              health.purgeLocalData();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Confirm Purge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
