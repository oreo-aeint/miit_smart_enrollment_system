import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'old_student_email_screen.dart';
import 'new_student_email_screen.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';
import 'my_drawer.dart';

class EnrollButtonScreen extends StatelessWidget {
  const EnrollButtonScreen({super.key});

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
              colors: [
                Color(0xFF87CEFA),
                Color(0xFFADD8E6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Builder(
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Image.asset(
                      'assets/img_2.png',
                      width: 50,
                      height: 50,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr("vsi"),
                style: AppTextStyles.heading,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: DropdownButton<Locale>(
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
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Centered row with buttons that will wrap if needed
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 40.0, // Horizontal space between buttons
                runSpacing: 40.0, // Vertical space if buttons wrap
                children: [
                  _buildStudentButton(
                    context: context,
                    text: tr('oldStudent'),
                    icon: Icons.person,
                    destination: const OldStudentEmailScreen(),
                  ),
                  _buildStudentButton(
                    context: context,
                    text: tr('newStudent'),
                    icon: Icons.person_add,
                    destination: const NewStudentEmailScreen(),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Back Button
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade100,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                        Icons.arrow_circle_left,
                        size: 40,
                        color: Colors.indigo
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build student buttons
  Widget _buildStudentButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Widget destination,
  }) {
    // Calculate button size based on screen width
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonSize = screenWidth > 600 ? 300 : screenWidth * 0.4;
    final double iconSize = screenWidth > 600 ? 160 : 80;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: RoundedBoxButton(
        text: text,
        icon: icon,
        iconSize: iconSize,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
      ),
    );
  }
}