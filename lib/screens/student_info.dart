import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Student model class with combined information
class Student {
  // Basic Information

  String? currentStudentPhotoUrl;
  String? currentIdFrontUrl;
  String? currentIdBackUrl;
  String? idFrontUrl;
  String? idBackUrl;
  String? studentPhotoUrl;
  String? idCardFrontUrl;
  String? idCardBackUrl;
  String? studentPhoto;
  String? idCardFront;
  String? idCardBack;
  String id;
  String name;
  String rollNo;
  String academicYear;
  String batch;
  String major;
  EnrollmentStatus enrollmentStatus;
  StudentStatus studentStatus;
  String eduMail;
  String courseYear;
  String registrationNumber;
  String dateOfBirth;
  String gender;
  String religion;

  // NRC Components (stored separately, displayed combined)
  String nrcDivision;
  String nrcTownship;
  String nrcType;
  String nrcNumber;

  // Combined NRC for display
  String get nrc => '$nrcDivision/$nrcTownship($nrcType)$nrcNumber';

  String contactNumber;
  String address;

  // Father information
  String fatherName;
  String fatherDateOfBirth;
  String fatherReligion;

  // Father NRC Components
  String fatherNrcDivision;
  String fatherNrcTownship;
  String fatherNrcType;
  String fatherNrcNumber;

  String get fatherNrc =>
      '$fatherNrcDivision/$fatherNrcTownship($fatherNrcType)$fatherNrcNumber';

  String fatherContactNumber;
  String fatherAddress;

  // Mother information
  String motherName;
  String motherDateOfBirth;
  String motherReligion;

  // Mother NRC Components
  String motherNrcDivision;
  String motherNrcTownship;
  String motherNrcType;
  String motherNrcNumber;

  String get motherNrc =>
      '$motherNrcDivision/$motherNrcTownship($motherNrcType)$motherNrcNumber';

  String motherContactNumber;
  String motherAddress;

  Student({
    // Basic Information (required)

    this.idFrontUrl,
    this.idBackUrl,
    this.studentPhotoUrl,
    this.idCardFrontUrl,
    this.idCardBackUrl,
    this.studentPhoto,
    this.idCardFront,
    this.idCardBack,
    required this.id,
    required this.name,
    required this.rollNo,
    required this.academicYear,
    required this.batch,
    required this.major,
    required this.enrollmentStatus,
    required this.studentStatus,
    required this.eduMail,
    required this.courseYear,
    required this.registrationNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.religion,

    // NRC Components
    required this.nrcDivision,
    required this.nrcTownship,
    required this.nrcType,
    required this.nrcNumber,

    required this.contactNumber,
    required this.address,

    // Father Information
    required this.fatherName,
    required this.fatherDateOfBirth,
    required this.fatherReligion,

    // Father NRC Components
    required this.fatherNrcDivision,
    required this.fatherNrcTownship,
    required this.fatherNrcType,
    required this.fatherNrcNumber,

    required this.fatherContactNumber,
    required this.fatherAddress,

    // Mother Information
    required this.motherName,
    required this.motherDateOfBirth,
    required this.motherReligion,

    // Mother NRC Components
    required this.motherNrcDivision,
    required this.motherNrcTownship,
    required this.motherNrcType,
    required this.motherNrcNumber,

    required this.motherContactNumber,
    required this.motherAddress,
  });

  // Create Student from Firestore Document
  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    print('Document ID: ${doc.id}');
    print('Document Data: $data');

    // Get academicInfo as a map or empty map if null
    Map<String, dynamic> academicInfo =
        data['academicInfo'] as Map<String, dynamic>? ?? {};

    // Get parents map
    Map<String, dynamic> parents =
        data['parents'] as Map<String, dynamic>? ?? {};

    // Extract father map
    Map<String, dynamic> father =
        parents['father'] as Map<String, dynamic>? ?? {};

    // Extract mother map
    Map<String, dynamic> mother =
        parents['mother'] as Map<String, dynamic>? ?? {};

    // Convert string values to enums
    EnrollmentStatus enrollmentStatus = EnrollmentStatus.pending;
    String enrollStatusValue = academicInfo['enrollStatus']?.toString() ?? 'pending';
    if (enrollStatusValue == 'enrolled') {
      enrollmentStatus = EnrollmentStatus.enrolled;
    } else if (enrollStatusValue == 'rejected') {
      enrollmentStatus = EnrollmentStatus.rejected;
    }

    StudentStatus studentStatus = StudentStatus.active;
    String academicStatusValue = academicInfo['academicStatus']?.toString() ?? 'active';
    if (academicStatusValue == 'suspended') {
      studentStatus = StudentStatus.suspended;
    } else if (academicStatusValue == 'graduated') {
      studentStatus = StudentStatus.graduated;
    }

    // Parse Father NRC from father map fields
    Map<String, String> parsedFatherNrc = _parseNRCFromFields(
      division: father['fnrc_state_division']?.toString() ?? '',
      township: father['fnrc_township']?.toString() ?? '',
      type: father['fnrc_type']?.toString() ?? 'N',
      number: father['fnrc']?.toString() ?? '',
    );

    // Parse Mother NRC from mother map fields
    Map<String, String> parsedMotherNrc = _parseNRCFromFields(
      division: mother['mnrc_state_division']?.toString() ?? '',
      township: mother['mnrc_township']?.toString() ?? '',
      type: mother['mnrc_type']?.toString() ?? 'N',
      number: mother['mnrc']?.toString() ?? '',
    );

    return Student(
      // Basic Information
      id: doc.id,
      name: data['sname']?.toString() ?? '',
      rollNo: data['srollno']?.toString() ?? '',
      academicYear: academicInfo['academicYear']?.toString() ?? '',
      batch: academicInfo['yearOfUniversity']?.toString() ?? '',
      major: data['smajor']?.toString() ?? '',
      enrollmentStatus: enrollmentStatus,
      studentStatus: studentStatus,
      eduMail: academicInfo['eduMail']?.toString() ?? '',
      courseYear: academicInfo['courseYear']?.toString() ?? '',
      registrationNumber: academicInfo['registrationNumber']?.toString() ?? '',
      dateOfBirth: data['sdob']?.toString() ?? '',
      gender: data['sgender']?.toString() ?? '',
      religion: data['sreligion']?.toString() ?? '',

      // NRC Components
      nrcDivision: data['snrc_state_division']?.toString() ?? '',
      nrcTownship: data['snrc_township']?.toString() ?? '',
      nrcType: data['snrc_type']?.toString() ?? 'N',
      nrcNumber: data['snrc']?.toString() ?? '',

      contactNumber: data['scontactNumber']?.toString() ?? '',
      address: data['saddress']?.toString() ?? '',

      // Father Information
      fatherName: father['fname_eng']?.toString() ?? '',
      fatherDateOfBirth: father['fdob']?.toString() ?? '',
      fatherReligion: father['freligion']?.toString() ?? '',

      // Father NRC Components
      fatherNrcDivision: parsedFatherNrc['division'] ?? '',
      fatherNrcTownship: parsedFatherNrc['township'] ?? '',
      fatherNrcType: parsedFatherNrc['type'] ?? 'N',
      fatherNrcNumber: parsedFatherNrc['number'] ?? '',

      fatherContactNumber: father['fphone']?.toString() ?? '',
      fatherAddress: father['faddress']?.toString() ?? '',

      // Mother Information
      motherName: mother['mname_eng']?.toString() ?? '',
      motherDateOfBirth: mother['mdob']?.toString() ?? '',
      motherReligion: mother['mreligion']?.toString() ?? '',

      // Mother NRC Components
      motherNrcDivision: parsedMotherNrc['division'] ?? '',
      motherNrcTownship: parsedMotherNrc['township'] ?? '',
      motherNrcType: parsedMotherNrc['type'] ?? 'N',
      motherNrcNumber: parsedMotherNrc['number'] ?? '',

      motherContactNumber: mother['mphone']?.toString() ?? '',
      motherAddress: mother['maddress']?.toString() ?? '',
    );
  }

  // Helper method to parse NRC into components from individual fields
  static Map<String, String> _parseNRCFromFields({
    required String division,
    required String township,
    required String type,
    required String number,
  }) {
    return {
      'division': division,
      'township': township,
      'type': type.isNotEmpty ? type : 'N',
      'number': number,
    };
  }

  // Convert Student to Map for Firestore
  Map<String, dynamic> toFirestore() {
    // Convert enrollmentStatus enum to string
    String enrollStatus;
    switch (enrollmentStatus) {
      case EnrollmentStatus.enrolled:
        enrollStatus = 'enrolled';
        break;
      case EnrollmentStatus.rejected:
        enrollStatus = 'rejected';
        break;
      case EnrollmentStatus.pending:
      default:
        enrollStatus = 'pending';
    }

    // Convert studentStatus enum to string
    String academicStatus;
    switch (studentStatus) {
      case StudentStatus.suspended:
        academicStatus = 'suspended';
        break;
      case StudentStatus.graduated:
        academicStatus = 'graduated';
        break;
      case StudentStatus.active:
      default:
        academicStatus = 'active';
    }

    // Return a map that updates both fields in the academicInfo subcollection
    return {
      'academicInfo.enrollStatus': enrollStatus,
      'academicInfo.academicStatus': academicStatus,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}

// Enrollment status enum
enum EnrollmentStatus { pending, enrolled, rejected }

// Student status enum
enum StudentStatus { active, suspended, graduated }

// Responsive Student Information Screen
class StudentInfoScreen extends StatefulWidget {
  const StudentInfoScreen({super.key});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  List<Student> students = [];
  bool isLoading = true;
  String? errorMessage;

  // Search variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Batch filter variables
  String? _selectedBatch;

  // Batch options
  List<String> get batchOptions {
    final batches = students.map((s) => s.batch).where((b) => b.isNotEmpty).toSet().toList();
    batches.sort();
    return batches;
  }

  // Count variables for cards
  int total = 0;
  int pending = 0;
  int enrolled = 0;
  int rejected = 0;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search matching function
  bool _matchesSearch(Student student) {
    final query = _searchQuery.toLowerCase().trim();
    if (query.isEmpty) return true;

    // Search in multiple fields
    return student.rollNo.toLowerCase().contains(query) ||
        student.name.toLowerCase().contains(query) ||
        student.batch.toLowerCase().contains(query) ||
        student.major.toLowerCase().contains(query) ||
        student.academicYear.toLowerCase().contains(query) ||
        (student.registrationNumber?.toLowerCase().contains(query) ?? false) ||
        (student.eduMail?.toLowerCase().contains(query) ?? false);
  }

  // Get filtered students based on search and batch filter
  List<Student> get filteredStudents {
    return students.where((student) {
      // Filter by search query
      if (!_matchesSearch(student)) return false;

      // Filter by batch
      if (_selectedBatch != null && student.batch != _selectedBatch) return false;

      return true;
    }).toList();
  }

  // Get CSE students from filtered list
  List<Student> get cseStudents {
    return filteredStudents.where((student) => student.major == 'CSE').toList();
  }

  // Get ECE students from filtered list
  List<Student> get eceStudents {
    return filteredStudents.where((student) => student.major == 'ECE').toList();
  }

  // Update counts for cards
  void _updateCounts() {
    setState(() {
      total = filteredStudents.length;
      pending = filteredStudents
          .where((student) =>
      student.enrollmentStatus == EnrollmentStatus.pending)
          .length;
      enrolled = filteredStudents
          .where((student) =>
      student.enrollmentStatus == EnrollmentStatus.enrolled)
          .length;
      rejected = filteredStudents
          .where((student) =>
      student.enrollmentStatus == EnrollmentStatus.rejected)
          .length;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _updateCounts();
    });
  }

  // Clear batch filter
  void _clearBatchFilter() {
    setState(() {
      _selectedBatch = null;
      _updateCounts();
    });
  }

  // Load students from Firebase
  Future<void> _loadStudents() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // First, check if Firebase is initialized and we have permission
      print('Attempting to load students from Firestore...');

      QuerySnapshot querySnapshot = await _firestore.collection('students').get();

      print('Found ${querySnapshot.docs.length} documents in students collection');

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          errorMessage = 'No students found in the database. Please add some students.';
          isLoading = false;
        });
        return;
      }

      setState(() {
        students = querySnapshot.docs
            .map((doc) => Student.fromFirestore(doc))
            .toList();
        isLoading = false;
        _updateCounts();
      });

      print('Successfully loaded ${students.length} students');
    } catch (e) {
      print('Error loading students from Firebase: $e');
      setState(() {
        errorMessage = 'Error loading students: $e';
        isLoading = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save student to Firebase
  Future<void> _saveStudent(Student student,
      {bool isUpdating = false}) async {
    try {
      if (isUpdating) {
        // For existing students - update both enrollStatus and academicStatus in academicInfo
        Map<String, dynamic> updateData = student.toFirestore();

        await _firestore
            .collection('students')
            .doc(student.id)
            .update(updateData);

        print('Updated student ${student.name}:');
        print('  - enrollStatus: ${updateData['academicInfo.enrollStatus']}');
        print('  - academicStatus: ${updateData['academicInfo.academicStatus']}');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Student status updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // For new students, you probably don't want to create them here
        print('Creating new students should be done through enrollment forms');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Use enrollment forms to create new students')),
        );
      }

      // Reload the data
      _loadStudents();
    } catch (e) {
      print('Error saving student: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete student from Firebase
  Future<void> _deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).delete();

      // Reload the data
      _loadStudents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting student: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  // Check if device is mobile based on screen width
  bool get isMobile => MediaQuery.of(context).size.width < 768;

  // Build responsive info cards
  Widget _buildInfoCards() {
    if (students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Text('No data available'),
      );
    }

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 8),
            _buildInfoCard(Icons.group, 'total'.tr(), total.toString(), Colors.blue),
            const SizedBox(width: 8),
            _buildInfoCard(Icons.pending_actions, 'pending1'.tr(), pending.toString(), Colors.orange),
            const SizedBox(width: 8),
            _buildInfoCard(Icons.school, 'enrolled'.tr(), enrolled.toString(), Colors.green),
            const SizedBox(width: 8),
            _buildInfoCard(Icons.cancel, 'rejected'.tr(), rejected.toString(), Colors.red),
            const SizedBox(width: 8),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoCard(Icons.group, 'total'.tr(), total.toString(), Colors.blue),
          _buildInfoCard(Icons.pending_actions, 'pending1'.tr(), pending.toString(), Colors.orange),
          _buildInfoCard(Icons.school, 'enrolled'.tr(), enrolled.toString(), Colors.green),
          _buildInfoCard(Icons.cancel, 'rejected'.tr(), rejected.toString(), Colors.red),
        ],
      );
    }
  }

  // Build info card widget
  Widget _buildInfoCard(
      IconData icon, String title, String value, Color color) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      width: isMobile ? 90 : (isSmallScreen ? 100 : 120),
      height: isMobile ? 90 : 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isMobile ? 24 : 28),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Build search box widget
  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search'.tr(),
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[600]!),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _updateCounts();
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _updateCounts();
                });
              },
            ),
        ],
      ),
    );
  }

  // Build batch filter dropdown
  Widget _buildBatchFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedBatch,
              decoration: InputDecoration(
                hintText: 'Select Batch',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[600]!),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Batches'),
                ),
                ...batchOptions.map((batch) {
                  return DropdownMenuItem(
                    value: batch,
                    child: Text('Batch $batch'),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedBatch = value;
                  _updateCounts();
                });
              },
              isExpanded: true,
            ),
          ),
          if (_selectedBatch != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: _clearBatchFilter,
            ),
        ],
      ),
    );
  }

  // Build major columns (CSE and ECE side by side)
  Widget _buildMajorColumns() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStudents,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No students found in the database.\nPlease add students through the enrollment form.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStudents,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredStudents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _searchQuery.isEmpty && _selectedBatch == null
                ? 'noStudents'.tr()
                : 'noSearchResults'.tr(),
            style: TextStyle(fontSize: 16, color: Colors.grey[600]!),
          ),
        ),
      );
    }

    if (isMobile) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildMajorColumn('CSE', cseStudents, Colors.blue),
            const SizedBox(height: 16),
            _buildMajorColumn('ECE', eceStudents, Colors.green),
          ],
        ),
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CSE Column
          Expanded(
            child: _buildMajorColumn('CSE', cseStudents, Colors.blue),
          ),
          const SizedBox(width: 16),

          // ECE Column
          Expanded(
            child: _buildMajorColumn('ECE', eceStudents, Colors.green),
          ),
        ],
      );
    }
  }

  // Alternative fix with ConstrainedBox
  Widget _buildMajorColumn(String major, List<Student> students, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7, // Set a max height
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Column Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    major == 'CSE' ? Icons.computer : Icons.electrical_services,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$major Students',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      students.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Students List
            Expanded(
              child: students.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'No $major students found',
                    style: TextStyle(
                      color: Colors.grey[600]!,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: false,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return _buildStudentListItem(student, index + 1, color);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStudentListItem(Student student, int index, Color color) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          radius: isSmallScreen ? 15 : 20,
          child: Text(
            index.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
        title: Text(
          student.name.isNotEmpty ? student.name : 'No Name',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 13 : 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roll No: ${student.rollNo.isNotEmpty ? student.rollNo : 'N/A'} | Batch: ${student.batch.isNotEmpty ? student.batch : 'N/A'}',
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: Colors.grey[600]!,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Status indicators - FIXED: Wrap with Wrap to prevent overflow
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                // Enrollment Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getEnrollmentStatusColor(student.enrollmentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getEnrollmentStatusColor(student.enrollmentStatus).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _getEnrollmentStatusText(student.enrollmentStatus),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 9 : 10,
                      color: _getEnrollmentStatusColor(student.enrollmentStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Student Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStudentStatusColor(student.studentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStudentStatusColor(student.studentStatus).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _getStudentStatusText(student.studentStatus),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 9 : 10,
                      color: _getStudentStatusColor(student.studentStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.visibility, size: isSmallScreen ? 16 : 18, color: Colors.green.shade700),
              onPressed: () => _viewDetails(student),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.edit, size: isSmallScreen ? 16 : 18, color: Colors.blue.shade700),
              onPressed: () => _editStudent(student),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.delete, size: isSmallScreen ? 16 : 18, color: Colors.red.shade700),
              onPressed: () => _deleteStudent(student.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        onTap: () => _viewDetails(student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info cards row
            Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              child: _buildInfoCards(),
            ),

            // Search box
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12.0 : 16.0,
                vertical: isMobile ? 4.0 : 8.0,
              ),
              child: _buildSearchBox(),
            ),

            // Batch filter dropdown
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12.0 : 16.0,
                vertical: isMobile ? 4.0 : 8.0,
              ),
              child: _buildBatchFilter(),
            ),

            // Search results count
            if ((_searchQuery.isNotEmpty || _selectedBatch != null) && filteredStudents.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12.0 : 16.0,
                  vertical: 4.0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filteredStudents.length} students found${_selectedBatch != null ? ' in Batch $_selectedBatch' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600]!,
                      fontStyle: FontStyle.italic,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
              ),

            const Divider(height: 1),

            // CSE and ECE Columns
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                child: _buildMajorColumns(),
              ),
            ),
          ],
        ),
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
    _showStudentForm(student: student);
  }

  Future<Map<String, String?>> fetchStudentPhotoUrls(String rollNo) async {
    try {
      final response = await Supabase.instance.client
          .from('student_photos')
          .select('student_photo_url, id_front_url, id_back_url')
          .eq('roll_no', rollNo)
          .maybeSingle();

      if (response == null) {
        return {
          'student_photo_url': null,
          'id_front_url': null,
          'id_back_url': null,
        };
      }

      return {
        'student_photo_url': response['student_photo_url'],
        'id_front_url': response['id_front_url'],
        'id_back_url': response['id_back_url'],
      };
    } catch (e) {
      print('Error fetching photo URLs: $e');
      return {
        'student_photo_url': null,
        'id_front_url': null,
        'id_back_url': null,
      };
    }
  }
  void _showStudentForm({Student? student}) {
    final isEditing = student != null;

    // Basic Information Controllers
    final nameController = TextEditingController(text: student?.name ?? '');
    final rollNoController = TextEditingController(text: student?.rollNo ?? '');
    final academicYearController = TextEditingController(text: student?.academicYear ?? '');
    final batchController = TextEditingController(text: student?.batch ?? '');
    final majorController = TextEditingController(text: student?.major ?? '');

    // Personal Information Controllers
    final eduMailController = TextEditingController(text: student?.eduMail ?? '');
    final courseYearController = TextEditingController(text: student?.courseYear ?? '');
    final regNoController = TextEditingController(text: student?.registrationNumber ?? '');
    final dobController = TextEditingController(text: student?.dateOfBirth ?? '');
    final genderController = TextEditingController(text: student?.gender ?? '');
    final religionController = TextEditingController(text: student?.religion ?? '');

    // NRC Controllers
    final nrcDivisionController = TextEditingController(text: student?.nrcDivision ?? '');
    final nrcTownshipController = TextEditingController(text: student?.nrcTownship ?? '');
    final nrcTypeController = TextEditingController(text: student?.nrcType ?? 'N');
    final nrcNumberController = TextEditingController(text: student?.nrcNumber ?? '');
    final contactController = TextEditingController(text: student?.contactNumber ?? '');
    final addressController = TextEditingController(text: student?.address ?? '');

    // Father Information Controllers
    final fatherNameController = TextEditingController(text: student?.fatherName ?? '');
    final fatherDobController = TextEditingController(text: student?.fatherDateOfBirth ?? '');
    final fatherReligionController = TextEditingController(text: student?.fatherReligion ?? '');
    final fatherNrcDivisionController = TextEditingController(text: student?.fatherNrcDivision ?? '');
    final fatherNrcTownshipController = TextEditingController(text: student?.fatherNrcTownship ?? '');
    final fatherNrcTypeController = TextEditingController(text: student?.fatherNrcType ?? 'N');
    final fatherNrcNumberController = TextEditingController(text: student?.fatherNrcNumber ?? '');
    final fatherContactController = TextEditingController(text: student?.fatherContactNumber ?? '');
    final fatherAddressController = TextEditingController(text: student?.fatherAddress ?? '');

    // Mother Information Controllers
    final motherNameController = TextEditingController(text: student?.motherName ?? '');
    final motherDobController = TextEditingController(text: student?.motherDateOfBirth ?? '');
    final motherReligionController = TextEditingController(text: student?.motherReligion ?? '');
    final motherNrcDivisionController = TextEditingController(text: student?.motherNrcDivision ?? '');
    final motherNrcTownshipController = TextEditingController(text: student?.motherNrcTownship ?? '');
    final motherNrcTypeController = TextEditingController(text: student?.motherNrcType ?? 'N');
    final motherNrcNumberController = TextEditingController(text: student?.motherNrcNumber ?? '');
    final motherContactController = TextEditingController(text: student?.motherContactNumber ?? '');
    final motherAddressController = TextEditingController(text: student?.motherAddress ?? '');

    // Photo state variables
    // Current URLs from table
    String? currentStudentPhotoUrl;
    String? currentIdFrontUrl;
    String? currentIdBackUrl;

    // New files to upload (if changed)
    File? newStudentPhotoFile;
    Uint8List? newStudentPhotoWebBytes;
    File? newIdFrontFile;
    Uint8List? newIdFrontWebBytes;
    File? newIdBackFile;
    Uint8List? newIdBackWebBytes;

    // Loading state
    bool isLoadingPhotos = true;

    EnrollmentStatus enrollmentStatus = student?.enrollmentStatus ?? EnrollmentStatus.pending;
    StudentStatus studentStatus = student?.studentStatus ?? StudentStatus.active;

    // Fetch existing photo URLs if editing
    if (isEditing) {
      fetchStudentPhotoUrls(student.rollNo).then((urls) {
        currentStudentPhotoUrl = urls['student_photo_url'];
        currentIdFrontUrl = urls['id_front_url'];
        currentIdBackUrl = urls['id_back_url'];
        isLoadingPhotos = false;
        // Note: You'll need to trigger a rebuild - we'll handle this inside the dialog
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Load photos if not loaded yet and editing
            if (isEditing && isLoadingPhotos) {
              fetchStudentPhotoUrls(student.rollNo).then((urls) {
                setState(() {
                  currentStudentPhotoUrl = urls['student_photo_url'];
                  currentIdFrontUrl = urls['id_front_url'];
                  currentIdBackUrl = urls['id_back_url'];
                  isLoadingPhotos = false;
                });
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? MediaQuery.of(context).size.width * 0.95 : 600,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Edit Student' : 'Add New Student',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ========== PHOTO EDIT SECTION ==========
                            _buildEditPhotoSection(
                              currentStudentPhotoUrl: currentStudentPhotoUrl,
                              currentIdFrontUrl: currentIdFrontUrl,
                              currentIdBackUrl: currentIdBackUrl,
                              newStudentPhotoFile: newStudentPhotoFile,
                              newStudentPhotoWebBytes: newStudentPhotoWebBytes,
                              newIdFrontFile: newIdFrontFile,
                              newIdFrontWebBytes: newIdFrontWebBytes,
                              newIdBackFile: newIdBackFile,
                              newIdBackWebBytes: newIdBackWebBytes,
                              onStudentPhotoPicked: (file, webBytes) {
                                setState(() {
                                  newStudentPhotoFile = file;
                                  newStudentPhotoWebBytes = webBytes;
                                });
                              },
                              onIdFrontPicked: (file, webBytes) {
                                setState(() {
                                  newIdFrontFile = file;
                                  newIdFrontWebBytes = webBytes;
                                });
                              },
                              onIdBackPicked: (file, webBytes) {
                                setState(() {
                                  newIdBackFile = file;
                                  newIdBackWebBytes = webBytes;
                                });
                              },
                            ),
                            const SizedBox(height: 24),

                            // Student Information section
                            _buildFormSection('Student Information'),
                            _buildTextField(nameController, 'Name'),
                            _buildTextField(rollNoController, 'Roll No'),
                            _buildTextField(academicYearController, 'Academic Year'),
                            _buildTextField(batchController, 'Batch'),
                            _buildTextField(majorController, 'Major'),
                            _buildTextField(eduMailController, 'Education Email'),
                            _buildTextField(courseYearController, 'Course Year'),
                            _buildTextField(regNoController, 'Registration Number'),
                            _buildTextField(dobController, 'Date of Birth'),
                            _buildTextField(genderController, 'Gender'),
                            _buildTextField(religionController, 'Religion'),

                            // Student NRC Components
                            _buildFormSection('Student NRC'),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(nrcDivisionController, 'Division'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(nrcTownshipController, 'Township'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(nrcTypeController, 'Type'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(nrcNumberController, 'Number'),
                                ),
                              ],
                            ),
                            Text(
                              'NRC Format: ${nrcDivisionController.text}/${nrcTownshipController.text}(${nrcTypeController.text})${nrcNumberController.text}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),

                            _buildTextField(contactController, 'Contact Number'),
                            _buildTextField(addressController, 'Address', lines: 2),

                            // Father Information
                            _buildFormSection('Father Information'),
                            _buildTextField(fatherNameController, 'Father Name'),
                            _buildTextField(fatherDobController, 'Father Date of Birth'),
                            _buildTextField(fatherReligionController, 'Father Religion'),

                            // Father NRC Components
                            _buildFormSection('Father NRC'),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(fatherNrcDivisionController, 'Division'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(fatherNrcTownshipController, 'Township'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(fatherNrcTypeController, 'Type'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(fatherNrcNumberController, 'Number'),
                                ),
                              ],
                            ),

                            _buildTextField(fatherContactController, 'Father Contact Number'),
                            _buildTextField(fatherAddressController, 'Father Address', lines: 2),

                            // Mother Information
                            _buildFormSection('Mother Information'),
                            _buildTextField(motherNameController, 'Mother Name'),
                            _buildTextField(motherDobController, 'Mother Date of Birth'),
                            _buildTextField(motherReligionController, 'Mother Religion'),

                            // Mother NRC Components
                            _buildFormSection('Mother NRC'),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(motherNrcDivisionController, 'Division'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(motherNrcTownshipController, 'Township'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(motherNrcTypeController, 'Type'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(motherNrcNumberController, 'Number'),
                                ),
                              ],
                            ),

                            _buildTextField(motherContactController, 'Mother Contact Number'),
                            _buildTextField(motherAddressController, 'Mother Address', lines: 2),

                            const SizedBox(height: 16),

                            // Status Selection
                            isMobile ? Column(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Enrollment Status',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
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
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Student Status',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
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
                            ) : Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Enrollment Status',
                                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Student Status',
                                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              // Show loading indicator
                              setState(() {
                                isLoadingPhotos = true;
                              });

                              try {
                                final rollNo = rollNoController.text;

                                // Upload new photos if any
                                if (newStudentPhotoFile != null || newStudentPhotoWebBytes != null) {
                                  final newUrl = await uploadNewPhoto(
                                      newStudentPhotoFile,
                                      newStudentPhotoWebBytes,
                                      rollNo,
                                      'student_photo'
                                  );
                                  if (newUrl != null) {
                                    currentStudentPhotoUrl = newUrl;
                                  }
                                }

                                if (newIdFrontFile != null || newIdFrontWebBytes != null) {
                                  final newUrl = await uploadNewPhoto(
                                      newIdFrontFile,
                                      newIdFrontWebBytes,
                                      rollNo,
                                      'id_front'
                                  );
                                  if (newUrl != null) {
                                    currentIdFrontUrl = newUrl;
                                  }
                                }

                                if (newIdBackFile != null || newIdBackWebBytes != null) {
                                  final newUrl = await uploadNewPhoto(
                                      newIdBackFile,
                                      newIdBackWebBytes,
                                      rollNo,
                                      'id_back'
                                  );
                                  if (newUrl != null) {
                                    currentIdBackUrl = newUrl;
                                  }
                                }

                                // Update student info in Firestore
                                final newStudent = Student(
                                  id: isEditing ? student!.id : '',
                                  name: nameController.text,
                                  rollNo: rollNoController.text,
                                  academicYear: academicYearController.text,
                                  batch: batchController.text,
                                  major: majorController.text,
                                  enrollmentStatus: enrollmentStatus,
                                  studentStatus: studentStatus,
                                  eduMail: eduMailController.text,
                                  courseYear: courseYearController.text,
                                  registrationNumber: regNoController.text,
                                  dateOfBirth: dobController.text,
                                  gender: genderController.text,
                                  religion: religionController.text,
                                  nrcDivision: nrcDivisionController.text,
                                  nrcTownship: nrcTownshipController.text,
                                  nrcType: nrcTypeController.text,
                                  nrcNumber: nrcNumberController.text,
                                  contactNumber: contactController.text,
                                  address: addressController.text,
                                  fatherName: fatherNameController.text,
                                  fatherDateOfBirth: fatherDobController.text,
                                  fatherReligion: fatherReligionController.text,
                                  fatherNrcDivision: fatherNrcDivisionController.text,
                                  fatherNrcTownship: fatherNrcTownshipController.text,
                                  fatherNrcType: fatherNrcTypeController.text,
                                  fatherNrcNumber: fatherNrcNumberController.text,
                                  fatherContactNumber: fatherContactController.text,
                                  fatherAddress: fatherAddressController.text,
                                  motherName: motherNameController.text,
                                  motherDateOfBirth: motherDobController.text,
                                  motherReligion: motherReligionController.text,
                                  motherNrcDivision: motherNrcDivisionController.text,
                                  motherNrcTownship: motherNrcTownshipController.text,
                                  motherNrcType: motherNrcTypeController.text,
                                  motherNrcNumber: motherNrcNumberController.text,
                                  motherContactNumber: motherContactController.text,
                                  motherAddress: motherAddressController.text,
                                );

                                await _saveStudent(newStudent, isUpdating: isEditing);

                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'Updated ${nameController.text}'
                                          : 'Added ${nameController.text}',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // Reload students list
                                _loadStudents();

                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                setState(() {
                                  isLoadingPhotos = false;
                                });
                              }
                            },
                            child: Text(isEditing ? 'Update' : 'Add'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _viewDetails(Student student) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? MediaQuery.of(context).size.width * 0.95 : 800,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Student Details: ${student.name.isNotEmpty ? student.name : 'N/A'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ========== PHOTO SECTION WITH ACTUAL URLs ==========
                        _buildPhotoSection(student), // Pass the student object
                        const SizedBox(height: 24),

                        // Student Information section
                        _buildSectionTitle('Student Information'),
                        _buildDetailRow('Name', student.name),
                        _buildDetailRow('Roll No', student.rollNo),
                        _buildDetailRow('Academic Year', student.academicYear),
                        _buildDetailRow('Batch', student.batch),
                        _buildDetailRow('Major', student.major),
                        _buildDetailRow('Enrollment Status',
                            _getEnrollmentStatusText(student.enrollmentStatus)),
                        _buildDetailRow('Student Status',
                            _getStudentStatusText(student.studentStatus)),
                        _buildDetailRow('Education Email', student.eduMail),
                        _buildDetailRow('Course Year', student.courseYear),
                        _buildDetailRow('Registration Number',
                            student.registrationNumber),
                        _buildDetailRow('Date of Birth', student.dateOfBirth),
                        _buildDetailRow('Gender', student.gender),
                        _buildDetailRow('Religion', student.religion),
                        _buildDetailRow('NRC', student.nrc),
                        _buildDetailRow('Contact Number', student.contactNumber),
                        _buildDetailRow('Address', student.address),

                        const SizedBox(height: 16),

                        // Father Information Section
                        _buildSectionTitle('Father Information'),
                        _buildDetailRow('Name', student.fatherName),
                        _buildDetailRow('Date of Birth', student.fatherDateOfBirth),
                        _buildDetailRow('Religion', student.fatherReligion),
                        _buildDetailRow('NRC', student.fatherNrc),
                        _buildDetailRow('Contact Number', student.fatherContactNumber),
                        _buildDetailRow('Address', student.fatherAddress),

                        const SizedBox(height: 16),

                        // Mother Information Section
                        _buildSectionTitle('Mother Information'),
                        _buildDetailRow('Name', student.motherName),
                        _buildDetailRow('Date of Birth', student.motherDateOfBirth),
                        _buildDetailRow('Religion', student.motherReligion),
                        _buildDetailRow('NRC', student.motherNrc),
                        _buildDetailRow('Contact Number', student.motherContactNumber),
                        _buildDetailRow('Address', student.motherAddress),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Close', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
// Add this method to your _StudentInfoScreenState class
  Widget _buildPhotoSection(Student student) {
    return FutureBuilder<Map<String, String?>>(
      future: getStudentPhotoUrls(student.rollNo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Loading state
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Photos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          print('Error loading photos: ${snapshot.error}');
          return _buildPhotoPlaceholderSection('Failed to load photos');
        }

        final urls = snapshot.data ?? {
          'student_photo_url': null,
          'id_front_url': null,
          'id_back_url': null,
        };

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Photos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 12),

              Column(
                children: [
                  _buildPhotoFrame('Student Photo', urls['student_photo_url']),
                  const SizedBox(height: 12),
                  _buildPhotoFrame('ID Card (Front)', urls['id_front_url']),
                  const SizedBox(height: 12),
                  _buildPhotoFrame('ID Card (Back)', urls['id_back_url']),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildPhotoPlaceholderSection(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Photos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<Map<String, String?>> getStudentPhotoUrls(String rollNo) async {
    try {
      final response = await Supabase.instance.client
          .from('student_photos')
          .select('student_photo_url, id_front_url, id_back_url')
          .eq('roll_no', rollNo)
          .maybeSingle();

      if (response == null) {
        print('No photo record found for roll_no: $rollNo');
        return {
          'student_photo_url': null,
          'id_front_url': null,
          'id_back_url': null,
        };
      }

      print('Found photo URLs for roll_no: $rollNo');
      print('  student_photo_url: ${response['student_photo_url']}');
      print('  id_front_url: ${response['id_front_url']}');
      print('  id_back_url: ${response['id_back_url']}');

      return {
        'student_photo_url': response['student_photo_url'],
        'id_front_url': response['id_front_url'],
        'id_back_url': response['id_back_url'],
      };

    } catch (e) {
      print('Error fetching photo URLs: $e');
      return {
        'student_photo_url': null,
        'id_front_url': null,
        'id_back_url': null,
      };
    }
  }



// Individua Photo Frame Widget

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildPhotoFrame(String title, String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Photo Frame
          GestureDetector(
            onTap: () {
              if (imageUrl != null && imageUrl.isNotEmpty) {
                _showFullScreenImage(imageUrl);
              }
            },
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return _buildPhotoPlaceholder('Failed to load');
                },
              )
                  : _buildPhotoPlaceholder('No photo uploaded'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 40,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isMobileView = isMobile || MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobileView ? 140 : 180,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobileView ? 12 : 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
              style: TextStyle(
                fontSize: isMobileView ? 12 : 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Edit Show Form with NRC components
  Future<String?> uploadNewPhoto(File? file, Uint8List? webBytes, String rollNo, String photoType) async {
    if (file == null && webBytes == null) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${rollNo}_${photoType}_$timestamp.jpg';
      final path = 'uploads/$fileName';

      // Upload to storage
      if (kIsWeb) {
        if (webBytes != null) {
          await Supabase.instance.client.storage
              .from('student_photos')
              .uploadBinary(path, webBytes, fileOptions: FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ));
        }
      } else {
        if (file != null) {
          await Supabase.instance.client.storage
              .from('student_photos')
              .upload(path, file, fileOptions: FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ));
        }
      }

      // Get public URL
      final imageUrl = Supabase.instance.client.storage
          .from('student_photos')
          .getPublicUrl(path);

      // Update table
      Map<String, dynamic> updateData = {
        'roll_no': rollNo,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (photoType == 'student_photo') {
        updateData['student_photo_url'] = imageUrl;
      } else if (photoType == 'id_front') {
        updateData['id_front_url'] = imageUrl;
      } else if (photoType == 'id_back') {
        updateData['id_back_url'] = imageUrl;
      }

      await Supabase.instance.client
          .from('student_photos')
          .upsert(updateData);

      print('Successfully uploaded and saved $photoType for roll_no: $rollNo');
      return imageUrl;

    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }
  Widget _buildEditPhotoSection({
    required String? currentStudentPhotoUrl,
    required String? currentIdFrontUrl,
    required String? currentIdBackUrl,
    required File? newStudentPhotoFile,
    required Uint8List? newStudentPhotoWebBytes,
    required File? newIdFrontFile,
    required Uint8List? newIdFrontWebBytes,
    required File? newIdBackFile,
    required Uint8List? newIdBackWebBytes,
    required Function(File?, Uint8List?) onStudentPhotoPicked,
    required Function(File?, Uint8List?) onIdFrontPicked,
    required Function(File?, Uint8List?) onIdBackPicked,
  }) {
    final ImagePicker picker = ImagePicker();

    Future<void> pickImage(Function(File?, Uint8List?) onPickedCallback) async {
      try {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );

        if (image != null) {
          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            onPickedCallback(null, bytes);
          } else {
            onPickedCallback(File(image.path), null);
          }
        }
      } catch (e) {
        print('Error picking image: $e');
      }
    }

    Widget buildPhotoPreview(
        String title,
        String? currentUrl,
        File? newFile,
        Uint8List? newWebBytes,
        Function(File?, Uint8List?) onPickedCallback
        ) {
      // Determine what to show
      Widget previewWidget;

      if (newFile != null) {
        // Show new picked file preview
        previewWidget = kIsWeb
            ? Image.network(newFile.path, fit: BoxFit.cover)
            : Image.file(newFile, fit: BoxFit.cover);
      } else if (newWebBytes != null) {
        previewWidget = Image.memory(newWebBytes, fit: BoxFit.cover);
      } else if (currentUrl != null && currentUrl.isNotEmpty) {
        // Show existing photo from URL
        previewWidget = Image.network(
          currentUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPhotoPlaceholder('Failed to load');
          },
        );
      } else {
        // Show placeholder
        previewWidget = _buildPhotoPlaceholder('No photo');
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: previewWidget,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () => pickImage(onPickedCallback),
                icon: const Icon(Icons.upload_file, size: 16),
                label: Text(
                    (newFile != null || newWebBytes != null || (currentUrl != null && currentUrl.isNotEmpty))
                        ? 'Change Photo'
                        : 'Upload Photo'
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  side: BorderSide(color: Colors.blue.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Photos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              buildPhotoPreview(
                'Student Photo',
                currentStudentPhotoUrl,
                newStudentPhotoFile,
                newStudentPhotoWebBytes,
                onStudentPhotoPicked,  // Pass the callback correctly
              ),
              const SizedBox(height: 12),
              buildPhotoPreview(
                'ID Card (Front)',
                currentIdFrontUrl,
                newIdFrontFile,
                newIdFrontWebBytes,
                onIdFrontPicked,  // Pass the callback correctly
              ),
              const SizedBox(height: 12),
              buildPhotoPreview(
                'ID Card (Back)',
                currentIdBackUrl,
                newIdBackFile,
                newIdBackWebBytes,
                onIdBackPicked,  // Pass the callback correctly
              ),
            ],
          ),
        ],
      ),
    );
  }

// New method with unique name - Form Photo Upload Section
  Widget _buildFormPhotoUploadSection({
    required String? studentPhoto,
    required String? idCardFront,
    required String? idCardBack,
    required Function(String?) onStudentPhotoChanged,
    required Function(String?) onIdCardFrontChanged,
    required Function(String?) onIdCardBackChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Photos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),

          // Always vertical stack
          Column(
            children: [
              _buildFormPhotoUploadFrame(
                'Student Photo',
                studentPhoto,
                onChanged: onStudentPhotoChanged,
              ),
              const SizedBox(height: 12),
              _buildFormPhotoUploadFrame(
                'ID Card (Front)',
                idCardFront,
                onChanged: onIdCardFrontChanged,
              ),
              const SizedBox(height: 12),
              _buildFormPhotoUploadFrame(
                'ID Card (Back)',
                idCardBack,
                onChanged: onIdCardBackChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

// Individual Photo Upload Frame with unique name
  Widget _buildFormPhotoUploadFrame(
      String title,
      String? currentPhoto, {
        required Function(String?) onChanged,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Photo Preview
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.grey.shade100,
            child: currentPhoto != null && currentPhoto.isNotEmpty
                ? ClipRRect(
              child: Image.network(
                currentPhoto,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFormPhotoPlaceholderWidget('Failed to load');
                },
              ),
            )
                : _buildFormPhotoPlaceholderWidget('No photo'),
          ),

          // Upload Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement image picker and upload to Supabase
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upload $title - Will connect to Supabase'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                // For testing, you can uncomment this to simulate upload:
                // onChanged('https://via.placeholder.com/150');
              },
              icon: const Icon(Icons.upload_file, size: 16),
              label: Text(currentPhoto != null ? 'Change Photo' : 'Upload Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Unique placeholder widget for form photos
  Widget _buildFormPhotoPlaceholderWidget(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 40,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

// New method for photo upload section in form
  Widget _buildFormPhotoSection({
    required String? studentPhoto,
    required String? idCardFront,
    required String? idCardBack,
    required Function(String?) onStudentPhotoChanged,
    required Function(String?) onIdCardFrontChanged,
    required Function(String?) onIdCardBackChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Photos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),

          // Always vertical stack
          Column(
            children: [
              _buildFormPhotoFrame(
                'Student Photo',
                studentPhoto,
                onChanged: onStudentPhotoChanged,
              ),
              const SizedBox(height: 12),
              _buildFormPhotoFrame(
                'ID Card (Front)',
                idCardFront,
                onChanged: onIdCardFrontChanged,
              ),
              const SizedBox(height: 12),
              _buildFormPhotoFrame(
                'ID Card (Back)',
                idCardBack,
                onChanged: onIdCardBackChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

// Individual Photo Upload Frame for Form
  Widget _buildFormPhotoFrame(
      String title,
      String? currentPhoto, {
        required Function(String?) onChanged,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Photo Preview
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.grey.shade100,
            child: currentPhoto != null && currentPhoto.isNotEmpty
                ? ClipRRect(
              child: Image.network(
                currentPhoto,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFormPhotoPlaceholder('Failed to load');
                },
              ),
            )
                : _buildFormPhotoPlaceholder('No photo'),
          ),

          // Upload Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement image picker and upload to Supabase
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upload $title - Will connect to Supabase'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                // For testing, you can uncomment this to simulate upload:
                // onChanged('https://via.placeholder.com/150');
              },
              icon: const Icon(Icons.upload_file, size: 16),
              label: Text(currentPhoto != null ? 'Change Photo' : 'Upload Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

// New placeholder method for form photos
  Widget _buildFormPhotoPlaceholder(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 40,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

// Add this method for photo upload section
  Widget _buildPhotoUploadSection({
    required String? studentPhoto,
    required String? idCardFront,
    required String? idCardBack,
    required Function(String?) onStudentPhotoChanged,
    required Function(String?) onIdCardFrontChanged,
    required Function(String?) onIdCardBackChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Photos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),

          // Always vertical stack
          Column(
            children: [
              _buildPhotoUploadFrame(
                'Student Photo',
                studentPhoto,
                onChanged: onStudentPhotoChanged,
              ),
              const SizedBox(height: 12),
              _buildPhotoUploadFrame(
                'ID Card (Front)',
                idCardFront,
                onChanged: onIdCardFrontChanged,
              ),
              const SizedBox(height: 12),
              _buildPhotoUploadFrame(
                'ID Card (Back)',
                idCardBack,
                onChanged: onIdCardBackChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

// Individual Photo Upload Frame with Upload Button
  Widget _buildPhotoUploadFrame(
      String title,
      String? currentPhoto, {
        required Function(String?) onChanged,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Photo Preview
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.grey.shade100,
            child: currentPhoto != null && currentPhoto.isNotEmpty
                ? ClipRRect(
              child: Image.network(
                currentPhoto,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPhotoPlaceholder('Failed to load');
                },
              ),
            )
                : _buildPhotoPlaceholder('No photo'),
          ),

          // Upload Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement image picker and upload to Supabase
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upload $title - Will connect to Supabase'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                // For testing, you can uncomment this to simulate upload:
                // onChanged('https://via.placeholder.com/150');
              },
              icon: const Icon(Icons.upload_file, size: 16),
              label: Text(currentPhoto != null ? 'Change Photo' : 'Upload Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildFormSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: lines,
        minLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
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
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(_getEnrollmentStatusText(status), style: const TextStyle(fontSize: 12)),
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
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(_getStudentStatusText(status), style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}