import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:miit_project/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile photo
  String profilePhotoUrl = '';

  // User data - only email remains
  String email = 'admin@miit.edu.mm';

  // Handle logout
  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('logout'.tr()),
          content: Text('confirmLogout'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to HomeScreen directly
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MIITHomePage()),
                );
              },
              child: Text('logout'.tr()),
            ),
          ],
        );
      },
    );
  }

  // Build profile photo
  Widget _buildProfilePhoto() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: profilePhotoUrl.isNotEmpty ? NetworkImage(profilePhotoUrl) : null,
          backgroundColor: Colors.lightBlue[100],
          child: profilePhotoUrl.isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.indigo)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.indigo,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Build menu options
  Widget _buildMenuOption(String title, IconData icon, VoidCallback onTap) {
    return Card(
      color: Colors.lightBlue[50],
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title.tr()),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile photo at center
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: _buildProfilePhoto()),
            ),

            // Display email only
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.lightBlue[50],
                child: ListTile(
                  leading: Icon(Icons.email, color: Colors.indigo),
                  title: Text('email'.tr()),
                  subtitle: Text(email),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Menu options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildMenuOption('changePassword'.tr(), Icons.lock, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                    );
                  }),
                  const SizedBox(height: 8),
                  _buildMenuOption('logout'.tr(), Icons.exit_to_app, _logout),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Change Password Screen (separate page) - Updated with Firebase Auth
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Controllers for editing
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Handle password change with Firebase Auth
  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('enterCurrentPassword'.tr()),
        ),
      );
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('enterNewPassword'.tr()),
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('passwordsDoNotMatch'.tr()),
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('passwordMustBe6Characters'.tr()),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;

      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('userNotLoggedIn'.tr()),
          ),
        );
        return;
      }

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text,
      );

      await user!.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(_newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('passwordChanged'.tr()),
        ),
      );

      // Clear password fields and navigate back
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'passwordChangeFailed'.tr();

      if (e.code == 'wrong-password') {
        errorMessage = 'wrongCurrentPassword'.tr();
      } else if (e.code == 'weak-password') {
        errorMessage = 'weakPassword'.tr();
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'requiresRecentLogin'.tr();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('passwordChangeFailed'.tr()),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordField(
      String label,
      TextEditingController controller,
      bool obscureText,
      VoidCallback onToggleVisibility,
      ) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label.tr(),
        labelStyle: const TextStyle(color: Colors.indigo),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.indigo),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.indigo),
        ),
        prefixIcon: const Icon(Icons.lock, color: Colors.indigo),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.indigo,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('changePassword'.tr(), style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF87CEFA),
                Color(0xFFADD8E6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.indigo),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildPasswordField(
              'currentPassword',
              _currentPasswordController,
              _obscureCurrentPassword,
                  () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              'newPassword',
              _newPasswordController,
              _obscureNewPassword,
                  () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              'confirmPassword',
              _confirmPasswordController,
              _obscureConfirmPassword,
                  () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: Text('changePassword'.tr(), style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}