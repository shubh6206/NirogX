import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nirogx_app/services/health_connect_service.dart';
import 'package:nirogx_app/providers/auth_provider.dart';
import 'package:nirogx_app/services/api_service.dart';

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

  // --- 1. Edit Profile Dialog ---
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
                decoration: const InputDecoration(labelText: "Full Name", focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C9B7)))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email Address", focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C9B7)))),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number", focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C9B7)))),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error picking image.")));
      }
    }
  }

  // --- 2. Functional: Add Vitals Log ---
  void _showVitalsLogSheet() {
    String selectedVital = 'Blood Pressure';
    final TextEditingController valueController = TextEditingController();
    bool isSaving = false; // Prevents the user from tapping 'Save' twice

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Log Manual Vital", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedVital,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: ['Blood Pressure', 'Body Weight', 'Blood Sugar'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value, style: GoogleFonts.poppins()));
                }).toList(),
                onChanged: (newValue) => setSheetState(() => selectedVital = newValue!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                keyboardType: TextInputType.text, // Changed to text to allow the '/' character
                decoration: InputDecoration(
                  labelText: "Enter Value (e.g., 120/80 or 75.5)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              
              // The Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSaving ? Colors.grey : const Color(0xFF00C9B7), 
                    padding: const EdgeInsets.symmetric(vertical: 14)
                  ),
                  onPressed: isSaving ? null : () async {
                    final inputText = valueController.text.trim();
                    if (inputText.isEmpty) return;

                    // Show a loading state on the button
                    setSheetState(() => isSaving = true);

                    try {
                      bool success = false;
                      
                      // 1. Special Handling for Blood Pressure "120/80" format
                      if (selectedVital == 'Blood Pressure' && inputText.contains('/')) {
                        final parts = inputText.split('/');
                        if (parts.length != 2) throw const FormatException("Invalid format");
                        final systolic = double.tryParse(parts[0]);
                        final diastolic = double.tryParse(parts[1]);
                        
                        if (systolic != null && diastolic != null) {
                          // Save as two separate float records so your SQLite database doesn't crash
                          bool s1 = await ApiService().logManualVital('Systolic BP', systolic, 'mmHg');
                          bool s2 = await ApiService().logManualVital('Diastolic BP', diastolic, 'mmHg');
                          success = s1 && s2;
                        } else {
                          throw const FormatException("Invalid BP");
                        }
                      } 
                      // 2. Standard Handling for Weight, Sugar, or a single number
                      else {
                        final val = double.tryParse(inputText);
                        if (val == null) throw const FormatException("Not a number");
                        
                        String unit = 'bpm';
                        if (selectedVital == 'Body Weight') unit = 'kg';
                        if (selectedVital == 'Blood Sugar') unit = 'mg/dL';
                        if (selectedVital == 'Blood Pressure') unit = 'mmHg';
                        
                        success = await ApiService().logManualVital(selectedVital, val, unit);
                      }

                      // 3. UI Feedback
                      if (mounted) {
                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("$selectedVital saved successfully!"), backgroundColor: Colors.green)
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to save. Check your server connection."), backgroundColor: Colors.redAccent)
                          );
                        }
                      }
                    } catch (e) {
                      // Catches typos like "120//80" or "80kg"
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a valid number format."), backgroundColor: Colors.orange)
                        );
                      }
                    } finally {
                      // Turn off the loading state
                      if (mounted) setSheetState(() => isSaving = false);
                    }
                  },
                  child: Text(
                    isSaving ? "Saving..." : "Save Record", 
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. Functional: Add Medical History ---
  void _showMedicalHistorySheet() {
    final TextEditingController conditionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add Medical Condition", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Log allergies, past surgeries, or chronic conditions.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: conditionController,
              decoration: InputDecoration(
                hintText: "e.g., Peanut Allergy, Asthma",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9B7), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  if (conditionController.text.isNotEmpty) {
                    bool success = await ApiService().addMedicalHistory(conditionController.text.trim());
                    
                    if (mounted && success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medical history updated!"), backgroundColor: Colors.green));
                    }
                  }
                },
                child: Text("Add to Profile", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- 4. Functional: Set Goals ---
  void _showSetGoalSheet() {
    double waterGoal = 2.0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Adjust Daily Goals", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Water Intake (Liters)", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text("${waterGoal.toStringAsFixed(1)} L", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF00C9B7))),
                ],
              ),
              Slider(
                value: waterGoal,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                activeColor: const Color(0xFF00C9B7),
                onChanged: (val) => setSheetState(() => waterGoal = val),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C9B7), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    bool success = await ApiService().updateGoal("Water Intake", waterGoal);
                    
                    if (mounted && success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Goals saved!"), backgroundColor: Colors.green));
                    }
                  },
                  child: Text("Save Targets", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Google Health Connect Integration
  Future<void> _linkHealthConnect() async {
    final service = HealthConnectService();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connecting to Health Connect...")));
    bool success = await service.connectAndFetchData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Health Connect synced successfully!"), backgroundColor: Color(0xFF00C9B7)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to sync. Please check permissions."), backgroundColor: Colors.redAccent));
      }
    }
  }

  // Logout
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

              // 2. User Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
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
                      onTap: _showSetGoalSheet, // <-- Replaced placeholder
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
                  Expanded(
                    child: Column(
                      children: [
                        _buildSettingsCard(
                          title: 'Health Goals',
                          icon: LucideIcons.target,
                          subtitle: 'Daily targets',
                          buttonText: 'View Goals',
                          color: brandTeal,
                          onPressed: _showSetGoalSheet, // <-- Replaced placeholder
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          title: 'Medical History',
                          icon: LucideIcons.stethoscope,
                          subtitle: 'View Conditions',
                          buttonText: 'Add New Record',
                          color: brandTeal,
                          onPressed: _showMedicalHistorySheet, // <-- Replaced placeholder
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          title: 'Help & Support',
                          icon: LucideIcons.helpCircle,
                          subtitle: 'FAQS',
                          buttonText: 'Get Help',
                          color: brandTeal,
                          onPressed: () {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Launching support portal...")));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSettingsCard(
                          title: 'Vitals Log',
                          icon: LucideIcons.activity,
                          buttonText: 'Add New Record',
                          color: brandTeal,
                          onPressed: _showVitalsLogSheet, // <-- Replaced placeholder
                        ),
                        const SizedBox(height: 16),
                        
                        // ⌚ Wearable Integration Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.watch, color: brandTeal, size: 28),
                                  const SizedBox(width: 8),
                                  const Icon(LucideIcons.smartphone, color: brandTeal, size: 28),
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
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('Data Privacy', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold))),
                                  Switch(
                                    value: _dataPrivacy,
                                    activeColor: brandTeal,
                                    onChanged: (val) => setState(() => _dataPrivacy = val),
                                  ),
                                ],
                              ),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
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

  Widget _buildSettingsCard({
    required String title, 
    required IconData icon, 
    String? subtitle, 
    String? buttonText, 
    required Color color,
    VoidCallback? onPressed, 
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 16)),
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
                onPressed: onPressed ?? () {},
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