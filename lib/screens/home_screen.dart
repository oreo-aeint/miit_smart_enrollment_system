import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';
import 'package:miit_project/screens/enroll_button_screen.dart';
import 'admin_login_screen.dart';
import 'package:miit_project/screens/exam_service.dart';

class MIITHomePage extends StatelessWidget {
  const MIITHomePage({super.key});

  @override
  Widget build(BuildContext context) {
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

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Top Row: Logo + Title + Language Switch
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/img_2.png', width: 60, height: 60),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('miit'),
                          style: AppTextStyles.heading,
                        ),
                      ),

                      // Language Switch Button (top-right)
                      DropdownButton<Locale>(
                        underline: const SizedBox(),
                        icon: const Icon(Icons.language, color: Colors.black),
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
                  ),

                  const SizedBox(height: 40),

                  // MIIT Description Card - Aligned to left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(20),
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
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title

                            const SizedBox(height: 12),

                            // About MIIT
                            Text(
                              "About MIIT",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Description text
                            Text(
                              tr('miitDescription'),
                              style: const TextStyle(
                                fontSize: 14,
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
                                _buildStatChip("Est. 2015", Icons.calendar_today),
                                _buildStatChip("CSE · ECE", Icons.computer),
                                _buildStatChip("5 Years", Icons.timer),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom-right buttons
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Bottom buttons with custom styling (no ActionButton component)
                        // Bottom buttons styled like stats chips
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Enroll Button - Chip Style
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
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                        size: 18,
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        tr('enroll'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Admin Login Button - Chip Style
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminLoginScreen(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                        size: 18,
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        tr('adminLogin'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // All your commented code remains here
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for stat chips
  Widget _buildStatChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
       // color: Colors.lightBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
         // color: Colors.lightBlue.withOpacity(0.3),
         // color: Colors.black,
          color: Colors.black,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.black),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              //color: Colors.white,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}