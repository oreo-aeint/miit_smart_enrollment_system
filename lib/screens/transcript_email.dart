import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:miit_project/screens/user_transcript.dart';
import 'my_drawer.dart';
import 'package:miit_project/components/input_text_box.dart';
import 'package:miit_project/components/radio_selector.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class TranscriptEmailScreen extends StatefulWidget {
  const TranscriptEmailScreen({super.key});

  @override
  State<TranscriptEmailScreen> createState() => _TranscriptEmailScreenState();
}

class _TranscriptEmailScreenState extends State<TranscriptEmailScreen> {
  String fullName = '';
  String rollNumber = '';
  bool _isFirebaseInitialized = false;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController rollNumberController = TextEditingController();

  // Validation states
  bool _hasCapitalLetters = false;
  bool _hasSpaces = false;
  bool _hasInvalidFullNameCharacters = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    fullNameController.addListener(() {
      setState(() {
        fullName = fullNameController.text;
        _validateFullName();
      });
    });
    rollNumberController.addListener(() {
      _validateRollNumber();
    });
  }

  void _validateRollNumber() {
    setState(() {
      rollNumber = rollNumberController.text;
      _hasCapitalLetters = rollNumber.contains(RegExp(r'[A-Z]'));
      _hasSpaces = rollNumber.contains(' ');
    });
  }

  void _validateFullName() {
    setState(() {
      // Full name should only contain letters, spaces, and apostrophes
      _hasInvalidFullNameCharacters = fullName.isNotEmpty &&
          fullName.contains(RegExp(r'[0-9!@#$%^&*()_+=\[\]{};:"\\|<>?~`]'));
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
    rollNumberController.dispose();
    super.dispose();
  }

  Future<void> _showAlert(String title, String message, {List<Widget>? actions}) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: actions ?? [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr("ok"), style: const TextStyle(color: Colors.indigo)),
            )
          ],
        );
      },
    );
  }

  Future<void> _showTranscriptRequestAlert(Map<String, dynamic> requestData) async {
    // Get the transcript request status from transcript_requests collection
    final status = requestData['status']?.toString() ?? 'Pending';
    final requestDate = requestData['requestDate'];
    final purpose = requestData['purpose']?.toString() ?? '';
    final lastUpdated = requestData['lastUpdated'];

    String title;
    String message;
    IconData icon;
    Color iconColor;
    List<Widget> actions = [];

    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        title = tr("transcriptRequestApproved");
        message = "${tr("transcriptAlreadyApprovedMessage")}\n\n"
            "${tr("requestDate")}: ${requestDate != null ? _formatDate(requestDate) : 'N/A'}\n"
            "${tr("lastUpdated")}: ${lastUpdated != null ? _formatDate(lastUpdated) : 'N/A'}\n"
            "${tr("purpose")}: $purpose";
        icon = Icons.check_circle;
        iconColor = Colors.green;
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr("ok"), style: const TextStyle(color: Colors.grey)),
          ),
        ];
        break;

      case 'pending':
        title = tr("transcriptRequestPending");
        message = "${tr("transcriptRequestAlreadySubmitted")}\n\n"
            "${tr("requestDate")}: ${requestDate != null ? _formatDate(requestDate) : 'N/A'}\n"
            "${tr("lastUpdated")}: ${lastUpdated != null ? _formatDate(lastUpdated) : 'N/A'}\n"
            "${tr("purpose")}: $purpose";
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
      case 'cancelled':
        title = tr("transcriptRequestRejected");
        message = "${tr("transcriptRequestWasRejected")}\n\n"
            "${tr("requestDate")}: ${requestDate != null ? _formatDate(requestDate) : 'N/A'}\n"
            "${tr("lastUpdated")}: ${lastUpdated != null ? _formatDate(lastUpdated) : 'N/A'}\n"
            "${tr("purpose")}: $purpose";
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
        title = tr("transcriptRequestUnknown");
        message = "${tr("transcriptRequestStatusNotSet")}\n\n"
            "${tr("requestDate")}: ${requestDate != null ? _formatDate(requestDate) : 'N/A'}\n"
            "${tr("lastUpdated")}: ${lastUpdated != null ? _formatDate(lastUpdated) : 'N/A'}\n"
            "${tr("purpose")}: $purpose";
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
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: actions,
        );
      },
    );
  }

  void _navigateToViewTranscript(Map<String, dynamic> requestData) {
    // Navigate to view transcript screen with request data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserTranscript(
          fullName: requestData['studentName']?.toString() ?? '',
          rollNumber: requestData['studentId']?.toString() ?? '',
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return "${date.toDate().toLocal().day}/${date.toDate().toLocal().month}/${date.toDate().toLocal().year}";
    } else if (date is DateTime) {
      return "${date.day}/${date.month}/${date.year}";
    }
    return date.toString();
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

  // Validation method for full name
  String? _validateFullNameInput() {
    if (_hasInvalidFullNameCharacters) {
      return tr("invalidNameCharacters");
    }
    return null;
  }

  void _checkTranscript() async {
    if (!_isFirebaseInitialized) {
      _showAlert(tr("error"), tr("firebaseNotInitialized"));
      return;
    }

    if (fullName.isEmpty || rollNumber.isEmpty) {
      _showAlert(tr("warning"), tr("fillAllFields"));
      return;
    }

    // Validate full name
    final fullNameValidationError = _validateFullNameInput();
    if (fullNameValidationError != null) {
      _showAlert(tr("invalidFormat"), fullNameValidationError);
      return;
    }

    // Validate roll number format
    final rollNumberValidationError = _validateRollNumberInput();
    if (rollNumberValidationError != null) {
      _showAlert(tr("invalidFormat"), rollNumberValidationError);
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
      // FIRST: Check if student exists in students collection
      final studentQuery = await FirebaseFirestore.instance
          .collection("students")
          .where("srollno", isEqualTo: rollNumber.trim())
          .limit(1)
          .get();

      if (studentQuery.docs.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        _showAlert(tr("notFound"), tr("studentNotFound"));
        return;
      }

      // Get student document
      final studentDoc = studentQuery.docs.first;
      final studentData = studentDoc.data();
      final storedName = studentData["sname"]?.toString() ?? '';

      // Check if name matches
      if (storedName.toLowerCase().trim() != fullName.toLowerCase().trim()) {
        Navigator.pop(context); // Close loading dialog
        _showAlert(
          tr("invalidCredentials"),
          tr("nameOrRollNumberMismatch"),
        );
        return;
      }

      // SECOND: Check if transcript request already exists in transcript_requests collection
      final transcriptRequestQuery = await FirebaseFirestore.instance
          .collection("transcript_requests")
          .where("studentId", isEqualTo: rollNumber.trim())
          .where("studentName", isEqualTo: fullName.trim())
          .limit(1)
          .get();

      Navigator.pop(context); // Close loading dialog

      if (transcriptRequestQuery.docs.isNotEmpty) {
        // Transcript request already exists - this is a second-time request
        final requestDoc = transcriptRequestQuery.docs.first;
        final requestData = requestDoc.data();
        await _showTranscriptRequestAlert(requestData);
      } else {
        // No transcript request exists - this is a first-time request
        // Check if transcript data exists in transcript collection
        final transcriptQuery = await FirebaseFirestore.instance
            .collection("transcript")
            .where("studentId", isEqualTo: rollNumber.trim())
            .limit(1)
            .get();

        Map<String, dynamic> transcriptData = {};
        String documentId = '';

        if (transcriptQuery.docs.isNotEmpty) {
          final transcriptDoc = transcriptQuery.docs.first;
          transcriptData = transcriptDoc.data();
          documentId = transcriptDoc.id;
        }

        // Navigate to UserTranscript screen for first-time request
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserTranscript(
              fullName: fullName,
              rollNumber: rollNumber,

            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _showAlert(tr("error"), "${tr("checkingError")}: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final rollNumberValidationError = _validateRollNumberInput();
    final fullNameValidationError = _validateFullNameInput();
    final hasRollNumberError = rollNumberValidationError != null;
    final hasFullNameError = fullNameValidationError != null;

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
                tr("transcriptVerification"),
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

              // Full Name field with validation
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 45,
                    child: TextField(
                      controller: fullNameController,
                      style: TextStyle(
                        color: hasFullNameError ? Colors.red : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: tr('fullName'),
                        labelStyle: TextStyle(
                          color: hasFullNameError ? Colors.red : Colors.indigo,
                        ),
                        prefixIcon: Icon(
                          Icons.person,
                          color: hasFullNameError ? Colors.red : Colors.indigo,
                        ),
                        filled: true,
                        fillColor: Colors.lightBlue[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        border: const OutlineInputBorder(),
                        focusedBorder: hasFullNameError
                            ? const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1.0),
                        )
                            : const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.indigo, width: 1.0),
                        ),
                        errorBorder: hasFullNameError
                            ? const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1.0),
                        )
                            : null,
                        focusedErrorBorder: hasFullNameError
                            ? const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1.0),
                        )
                            : null,
                      ),
                    ),
                  ),
                  if (hasFullNameError && fullName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        fullNameValidationError!,
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

              // Roll Number input with validation
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 45,
                    child: TextField(
                      controller: rollNumberController,
                      style: TextStyle(
                        color: hasRollNumberError ? Colors.red : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: tr('rollNo1'),
                        labelStyle: TextStyle(
                          color: hasRollNumberError ? Colors.red : Colors.indigo,
                        ),
                        prefixIcon: Icon(
                          Icons.badge,
                          color: hasRollNumberError ? Colors.red : Colors.indigo,
                        ),
                        filled: true,
                        fillColor: Colors.lightBlue[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        border: const OutlineInputBorder(),
                        focusedBorder: hasRollNumberError
                            ? const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1.0),
                        )
                            : const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.indigo, width: 1.0),
                        ),
                        errorBorder: hasRollNumberError
                            ? const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1.0),
                        )
                            : null,
                        focusedErrorBorder: hasRollNumberError
                            ? const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1.0),
                        )
                            : null,
                      ),
                    ),
                  ),
                  if (hasRollNumberError && rollNumber.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        rollNumberValidationError!,
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

              // Check Transcript button (localized)
              ActionButton(
                text: tr("check1"),
                icon: Icons.fact_check_rounded,
                onPressed: _checkTranscript,
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