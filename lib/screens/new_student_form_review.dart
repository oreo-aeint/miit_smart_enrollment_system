import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:miit_project/components/text.dart';
import 'home_screen.dart';
import 'my_drawer.dart';
import 'old_student_enrollment_app.dart';

class NewStudentFormReview extends StatefulWidget {
  final String studentEmail;
  final String studentId;
  final Map<String, dynamic> studentData;

  const NewStudentFormReview({
    Key? key,
    required this.studentEmail,
    required this.studentId,
    required this.studentData,
  }) : super(key: key);

  @override
  State<NewStudentFormReview> createState() => _OldStudentFormReviewState();
}

class _OldStudentFormReviewState extends State<NewStudentFormReview> {
  List<Map<String, dynamic>> _enrollmentRequests = [];
  bool _isLoading = true;
  String? _currentAcademicYear;

  @override
  void initState() {
    super.initState();
    _loadCurrentAcademicYear();
    _loadEnrollmentHistory();
  }

  Future<void> _loadCurrentAcademicYear() async {
    try {
      final academicYearDoc = await FirebaseFirestore.instance
          .collection('admin_academic_year')
          .doc('admin')
          .get();

      if (academicYearDoc.exists) {
        final academicYearData = academicYearDoc.data();
        final startYear = academicYearData?['astart_year']?.toString();
        final endYear = academicYearData?['aend_year']?.toString();
        if (startYear != null && endYear != null) {
          setState(() {
            _currentAcademicYear = '$startYear-$endYear';
          });
        }
      }
    } catch (e) {
      print('Error loading current academic year: $e');
    }
  }

  Future<void> _loadEnrollmentHistory() async {
    try {
      final enrollmentQuery = await FirebaseFirestore.instance
          .collection('enrollment_requests')
          .where('studentId', isEqualTo: widget.studentId)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _enrollmentRequests = enrollmentQuery.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          data['requestDate'] = data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now();
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading enrollment history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isImportant ? Colors.indigo : Colors.grey[700],
                fontSize: isImportant ? 15 : 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: TextStyle(
                fontSize: isImportant ? 15 : 14,
                fontWeight: isImportant ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    final data = widget.studentData;
    final academicInfo = data['academicInfo'] as Map<String, dynamic>? ?? {};
    final parents = data['parents'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        // Student Basic Information
        _buildInfoCard(
          tr('studentInformation'),
          [
            _buildInfoRow(tr('mName'), data['sname_myanmar']?.toString() ?? ''),
            _buildInfoRow(tr('eName'), data['sname']?.toString() ?? '', isImportant: true),
            _buildInfoRow(tr('rollNo'), data['srollno']?.toString() ?? '', isImportant: true),
            _buildInfoRow(tr('gender'), data['sgender']?.toString() ?? ''),
            _buildInfoRow(tr('religion'), data['sreligion']?.toString() ?? ''),
            _buildInfoRow(tr('phoneNo'), data['scontactNumber']?.toString() ?? ''),
            _buildInfoRow(tr('bDate'), data['sdob']?.toString() ?? ''),
            _buildInfoRow(tr('nrc'), data['snrc']?.toString() ?? ''),
            _buildInfoRow(tr('address'), data['saddress']?.toString() ?? ''),
          ],
        ),

        // Academic Information
        _buildInfoCard(
          tr('academicInformation'),
          [
            _buildInfoRow(tr('registrationNo'), academicInfo['registrationNumber']?.toString() ?? ''),
            _buildInfoRow(tr('yearOfUni'), academicInfo['yearOfUniversity']?.toString() ?? ''),
            _buildInfoRow(tr('courseYear'), academicInfo['courseYear']?.toString() ?? ''),
            _buildInfoRow(tr('academicYear'), academicInfo['academicYear']?.toString() ?? ''),
            _buildInfoRow(tr('email'), academicInfo['eduMail']?.toString() ?? ''),
          ],
        ),

        // Father's Information
        if (parents['father'] != null)
          _buildInfoCard(
            tr('fInformation'),
            [
              _buildInfoRow(tr('mName'), parents['father']['fname_mm']?.toString() ?? ''),
              _buildInfoRow(tr('eName'), parents['father']['fname_eng']?.toString() ?? ''),
              _buildInfoRow(tr('religion'), parents['father']['freligion']?.toString() ?? ''),
              _buildInfoRow(tr('phoneNo'), parents['father']['fphone']?.toString() ?? ''),
              _buildInfoRow(tr('bDate'), parents['father']['fdob']?.toString() ?? ''),
              _buildInfoRow(tr('nrc'), parents['father']['fnrc']?.toString() ?? ''),
              _buildInfoRow(tr('address'), parents['father']['faddress']?.toString() ?? ''),
            ],
          ),

        // Mother's Information
        if (parents['mother'] != null)
          _buildInfoCard(
            tr('mInformation'),
            [
              _buildInfoRow(tr('mName'), parents['mother']['mname_mm']?.toString() ?? ''),
              _buildInfoRow(tr('eName'), parents['mother']['mname_eng']?.toString() ?? ''),
              _buildInfoRow(tr('religion'), parents['mother']['mreligion']?.toString() ?? ''),
              _buildInfoRow(tr('phoneNo'), parents['mother']['mphone']?.toString() ?? ''),
              _buildInfoRow(tr('bDate'), parents['mother']['mdob']?.toString() ?? ''),
              _buildInfoRow(tr('nrc'), parents['mother']['mnrc']?.toString() ?? ''),
              _buildInfoRow(tr('address'), parents['mother']['maddress']?.toString() ?? ''),
            ],
          ),
      ],
    );
  }

  Widget _buildEnrollmentHistory() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter for current academic year enrollments
    final currentYearEnrollments = _currentAcademicYear != null
        ? _enrollmentRequests.where((request) => request['academicYear'] == _currentAcademicYear).toList()
        : [];


    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Academic Year Header
            if (_currentAcademicYear != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${tr("currentAcademicYear")}: $_currentAcademicYear',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),


            const SizedBox(height: 12),

            ...currentYearEnrollments.map((request) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with date and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${request['requestDate'].day}/${request['requestDate'].month}/${request['requestDate'].year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(request['status'] ?? 'Pending'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request['status']?.toString().toUpperCase() ?? 'PENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Enrollment details
                    _buildInfoRow(tr('courseYear'), request['courseYear']?.toString() ?? ''),
                    _buildInfoRow(tr('major'), request['major']?.toString() ?? ''),
                    _buildInfoRow(tr('studentType'), request['studentType']?.toString() ?? ''),
                    _buildInfoRow(tr('academicYear'), request['academicYear']?.toString() ?? ''),

                    // Payment status
                    Row(
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            '${tr('paymentStatus')}:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPaymentStatusColor(request['paymentStatus'] ?? 'Pending'),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            request['paymentStatus']?.toString().toUpperCase() ?? 'PENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Approval information (if available)
                    if (request['approvedBy'] != null)
                      _buildInfoRow(tr('approvedBy'), request['approvedBy']?.toString() ?? ''),

                    if (request['approvedDate'] != null)
                      _buildInfoRow(
                        tr('approvedDate'),
                        (request['approvedDate'] as Timestamp).toDate().toString().split(' ')[0],
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _startNewEnrollment() {
    // Check if there's already an enrollment for current academic year
    final hasCurrentYearEnrollment = _currentAcademicYear != null &&
        _enrollmentRequests.any((request) => request['academicYear'] == _currentAcademicYear);

    if (hasCurrentYearEnrollment) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr("alreadyEnrolled")),
          content: Text(tr("alreadyEnrolledMessage")),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr("ok")),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OldStudentEnrollmentApp(
          studentData: widget.studentData,
          studentId: widget.studentId,
        ),
      ),
    );
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
              colors: [Color(0xFF87CEFA), Color(0xFFADD8E6)],
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
              child: Text(tr("formReview"), style: AppTextStyles.heading),
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
                  DropdownMenuItem(value: Locale('en'), child: Text("English")),
                  DropdownMenuItem(value: Locale('my'), child: Text("မြန်မာ")),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading && _enrollmentRequests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Summary Card
            Card(
              elevation: 4,
              color: Colors.lightBlue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.studentData['sname']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Roll No: ${widget.studentData['srollno']?.toString() ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Email: ${widget.studentEmail}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Enrollment History Section
            _buildEnrollmentHistory(),

            // Student Information Section
            _buildStudentInfo(),

            // Action Buttons
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Replace current screen with MIITHomePage
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MIITHomePage(), // Replace with your actual home page class name
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: Text(
                        tr('backToHome'),
                        style: const TextStyle(color: Colors.lightBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}