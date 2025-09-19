import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Student model class
class Student {
  String id;
  String name;
  String rollNo;
  String batch;
  String major;
  EnrollmentStatus enrollmentStatus;
  StudentStatus studentStatus;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.batch,
    required this.major,
    required this.enrollmentStatus,
    required this.studentStatus,
  });

  // Create Student from Firestore Document
  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert string values to enums
    EnrollmentStatus enrollmentStatus = EnrollmentStatus.pending;
    if (data['enrollStatus'] == 'enrolled') {
      enrollmentStatus = EnrollmentStatus.enrolled;
    } else if (data['enrollStatus'] == 'rejected') {
      enrollmentStatus = EnrollmentStatus.rejected;
    }

    StudentStatus studentStatus = StudentStatus.active;
    if (data['academicStatus'] == 'suspended') {
      studentStatus = StudentStatus.suspended;
    } else if (data['academicStatus'] == 'graduated') {
      studentStatus = StudentStatus.graduated;
    }

    return Student(
      id: doc.id,
      name: data['sname'] ?? '',
      rollNo: data['srollno'] ?? '',
      batch: data['academicInfo']?['yearOfUniversity'] ?? '',
      major: data['smajor'] ?? '',
      enrollmentStatus: enrollmentStatus,
      studentStatus: studentStatus,
    );
  }

  // Convert Student to Map for Firestore
  Map<String, dynamic> toFirestore() {
    String enrollStatus = 'pending';
    if (enrollmentStatus == EnrollmentStatus.enrolled) {
      enrollStatus = 'enrolled';
    } else if (enrollmentStatus == EnrollmentStatus.rejected) {
      enrollStatus = 'rejected';
    }

    String academicStatus = 'active';
    if (studentStatus == StudentStatus.suspended) {
      academicStatus = 'suspended';
    } else if (studentStatus == StudentStatus.graduated) {
      academicStatus = 'graduated';
    }

    return {
      'sname': name,
      'srollno': rollNo,
      'academicInfo': {
        'yearOfUniversity': batch,
      },
      'smajor': major,
      'enrollStatus': enrollStatus,
      'academicStatus': academicStatus,
    };
  }
}

// Enrollment status enum
enum EnrollmentStatus { pending, enrolled, rejected }

// Student status enum
enum StudentStatus { active, suspended, graduated }

// Student Information Screen with Table
class StudentInfoScreen extends StatefulWidget {
  const StudentInfoScreen({super.key});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  List<Student> students = [];
  bool isLoading = true;

  // Filter variables
  String? selectedBatch;
  String? selectedMajor;

  // Count variables for cards
  int total = 0;
  int pending = 0;
  int enrolled = 0;
  int rejected = 0;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get unique batches and majors for dropdowns
  List<String> get batches {
    Set<String> batchSet = students.map((student) => student.batch).toSet();
    return ['All', ...batchSet.toList()..sort()];
  }

  List<String> get majors {
    Set<String> majorSet = students.map((student) => student.major).toSet();
    return ['All', ...majorSet.toList()..sort()];
  }

  // Get filtered students based on selections
  List<Student> get filteredStudents {
    if (selectedBatch == 'All') selectedBatch = null;
    if (selectedMajor == 'All') selectedMajor = null;

    return students.where((student) {
      final batchMatch =
          selectedBatch == null || student.batch == selectedBatch;
      final majorMatch =
          selectedMajor == null || student.major == selectedMajor;
      return batchMatch && majorMatch;
    }).toList();
  }

  // Update counts for cards
  void _updateCounts() {
    setState(() {
      total = filteredStudents.length;
      pending = filteredStudents
          .where((student) => student.enrollmentStatus == EnrollmentStatus.pending)
          .length;
      enrolled = filteredStudents
          .where((student) => student.enrollmentStatus == EnrollmentStatus.enrolled)
          .length;
      rejected = filteredStudents
          .where((student) => student.enrollmentStatus == EnrollmentStatus.rejected)
          .length;
    });
  }

  @override
  void initState() {
    super.initState();
    selectedBatch = 'All';
    selectedMajor = 'All';
    _loadStudents();
  }

  // Load students from Firebase
  Future<void> _loadStudents() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('students').get();

      setState(() {
        students = querySnapshot.docs
            .map((doc) => Student.fromFirestore(doc))
            .toList();
        isLoading = false;
        _updateCounts();
      });
    } catch (e) {
      print('Error loading students from Firebase: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Save student to Firebase
  Future<void> _saveStudent(Student student, {bool isUpdating = false}) async {
    try {
      if (isUpdating) {
        await _firestore.collection('students').doc(student.id).update(student.toFirestore());
      } else {
        // For new students, let Firestore generate the ID
        await _firestore.collection('students').add(student.toFirestore());
      }

      // Reload the data
      _loadStudents();
    } catch (e) {
      print('Error saving student: $e');
    }
  }

  // Delete student from Firebase
  Future<void> _deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).delete();

      // Reload the data
      _loadStudents();
    } catch (e) {
      print('Error deleting student: $e');
    }
  }

  // Helper method to get localized status text
  String _getEnrollmentStatusText(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.pending:
        return "pending1".tr();
      case EnrollmentStatus.enrolled:
        return "enrolled".tr();
      case EnrollmentStatus.rejected:
        return "rejected".tr();
    }
  }

  String _getStudentStatusText(StudentStatus status) {
    switch (status) {
      case StudentStatus.active:
        return "active".tr();
      case StudentStatus.suspended:
        return "suspended".tr();
      case StudentStatus.graduated:
        return "graduated".tr();
    }
  }

  // Build info card widget
  Widget _buildInfoCard(IconData icon, String title, String value, Color color) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Info cards row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoCard(Icons.group, 'total'.tr(), total.toString(), Colors.blue),
                _buildInfoCard(Icons.pending_actions, 'pending1'.tr(), pending.toString(), Colors.orange),
                _buildInfoCard(Icons.school, 'enrolled'.tr(), enrolled.toString(), Colors.green),
                _buildInfoCard(Icons.cancel, 'rejected'.tr(), rejected.toString(), Colors.red),
              ],
            ),
          ),
          // Filter dropdowns
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Batch filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBatch,
                    decoration: InputDecoration(
                      labelText: 'batch'.tr(),
                      border: OutlineInputBorder(),
                    ),
                    items: batches.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedBatch = newValue;
                        _updateCounts();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                // Major filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedMajor,
                    decoration: InputDecoration(
                      labelText: 'major'.tr(),
                      border: OutlineInputBorder(),
                    ),
                    items: majors.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMajor = newValue;
                        _updateCounts();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // Data table with vertical scrollbar
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DataTable(
                      dividerThickness: 1,
                      columnSpacing: 20, // Increased spacing
                      horizontalMargin: 12, // Increased margin
                      headingRowColor: MaterialStateProperty.all(
                        Colors.indigo.shade50,
                      ),
                      columns: [
                        DataColumn(
                          label: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 40),
                            child: Text(
                              'ID',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 120),
                            child: Text(
                              'name'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 150),
                            child: Text(
                              'rollNo'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 60),
                            child: Text(
                              'batch'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 80),
                            child: Text(
                              'major'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 150),
                            child: Text(
                              'enrollment'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 120),
                            child: Text(
                              'status'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 120),
                            child: Text(
                              'actions'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                      rows: List<DataRow>.generate(
                          students.length,
                              (index) {
                            final student = students[index];
                            return DataRow(
                              cells: [
                                DataCell(ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: 40),
                                  child: Text(
                                    (index + 1).toString(), // 👈 numbering instead of Firestore id
                                    style: TextStyle(fontSize: 14),
                                  ),
                                )),
                            DataCell(ConstrainedBox(
                              constraints: BoxConstraints(minWidth: 120),
                              child: Text(student.name, style: TextStyle(fontSize: 14)),
                            )),
                            DataCell(ConstrainedBox(
                              constraints: BoxConstraints(minWidth: 150),
                              child: Text(student.rollNo, style: TextStyle(fontSize: 14)),
                            )),
                            DataCell(ConstrainedBox(
                              constraints: BoxConstraints(minWidth: 60),
                              child: Text(student.batch, style: TextStyle(fontSize: 14)),
                            )),
                            DataCell(ConstrainedBox(
                              constraints: BoxConstraints(minWidth: 80),
                              child: Text(student.major, style: TextStyle(fontSize: 14)),
                            )),
                            DataCell(
                              ConstrainedBox(
                                constraints: BoxConstraints(minWidth: 150),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Read-only status indicator
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getEnrollmentStatusColor(student.enrollmentStatus),
                                        border: Border.all(
                                          color: _getEnrollmentStatusColor(student.enrollmentStatus),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(Icons.check, size: 16, color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getEnrollmentStatusText(student.enrollmentStatus),
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: BoxConstraints(minWidth: 120),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Read-only status indicator
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getStudentStatusColor(student.studentStatus),
                                        border: Border.all(
                                          color: _getStudentStatusColor(student.studentStatus),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(Icons.check, size: 16, color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getStudentStatusText(student.studentStatus),
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: BoxConstraints(minWidth: 120),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red.shade700,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        _deleteStudent(student as String);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.blue.shade700,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        _editStudent(student);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.visibility,
                                        color: Colors.green.shade700,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        _viewDetails(student);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

    );
  }

  Color _getEnrollmentStatusColor(EnrollmentStatus status) {
    switch (status) {
      case EnrollmentStatus.pending:
        return Colors.orange;
      case EnrollmentStatus.enrolled:
        return Colors.green;
      case EnrollmentStatus.rejected:
        return Colors.red;
    }
  }

  Color _getStudentStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.active:
        return Colors.green;
      case StudentStatus.suspended:
        return Colors.orange;
      case StudentStatus.graduated:
        return Colors.blue;
    }
  }


  void _editStudent(Student student) {
    // Show edit form
    _showStudentForm(student: student);
  }

  void _viewDetails(Student student) {
    // Find the index of the student in the filtered list
    int index = filteredStudents.indexWhere((s) => s.id == student.id);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${'studentDetails'.tr()}: ${student.name}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ID: ${index + 1}'),
                Text('${'rollNo'.tr()}: ${student.rollNo}'),
                Text('${'batch'.tr()}: ${student.batch}'),
                Text('${'major'.tr()}: ${student.major}'),
                Text(
                  '${'enrollment'.tr()}: ${_getEnrollmentStatusText(student.enrollmentStatus)}',
                ),
                Text(
                  '${'status'.tr()}: ${_getStudentStatusText(student.studentStatus)}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('close'.tr()),
            ),
          ],
        );
      },
    );
  }



  //Edit Show Form
  void _showStudentForm({Student? student}) {
    final isEditing = student != null;
    final idController = TextEditingController(text: student?.id ?? '');
    final nameController = TextEditingController(text: student?.name ?? '');
    final rollNoController = TextEditingController(text: student?.rollNo ?? '');
    final batchController = TextEditingController(text: student?.batch ?? '');
    final majorController = TextEditingController(text: student?.major ?? '');

    EnrollmentStatus enrollmentStatus =
        student?.enrollmentStatus ?? EnrollmentStatus.pending;
    StudentStatus studentStatus =
        student?.studentStatus ?? StudentStatus.active;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'editStudent'.tr() : 'addNewStudent'.tr(),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isEditing) SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'name'.tr(),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: rollNoController,
                      decoration: InputDecoration(
                        labelText: 'rollNo'.tr(),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: batchController,
                      decoration: InputDecoration(
                        labelText: 'batch'.tr(),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: majorController,
                      decoration: InputDecoration(
                        labelText: 'major'.tr(),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Enrollment Status Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'enrollment'.tr(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFormEnrollmentStatusRadio(
                              EnrollmentStatus.pending,
                              enrollmentStatus,
                                  (status) {
                                setState(() {
                                  enrollmentStatus = status;
                                });
                              },
                            ),
                            _buildFormEnrollmentStatusRadio(
                              EnrollmentStatus.enrolled,
                              enrollmentStatus,
                                  (status) {
                                setState(() {
                                  enrollmentStatus = status;
                                });
                              },
                            ),
                            _buildFormEnrollmentStatusRadio(
                              EnrollmentStatus.rejected,
                              enrollmentStatus,
                                  (status) {
                                setState(() {
                                  enrollmentStatus = status;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Student Status Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'status'.tr(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFormStudentStatusRadio(
                              StudentStatus.active,
                              studentStatus,
                                  (status) {
                                setState(() {
                                  studentStatus = status;
                                });
                              },
                            ),
                            _buildFormStudentStatusRadio(
                              StudentStatus.suspended,
                              studentStatus,
                                  (status) {
                                setState(() {
                                  studentStatus = status;
                                });
                              },
                            ),
                            _buildFormStudentStatusRadio(
                              StudentStatus.graduated,
                              studentStatus,
                                  (status) {
                                setState(() {
                                  studentStatus = status;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newStudent = Student(
                      id: isEditing ? student.id : '', // For new students, ID will be generated by Firestore
                      name: nameController.text,
                      rollNo: rollNoController.text,
                      batch: batchController.text,
                      major: majorController.text,
                      enrollmentStatus: enrollmentStatus,
                      studentStatus: studentStatus,
                    );

                    _saveStudent(newStudent, isUpdating: isEditing);

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? '${'updated'.tr()} ${nameController.text}'
                              : '${'added'.tr()} ${nameController.text}',
                        ),
                      ),
                    );
                  },
                  child: Text(isEditing ? 'update'.tr() : 'add'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFormEnrollmentStatusRadio(
      EnrollmentStatus status,
      EnrollmentStatus selectedStatus,
      Function(EnrollmentStatus) onChanged,
      ) {
    final color = status == EnrollmentStatus.pending
        ? Colors.orange
        : status == EnrollmentStatus.enrolled
        ? Colors.green
        : Colors.red;

    return Column(
      children: [
        GestureDetector(
          onTap: () => onChanged(status),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectedStatus == status ? color : Colors.grey.shade300,
              border: Border.all(color: color, width: 2),
            ),
            child: selectedStatus == status
                ? Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        SizedBox(height: 4),
        Text(_getEnrollmentStatusText(status), style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildFormStudentStatusRadio(
      StudentStatus status,
      StudentStatus selectedStatus,
      Function(StudentStatus) onChanged,
      ) {
    final color = status == StudentStatus.active
        ? Colors.green
        : status == StudentStatus.suspended
        ? Colors.orange
        : Colors.blue;

    return Column(
      children: [
        GestureDetector(
          onTap: () => onChanged(status),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectedStatus == status ? color : Colors.grey.shade300,
              border: Border.all(color: color, width: 2),
            ),
            child: selectedStatus == status
                ? Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        SizedBox(height: 4),
        Text(_getStudentStatusText(status), style: TextStyle(fontSize: 12)),
      ],
    );
  }
}