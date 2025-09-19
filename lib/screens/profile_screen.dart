import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:miit_project/screens/home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile photo
  String profilePhotoUrl = '';

  // User data
  String username = 'Phyo Myat Htoo Sint';
  String email = 'phyomyathtoosint@gmail.com';
  String phoneNo = '+959 259539974';

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

            // Menu options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildMenuOption('account'.tr(), Icons.person, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AccountScreen(
                        username: username,
                        email: email,
                        phoneNo: phoneNo,
                        onProfileUpdated: (newUsername, newEmail, newPhoneNo) {
                          setState(() {
                            username = newUsername;
                            email = newEmail;
                            phoneNo = newPhoneNo;
                          });
                        },
                      )),
                    );
                  }),
                  const SizedBox(height: 8),
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

// Account Screen (separate page)
class AccountScreen extends StatefulWidget {
  final String username;
  final String email;
  final String phoneNo;
  final Function(String, String, String) onProfileUpdated;

  const AccountScreen({
    super.key,
    required this.username,
    required this.email,
    required this.phoneNo,
    required this.onProfileUpdated,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.lightBlue[50], // Light blue background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo, // Indigo text color
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.indigo, // Indigo text color
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('account'.tr(), style: const TextStyle(color: Colors.indigo,fontWeight: FontWeight.bold)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountEditScreen(
                  username: widget.username,
                  email: widget.email,
                  phoneNo: widget.phoneNo,
                  onProfileUpdated: widget.onProfileUpdated,
                )),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.white, // Light blue card background
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'accountInformation'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('username'.tr(), widget.username),
                    const SizedBox(height: 8),
                    _buildInfoRow('email'.tr(), widget.email),
                    const SizedBox(height: 8),
                    _buildInfoRow('phoneNumber'.tr(), widget.phoneNo),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Account Edit Screen (separate page)
class AccountEditScreen extends StatefulWidget {
  final String username;
  final String email;
  final String phoneNo;
  final Function(String, String, String) onProfileUpdated;

  const AccountEditScreen({
    super.key,
    required this.username,
    required this.email,
    required this.phoneNo,
    required this.onProfileUpdated,
  });

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  // Controllers for editing
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username;
    _emailController.text = widget.email;
    _phoneController.text = widget.phoneNo;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Handle account information update
  void _updateAccountInfo() {
    widget.onProfileUpdated(
      _usernameController.text,
      _emailController.text,
      _phoneController.text,
    );

    // In a real app, you would save these changes to your backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('profileUpdated'.tr()),
      ),
    );

    // Navigate back to profile screen
    Navigator.pop(context);
  }

  Widget _buildFormField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.indigo),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.indigo),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.indigo),
        ),
        prefixIcon: Icon(icon, color: Colors.indigo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('editProfile'.tr(), style: const TextStyle(color: Colors.indigo,fontWeight: FontWeight.bold)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'accountInformation'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 24),
            _buildFormField('username'.tr(), _usernameController, Icons.alternate_email),
            const SizedBox(height: 16),
            _buildFormField('email'.tr(), _emailController, Icons.email),
            const SizedBox(height: 16),
            _buildFormField('phoneNumber'.tr(), _phoneController, Icons.phone),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _updateAccountInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: Text('save'.tr(), style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Change Password Screen (separate page)
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Password change fields
  String currentPassword = 'miit123';
  String newPassword = '';

  // Controllers for editing
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // Handle password change
  void _changePassword() {
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

    // In a real app, you would verify the current password and update it
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('passwordChanged'.tr()),
      ),
    );

    // Clear password fields and navigate back
    _currentPasswordController.clear();
    _newPasswordController.clear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('changePassword'.tr(), style: const TextStyle(color: Colors.indigo)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'currentPassword',
                labelStyle: TextStyle(color: Colors.indigo),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo),
                ),
                prefixIcon: Icon(Icons.lock, color: Colors.indigo),
              ).copyWith(labelText: 'currentPassword'.tr()),
              onChanged: (value) {
                setState(() {
                  currentPassword = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              enabled: currentPassword.isNotEmpty,
              decoration: InputDecoration(
                labelText: 'newPassword'.tr(),
                labelStyle: const TextStyle(color: Colors.indigo),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo),
                ),
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.indigo),
                hintText: currentPassword.isEmpty ? 'enterCurrentPasswordFirst'.tr() : '',
              ),
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