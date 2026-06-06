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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Main Title
                      Text(
                        tr("Welcome!"),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtitle with decorative line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade200, Colors.blue.shade400],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Choose your path",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 30,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade400, Colors.blue.shade200],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Buttons section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 30,
                          runSpacing: 30,
                          children: [
                            _buildStudentButton(
                              context: context,
                              text: tr('oldStudent'),
                              description: tr("verifyExisting"),
                              icon: Icons.person,
                              destination: const OldStudentEmailScreen(),
                              isOldStudent: true,
                            ),
                            _buildStudentButton(
                              context: context,
                              text: tr('newStudent'),
                              description: tr("registerNew"),
                              icon: Icons.person_add,
                              destination: const NewStudentEmailScreen(),
                              isOldStudent: false,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Back Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.bottomLeft,
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
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to build student buttons
  Widget _buildStudentButton({
    required BuildContext context,
    required String text,
    required String description,
    required IconData icon,
    required Widget destination,
    required bool isOldStudent,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Adjust button size based on screen dimensions
    double buttonSize;
    if (screenWidth > 650) {
      buttonSize = 300;
    } else if (screenHeight < 700) {
      buttonSize = 170;
    } else if (screenHeight < 800) {
      buttonSize = 190;
    } else {
      buttonSize = 200;
    }

    // Different colors for old vs new student
    final MaterialColor primaryMaterialColor = isOldStudent ? Colors.blue : Colors.green;
    final Color lightColor = isOldStudent ? Colors.blue.shade50 : Colors.green.shade50;
    final Color primaryColor = primaryMaterialColor;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lightColor,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destination),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: buttonSize > 180 ? 40 : 35,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: buttonSize > 180 ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    color: primaryMaterialColor.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: buttonSize > 180 ? 12 : 10,
                    color: Colors.grey.shade600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                // Small indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isOldStudent ? "Existing" : "New",
                        style: TextStyle(
                          fontSize: buttonSize > 180 ? 11 : 10,
                          color: primaryMaterialColor.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: buttonSize > 180 ? 8 : 7,
                        color: primaryMaterialColor.shade700,
                      ),
                    ],
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