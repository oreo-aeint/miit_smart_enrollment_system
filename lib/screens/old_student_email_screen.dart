import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'my_drawer.dart';
import 'old_student_enrollment_app.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';
import 'package:miit_project/components/input_text_box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:miit_project/screens/old_uni_rules.dart';

class OldStudentEmailScreen extends StatefulWidget {
  const OldStudentEmailScreen({super.key});

  @override
  State<OldStudentEmailScreen> createState() => _OldStudentEmailScreenState();
}

class _OldStudentEmailScreenState extends State<OldStudentEmailScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  bool _isFirebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();

  }

  Future<void> _initializeFirebase() async {
    if (!_isFirebaseInitialized) {
      try {
        await Firebase.initializeApp();
        setState(() {
          _isFirebaseInitialized = true;
        });
      } catch (e) {
        print("Firebase initialization error: $e");
      }
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.indigo, size: 28),
              const SizedBox(width: 10),
              Text(title),
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

  Future<void> _checkAndNavigate() async {
    if (!_isFirebaseInitialized) {
      _showAlert(tr("error"), tr("firebaseNotInitialized"));
      return;
    }

    if (emailController.text.trim().isEmpty) {
      _showAlert(tr("warning"), tr("emailRequired"));
      return;
    }

    final email = emailController.text.trim();
    if (!email.endsWith('@miit.edu.mm')) {
      _showAlert(tr("invalidEmail"), tr("mustBeMiitEmail"));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // First, get the admin academic year from the 'admin' document
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin_academic_year')
          .doc('admin') // Document ID is 'admin' based on your structure
          .get();

      if (!adminDoc.exists) {
        _showAlert(tr("error"), tr("adminYearNotSet"));
        return;
      }

      final adminStartYear = adminDoc.get('astart_year') as int;
      final adminEndYear = adminDoc.get('aend_year') as int;

      // Then check the student
      final querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('academicInfo.eduMail', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showAlert(tr("emailNotFound"), tr("emailNotRegistered"));
      } else {
        final doc = querySnapshot.docs.first;
        final studentData = doc.data();
        final studentId = doc.id;

        // Check if student's start year matches admin's start year
        final academicInfo = studentData['academicInfo'] as Map<String, dynamic>;
        final studentStartYear = academicInfo['start_year'] as int;
        final studentEndYear = academicInfo['end_year'] as int;

        if (studentStartYear == adminStartYear && studentEndYear == adminEndYear) {
          _showAlert(tr("alreadyEnrolled"), tr("alreadyEnrolledMessage"));
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OldUniRules(
                studentData: studentData,
                studentId: studentId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Error checking email: $e");
      _showAlert(tr("error"), "${tr("checkingEmailError")}: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 80),
              InputTextBox(
                label: tr('email'),
                controller: emailController,
                icon: Icons.email,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 170,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : ActionButton(
                  text: tr("check"),
                  icon: Icons.fact_check_rounded,
                  onPressed: _checkAndNavigate,
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Stack(
                  children: [
                    Text(
                      tr("mustRollNo"),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2.2
                          ..color = Colors.white60,
                      ),
                    ),
                    Text(
                      tr("mustRollNo"),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
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