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
import 'package:miit_project/screens/old_student_form_review.dart';
import 'package:miit_project/screens/new_student_form_review.dart';


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

class NewStudentEmailScreen extends StatefulWidget {
  const NewStudentEmailScreen({super.key});

  @override
  State<NewStudentEmailScreen> createState() => _NewStudentEmailScreenState();
}

class _NewStudentEmailScreenState extends State<NewStudentEmailScreen> {
  String major = 'CSE';
  String fullName = '';
  String admissionNo = '';
  bool _isFirebaseInitialized = false;
  bool isLoading = false; // Added missing isLoading variable

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController admissionNoController = TextEditingController();

  // Validation states
  bool _hasCapitalLetters = false;
  bool _hasSpaces = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    fullNameController.addListener(() {
      setState(() {
        fullName = fullNameController.text;
      });
    });
    admissionNoController.addListener(() {
      _validateRollNumber();
    });
  }

  void _validateRollNumber() {
    setState(() {
      admissionNo = admissionNoController.text;
      _hasCapitalLetters = admissionNo.contains(RegExp(r'[A-Z]'));
      _hasSpaces = admissionNo.contains(' ');
    });
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

  @override
  void dispose() {
    fullNameController.dispose();
    admissionNoController.dispose();
    super.dispose();
  }

  Future<void> _showAlert(String title, String message) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Expanded(  // Add this to prevent overflow
                child: Text(title),
              ),
            ],
          ),
          content: ConstrainedBox(  // Add this to constrain content width
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Text(message),
          ),
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

  // Validation method for roll number
  String? _validateRollNumberInput() {
    if (_hasCapitalLetters && _hasSpaces) {
      return tr("capitalLettersAndSpacesError");
    } else if (_hasCapitalLetters) {
      return tr("capitalLettersError");
    } else if (_hasSpaces) {
      return tr("spacesError");
    }
    return null;
  }

  void _submitForm() async {
    if (!_isFirebaseInitialized) {
      _showAlert(tr("error"), tr("firebaseNotInitialized"));
      return;
    }

    if (fullName.isEmpty || admissionNo.isEmpty) {
      _showAlert(tr("warning"), tr("fillAllFields"));
      return;
    }

    // Validate roll number format
    final validationError = _validateRollNumberInput();
    if (validationError != null) {
      _showAlert(tr("invalidFormat"), validationError);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // First, get the admin academic year
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin_academic_year')
          .doc('admin')
          .get();

      if (!adminDoc.exists) {
        _showAlert(tr("error"), tr("adminYearNotSet"));
        setState(() {
          isLoading = false;
        });
        return;
      }

      final adminStartYear = adminDoc.get('astart_year') as int;
      final adminEndYear = adminDoc.get('aend_year') as int;

      // Check if student already exists with both name and roll number in students collection
      final studentsQuery = await FirebaseFirestore.instance
          .collection("students")
          .where("srollno", isEqualTo: admissionNo.trim())
          .where("sname", isEqualTo: fullName.trim())
          .limit(1)
          .get();

      if (studentsQuery.docs.isNotEmpty) {
        // Student exists in students collection
        final studentDoc = studentsQuery.docs.first;
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;

        final academicInfo = studentData['academicInfo'] as Map<String, dynamic>? ?? {};
        final studentStartYear = academicInfo['start_year'] as int?;
        final studentEndYear = academicInfo['end_year'] as int?;
        final studentType = studentData['stype'] as String?;

        setState(() {
          isLoading = false;
        });

        // 🎯 CHECK 1: Is this an OLD student?
        if (studentType == 'old') {
          // OLD Student trying to enroll as NEW → Show SIMPLE ERROR (no review button)
          _showAlert(
            tr("enrollmentError"),
            tr("oldStudentCannotEnrollAsNew"),
          );
          return;
        }

        // 🎯 CHECK 2: Is this a NEW student already enrolled for CURRENT year?
        else if (studentStartYear == adminStartYear && studentEndYear == adminEndYear) {
          // NEW Student already enrolled for CURRENT year → Check enrollStatus
          await _showEnrollmentStatusAlert(studentData, studentId, admissionNo);
          return;
        }
        else {
          // NEW Student exists but NOT for current academic year → Continue enrollment
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewUniRules(
                studentData: studentData,
                studentId: studentId,
                admissionNo: admissionNo,
                fullName: fullName,
              ),
            ),
          );
          return;
        }
      }

      // If student doesn't exist in students collection, check entrance_pass_stu
      final docRef = FirebaseFirestore.instance
          .collection("entrance_pass_stu")
          .doc(admissionNo);

      final docSnapshot = await docRef.get();

      setState(() {
        isLoading = false;
      });

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final storedName = data["fullName"]?.toString() ?? '';

        if (storedName.toLowerCase().trim() == fullName.toLowerCase().trim()) {
          // 🎯 NEW Student (First Time) → Continue to enrollment
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewUniRules(
                admissionNo: admissionNo,
                fullName: fullName,
              ),
            ),
          );
        } else {
          _showAlert(tr("invalidName"), tr("nameDoesNotMatch"));
        }
      } else {
        _showAlert(tr("notFound"), tr("rollNumberNotFound"));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showAlert(tr("error"), "${tr("checkingError")}: ${e.toString()}");
    }
  }

  Future<void> _showEnrollmentStatusAlert(
      Map<String, dynamic> studentData, String studentId, String rollNo) async {
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
        message = tr("alreadyEnrolledAsNewStudent");
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
                  builder: (context) => NewStudentFormReview(
                    studentEmail: studentData['academicInfo']?['eduMail'] ?? '',
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

  @override
  Widget build(BuildContext context) {
    final validationError = _validateRollNumberInput();
    final hasError = validationError != null;

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
              const SizedBox(height: 40),

              // Full Name field with floating label
              SizedBox(
                height: 45,
                child: TextField(
                  controller: fullNameController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: tr('fullName'),
                    labelStyle: const TextStyle(color: Colors.indigo),
                    prefixIcon: const Icon(Icons.person, color: Colors.indigo),
                    filled: true,
                    fillColor: Colors.lightBlue[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.indigo, width: 1.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Admission Number input with validation and floating label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 45,
                    child: TextField(
                      controller: admissionNoController,
                      style: TextStyle(
                        color: hasError ? Colors.red : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: tr('rollNo1'),
                        labelStyle: TextStyle(
                          color: hasError ? Colors.red : Colors.indigo,
                        ),
                        prefixIcon: Icon(
                          Icons.badge,
                          color: hasError ? Colors.red : Colors.indigo,
                        ),
                        filled: true,
                        fillColor: Colors.lightBlue[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        border: const OutlineInputBorder(),
                        focusedBorder: hasError
                            ? const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1.0),
                        )
                            : const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.indigo, width: 1.0),
                        ),
                        errorBorder: hasError
                            ? const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1.0),
                        )
                            : null,
                        focusedErrorBorder: hasError
                            ? const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1.0),
                        )
                            : null,
                      ),
                    ),
                  ),
                  if (hasError && admissionNo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        validationError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Submit button - FIXED: Changed _checkAndNavigate to _submitForm
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
                  onPressed: _submitForm, // Changed from _checkAndNavigate to _submitForm
                ),
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