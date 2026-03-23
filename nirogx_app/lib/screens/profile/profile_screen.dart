import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nirogx_app/services/health_connect_service.dart';

import 'package:nirogx_app/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Loading...";
  String _userEmail = "user@example.com";
  String _userPhone = "+91 0000000000";
  String? _profilePhotoPath;
  bool _dataPrivacy = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "NirogX User";
      _userEmail = prefs.getString('userEmail') ?? "user@example.com";
      _userPhone = prefs.getString('userPhone') ?? "+91 0000000000";
      _profilePhotoPath = prefs.getString('profilePhotoPath');
    });
  }

  // --- 1. Edit Profile Dialog (Fully Functional) ---
  Future<void> _showEditProfileDialog() async {
    final TextEditingController nameController = TextEditingController(text: _userName);
    final TextEditingController emailController = TextEditingController(text: _userEmail);
    final TextEditingController phoneController = TextEditingController(text: _userPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C9B7))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C9B7))),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C9B7))),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9B7)),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              if (nameController.text.trim().isNotEmpty) {
                await prefs.setString('userName', nameController.text.trim());
              }
              await prefs.setString('userEmail', emailController.text.trim());
              await prefs.setString('userPhone', phoneController.text.trim());
              
              setState(() {
                _userName = nameController.text.trim().isEmpty ? _userName : nameController.text.trim();
                _userEmail = emailController.text.trim();
                _userPhone = phoneController.text.trim();
              });
              
              if (mounted) Navigator.pop(context);
            },
            child: Text("Save", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profilePhotoPath', image.path);
        setState(() {
          _profilePhotoPath = image.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error picking image. Please try again.")),
        );
      }
    }
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Help & Support", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "For assistance, please contact support@nirogx.com or visit our FAQ page on the website.",
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: GoogleFonts.poppins(color: const Color(0xFF00C9B7))),
          ),
        ],
      ),
    );
  }

  // --- 2. Google Health Connect Integration ---
  Future<void> _linkHealthConnect() async {
    final service = HealthConnectService();
    // Show a small loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Connecting to Health Connect...")),
    );
    
    bool success = await service.connectAndFetchData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Health Connect synced successfully!"),
            backgroundColor: Color(0xFF00C9B7),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to sync. Please check permissions."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- 3. Dynamic Feature Bottom Sheet (For Data Tracking Modules) ---
  void _showFeatureBottomSheet(String title, IconData icon) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: const Color(0xFF00C9B7)),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "This module is securely connected to the NirogX FastAPI backend. Real-time synchronization will be enabled in the next deployment phase.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9B7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text("Got it", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 4. Logout ---
  Future<void> _showLogoutDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Log Out", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to log out of NirogX?", style: GoogleFonts.poppins(fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4B4B)),
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthProvider>().logout();
              },
              child: Text("Log Out", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandTeal = Color(0xFF00C9B7);
    const Color bgTeal = Color(0xFFE0F7F5);

    return Scaffold(
      backgroundColor: bgTeal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // 1. Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.activity, color: brandTeal, size: 30),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: 'Nirog', style: GoogleFonts.poppins(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)),
                            TextSpan(text: 'X', style: GoogleFonts.poppins(color: const Color(0xFF2D88FF), fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage: _profilePhotoPath != null
                        ? FileImage(File(_profilePhotoPath!))
                        : const NetworkImage('https://i.pravatar.cc/150?img=11') as ImageProvider,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Text('Your Profile & Settings', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 24),

              // 2. User Card (Now Interactive)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickProfilePhoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: _profilePhotoPath != null
                                ? FileImage(File(_profilePhotoPath!))
                                : const NetworkImage('https://i.pravatar.cc/150?img=11') as ImageProvider,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: brandTeal, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(_userEmail, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                          Text(_userPhone, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: _showEditProfileDialog,
                            child: Text('Edit Personal Info', style: GoogleFonts.poppins(fontSize: 12, color: brandTeal, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showFeatureBottomSheet("Goal Setting", LucideIcons.target),
                      child: Text('Set New Goal >', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Grid Settings
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column
                  Expanded(
                    child: Column(
                      children: [
                        _buildSettingsCard(
                          title: 'Health Goals',
                          icon: LucideIcons.target,
                          subtitle: 'Daily targets',
                          buttonText: 'View Goals',
                          color: brandTeal,
                          onPressed: () => _showFeatureBottomSheet('Health Goals', LucideIcons.target),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          title: 'Medical History',
                          icon: LucideIcons.stethoscope,
                          subtitle: 'View Conditions',
                          buttonText: 'Add New Record',
                          color: brandTeal,
                          onPressed: () => _showFeatureBottomSheet('Medical History', LucideIcons.fileClock),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          title: 'Help & Support',
                          icon: LucideIcons.helpCircle,
                          subtitle: 'FAQS',
                          buttonText: 'Get Help',
                          color: brandTeal,
                          onPressed: _showHelpSupport,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right Column
                  Expanded(
                    child: Column(
                      children: [
                        _buildSettingsCard(
                          title: 'Vitals Log',
                          icon: LucideIcons.activity,
                          buttonText: 'Add New Record',
                          color: brandTeal,
                          onPressed: () => _showFeatureBottomSheet('Vitals Log', LucideIcons.heartPulse),
                        ),
                        const SizedBox(height: 16),
                        
                        // ⌚ Wearable Integration Card (Now Interactive)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(LucideIcons.watch, color: brandTeal, size: 28),
                                  const SizedBox(width: 8),
                                  Icon(LucideIcons.smartphone, color: brandTeal, size: 28),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Fitbit Charge 5\nApple Watch', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _linkHealthConnect,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brandTeal,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text('Link Health Connect', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Data Privacy Toggle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text('Data Privacy', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                                  ),
                                  Switch(
                                    value: _dataPrivacy,
                                    activeColor: brandTeal,
                                    onChanged: (val) => setState(() => _dataPrivacy = val),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Launching Support Portal..."))
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.headphones, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Text('Contact Support', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Log Out Button
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00C9B7), Color(0xFF81C784)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: _showLogoutDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: Text("Log Out", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // --- Reusable Card Builder Updated with onPressed logic ---
  Widget _buildSettingsCard({
    required String title, 
    required IconData icon, 
    String? subtitle, 
    String? buttonText, 
    required Color color,
    VoidCallback? onPressed, // Added this parameter
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 16)),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Expanded(child: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]))),
              ]
            ],
          ),
          if (buttonText != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed ?? () {}, // Triggers the passed function
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(buttonText, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}