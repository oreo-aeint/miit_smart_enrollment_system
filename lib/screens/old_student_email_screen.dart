import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'my_drawer.dart';
import 'package:miit_project/screens/old_student_form_review.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';
import 'package:miit_project/components/input_text_box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:miit_project/screens/old_uni_rules.dart';
import 'package:miit_project/screens/user_transcript.dart';
import 'package:miit_project/screens/graduated_stu_gpa.dart';

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

  Future<void> _showAlert(String title, String message) async {
    return showDialog(
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

  Future<void> _showEnrollmentStatusAlert(
      Map<String, dynamic> studentData, String studentId, String email) async {
    final academicInfo = studentData['academicInfo'] as Map<String, dynamic>? ?? {};
    final enrollStatus = academicInfo['enrollStatus'] as String? ?? 'pending';

    String title;
    String message;
    IconData icon;
    Color iconColor;
    List<Widget> actions = [];

    switch (enrollStatus.toLowerCase()) {
      case 'enrolled':
        title = tr("enrollmentCompleted");
        message = tr("alreadyEnrolledMessage");
        icon = Icons.check_circle;
        iconColor = Colors.green;
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr("cancel"), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OldStudentFormReview(
                    studentEmail: email,
                    studentId: studentId,
                    studentData: studentData,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
            ),
            child: Text(tr("viewFormReview"), style: const TextStyle(color: Colors.white)),
          ),
        ];
        break;

      case 'pending':
        title = tr("enrollmentPending");
        message = tr("enrollmentStillPending");
        icon = Icons.pending;
        iconColor = Colors.orange;
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr("ok"), style: const TextStyle(color: Colors.indigo)),
          ),
        ];
        break;

      case 'rejected':
        title = tr("enrollmentRejected");
        message = tr("enrollmentHasBeenRejected");
        icon = Icons.cancel;
        iconColor = Colors.red;
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr("ok"), style: const TextStyle(color: Colors.indigo)),
          ),
        ];
        break;

      default:
        title = tr("enrollmentStatusUnknown");
        message = tr("enrollmentStatusNotSet");
        icon = Icons.help;
        iconColor = Colors.grey;
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr("ok"), style: const TextStyle(color: Colors.indigo)),
          ),
        ];
    }

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: actions,
        );
      },
    );
  }

  Future<void> _showGraduationAlert(String studentId, String email, String fullName, String rollNumber) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.school, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Text(tr("congratulations")),
            ],
          ),
          content: Text(tr("You did it! So proud!")),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to GPA page for graduated students
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GraduatedStudentGpaPage( // Replace with your actual page name
                      fullName: fullName,
                      rollNumber: rollNumber,
                      studentId: studentId,
                      email: email,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              child: Text(tr("To View GPA"), style: const TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserTranscript(
                      fullName: fullName,
                      rollNumber: rollNumber,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
              ),
              child: Text(tr("To Request Transcript"), style: const TextStyle(color: Colors.white)),
            ),
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
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin_academic_year')
          .doc('admin')
          .get();

      if (!adminDoc.exists) {
        _showAlert(tr("error"), tr("adminYearNotSet"));
        return;
      }

      dynamic adminStartYearValue = adminDoc.get('astart_year');
      dynamic adminEndYearValue = adminDoc.get('aend_year');

      int? safeParseInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value);
        try {
          return int.parse(value.toString());
        } catch (e) {
          return null;
        }
      }

      final adminStartYear = safeParseInt(adminStartYearValue);
      final adminEndYear = safeParseInt(adminEndYearValue);

      if (adminStartYear == null || adminEndYear == null) {
        _showAlert(tr("error"), tr("adminYearInvalid"));
        return;
      }

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

        final academicInfo = studentData['academicInfo'] as Map<String, dynamic>? ?? {};
        final personalInfo = studentData['personalInfo'] as Map<String, dynamic>? ?? {};
        final academicStatus = academicInfo['academicStatus'] as String? ?? '';

        final fullName = personalInfo['fullName'] as String? ??
            personalInfo['name'] as String? ??
            personalInfo['studentName'] as String? ??
            '';

        final rollNumber = academicInfo['roll_no'] as String? ??
            academicInfo['rollNumber'] as String? ??
            academicInfo['studentId'] as String? ??
            '';

        if (academicStatus.toLowerCase() == 'graduated') {
          await _showGraduationAlert(studentId, email, fullName, rollNumber);
          return;
        }

        dynamic studentStartYearValue = academicInfo['start_year'];
        dynamic studentEndYearValue = academicInfo['end_year'];

        final studentStartYear = safeParseInt(studentStartYearValue);
        final studentEndYear = safeParseInt(studentEndYearValue);

        if (studentStartYear == adminStartYear && studentEndYear == adminEndYear) {
          await _showEnrollmentStatusAlert(studentData, studentId, email);
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
                    ? const Center(
                  child: AnimatedLoadingDots(
                    color: Colors.indigo,
                  ),
                )
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
    );
  }
}