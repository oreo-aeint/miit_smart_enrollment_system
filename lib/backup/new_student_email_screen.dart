import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'my_drawer.dart';
import 'package:miit_project/components/input_text_box.dart';
import 'package:miit_project/components/radio_selector.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';
import 'new_student_enrollment_app.dart';
import 'package:miit_project/screens/new_uni_rules.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';



class NewStudentEmailScreen extends StatefulWidget {
  const NewStudentEmailScreen({super.key});

  @override
  State<NewStudentEmailScreen> createState() => _NewStudentEmailScreenState();
}

class _NewStudentEmailScreenState extends State<NewStudentEmailScreen> {
  String major = 'CSE';
  String fullName = '';
  String admissionNo = '';

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController admissionNoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fullNameController.addListener(() {
      setState(() {
        fullName = fullNameController.text;
      });
    });
    admissionNoController.addListener(() {
      setState(() {
        admissionNo = admissionNoController.text;
      });
    });
  }

  @override
  void dispose() {
    fullNameController.dispose();
    admissionNoController.dispose();
    super.dispose();
  }


  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(tr("infoNotYet")),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr("ok"), style: const TextStyle(color: Colors.indigo)),
            )
          ],
        );
      },
    );
  }

  void _submitForm() async {
    if (fullName.isEmpty || admissionNo.isEmpty) {
      _showAlert(tr("warning"));
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Check if student already exists with both name and roll number
      final studentsQuery = await FirebaseFirestore.instance
          .collection("students")
          .where("srollno", isEqualTo: admissionNo.trim())
          .where("sname", isEqualTo: fullName.trim())
          .get();

      if (studentsQuery.docs.isNotEmpty) {
        // Student already enrolled
        Navigator.pop(context);
        _showAlert("You are already enrolled!");
        return;
      }

      // Continue with your existing enrollment process
      final docRef = FirebaseFirestore.instance
          .collection("entrance_pass_stu")
          .doc(admissionNo);

      final docSnapshot = await docRef.get();

      Navigator.pop(context);

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final storedName = data["fullName"];

        if (storedName.toLowerCase().trim() == fullName.toLowerCase().trim()) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewUniRules(),
            ),
          );
        } else {
          _showAlert("⚠️ Name does not match for this Roll Number!");
        }
      } else {
        _showAlert("⚠️ Roll Number not found!");
      }
    } catch (e) {
      Navigator.pop(context);
      _showAlert("Error: $e");
    }
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
              colors: [
                Color(0xFF87CEFA), // Light Sky Blue
                Color(0xFFADD8E6), // Light Blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            // Drawer / Logo
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

            // Title Text (localized)
            Expanded(
              child: Text(
                tr("vsi"),
                style: AppTextStyles.heading,
              ),
            ),

            // Language Switch Dropdown (Top-Right)
            Padding(
              padding: const EdgeInsets.only(right: 16.0), // moves dropdown left a bit
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Full Name (localized)
              InputTextBox(
                label: tr('fullName'),
                controller: fullNameController,
                onChanged: (val) => setState(() => fullName = val),
                icon: Icons.person,
              ),
              const SizedBox(height: 20),

              // Admission Number input (localized)
              InputTextBox(
                label: tr('rollNo1'),
                controller: admissionNoController,
                onChanged: (val) => setState(() => admissionNo = val),
                icon: Icons.badge,
              ),
              const SizedBox(height: 20),


              // Submit button (localized)
              ActionButton(
                text: tr("check1"),
                icon: Icons.fact_check_rounded,
                onPressed: _submitForm,
              ),

              const Spacer(),

              // Back button
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
                            Icons.arrow_circle_left, size: 40, color: Colors.indigo)
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
