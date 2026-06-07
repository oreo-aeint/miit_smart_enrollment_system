import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentResultsPage extends StatefulWidget {
  const StudentResultsPage({super.key});

  @override
  State<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> entrancePassedStudents = [];
  List<Map<String, dynamic>> examPassedStudents = [];
  List<Map<String, dynamic>> graduatedStudents = [];
  bool _isLoadingGraduated = true;

  StreamSubscription<QuerySnapshot>? _entranceSubscription;
  StreamSubscription<QuerySnapshot>? _examsSubscription;
  StreamSubscription<QuerySnapshot>? _graduatedSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupStudentsListener();
    _setupGraduatedStudentsListener();
  }

  @override
  void dispose() {
    _entranceSubscription?.cancel();
    _examsSubscription?.cancel();
    _graduatedSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupStudentsListener() {
    _entranceSubscription = FirebaseFirestore.instance
        .collection('entrance_pass_stu')
        .snapshots()
        .listen((snapshot) {
      _processEntrancePassedStudents(snapshot.docs);
    }, onError: (error) {
      print('Error in entrance listener: $error');
    });

    _examsSubscription = FirebaseFirestore.instance
        .collection('exams')
        .snapshots()
        .listen((snapshot) {
      _processExamPassedStudents(snapshot.docs);
    }, onError: (error) {
      print('Error in exams listener: $error');
    });
  }

  void _setupGraduatedStudentsListener() {
    _isLoadingGraduated = true;
    setState(() {});

    _graduatedSubscription = FirebaseFirestore.instance
        .collection('students')
        .where('academicInfo.academicStatus', isEqualTo: 'graduated')
        .snapshots()
        .listen((snapshot) {
      _processGraduatedStudents(snapshot.docs);
    }, onError: (error) {
      print('Error in graduated listener: $error');
      setState(() {
        _isLoadingGraduated = false;
      });
    });
  }

  // Helper to get name from any document (tries multiple fields)
  String _getNameFromDocument(Map<String, dynamic> data, String docId) {
    final nameFields = ['studentName', 'fullName', 'name', 'sname', 'fullname'];
    for (var field in nameFields) {
      if (data.containsKey(field) && data[field] != null && data[field].toString().isNotEmpty) {
        return data[field].toString();
      }
    }
    return '';
  }

  void _processEntrancePassedStudents(List<QueryDocumentSnapshot> docs) {
    final List<Map<String, dynamic>> students = [];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = _getNameFromDocument(data, doc.id);
      students.add({
        "id": doc.id,
        "rollNumber": doc.id,
        "fullName": name.isEmpty ? 'Student ${doc.id}' : name,
        "type": "entrance",
      });
    }
    setState(() {
      entrancePassedStudents = students;
    });
  }

  Future<void> _processExamPassedStudents(List<QueryDocumentSnapshot> docs) async {
    final List<Map<String, dynamic>> students = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      String studentName = _getNameFromDocument(data, doc.id);

      // If name still empty, try to fetch from entrance_pass_stu collection (same roll number)
      if (studentName.isEmpty) {
        try {
          final entranceDoc = await FirebaseFirestore.instance
              .collection('entrance_pass_stu')
              .doc(doc.id)
              .get();
          if (entranceDoc.exists) {
            final entranceData = entranceDoc.data() as Map<String, dynamic>?;
            if (entranceData != null) {
              studentName = _getNameFromDocument(entranceData, doc.id);
            }
          }
        } catch (e) {
          print('Error fetching entrance data for ${doc.id}: $e');
        }
      }

      // If still empty, try students collection
      if (studentName.isEmpty) {
        try {
          final studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(doc.id)
              .get();
          if (studentDoc.exists) {
            final studentData = studentDoc.data() as Map<String, dynamic>?;
            if (studentData != null) {
              studentName = _getNameFromDocument(studentData, doc.id);
            }
          }
        } catch (e) {
          print('Error fetching student data for ${doc.id}: $e');
        }
      }

      // Final fallback
      if (studentName.isEmpty) {
        studentName = 'Student ${doc.id}';
      }

      students.add({
        "id": doc.id,
        "rollNumber": doc.id,
        "fullName": studentName,
        "type": "exam",
        "examData": data,
        "loadingDetails": false,
      });
    }

    setState(() {
      examPassedStudents = students;
    });
  }

  Future<void> _processGraduatedStudents(List<QueryDocumentSnapshot> docs) async {
    final List<Map<String, dynamic>> students = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final academicInfo = data['academicInfo'] as Map<String, dynamic>? ?? {};
      final personalInfo = data['personalInfo'] as Map<String, dynamic>? ?? {};

      String studentName = _getNameFromDocument(personalInfo, doc.id);
      if (studentName.isEmpty) studentName = _getNameFromDocument(data, doc.id);
      if (studentName.isEmpty) studentName = 'Student ${doc.id}';

      String rollNumber = academicInfo['roll_no']?.toString() ??
          academicInfo['rollNumber']?.toString() ??
          data['scrollno']?.toString() ??
          doc.id;

      String studentEmail = academicInfo['eduMail']?.toString() ??
          data['email']?.toString() ??
          'N/A';

      String enrollStatus = academicInfo['enrollStatus']?.toString() ?? 'N/A';
      String graduationYear = academicInfo['end_year']?.toString() ??
          academicInfo['graduationYear']?.toString() ??
          'N/A';

      Map<String, dynamic> examData = {};
      try {
        final examDoc = await FirebaseFirestore.instance
            .collection('exams')
            .doc(doc.id)
            .get();
        if (examDoc.exists) {
          examData = examDoc.data() as Map<String, dynamic>? ?? {};
        }
      } catch (e) {
        print('Error fetching exam data for ${doc.id}: $e');
      }

      final academicData = _getAcademicData(examData);

      students.add({
        "id": doc.id,
        "rollNumber": rollNumber,
        "fullName": studentName,
        "studentEmail": studentEmail,
        "enrollStatus": enrollStatus,
        "graduationYear": graduationYear,
        "type": "graduated",
        "examData": examData,
        "academicData": academicData,
        "loadingDetails": false,
      });
    }

    setState(() {
      graduatedStudents = students;
      _isLoadingGraduated = false;
    });
  }

  Map<String, dynamic> _getAcademicData(Map<String, dynamic> examData) {
    final academicData = <String, dynamic>{};
    examData.forEach((key, value) {
      if (_isAcademicYear(key) && value != null) {
        academicData[key] = value;
      }
    });
    return academicData;
  }

  bool _isAcademicYear(String key) {
    const academicYears = [
      'firstYear', 'secondYear', 'thirdYear', 'fourthYear', 'finalYear',
      'MEFirstYear', 'MESecondYear'
    ];
    return academicYears.contains(key);
  }

  int _countTotalSemesters(Map<String, dynamic> academicData) {
    int total = 0;
    academicData.forEach((year, yearData) {
      if (yearData is Map<String, dynamic>) total += yearData.length;
    });
    return total;
  }

  // --- Delete Functions ---
  Future<void> _deleteStudent(String collection, String docId, String name) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $name deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting $name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(Map<String, dynamic> student) {
    final isExam = student['type'] == 'exam';
    final isEntrance = student['type'] == 'entrance';
    final isGraduated = student['type'] == 'graduated';

    String collection;
    if (isExam) collection = 'exams';
    else if (isEntrance) collection = 'entrance_pass_stu';
    else collection = 'students';

    final docId = student['id'];
    final name = student['fullName'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Student'),
        content: Text('Are you sure you want to delete $name? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent(collection, docId, name);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  // --- Details Dialogs ---
  void _showGraduateStudentDetails(Map<String, dynamic> student) {
    final academicData = student["academicData"] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth * 0.35;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.school, color: Colors.amber),
              const SizedBox(width: 8),
              Text('graduationDetails'.tr()),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('studentName'.tr(), student["fullName"]),
                  _buildDetailRow('rollNumber'.tr(), student["rollNumber"]),
                  _buildDetailRow('graduationYear'.tr(), student["graduationYear"]),
                  _buildDetailRow('email'.tr(), student["studentEmail"]),
                  _buildDetailRow('enrollmentStatus'.tr(), student["enrollStatus"]),
                  const SizedBox(height: 16),
                  if (academicData.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.assignment_turned_in, color: Colors.amber[700], size: 20),
                          const SizedBox(width: 8),
                          Text('academicRecords'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildAcademicRecords(academicData),
                  ] else ...[
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.school_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('noAcademicRecords'.tr(), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showExamStudentDetails(Map<String, dynamic> student) {
    final examData = student["examData"] as Map<String, dynamic>? ?? {};
    final academicData = _getAcademicData(examData);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth * 0.35;
        return AlertDialog(
          title: Text('studentAcademicRecords'.tr()),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('studentName'.tr(), student["fullName"]),
                  _buildDetailRow('rollNumber'.tr(), student["rollNumber"]),
                  const SizedBox(height: 16),
                  Text('academicRecords'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._buildAcademicRecords(academicData),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAcademicRecords(Map<String, dynamic> academicData) {
    final widgets = <Widget>[];
    if (academicData.isEmpty) {
      return [
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Icon(Icons.school_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('noAcademicRecords'.tr(), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
        ),
      ];
    }

    academicData.forEach((academicYear, yearData) {
      if (yearData is Map<String, dynamic>) {
        final semesters = yearData;
        if (semesters.isNotEmpty) {
          widgets.addAll([
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatAcademicYearName(academicYear),
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
          ]);

          semesters.forEach((semester, grade) {
            widgets.add(Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.blue[300]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatSemesterName(semester),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        grade.toString(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ));
          });
        }
      }
    });
    return widgets;
  }

  String _formatAcademicYearName(String yearKey) {
    const yearNames = {
      'firstYear': 'First Year',
      'secondYear': 'Second Year',
      'thirdYear': 'Third Year',
      'fourthYear': 'Fourth Year',
      'finalYear': 'Final Year',
      'MEFirstYear': 'ME First Year',
      'MESecondYear': 'ME Second Year',
    };
    return yearNames[yearKey] ?? yearKey;
  }

  String _formatSemesterName(String semester) {
    const semesterNames = {
      'firstSemester': 'First Semester',
      'secondSemester': 'Second Semester',
    };
    return semesterNames[semester] ?? semester;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  // --- Cards with Delete Button ---
  Widget _buildEntranceStudentCard(Map<String, dynamic> student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline, color: Colors.blue[600]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student["fullName"],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Roll No: ${student["rollNumber"]}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Text(
                      'entrancePassed'.tr(),
                      style: TextStyle(fontSize: 11, color: Colors.blue[800], fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(student),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamStudentCard(Map<String, dynamic> student) {
    final examData = student["examData"] as Map<String, dynamic>? ?? {};
    final academicData = _getAcademicData(examData);
    final hasRecords = academicData.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student["fullName"],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Roll No: ${student["rollNumber"]}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'examPassed'.tr(),
                          style: TextStyle(fontSize: 12, color: Colors.green[800], fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (hasRecords) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_countTotalSemesters(academicData)} semesters',
                            style: TextStyle(fontSize: 11, color: Colors.orange[800], fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: student["loadingDetails"] == true || !hasRecords
                      ? null
                      : () => _showExamStudentDetails(student),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasRecords ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: student["loadingDetails"] == true
                      ? const SizedBox(height: 16, width: 25, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('details'.tr(), style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(student),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraduateStudentCard(Map<String, dynamic> student) {
    final academicData = student["academicData"] as Map<String, dynamic>? ?? {};
    final hasRecords = academicData.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade300, Colors.amber.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student["fullName"],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Roll No: ${student["rollNumber"]}",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.amber.shade800),
                            const SizedBox(width: 4),
                            Text('graduated'.tr(), style: TextStyle(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          student["graduationYear"],
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: student["loadingDetails"] == true
                      ? null
                      : () => _showGraduateStudentDetails(student),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: student["loadingDetails"] == true
                      ? const SizedBox(height: 16, width: 25, child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, size: 14),
                      const SizedBox(width: 4),
                      Text('view'.tr(), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(student),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab Views ---
  Widget _buildEntrancePassedView() {
    if (entrancePassedStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('noEntrancePassedStudents'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView(
      children: entrancePassedStudents.map((student) => _buildEntranceStudentCard(student)).toList(),
    );
  }

  Widget _buildExamPassedView() {
    if (examPassedStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('noExamPassedStudents'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView(
      children: examPassedStudents.map((student) => _buildExamStudentCard(student)).toList(),
    );
  }

  Widget _buildGraduatedView() {
    if (_isLoadingGraduated) {
      return const Center(child: CircularProgressIndicator());
    }
    if (graduatedStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
              child: Icon(Icons.school_outlined, size: 64, color: Colors.amber.shade300),
            ),
            const SizedBox(height: 16),
            Text('noGraduatedStudents'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('graduatedStudentsWillAppearHere'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoadingGraduated = true);
        _graduatedSubscription?.cancel();
        _setupGraduatedStudentsListener();
      },
      child: ListView(
        children: graduatedStudents.map((student) => _buildGraduateStudentCard(student)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.school_outlined), text: '${'entrancePassed'.tr()} (${entrancePassedStudents.length})'),
            Tab(icon: const Icon(Icons.assignment_turned_in_outlined), text: '${'examPassed'.tr()} (${examPassedStudents.length})'),
            Tab(icon: const Icon(Icons.school, color: Colors.amber), text: '${'graduated'.tr()} (${graduatedStudents.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEntrancePassedView(),
          _buildExamPassedView(),
          _buildGraduatedView(),
        ],
      ),
    );
  }
}