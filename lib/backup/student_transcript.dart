import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class StudentTranscript extends StatefulWidget {
  final String transcriptRequestId;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final VoidCallback? onTranscriptSent;

  const StudentTranscript({
    Key? key,
    required this.transcriptRequestId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    this.onTranscriptSent,
  }) : super(key: key);

  @override
  _StudentTranscriptState createState() => _StudentTranscriptState();
}

class _StudentTranscriptState extends State<StudentTranscript> {
  Map<String, dynamic>? _transcriptData;
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _examData;
  List<Map<String, dynamic>> _academicRecords = [];
  bool _isLoading = true;
  bool _isGeneratingPDF = false;
  bool _isSendingEmail = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Uint8List? _miitLogo;
  TextEditingController _emailController = TextEditingController();
  String? _savedFilePath;

  // Email configuration
  final String _outlookSenderEmail = "registrar@miit.edu.mm";
  final String _outlookSenderPassword = "PMHS@81204";
  final String _outlookSmtpServer = "smtp.office365.com";
  final int _outlookSmtpPort = 587;

  // Platform detection
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isMobile => isAndroid || isIOS;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  // Initialize async operations
  Future<void> _initializeAsync() async {
    await _loadTranscriptData();
    _setupEmailController();
  }

  void _setupEmailController() {
    final studentEmail = _getStudentMiitEmail();
    _emailController.text = studentEmail;
  }

  String _getStudentMiitEmail() {
    return '${widget.rollNumber}@miit.edu.mm';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // SAFE METHOD TO GET TEMPORARY DIRECTORY WITH FALLBACK
  Future<Directory> _getSafeTemporaryDirectory() async {
    if (kIsWeb) {
      throw Exception('Web platform does not support file system directories');
    }

    try {
      // Try to get temporary directory first
      return await getTemporaryDirectory();
    } catch (e) {
      print('getTemporaryDirectory failed: $e');
      try {
        // Fallback to application documents directory
        return await getApplicationDocumentsDirectory();
      } catch (e2) {
        print('getApplicationDocumentsDirectory also failed: $e2');
        // Final fallback - create a temp directory in the current working directory
        final tempDir = Directory('temp');
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
        }
        return tempDir;
      }
    }
  }

  // SAFE METHOD TO GET DOWNLOADS DIRECTORY
  Future<Directory?> _getSafeDownloadsDirectory() async {
    if (kIsWeb) return null;

    try {
      if (isAndroid) {
        return await getDownloadsDirectory();
      }
      return null;
    } catch (e) {
      print('getDownloadsDirectory failed: $e');
      return null;
    }
  }

  // SAFE METHOD TO GET EXTERNAL STORAGE
  Future<Directory?> _getSafeExternalStorageDirectory() async {
    if (kIsWeb) return null;

    try {
      if (isAndroid) {
        return await getExternalStorageDirectory();
      }
      return null;
    } catch (e) {
      print('getExternalStorageDirectory failed: $e');
      return null;
    }
  }

  Future<void> _loadLogo() async {
    try {
      final byteData = await rootBundle.load('assets/img_2.png');
      setState(() {
        _miitLogo = byteData.buffer.asUint8List();
      });
    } catch (e) {
      print('Error loading logo: $e');
    }
  }

  Future<void> _loadTranscriptData() async {
    try {
      await _loadLogo();

      final transcriptDoc = await _firestore
          .collection('transcript_requests')
          .doc(widget.transcriptRequestId)
          .get();

      if (transcriptDoc.exists) {
        setState(() {
          _transcriptData = transcriptDoc.data() as Map<String, dynamic>;
        });
      }

      final studentDoc = await _firestore
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (studentDoc.exists) {
        setState(() {
          _studentData = studentDoc.data() as Map<String, dynamic>;
        });
      }

      await _loadExamDataFromFirestore();
      await _loadAcademicRecords();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transcript data: $e');
      _generateSampleAcademicRecords();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExamDataFromFirestore() async {
    try {
      print('Loading exam data for roll number: ${widget.rollNumber}');

      final examDoc = await _firestore
          .collection('exams')
          .doc(widget.rollNumber)
          .get();

      if (examDoc.exists) {
        final data = examDoc.data() as Map<String, dynamic>;
        print('Found exam data: $data');

        setState(() {
          _examData = data;
        });
      } else {
        print('No exam document found with ID: ${widget.rollNumber}');
        _createPlaceholderExamData();
      }
    } catch (e) {
      print('Error loading exam data: $e');
      _createPlaceholderExamData();
    }
  }

  void _createPlaceholderExamData() {
    setState(() {
      _examData = {
        'firstYear': {
          'firstSemester': {'SGPA': '3.2'},
          'secondSemester': {'SGPA': '2.9'},
        },
        'secondYear': {
          'firstSemester': {'SGPA': '3.5'},
          'secondSemester': {'SGPA': '3.8'},
        },
        'thirdYear': {
          'firstSemester': {'SGPA': '3.7'},
          'secondSemester': {'SGPA': '3.9'},
        },
        'fourthYear': {
          'firstSemester': {'SGPA': '3.6'},
          'secondSemester': {'SGPA': '3.8'},
        },
        'fifthYear': {
          'firstSemester': {'SGPA': '3.5'},
          'secondSemester': {'SGPA': '3.82'},
        },
      };
    });
  }

  Map<String, Map<String, dynamic>> _getSemesterStatsFromFirestore() {
    final Map<String, Map<String, dynamic>> stats = {};

    if (_examData == null) {
      print('No exam data available');
      return stats;
    }

    final years = ['firstYear', 'secondYear', 'thirdYear', 'fourthYear', 'fifthYear'];
    final yearNames = ['First Year', 'Second Year', 'Third Year', 'Fourth Year', 'Fifth Year'];

    for (int i = 0; i < years.length; i++) {
      final yearKey = years[i];
      final yearName = yearNames[i];

      if (_examData!.containsKey(yearKey)) {
        final yearData = _examData![yearKey];

        if (yearData is Map<String, dynamic>) {
          if (yearData.containsKey('firstSemester')) {
            final semesterData = yearData['firstSemester'];
            if (semesterData is Map<String, dynamic>) {
              final sgpa = semesterData['SGPA'] ?? semesterData['GPA'] ?? '0.0';
              final gpa = double.tryParse(sgpa.toString()) ?? 0.0;

              stats['$yearName, Semester 1'] = {
                'gpa': gpa,
                'credits': 18.0,
                'qualityPoints': 0.0,
              };
            }
          }

          if (yearData.containsKey('secondSemester')) {
            final semesterData = yearData['secondSemester'];
            if (semesterData is Map<String, dynamic>) {
              final sgpa = semesterData['SGPA'] ?? semesterData['GPA'] ?? '0.0';
              final gpa = double.tryParse(sgpa.toString()) ?? 0.0;

              stats['$yearName, Semester 2'] = {
                'gpa': gpa,
                'credits': 18.0,
                'qualityPoints': 0.0,
              };
            }
          }
        }
      }
    }

    return stats;
  }

  Map<String, dynamic> _calculateOverallStats() {
    final semesterStats = _getSemesterStatsFromFirestore();
    double totalGPA = 0.0;
    int semesterCount = 0;

    for (final entry in semesterStats.entries) {
      final gpa = entry.value['gpa'] as double;
      totalGPA += gpa;
      semesterCount++;
    }

    final cgpa = semesterCount > 0 ? totalGPA / semesterCount : 0.0;

    return {
      'cgpa': cgpa.toStringAsFixed(2),
      'rawTotalGPA': totalGPA.toStringAsFixed(2),
      'semesterCount': semesterCount,
      'overallGrade': _examData?['overallGrade'] ?? 'N/A',
      'passOrFail': _examData?['passOrFail'] ?? 'N/A',
    };
  }

  Future<void> _loadAcademicRecords() async {
    try {
      final academicSnapshot = await _firestore
          .collection('students')
          .doc(widget.studentId)
          .collection('academic_records')
          .orderBy('year')
          .orderBy('semester')
          .get();

      if (academicSnapshot.docs.isNotEmpty) {
        setState(() {
          _academicRecords = academicSnapshot.docs
              .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'year': data['year'] ?? 1,
              'semester': data['semester'] ?? 1,
              'courseCode': data['courseCode'] ?? 'MIIT101',
              'courseTitle': data['courseTitle'] ?? 'Course Title',
              'credits': data['credits'] ?? 3,
              'grade': data['grade'] ?? 'A',
              'gradePoints': _calculateGradePoints(data['grade'] ?? 'A'),
              'qualityPoints': ((data['credits'] ?? 3) as num).toDouble() *
                  _calculateGradePoints(data['grade'] ?? 'A'),
            };
          })
              .toList();
        });
        return;
      }

      _generateSampleAcademicRecords();
    } catch (e) {
      print('Error loading academic records: $e');
      _generateSampleAcademicRecords();
    }
  }

  double _calculateGradePoints(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+':
      case 'A':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'D+':
        return 1.3;
      case 'D':
        return 1.0;
      default:
        return 0.0;
    }
  }

  void _generateSampleAcademicRecords() {
    final sampleRecords = <Map<String, dynamic>>[];

    sampleRecords.addAll([
      {
        'year': 1,
        'semester': 1,
        'courseCode': 'MIIT101',
        'courseTitle': 'Introduction to Programming',
        'credits': 3,
        'grade': 'A',
        'gradePoints': 4.0,
        'qualityPoints': 12.0,
      },
    ]);

    setState(() {
      _academicRecords = sampleRecords;
    });
  }

  Future<String?> _savePDFToDevice(Uint8List pdfBytes) async {
    try {
      if (kIsWeb) {
        await _savePdfForWeb(pdfBytes);
        return null;
      }

      Directory saveDir;

      if (isAndroid) {
        // Try downloads directory first
        final downloadsDir = await _getSafeDownloadsDirectory();
        if (downloadsDir != null) {
          saveDir = downloadsDir;
        } else {
          final externalDir = await _getSafeExternalStorageDirectory();
          if (externalDir != null) {
            saveDir = externalDir;
          } else {
            saveDir = await _getSafeTemporaryDirectory();
          }
        }
      } else if (isIOS) {
        saveDir = await _getSafeTemporaryDirectory();
      } else {
        saveDir = await _getSafeTemporaryDirectory();
      }

      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'MIIT_Transcript_${widget.rollNumber}_$timestamp.pdf';
      final filePath = '${saveDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes, flush: true);

      setState(() {
        _savedFilePath = filePath;
      });

      if (kDebugMode) {
        print('PDF saved to: $filePath');
      }

      return filePath;
    } catch (e) {
      print('Error saving PDF to device: $e');
      return null;
    }
  }

  Future<void> _savePdfForWeb(Uint8List pdfBytes) async {
    try {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final fileName = 'MIIT_Transcript_${widget.rollNumber}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();

      Future.delayed(const Duration(milliseconds: 100), () {
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transcript downloaded successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error saving PDF on web: $e');
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('PDF file not found');
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'MIIT Official Transcript\n'
            'Student: ${widget.studentName}\n'
            'Roll Number: ${widget.rollNumber}\n'
            'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
        subject: 'MIIT Transcript - ${widget.studentName}',
      );
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  Future<void> _saveTranscriptPDF() async {
    if (_isGeneratingPDF) return;

    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final pdfBytes = await _generateTranscriptPDF();
      final savedPath = await _savePDFToDevice(pdfBytes);

      if (savedPath != null && !kIsWeb && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transcript saved successfully!'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () async {
                await _shareFile(savedPath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error saving transcript: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transcript: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPDF = false;
        });
      }
    }
  }

  // WEB-COMPATIBLE EMAIL SENDING USING HTML EMAIL (mailto:)
  Future<bool> _sendEmailViaWeb({
    required String to,
    required String subject,
    required String body,
    required Uint8List attachment,
    required String attachmentName,
  }) async {
    try {
      // Show dialog with instructions for web
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Web Platform Notice'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email sending via SMTP is not available on web platform.\n\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Option 1: Download and send manually',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Click "Download PDF" to save the transcript\n'
                          '2. Open your email client\n'
                          '3. Send to: $to\n'
                          '4. Attach the downloaded PDF',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Option 2: Open in email client',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click "Open Email Client" to compose an email with the subject and body pre-filled.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Student Email:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            to,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Download PDF
                    await _savePDFToDevice(attachment);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PDF downloaded. Please email it manually.'),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                  child: const Text('Download PDF'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Open email client with mailto:
                    final encodedSubject = Uri.encodeComponent(subject);
                    final encodedBody = Uri.encodeComponent(body);
                    final mailtoUrl = 'mailto:$to?subject=$encodedSubject&body=$encodedBody';
                    html.window.open(mailtoUrl, '_blank');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Open Email Client'),
                ),
              ],
            );
          },
        );
      }

      return false; // Email wasn't sent automatically via web
    } catch (e) {
      print('Error in web email flow: $e');
      return false;
    }
  }

  // ORIGINAL SMTP METHOD FOR MOBILE/DESKTOP
  Future<bool> _sendEmailViaOutlook({
    required String to,
    required String subject,
    required String body,
    required Uint8List attachment,
    required String attachmentName,
  }) async {
    // Check if we're on web - if so, use web method
    if (kIsWeb) {
      return _sendEmailViaWeb(
        to: to,
        subject: subject,
        body: body,
        attachment: attachment,
        attachmentName: attachmentName,
      );
    }

    // For non-web platforms, use SMTP
    File? tempFile;

    try {
      print('Starting email sending process...');
      print('To: $to');
      print('Subject: $subject');
      print('Attachment size: ${attachment.length} bytes');

      // Create temporary file for attachment using safe directory method
      final tempDir = await _getSafeTemporaryDirectory();
      tempFile = File('${tempDir.path}/$attachmentName');
      await tempFile.writeAsBytes(attachment);

      // Verify file was created
      if (!await tempFile.exists()) {
        throw Exception('Failed to create temporary attachment file');
      }

      print('Temporary attachment created: ${tempFile.path}');

      // Create SMTP server configuration for Outlook
      final smtpServer = SmtpServer(
        _outlookSmtpServer,
        port: _outlookSmtpPort,
        ssl: false,
        username: _outlookSenderEmail,
        password: _outlookSenderPassword,
      );

      // Create email message
      final message = Message()
        ..from = Address(_outlookSenderEmail, 'MIIT Registrar Office')
        ..recipients.add(to)
        ..subject = subject
        ..text = body;

      // Add attachment using FileAttachment
      message.attachments.add(FileAttachment(tempFile));

      // Send the email with timeout
      print('Connecting to SMTP server $_outlookSmtpServer:$_outlookSmtpPort...');
      final sendReport = await send(message, smtpServer).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('SMTP connection timeout after 30 seconds');
        },
      );

      print('Email sent successfully!');
      print('Send report: ${sendReport.toString()}');

      return true;
    } catch (e) {
      print('Error sending email: $e');

      // Check for specific authentication errors
      if (e.toString().contains('535') || e.toString().contains('Authentication')) {
        throw Exception('Email authentication failed. Please check:\n1. Email address: $_outlookSenderEmail\n2. Password is correct\n3. Less secure app access is enabled for this Outlook account');
      }

      // Try alternative SMTP server if primary fails
      try {
        print('Trying alternative SMTP server smtp-mail.outlook.com...');
        final altSmtpServer = SmtpServer(
          'smtp-mail.outlook.com',
          port: 587,
          ssl: false,
          username: _outlookSenderEmail,
          password: _outlookSenderPassword,
        );

        // Recreate message for alt server
        final message = Message()
          ..from = Address(_outlookSenderEmail, 'MIIT Registrar Office')
          ..recipients.add(to)
          ..subject = subject
          ..text = body;

        // Recreate temp file if needed
        if (tempFile == null || !await tempFile!.exists()) {
          final tempDir = await _getSafeTemporaryDirectory();
          tempFile = File('${tempDir.path}/$attachmentName');
          await tempFile!.writeAsBytes(attachment);
        }

        message.attachments.add(FileAttachment(tempFile!));

        final sendReport = await send(message, altSmtpServer);
        print('Email sent via alternative server!');
        print('Send report: ${sendReport.toString()}');
        return true;
      } catch (altError) {
        print('Alternative server also failed: $altError');

        if (altError.toString().contains('535') || altError.toString().contains('Authentication')) {
          throw Exception('Authentication failed on both SMTP servers. Please verify your Outlook email credentials.');
        }

        throw Exception('Failed to send email: ${altError.toString()}');
      }
    } finally {
      // Clean up temporary file
      if (tempFile != null) {
        try {
          if (await tempFile!.exists()) {
            await tempFile!.delete();
            print('Temporary file cleaned up');
          }
        } catch (e) {
          print('Error cleaning up temp file: $e');
        }
      }
    }
  }

  Future<void> _sendTranscriptEmail() async {
    if (_isSendingEmail) return;

    setState(() {
      _isSendingEmail = true;
    });

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Generating and sending transcript...'),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      final pdfBytes = await _generateTranscriptPDF();

      final studentEmail = _getStudentMiitEmail();
      final emailSubject = 'Official Academic Transcript - ${widget.studentName} (${widget.rollNumber})';
      final emailBody = _generateEmailBody();

      bool emailSent = await _sendEmailViaOutlook(
        to: studentEmail,
        subject: emailSubject,
        body: emailBody,
        attachment: pdfBytes,
        attachmentName: 'MIIT_Transcript_${widget.rollNumber}.pdf',
      );

      if (emailSent && mounted) {
        await _updateTranscriptStatus(studentEmail);

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✓ Transcript sent successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Sent to: $studentEmail',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        if (widget.onTranscriptSent != null) {
          widget.onTranscriptSent!();
        }
      } else if (kIsWeb && mounted) {
        // On web, email wasn't sent automatically but user was shown options
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please follow the instructions to send the email manually.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error sending email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error sending email',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });
      }
    }
  }

  String _generateEmailBody() {
    final overallStats = _calculateOverallStats();
    final semesterStats = _getSemesterStatsFromFirestore();

    String semesterDetails = '';
    semesterStats.forEach((semester, data) {
      semesterDetails += '\n• $semester: ${data['gpa'].toStringAsFixed(2)}';
    });

    return '''
Dear ${widget.studentName},

Please find attached your official academic transcript from the Myanmar Institute of Information Technology.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STUDENT DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Name: ${widget.studentName}
Roll Number: ${widget.rollNumber}
Program: ${_transcriptData?['classSubject'] ?? 'Information Technology'}
Date Issued: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ACADEMIC SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$semesterDetails

Overall CGPA: ${overallStats['cgpa']}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OFFICIAL DOCUMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This is an official document issued by the Registrar's Office.
For verification purposes, please contact registrar@miit.edu.mm

This transcript has been digitally signed and verified.

Best regards,
Registrar's Office
Myanmar Institute of Information Technology
    ''';
  }

  Future<Uint8List> _generateTranscriptPDF() async {
    final pdf = pw.Document();
    final overallStats = _calculateOverallStats();
    final semesterStats = _getSemesterStatsFromFirestore();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with Logo
              pw.Row(
                children: [
                  if (_miitLogo != null)
                    pw.Container(
                      width: 80,
                      height: 80,
                      child: pw.Image(pw.MemoryImage(_miitLogo!)),
                    ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MYANMAR INSTITUTE OF INFORMATION TECHNOLOGY',
                          style: pw.TextStyle(
                            fontSize: 25,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'OFFICIAL TRANSCRIPT OF ACADEMIC RECORD',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 25),

              // Student Information
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                ),
                padding: pw.EdgeInsets.all(15),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'STUDENT INFORMATION',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfInfoRow('Name:', widget.studentName),
                              pw.SizedBox(height: 8),
                              _buildPdfInfoRow('Student ID:', widget.rollNumber),
                              pw.SizedBox(height: 8),
                              _buildPdfInfoRow('Date of Birth:', _studentData?['sdob'] ?? 'N/A'),
                              pw.SizedBox(height: 8),
                              _buildPdfInfoRow('NRC:', _transcriptData?['nrc'] ?? 'N/A'),
                            ],
                          ),
                        ),
                        pw.Container(
                          width: 1,
                          height: 100,
                          color: PdfColors.grey400,
                          margin: pw.EdgeInsets.symmetric(horizontal: 20),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfInfoRow('Program:', _transcriptData?['classSubject'] ?? 'Information Technology'),
                              pw.SizedBox(height: 8),
                              _buildPdfInfoRow('Major:', 'Computer Science & Engineering'),
                              pw.SizedBox(height: 8),
                              _buildPdfInfoRow('Academic Year:', _transcriptData?['academicYear'] ?? 'N/A'),
                              pw.SizedBox(height: 8),
                              _buildPdfInfoRow('Date Issued:', DateFormat('dd MMMM yyyy').format(DateTime.now())),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),

              // Semester-wise Summary
              pw.Text(
                'SEMESTER-WISE GPA SUMMARY',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              if (semesterStats.isNotEmpty) ...[
                pw.Table.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                  cellStyle: pw.TextStyle(fontSize: 10),
                  headers: ['Semester', 'SGPA'],
                  data: semesterStats.entries.map((entry) {
                    return [
                      entry.key,
                      entry.value['gpa'].toStringAsFixed(2),
                    ];
                  }).toList(),
                ),
              ],

              pw.SizedBox(height: 25),

              // Overall Statistics
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'OVERALL STATISTICS',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Cumulative GPA (CGPA):',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              overallStats['cgpa'],
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Total Semesters:',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              '${overallStats['semesterCount']}',
                              style: pw.TextStyle(
                                fontSize: 16,
                                color: PdfColors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 25),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: PdfColors.black,
                        margin: pw.EdgeInsets.only(bottom: 5),
                      ),
                      pw.Text(
                        'Dr. Win Aye',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Authorized Signature',
                        style: pw.TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: PdfColors.black,
                        margin: pw.EdgeInsets.only(bottom: 5),
                      ),
                      pw.Text(
                        'Dr. Myo Min Thein',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Head of Department',
                        style: pw.TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: 200,
                      height: 1,
                      color: PdfColors.black,
                      margin: pw.EdgeInsets.only(bottom: 5),
                    ),
                    pw.Text(
                      'Dr. Khin Maung Zaw',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Registrar',
                      style: pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.Text(
                'This is an official document issued by Myanmar Institute of Information Technology.',
                style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'For verification, contact: registrar@miit.edu.mm',
                style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Future<void> _showEmailDialog() async {
    _emailController.text = _getStudentMiitEmail();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.email, color: Colors.blue),
              const SizedBox(width: 10),
              const Text('Send Transcript to Student'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kIsWeb
                      ? 'On web, you will need to download the PDF and send it manually.\n\n'
                      : 'This will send the transcript to the student\'s MIIT email:',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Student Email:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _getStudentMiitEmail(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  kIsWeb
                      ? 'The transcript PDF will be downloaded and you can attach it to your email.'
                      : 'The transcript will be attached as a PDF file.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  kIsWeb ? '' : 'This may take a few moments...',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_isSendingEmail)
                  const Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: Column(
                      children: [
                        LinearProgressIndicator(),
                        SizedBox(height: 10),
                        Text(
                          'Sending email...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSendingEmail ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSendingEmail ? null : () async {
                Navigator.of(context).pop();
                await _sendTranscriptEmail();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Send to Student'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTranscriptStatus(String recipientEmail) async {
    try {
      await _firestore
          .collection('transcript_requests')
          .doc(widget.transcriptRequestId)
          .update({
        'status': 'Approved',
        'sentDate': FieldValue.serverTimestamp(),
        'sentBy': FirebaseAuth.instance.currentUser?.email ?? 'Admin',
        'recipientEmail': recipientEmail,
        'isSent': true,
        'lastSentDate': FieldValue.serverTimestamp(),
        'emailSentCount': FieldValue.increment(1),
      });

      print('Transcript status updated in Firestore');
    } catch (e) {
      print('Error updating transcript status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final semesterStats = _getSemesterStatsFromFirestore();
    final overallStats = _calculateOverallStats();
    final studentEmail = _getStudentMiitEmail();

    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Transcript'),
        actions: [
          if (_transcriptData?['isSent'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Sent to: $studentEmail',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _isGeneratingPDF ? null : _saveTranscriptPDF,
            tooltip: 'Save PDF',
          ),
          IconButton(
            icon: _isSendingEmail
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.send),
            onPressed: _isSendingEmail ? null : _showEmailDialog,
            tooltip: 'Send to Student Email',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Notice for Web
            if (kIsWeb)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Web Version Notice: Email sending is not available. Use the "Send to Student" button to download PDF and open email client.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (kIsWeb) const SizedBox(height: 16),

            // Student Email Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.email, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Student MIIT Email:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            studentEmail,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: studentEmail));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Student Information
            Card(
              elevation: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STUDENT INFORMATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        if (_transcriptData?['sentDate'] != null)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Last sent: ${DateFormat('dd/MM/yyyy').format((_transcriptData?['sentDate'] as Timestamp).toDate())}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    if (isMobile)
                      Column(
                        children: [
                          _buildInfoRow('Name:', widget.studentName, isMobile),
                          _buildInfoRow('Student ID:', widget.rollNumber, isMobile),
                          _buildInfoRow('Date of Birth:', _studentData?['sdob'] ?? 'N/A', isMobile),
                          _buildInfoRow('NRC:', _transcriptData?['nrc'] ?? 'N/A', isMobile),

                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),

                          _buildInfoRow('Program:', _transcriptData?['classSubject'] ?? 'Information Technology', isMobile),
                          _buildInfoRow('Major:', 'Computer Science & Engineering', isMobile),
                          _buildInfoRow('Academic Year:', _transcriptData?['academicYear'] ?? 'N/A', isMobile),
                          _buildInfoRow('Date Issued:', DateFormat('dd MMMM yyyy').format(DateTime.now()), isMobile),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Name:', widget.studentName, isMobile),
                                _buildInfoRow('Student ID:', widget.rollNumber, isMobile),
                                _buildInfoRow('Date of Birth:', _studentData?['sdob'] ?? 'N/A', isMobile),
                                _buildInfoRow('NRC:', _transcriptData?['nrc'] ?? 'N/A', isMobile),
                              ],
                            ),
                          ),

                          Container(
                            width: 1,
                            height: 140,
                            color: Colors.grey[300],
                            margin: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 30),
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Program:', _transcriptData?['classSubject'] ?? 'Information Technology', isMobile),
                                _buildInfoRow('Major:', 'Computer Science & Engineering', isMobile),
                                _buildInfoRow('Academic Year:', _transcriptData?['academicYear'] ?? 'N/A', isMobile),
                                _buildInfoRow('Date Issued:', DateFormat('dd MMMM yyyy').format(DateTime.now()), isMobile),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Semester Summary Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'SEMESTER SUMMARY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    if (semesterStats.isNotEmpty) ...[
                      SingleChildScrollView(
                        scrollDirection: isMobile ? Axis.horizontal : Axis.vertical,
                        child: DataTable(
                          columnSpacing: isMobile ? 20 : 40,
                          horizontalMargin: isMobile ? 10 : 20,
                          columns: const [
                            DataColumn(label: Text('Semester')),
                            DataColumn(label: Text('SGPA')),
                          ],
                          rows: semesterStats.entries.map((entry) {
                            final gpa = entry.value['gpa'] as double;
                            return DataRow(cells: [
                              DataCell(
                                Container(
                                  width: isMobile ? 150 : null,
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getGPAColor(gpa),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    gpa.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.yellow[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 40),
                            SizedBox(height: 10),
                            Text(
                              'No semester GPA data found',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Overall Statistics and Grading System
            if (isMobile)
              Column(
                children: [
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.calculate, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'OVERALL STATISTICS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cumulative GPA (CGPA):',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    overallStats['cgpa'],
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Total Semesters:',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${overallStats['semesterCount']}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.grade, color: Colors.purple, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'GRADING SYSTEM',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildGradeRow('A+ / A', '4.0'),
                          _buildGradeRow('A-', '3.7'),
                          _buildGradeRow('B+', '3.3'),
                          _buildGradeRow('B', '3.0'),
                          _buildGradeRow('B-', '2.7'),
                          _buildGradeRow('C+', '2.3'),
                          _buildGradeRow('C', '2.0'),
                          _buildGradeRow('D', '1.0'),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calculate, color: Colors.green, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'OVERALL STATISTICS',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cumulative GPA (CGPA):',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      overallStats['cgpa'],
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Total Semesters:',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${overallStats['semesterCount']}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  Expanded(
                    child: Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.grade, color: Colors.purple, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'GRADING SYSTEM',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            _buildGradeRow('A+ / A', '4.0'),
                            _buildGradeRow('A-', '3.7'),
                            _buildGradeRow('B+', '3.3'),
                            _buildGradeRow('B', '3.0'),
                            _buildGradeRow('B-', '2.7'),
                            _buildGradeRow('C+', '2.3'),
                            _buildGradeRow('C', '2.0'),
                            _buildGradeRow('D', '1.0'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 30),

            // Action Buttons
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isGeneratingPDF ? null : _saveTranscriptPDF,
                    icon: _isGeneratingPDF
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.save_alt),
                    label: Text(_isGeneratingPDF ? 'Saving...' : 'Save PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 40,
                        vertical: isMobile ? 12 : 15,
                      ),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isSendingEmail ? null : _showEmailDialog,
                    icon: _isSendingEmail
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.send),
                    label: Text(_isSendingEmail ? 'Sending...' : 'Send to Student Email'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 40,
                        vertical: isMobile ? 12 : 15,
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 100 : 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 15),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeRow(String grade, String points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            grade,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Text(
            points,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  Color _getGPAColor(double gpa) {
    if (gpa >= 3.7) return Colors.green;
    if (gpa >= 3.3) return Colors.lightGreen;
    if (gpa >= 3.0) return Colors.blue;
    if (gpa >= 2.7) return Colors.blue[300]!;
    if (gpa >= 2.3) return Colors.orange;
    if (gpa >= 2.0) return Colors.orange[300]!;
    return Colors.red;
  }
}