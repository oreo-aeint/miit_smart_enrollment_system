// graduated_student_gpa_page.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../components/text.dart';
import 'my_drawer.dart';

class GraduatedStudentGpaPage extends StatefulWidget {
  final String fullName;
  final String rollNumber;
  final String studentId;
  final String email;

  const GraduatedStudentGpaPage({
    Key? key,
    required this.fullName,
    required this.rollNumber,
    required this.studentId,
    required this.email,
  }) : super(key: key);

  @override
  State<GraduatedStudentGpaPage> createState() => _GraduatedStudentGpaPageState();
}

class _GraduatedStudentGpaPageState extends State<GraduatedStudentGpaPage> {
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _examData;
  String _fetchedFullName = '';
  String _fetchedRollNumber = '';
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await _fetchStudentDataByRollNumber();
    await _loadExamData();
    setState(() {
      _isLoading = false;
    });
  }

  // Method to fetch student data using roll number as document ID (same as UserTranscript)
  Future<void> _fetchStudentDataByRollNumber() async {
    try {
      // Use the roll number as document ID (like UserTranscript does)
      String rollNum = widget.rollNumber;

      // If studentId is provided and different, try that too
      if (widget.studentId.isNotEmpty && widget.studentId != rollNum) {
        rollNum = widget.studentId;
      }

      print('Fetching student data for roll number: $rollNum');

      DocumentSnapshot studentDoc = await _firestore
          .collection('students')
          .doc(rollNum)
          .get();

      if (studentDoc.exists) {
        var studentData = studentDoc.data() as Map<String, dynamic>;

        setState(() {
          _studentData = studentData;

          // Extract name - following UserTranscript pattern
          // First try sname (as in UserTranscript), then personalInfo.fullName
          _fetchedFullName = studentData['sname']?.toString() ?? '';

          if (_fetchedFullName.isEmpty && studentData.containsKey('personalInfo')) {
            var personalInfo = studentData['personalInfo'] as Map<String, dynamic>? ?? {};
            _fetchedFullName = personalInfo['fullName']?.toString() ?? '';
          }

          if (_fetchedFullName.isEmpty) {
            _fetchedFullName = widget.fullName;
          }

          // Get roll number from document ID
          _fetchedRollNumber = studentDoc.id;
        });

        print('Student data loaded successfully for: $_fetchedFullName');
        print('Roll number: $_fetchedRollNumber');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ကျောင်းသားအချက်အလက်များ အောင်မြင်စွာ ရယူပြီးပါပြီ။'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('No student document found for roll number: $rollNum');
        setState(() {
          _fetchedFullName = widget.fullName;
          _fetchedRollNumber = widget.rollNumber;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ကျောင်းသားအချက်အလက်များ မတွေ့ရှိပါ။'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching student data: $e');
      setState(() {
        _fetchedFullName = widget.fullName;
        _fetchedRollNumber = widget.rollNumber;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ဒေတာရယူရာတွင် အမှားအယွင်းဖြစ်ပွားပါသည်: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadExamData() async {
    try {
      String rollNum = _fetchedRollNumber.isNotEmpty ? _fetchedRollNumber : widget.rollNumber;

      print('Loading exam data for roll number: $rollNum');

      final examDoc = await _firestore
          .collection('exams')
          .doc(rollNum)
          .get();

      if (examDoc.exists) {
        final data = examDoc.data() as Map<String, dynamic>;
        print('Found exam data: $data');
        setState(() {
          _examData = data;
        });
      } else {
        print('No exam document found with ID: $rollNum');
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

  Map<String, Map<String, dynamic>> _getSemesterStats() {
    final Map<String, Map<String, dynamic>> stats = {};

    if (_examData == null) {
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
              stats['$yearName, Semester 1'] = {'gpa': gpa};
            }
          }

          if (yearData.containsKey('secondSemester')) {
            final semesterData = yearData['secondSemester'];
            if (semesterData is Map<String, dynamic>) {
              final sgpa = semesterData['SGPA'] ?? semesterData['GPA'] ?? '0.0';
              final gpa = double.tryParse(sgpa.toString()) ?? 0.0;
              stats['$yearName, Semester 2'] = {'gpa': gpa};
            }
          }
        }
      }
    }

    return stats;
  }

  Map<String, dynamic> _calculateOverallStats() {
    final semesterStats = _getSemesterStats();
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
      'semesterCount': semesterCount,
    };
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final semesterStats = _getSemesterStats();
    final overallStats = _calculateOverallStats();
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;

    // Use the fetched name
    final displayName = _fetchedFullName.isNotEmpty ? _fetchedFullName : widget.fullName;
    final displayRollNumber = _fetchedRollNumber.isNotEmpty ? _fetchedRollNumber : widget.rollNumber;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Graduated Student Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GRADUATED STUDENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                      Text(
                        displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Student Information Card
            Card(
              elevation: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STUDENT INFORMATION',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 15),

                    if (isMobile)
                      Column(
                        children: [
                          _buildInfoRow('Name:', displayName, isMobile),
                          _buildInfoRow('Roll Number:', displayRollNumber, isMobile),
                          _buildInfoRow('Email:', widget.email, isMobile),
                          _buildInfoRow('Date of Birth:', _studentData?['sdob'] ??
                              _studentData?['personalInfo']?['sdob'] ?? 'N/A', isMobile),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow('Program:', _studentData?['smajor_full'] ?? 'Information Technology', isMobile),
                          _buildInfoRow('Major:', 'Computer Science & Engineering', isMobile),
                          _buildInfoRow('Status:', 'GRADUATED', isMobile),
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
                                _buildInfoRow('Name:', displayName, isMobile),
                                _buildInfoRow('Roll Number:', displayRollNumber, isMobile),
                                _buildInfoRow('Email:', widget.email, isMobile),
                                _buildInfoRow('Date of Birth:', _studentData?['sdob'] ??
                                    _studentData?['personalInfo']?['sdob'] ?? 'N/A', isMobile),
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
                                _buildInfoRow('Program:', _studentData?['smajor_full'] ?? 'Information Technology', isMobile),
                                _buildInfoRow('Major:', 'Computer Science & Engineering', isMobile),
                                _buildInfoRow('Status:', 'GRADUATED', isMobile),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}