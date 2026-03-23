import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:nirogx_app/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle Local Login
  Future<void> _handleLogin() async {
    // Basic validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate a brief network/processing delay
    await Future.delayed(const Duration(seconds: 1));

    // Store login state locally so the user stays logged in
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', _emailController.text.trim());

    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/'); // Route to Home Screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const Color nirogTeal = Color(0xFF00C9B7);
    const Color nirogBlue = Color(0xFF2D88FF);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Blurred Background Image
          Container(
            height: size.height,
            width: size.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                // Placeholder matching the mountain/nature vibe. Replace with AssetImage if you have the local file.
                image: NetworkImage('https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Dark overlay to make the card pop
          Container(
            color: Colors.black.withValues(alpha: 0.2),
          ),

          // 2. Main Centered Card Area
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    // The outer light cyan card
                    color: const Color(0xFFD4F1F4).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 30),
                      
                      // Logo Icon Placeholder (Using LucideIcons to mimic the Caduceus)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        child: const Icon(LucideIcons.activity, size: 48, color: nirogTeal),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // RichText for the NirogX Logo (Black and Blue)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Nirog',
                              style: GoogleFonts.poppins(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'X',
                              style: GoogleFonts.poppins(color: nirogBlue, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // 3. The Inner White Login Card
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Welcome to NirogX",
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 24),

                            // Email Field
                            _buildTextField(
                              controller: _emailController,
                              hintText: 'Email',
                              icon: LucideIcons.mail,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            _buildTextField(
                              controller: _passwordController,
                              hintText: 'Password',
                              icon: LucideIcons.lock,
                              isPassword: true,
                            ),

                            // Forgot Password
                            Align(
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () {}, // Future feature
                                child: Text(
                                  "Forgot Password?",
                                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Gradient Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [nirogTeal, nirogBlue],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(
                                          "Log In",
                                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            Text("or continue with", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
                            const SizedBox(height: 16),

                            // Social Login Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(Icons.facebook, const Color(0xFF1877F2)),
                                const SizedBox(width: 20),
                                _buildSocialButton(Icons.g_mobiledata, const Color(0xFFDB4437)), // Close enough to Google icon
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Sign Up Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account? ", style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12)),
                                GestureDetector(
                                  onTap: () => context.push('/signup'),
                                  child: Text(
                                    "Sign Up",
                                    style: GoogleFonts.poppins(color: nirogBlue, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Demo Mode Button
                            TextButton(
                              onPressed: () {
                                context.read<AuthProvider>().setDemoMode(true);
                                context.go('/');
                              },
                              child: Text(
                                "Try Demo Mode",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        suffixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C9B7)),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}