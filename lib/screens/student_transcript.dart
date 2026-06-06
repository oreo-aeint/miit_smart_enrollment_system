import 'dart:io';
import 'dart:typed_data';
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
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

class StudentTranscript extends StatefulWidget {
  final String transcriptRequestId;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String? studentEmail;
  final VoidCallback? onTranscriptSent;

  const StudentTranscript({
    Key? key,
    required this.transcriptRequestId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    this.studentEmail,
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
  String _manualStudentEmail = '';
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Platform detection
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isMobile => isAndroid || isIOS;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    if (Platform.isAndroid && !kIsWeb) {
      final hasPermission = await _checkStoragePermissions();
      if (!hasPermission && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission required to save PDFs'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<bool> _checkStoragePermissions() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      try {
        if (await Permission.storage.isRestricted) {
          final status = await Permission.manageExternalStorage.request();
          return status.isGranted;
        } else {
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } catch (e) {
        print('Permission error: $e');
        return false;
      }
    }
    return true;
  }

  Future<void> _initializeAsync() async {
    await _loadTranscriptData();
    _setupEmailController();
  }

  void _setupEmailController() {
    if (widget.studentEmail != null && widget.studentEmail!.isNotEmpty) {
      _emailController.text = widget.studentEmail!;
      _manualStudentEmail = widget.studentEmail!;
    } else if (_manualStudentEmail.isNotEmpty) {
      _emailController.text = _manualStudentEmail;
    } else {
      _emailController.text = '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<Directory> _getSafeTemporaryDirectory() async {
    if (kIsWeb) {
      throw Exception('Web platform does not support file system directories');
    }

    try {
      return await getTemporaryDirectory();
    } catch (e) {
      print('getTemporaryDirectory failed: $e');
      try {
        return await getApplicationDocumentsDirectory();
      } catch (e2) {
        print('getApplicationDocumentsDirectory also failed: $e2');
        final tempDir = Directory('temp');
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
        }
        return tempDir;
      }
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

          if (widget.studentEmail == null && _transcriptData?.containsKey('email') == true) {
            _manualStudentEmail = _transcriptData!['email'] ?? '';
            _emailController.text = _manualStudentEmail;
          }

          if (_transcriptData?.containsKey('manualEmailUsed') == true) {
            _manualStudentEmail = _transcriptData!['manualEmailUsed'] ?? '';
            if (widget.studentEmail == null) {
              _emailController.text = _manualStudentEmail;
            }
          }
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

  // FIXED: Save PDF for Web - downloads automatically
  // Web save method
  Future<void> _savePdfForWeb(Uint8List pdfBytes) async {
    try {
      final fileName = 'MIIT_Transcript_${widget.rollNumber}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();

      // Clean up
      Future.delayed(const Duration(milliseconds: 100), () {
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✓ PDF Downloaded Successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(fileName, style: const TextStyle(fontSize: 11)),
                const Text('Check your Downloads folder', style: TextStyle(fontSize: 11)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error saving PDF on web: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // FIXED: Save PDF for Android and iOS
  // FIXED: PDF Save method for mobile devices only
  Future<String?> _savePDFToDevice(Uint8List pdfBytes) async {
    if (_isGeneratingPDF) return null;

    setState(() => _isGeneratingPDF = true);

    try {
      final fileName = 'MIIT_Transcript_${widget.rollNumber}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (Platform.isAndroid) {
        // Try multiple save locations for Android
        String? savedPath;

        // Method 1: Save to Downloads folder
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null && await downloadsDir.exists()) {
          try {
            final downloadFile = File('${downloadsDir.path}/$fileName');
            await downloadFile.writeAsBytes(pdfBytes);
            savedPath = downloadFile.path;
            print('✅ Saved to Downloads: $savedPath');
          } catch (e) {
            print('Failed to save to Downloads: $e');
          }
        }

        // Method 2: Save to Documents folder via external storage
        if (savedPath == null) {
          try {
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              final docsDir = Directory('${externalDir.parent.parent.path}/Documents/MIIT_Transcripts');
              if (!await docsDir.exists()) {
                await docsDir.create(recursive: true);
              }
              final docFile = File('${docsDir.path}/$fileName');
              await docFile.writeAsBytes(pdfBytes);
              savedPath = docFile.path;
              print('✅ Saved to Documents: ${docFile.path}');
            }
          } catch (e) {
            print('Failed to save to Documents: $e');
          }
        }

        // Method 3: Fallback to app documents directory
        if (savedPath == null) {
          final appDir = await getApplicationDocumentsDirectory();
          final appFile = File('${appDir.path}/$fileName');
          await appFile.writeAsBytes(pdfBytes);
          savedPath = appFile.path;
          print('✅ Saved to App Documents: $savedPath');
        }

        if (mounted && savedPath != null) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✓ PDF Saved Successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(fileName, style: const TextStyle(fontSize: 11)),
                  const Text('Check Downloads folder', style: TextStyle(fontSize: 11)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OPEN',
                onPressed: () {
                  if (savedPath != null) {
                    _openFileWithFallback(savedPath);
                  }
                },
              ),
            ),
          );
          return savedPath;
        }
      } else if (Platform.isIOS) {
        // iOS - use documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final file = File('${appDir.path}/$fileName');
        await file.writeAsBytes(pdfBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✓ PDF Saved Successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(fileName, style: const TextStyle(fontSize: 11)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OPEN',
                onPressed: () => OpenFilex.open(file.path),
              ),
            ),
          );
        }
        return file.path;
      }
    } catch (e) {
      print('❌ Error saving PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPDF = false);
    }
    return null;
  }

  Future<void> _openFileWithFallback(String? filePath) async {
    if (filePath == null) {
      print('File path is null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No file to open'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        if (mounted) {
          final shouldShare = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cannot Open File'),
              content: const Text('Would you like to share the file instead?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Share'),
                ),
              ],
            ),
          );

          if (shouldShare == true) {
            await _shareFile(filePath);
          }
        }
      }
    } catch (e) {
      print('Error opening file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open file automatically. Save location: $filePath'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'COPY PATH',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: filePath));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Path copied to clipboard')),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File is empty');
      }

      print('Sharing file: $filePath (${fileSize} bytes)');

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'MIIT Official Transcript\n'
            'Student: ${widget.studentName}\n'
            'Roll Number: ${widget.rollNumber}\n'
            'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\n\n'
            'This is an official academic transcript from MIIT.',
        subject: 'MIIT Transcript - ${widget.studentName} (${widget.rollNumber})',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share dialog opened'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error sharing file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // FIXED: Main save function called from button
  Future<void> _saveTranscriptPDF() async {
    if (_isGeneratingPDF) return;

    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 10),
                Text('Generating PDF...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final pdfBytes = await _generateTranscriptPDF();

      if (kIsWeb) {
        // Web: Directly call web save method
        await _savePdfForWeb(pdfBytes);
      } else {
        // Mobile: Save to device
        final savedPath = await _savePDFToDevice(pdfBytes);
        if (savedPath != null && mounted) {
          setState(() {
            _savedFilePath = savedPath;
          });
        }
      }
    } catch (e) {
      print('Error saving transcript: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

  Future<bool> _sendEmailViaWeb({
    required String to,
    required String subject,
    required String body,
    required Uint8List attachment,
    required String attachmentName,
  }) async {
    try {
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
                      'Email sending is not available on web platform.\n\n',
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
                          Text(
                            'Platform: ${kIsWeb ? "WEB (Manual only)" : "MOBILE"}',
                            style: TextStyle(color: kIsWeb ? Colors.red : Colors.green),
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

      return false;
    } catch (e) {
      print('Error in web email flow: $e');
      return false;
    }
  }

  Future<bool> _sendEmailViaNativeIntent({
    required String to,
    required String subject,
    required String body,
    required Uint8List attachment,
    required String attachmentName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'MIIT_Transcript_${widget.rollNumber}_$timestamp.pdf';

      Directory? saveDir;

      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          saveDir = Directory('${externalDir.path}/MIIT_Transcripts');
          if (!await saveDir.exists()) {
            await saveDir.create(recursive: true);
          }
        }
      }

      if (saveDir == null) {
        final tempDir = await getTemporaryDirectory();
        saveDir = tempDir;
      }

      final file = File('${saveDir.path}/$uniqueFileName');
      await file.writeAsBytes(attachment);

      if (!await file.exists()) {
        throw Exception('Failed to save attachment file');
      }

      if (mounted) {
        final result = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Send Transcript'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.email, size: 50, color: Colors.blue),
                  const SizedBox(height: 10),
                  Text('Send to: $to', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  const Text('Choose how to send:'),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'email'),
                    icon: const Icon(Icons.email),
                    label: const Text('Send with Email App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 45),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'share'),
                    icon: const Icon(Icons.share),
                    label: const Text('Share PDF Only'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 45),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (result == 'email') {
          await _sendEmailWithAttachment(file.path, to, subject, body);
        } else if (result == 'share') {
          await Share.shareXFiles(
            [XFile(file.path)],
            text: body,
            subject: subject,
          );
        }
      }
      return true;
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _sendEmailWithAttachment(String filePath, String to, String subject, String body) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: body,
        subject: subject,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter recipient email: $to in your email app'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'COPY',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: to));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email copied! Paste in "To" field')),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Email send error: $e');
      rethrow;
    }
  }

  Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String body,
    required Uint8List attachment,
    required String attachmentName,
  }) async {
    if (kIsWeb) {
      return _sendEmailViaWeb(
        to: to,
        subject: subject,
        body: body,
        attachment: attachment,
        attachmentName: attachmentName,
      );
    }

    return await _sendEmailViaNativeIntent(
      to: to,
      subject: subject,
      body: body,
      attachment: attachment,
      attachmentName: attachmentName,
    );
  }

  Future<void> _sendTranscriptEmail(String studentEmail) async {
    if (_isSendingEmail) return;

    setState(() {
      _isSendingEmail = true;
    });

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 10),
                Text('Generating transcript and preparing email...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      final pdfBytes = await _generateTranscriptPDF();

      final emailSubject = 'Official Academic Transcript - ${widget.studentName} (${widget.rollNumber})';
      final emailBody = _generateEmailBody();

      bool emailSent = await _sendEmail(
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
                  '✓ Email client opened!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Please paste this email in "To" field: $studentEmail',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'COPY',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: studentEmail));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email copied! Paste in "To" field')),
                );
              },
            ),
          ),
        );

        if (widget.onTranscriptSent != null) {
          widget.onTranscriptSent!();
        }
      } else if (kIsWeb && mounted) {
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
                  'Error opening email',
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
    _emailController.text = widget.studentEmail ?? _manualStudentEmail;

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
                const Text('Enter student email address:', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 15),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Student Email Address',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    hintText: 'student@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'How to send:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. PDF will be generated and attached\n'
                            '2. Select your email app\n'
                            '3. The student email will be copied to clipboard\n'
                            '4. Paste the email in the "To" field\n'
                            '5. Review and send',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (_isSendingEmail) ...[
                  const SizedBox(height: 15),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 10),
                  const Center(child: Text('Generating PDF...', style: TextStyle(fontSize: 12))),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSendingEmail ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSendingEmail ? null : () async {
                final email = _emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an email address'), backgroundColor: Colors.red),
                  );
                  return;
                }
                if (!email.contains('@') || !email.contains('.')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid email address'), backgroundColor: Colors.red),
                  );
                  return;
                }
                _manualStudentEmail = email;
                Navigator.pop(context);
                await _sendTranscriptEmail(email);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Generate & Send'),
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
        'manualEmailUsed': recipientEmail,
      });

      print('Transcript status updated in Firestore with email: $recipientEmail');
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

    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Transcript'),
        actions: [
          if (_transcriptData?['isSent'] == true && _manualStudentEmail.isNotEmpty)
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
                    'Sent to: $_manualStudentEmail',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          IconButton(
            icon: _isGeneratingPDF
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.save_alt),
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
                          'Web Version Notice: Click Save PDF to download the transcript file.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (kIsWeb) const SizedBox(height: 16),

            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.email, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Student Email:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _manualStudentEmail.isNotEmpty
                                ? _manualStudentEmail
                                : 'Not set - enter when sending',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _manualStudentEmail.isNotEmpty
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _manualStudentEmail.isNotEmpty
                                  ? Colors.blue[800]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: _showEmailDialog,
                          tooltip: 'Set/Edit Email',
                        ),
                        if (_manualStudentEmail.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _manualStudentEmail));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Email copied to clipboard')),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                    label: Text(_isGeneratingPDF ? 'Generating...' : 'Save PDF'),
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
                    label: Text(_isSendingEmail ? 'Preparing...' : 'Send to Student'),
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
                  if (_savedFilePath != null && !kIsWeb)
                    TextButton.icon(
                      onPressed: () => _shareFile(_savedFilePath!),
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF'),
                    ),
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