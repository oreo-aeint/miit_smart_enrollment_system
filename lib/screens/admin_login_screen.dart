import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miit_project/screens/admin_drawer.dart';
import 'my_drawer.dart';
import 'package:miit_project/components/input_text_box.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';

// Animated Loading Dots Widget
class AnimatedLoadingDots extends StatefulWidget {
  final Color color;

  const AnimatedLoadingDots({Key? key, this.color = Colors.white}) : super(key: key);

  @override
  State<AnimatedLoadingDots> createState() => _AnimatedLoadingDotsState();
}

class _AnimatedLoadingDotsState extends State<AnimatedLoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAnimatedDot(0),
        const SizedBox(width: 8),
        _buildAnimatedDot(1),
        const SizedBox(width: 8),
        _buildAnimatedDot(2),
      ],
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.3;
        double value = (_controller.value + delay) % 1.0;
        double scale = 0.3 + (value * 0.7);
        double opacity = 0.3 + (value * 0.7);

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adminLoggedIn', false);
    await FirebaseAuth.instance.signOut();
  }

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _clearLoginStatus();
  }

  Future<void> _clearLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adminLoggedIn', false);
  }

  Future<void> _loginAdmin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!email.endsWith('@miit.edu.mm')) {
      _showErrorDialog("Only @miit.edu.mm emails are allowed for admin login.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase Auth login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('adminLoggedIn', true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDrawer()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed.";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format.";
      }

      if (mounted) {
        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("error".tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("ok".tr()),
          ),
        ],
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const MyDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF87CEFA), Color(0xFFADD8E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.asset('assets/img_2.png', width: 50, height: 50),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text("adminLogin".tr(), style: AppTextStyles.heading),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: DropdownButton<Locale>(
                underline: const SizedBox(),
                icon: const Icon(Icons.language, color: Colors.indigo),
                value: context.locale,
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) context.setLocale(newLocale);
                },
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text("English")),
                  DropdownMenuItem(value: Locale('my'), child: Text("မြန်မာ")),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black38, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings,
                    size: 80, color: Colors.indigo),
                const SizedBox(height: 20),
                Text(
                  "adminLogin".tr(),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo),
                ),
                const SizedBox(height: 20),
                InputTextBox(
                  label: "email".tr(),
                  controller: _emailController,
                  icon: Icons.email_outlined,
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: "password".tr(),
                      labelStyle: const TextStyle(color: Colors.indigo),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.indigo),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.indigo,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ========== UPDATED LOGIN BUTTON WITH BEAUTIFUL LOADING ==========
                SizedBox(
                  width: 150,  // ← Short button width
                  child: _isLoading
                      ? Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF87CEFA), Color(0xFFADD8E6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: AnimatedLoadingDots(
                        color: Colors.indigo,
                      ),
                    ),
                  )
                      : ActionButton(
                    text: "login".tr(),
                    icon: Icons.login,
                    onPressed: _loginAdmin,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}