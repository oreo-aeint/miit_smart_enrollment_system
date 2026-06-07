import 'package:flutter/material.dart';  // ✅ THIS WAS MISSING
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';
import 'package:miit_project/screens/enroll_button_screen.dart';
import 'admin_login_screen.dart';
import 'package:miit_project/screens/exam_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:miit_project/screens/admin_drawer.dart';
import 'my_drawer.dart';

class MIITHomePage extends StatelessWidget {
  const MIITHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/img_4.jpg',
              fit: BoxFit.cover,
              color: Colors.white.withOpacity(0.7),
              colorBlendMode: BlendMode.modulate,
            ),
          ),

          // Main Content - Using SingleChildScrollView to prevent overflow
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Logo + Title + Language Switch
                    _buildHeader(context, screenWidth),

                    const SizedBox(height: 30),

                    // MIIT Description Card
                    _buildDescriptionCard(context, screenWidth, screenHeight),

                    const SizedBox(height: 40),

                    // Bottom buttons
                    _buildBottomButtons(context, screenWidth, screenHeight),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/img_2.png',
          width: screenWidth * 0.12,
          height: screenWidth * 0.12,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tr('miit'),
            style: AppTextStyles.heading.copyWith(
              fontSize: screenWidth * 0.07,
            ),
            overflow: TextOverflow.visible,
          ),
        ),
        // Language Switch Button
        DropdownButton<Locale>(
          underline: const SizedBox(),
          icon: Icon(Icons.language, color: Colors.black, size: screenWidth * 0.06),
          value: context.locale,
          onChanged: (Locale? newLocale) {
            if (newLocale != null) {
              context.setLocale(newLocale);
            }
          },
          items: const [
            DropdownMenuItem(
              value: Locale('en'),
              child: Text("English"),
            ),
            DropdownMenuItem(
              value: Locale('my'),
              child: Text("မြန်မာ"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, double screenWidth, double screenHeight) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.9,
      ),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.lightBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About MIIT",
            style: TextStyle(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('miitDescription'),
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              height: 1.6,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Stats chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip("Est. 2015", Icons.calendar_today, screenWidth),
              _buildStatChip("CSE · ECE", Icons.computer, screenWidth),
              _buildStatChip("5 Years", Icons.timer, screenWidth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, double screenWidth, double screenHeight) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Enroll Button
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EnrollButtonScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                color: Colors.lightBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.85),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school,
                    size: screenWidth * 0.045,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('enroll'),
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Admin Login Button
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                 builder: (_) => const AdminLoginScreen(),
                    //builder: (_) => const AdminDrawer(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                color: Colors.lightBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.85),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: screenWidth * 0.045,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('adminLogin'),
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Test Connection Button
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await Supabase.instance.client
                    .from('student_photos')
                    .select()
                    .limit(1);
                print('✅ Supabase query successful: $result');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Connected to Supabase!')),
                );
              } catch (e) {
                print('❌ Supabase query failed: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Connection failed: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.012,
              ),
            ),
            child: Text(
              'Test Supabase Connection',
              style: TextStyle(fontSize: screenWidth * 0.03),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for stat chips
  Widget _buildStatChip(String label, IconData icon, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenWidth * 0.01,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: screenWidth * 0.03, color: Colors.black),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.028,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}