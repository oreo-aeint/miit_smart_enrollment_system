import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:miit_project/screens/old_uni_rules.dart';

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

  // Convert Student to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rollNo': rollNo,
      'batch': batch,
      'major': major,
      'enrollmentStatus': enrollmentStatus.index,
      'studentStatus': studentStatus.index,
    };
  }

  // Create Student from Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      rollNo: map['rollNo'],
      batch: map['batch'],
      major: map['major'],
      enrollmentStatus: EnrollmentStatus.values[map['enrollmentStatus']],
      studentStatus: StudentStatus.values[map['studentStatus']],
    );
  }

  // Convert Student to JSON
  String toJson() => json.encode(toMap());

  // Create Student from JSON
  factory Student.fromJson(String source) =>
      Student.fromMap(json.decode(source));
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

  // Filter variables
  String? selectedBatch;
  String? selectedMajor;

  // Count variables for cards
  int total = 0;
  int pending = 0;
  int enrolled = 0;
  int rejected = 0;

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

  // Load students from shared preferences
  Future<void> _loadStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentsJson = prefs.getStringList('students');

      if (studentsJson != null) {
        setState(() {
          students = studentsJson
              .map((json) => Student.fromJson(json))
              .toList();
          _updateCounts();
        });
      } else {
        // Load initial data if no saved data exists
        setState(() {
          students = [
            Student(
              id: '1',
              name: 'Aeint Chit Thu',
              rollNo: '2022-MIIT-CSE-011',
              batch: '2022',
              major: 'CSE',
              enrollmentStatus: EnrollmentStatus.enrolled,
              studentStatus: StudentStatus.active,
            ),
            Student(
              id: '2',
              name: 'Phyo Myat Htoo Sint',
              rollNo: '2022-MIIT-CSE-023',
              batch: '2022',
              major: 'CSE',
              enrollmentStatus: EnrollmentStatus.enrolled,
              studentStatus: StudentStatus.active,
            ),
            Student(
              id: '3',
              name: 'Win Pa Pa Phyo',
              rollNo: '2022-MIIT-CSE-029',
              batch: '2022',
              major: 'CSE',
              enrollmentStatus: EnrollmentStatus.enrolled,
              studentStatus: StudentStatus.active,
            ),
            Student(
              id: '4',
              name: 'Su Yadanar Win',
              rollNo: '2022-MIIT-CSE-045',
              batch: '2022',
              major: 'CSE',
              enrollmentStatus: EnrollmentStatus.rejected,
              studentStatus: StudentStatus.suspended,
            ),
            Student(
              id: '5',
              name: 'Min Khant Maung',
              rollNo: '2025-MIIT-CSE-001',
              batch: '2025',
              major: 'CSE',
              enrollmentStatus: EnrollmentStatus.pending,
              studentStatus: StudentStatus.active,
            ),
            Student(
              id: '6',
              name: 'Aung Thiha',
              rollNo: '2015-MIIT-ECE-035',
              batch: '2015',
              major: 'ECE',
              enrollmentStatus: EnrollmentStatus.enrolled,
              studentStatus: StudentStatus.graduated,
            ),
            Student(
              id: '7',
              name: 'MiMi Thin Naing',
              rollNo: '2022-MIIT-CSE-025',
              batch: '2022',
              major: 'CSE',
              enrollmentStatus: EnrollmentStatus.enrolled,
              studentStatus: StudentStatus.suspended,
            ),
          ];
          _updateCounts();
        });
        _saveStudents();
      }
    } catch (e) {
      print('Error loading students: $e');
    }
  }


  // Save students to shared preferences
  Future<void> _saveStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentsJson = students.map((student) => student.toJson()).toList();
      await prefs.setStringList('students', studentsJson);
    } catch (e) {
      print('Error saving students: $e');
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
                      rows: filteredStudents.map((student) {
                        return DataRow(
                          cells: [
                            DataCell(ConstrainedBox(
                              constraints: BoxConstraints(minWidth: 40),
                              child: Text(student.id, style: TextStyle(fontSize: 14)),
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
                                        _deleteStudent(student);
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
      /*floatingActionButton: FloatingActionButton(
        onPressed: _addNewStudent,
        child: const Icon(Icons.add),
      ),*/
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

  //deleteStudent
  void _deleteStudent(Student student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('deleteStudent'.tr()),
          content: Text('${'deleteConfirm'.tr()} ${student.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  students.remove(student);
                  _saveStudents(); // Save after deletion
                  _updateCounts(); // Update the card counts
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${student.name} ${'deleted'.tr()}')),
                );
              },
              child: Text('delete'.tr(), style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _editStudent(Student student) {
    // Show edit form
    _showStudentForm(student: student);
  }

  void _viewDetails(Student student) {
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
                Text('ID: ${student.id}'),
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

  void _addNewStudent() {
    // Show add form
    _showStudentForm();
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
                    TextField(
                      controller: idController,
                      decoration: InputDecoration(
                        labelText: 'ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
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
                      id: idController.text,
                      name: nameController.text,
                      rollNo: rollNoController.text,
                      batch: batchController.text,
                      major: majorController.text,
                      enrollmentStatus: enrollmentStatus,
                      studentStatus: studentStatus,
                    );

                    if (isEditing) {
                      // Update existing student
                      final index = students.indexWhere(
                            (s) => s.id == student!.id,
                      );
                      if (index != -1) {
                        setState(() {
                          students[index] = newStudent;
                          _saveStudents(); // Save after editing
                          _updateCounts(); // Update the card counts
                        });
                      }
                    } else {
                      // Add new student
                      setState(() {
                        students.add(newStudent);
                        _saveStudents(); // Save after adding
                        _updateCounts(); // Update the card counts
                      });
                    }

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