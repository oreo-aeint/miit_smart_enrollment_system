import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnrollmentRequestPage extends StatefulWidget {
  const EnrollmentRequestPage({super.key});

  @override
  State<EnrollmentRequestPage> createState() => _EnrollmentRequestPageState();
}

class _EnrollmentRequestPageState extends State<EnrollmentRequestPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> oldStudentRequests = [];
  List<Map<String, dynamic>> newStudentRequests = [];
  StreamSubscription<QuerySnapshot>? _oldStudentsSubscription;
  StreamSubscription<QuerySnapshot>? _newStudentsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupStudentsListener();
  }

  @override
  void dispose() {
    _oldStudentsSubscription?.cancel();
    _newStudentsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupStudentsListener() {
    // Listen for OLD students with pending enrollment
    _oldStudentsSubscription = FirebaseFirestore.instance
        .collection('students')
        .where('stype', isEqualTo: 'old')
        .where('academicInfo.enrollStatus', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      print('Found ${snapshot.docs.length} old students with pending enrollment');
      _processOldStudentRequests(snapshot.docs);
    });

    // Listen for NEW students with pending enrollment
    _newStudentsSubscription = FirebaseFirestore.instance
        .collection('students')
        .where('stype', isEqualTo: 'new')
        .where('academicInfo.enrollStatus', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      print('Found ${snapshot.docs.length} new students with pending enrollment');
      _processNewStudentRequests(snapshot.docs);
    });
  }

  bool _isOldStudentByYear(int? startYear) {
    if (startYear == null) return false;

    // Get current admin year for comparison
    // You might need to fetch this from your admin_academic_year collection
    final currentYear = DateTime.now().year;
    return startYear < currentYear;
  }

  bool _hasPreviousEnrollment(Map<String, dynamic> studentData) {
    // Check if student has payment records in previous academic years
    // This would require checking your paymentInfo collection
    return false; // Implement based on your business logic
  }

  void _processOldStudentRequests(List<QueryDocumentSnapshot> docs) {
    final requests = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final academicInfo = data['academicInfo'] as Map<String, dynamic>? ?? {};

      return {
        "id": doc.id, // Student document ID
        "studentId": doc.id,
        "name": data['sname'] ?? 'Unknown',
        "rollNo1": data['srollno'] ?? 'N/A',
        "courseYear": academicInfo['courseYear'] ?? 'N/A',
        "major": data['smajor'] ?? 'N/A',
        "paymentStatus": "pending", // Default since we're not using enrollment_requests
        "paymentAmount": 0,
        "paymentReference": 'N/A',
        "paymentDate": null,
        "isNewStudent": false, // This is old student
        "status": academicInfo['enrollStatus'] ?? 'pending',
        "approvedBy": null,
        "approvedDate": null,
        "accepted": false,
        "rejected": false,
        "processing": false,
        "deleting": false,
        "studentData": data, // Store full student data for details
      };
    }).toList();

    setState(() {
      oldStudentRequests = requests;
    });
  }

  void _processNewStudentRequests(List<QueryDocumentSnapshot> docs) {
    final requests = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final academicInfo = data['academicInfo'] as Map<String, dynamic>? ?? {};

      return {
        "id": doc.id, // Student document ID
        "studentId": doc.id,
        "name": data['sname'] ?? 'Unknown',
        "rollNo1": data['srollno'] ?? 'N/A',
        "courseYear": academicInfo['courseYear'] ?? 'N/A',
        "major": data['smajor'] ?? 'N/A',
        "paymentStatus": "pending", // Default since we're not using enrollment_requests
        "paymentAmount": 0,
        "paymentReference": 'N/A',
        "paymentDate": null,
        "isNewStudent": true, // This is new student
        "status": academicInfo['enrollStatus'] ?? 'pending',
        "approvedBy": null,
        "approvedDate": null,
        "accepted": false,
        "rejected": false,
        "processing": false,
        "deleting": false,
        "studentData": data, // Store full student data for details
      };
    }).toList();

    setState(() {
      newStudentRequests = requests;
    });
  }

  Future<Map<String, dynamic>?> _getStudentDetails(String studentId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('students').doc(studentId).get();
      if (doc.exists) return doc.data();
    } catch (e) {
      print("Error getting student details: $e");
    }
    return null;
  }

  // Individual confirm button handler
  Future<void> _confirmIndividualRequest(Map<String, dynamic> request) async {
    if (!request["accepted"] && !request["rejected"]) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('pleaseSelectAcceptOrReject'.tr()), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() {
      request["processing"] = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentTime = FieldValue.serverTimestamp();

      // Update student document directly
      final studentRef = FirebaseFirestore.instance.collection('students').doc(request["studentId"]);

      if (request["accepted"]) {
        // Accepted - Enrolled & Active status
        await studentRef.update({
          'academicInfo.enrollStatus': 'enrolled',
          'academicInfo.academicStatus': 'active',
          'academicInfo.enrollmentDate': currentTime,
          'academicInfo.approvedBy': currentUser?.email ?? 'Admin',
          'academicInfo.approvedDate': currentTime,
          'lastUpdated': currentTime,
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${request["name"]} ${'acceptedSuccessfully'.tr()}'), backgroundColor: Colors.green)
        );

        // Update local state to reflect the change
        setState(() {
          request["status"] = 'enrolled';
          request["accepted"] = true;
          request["rejected"] = false;
          request["approvedBy"] = currentUser?.email ?? 'Admin';
          request["approvedDate"] = DateTime.now();
        });

      } else if (request["rejected"]) {
        // Rejected - Rejected & Suspended status
        await studentRef.update({
          'academicInfo.enrollStatus': 'rejected',
          'academicInfo.academicStatus': 'suspended',
          'academicInfo.enrollmentDate': currentTime,
          'academicInfo.approvedBy': currentUser?.email ?? 'Admin',
          'academicInfo.approvedDate': currentTime,
          'lastUpdated': currentTime,
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${request["name"]} ${'rejectedSuccessfully'.tr()}'), backgroundColor: Colors.red)
        );

        // Update local state to reflect the change
        setState(() {
          request["status"] = 'rejected';
          request["accepted"] = false;
          request["rejected"] = true;
          request["approvedBy"] = currentUser?.email ?? 'Admin';
          request["approvedDate"] = DateTime.now();
        });
      }

    } catch (e) {
      print("Error processing individual request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorProcessingRequest'.tr()), backgroundColor: Colors.red)
      );
    } finally {
      setState(() {
        request["processing"] = false;
      });
    }
  }

  // Delete request handler - Now we'll remove from pending list instead of deleting document
  Future<void> _deleteRequest(Map<String, dynamic> request) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('removeConfirmation'.tr()),
          content: Text('removeRequestConfirmation'.tr(args: [request["name"]])),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('remove'.tr()),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    setState(() {
      request["deleting"] = true;
    });

    try {
      // Since we're working with student documents, we'll just update the status to remove from pending
      await FirebaseFirestore.instance.collection('students').doc(request["studentId"]).update({
        'academicInfo.enrollStatus': 'Removed',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${request["name"]} ${'removedSuccessfully'.tr()}'), backgroundColor: Colors.green)
      );

      // Remove the request from the list
      setState(() {
        if (request["isNewStudent"]) {
          newStudentRequests.removeWhere((req) => req["id"] == request["id"]);
        } else {
          oldStudentRequests.removeWhere((req) => req["id"] == request["id"]);
        }
      });

    } catch (e) {
      print("Error removing request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errorRemovingRequest'.tr()), backgroundColor: Colors.red)
      );
    } finally {
      setState(() {
        request["deleting"] = false;
      });
    }
  }

  void _showStudentDetails(Map<String, dynamic> request) {
    final studentDetails = request["studentData"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('studentDetails'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('studentRollNo'.tr(), request["rollNo1"]),
              _buildDetailRow('studentType'.tr(), request["isNewStudent"] ? 'newStudent'.tr() : 'oldStudent'.tr()),
              _buildDetailRow('enrollmentStatus'.tr(), request["status"]),
              if (request["approvedBy"] != null) _buildDetailRow('approvedBy'.tr(), request["approvedBy"]),
              if (request["approvedDate"] != null) _buildDetailRow('approvedDate'.tr(), _formatDate(request["approvedDate"])),
              _buildDetailRow('bDate'.tr(), studentDetails['sdob'] ?? 'N/A'),
              _buildDetailRow('fatherName'.tr(), studentDetails['parents']?['father']?['fname_eng'] ?? 'N/A'),
              _buildDetailRow('motherName'.tr(), studentDetails['parents']?['mother']?['mname_eng'] ?? 'N/A'),
              _buildDetailRow('address'.tr(), studentDetails['saddress'] ?? 'N/A'),
              _buildDetailRow('religion'.tr(), studentDetails['sreligion'] ?? 'N/A'),
              _buildDetailRow('gender'.tr(), studentDetails['sgender'] ?? 'N/A'),
              const SizedBox(height: 16),
              Text('academicInformation'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              _buildDetailRow('courseYear'.tr(), request["courseYear"] ?? 'N/A'),
              _buildDetailRow('major'.tr(), request["major"] ?? 'N/A'),
              _buildDetailRow('academicYear'.tr(), studentDetails['academicInfo']?['academicYear'] ?? 'N/A'),
              _buildDetailRow('enrollStatus'.tr(), studentDetails['academicInfo']?['enrollStatus'] ?? 'N/A'),
              _buildDetailRow('academicStatus'.tr(), studentDetails['academicInfo']?['academicStatus'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> request) {
    // Since we're not using enrollment_requests, show basic payment info
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('paymentInformation'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('studentID'.tr(), request["rollNo1"]),
              _buildDetailRow('studentName'.tr(), request["name"]),
              _buildDetailRow('studentType'.tr(), request["isNewStudent"] ? 'newStudent'.tr() : 'oldStudent'.tr()),
              _buildDetailRow('enrollmentStatus'.tr(), request["status"]),
              _buildDetailRow('paymentStatus'.tr(), 'Pending - To be processed'),
              _buildDetailRow('note'.tr(), 'Payment will be processed after enrollment approval'),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return date.toString();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, bool isNewStudent) {
    final bool isPending = request["status"] == 'pending';
    final bool isEnrolled = request["status"] == 'enrolled';
    final bool isRejected = request["status"] == 'rejected';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Student Info Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request["name"]!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${request["rollNo1"]!} • ${isNewStudent ? 'newStudent'.tr() : 'oldStudent'.tr()}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "${'payment1'.tr()}: ${request["paymentStatus"]}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isEnrolled
                                  ? Colors.green[100]
                                  : isRejected
                                  ? Colors.red[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request["status"]!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isEnrolled
                                    ? Colors.green[800]
                                    : isRejected
                                    ? Colors.red[800]
                                    : Colors.orange[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (request["approvedBy"] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          "Approved by: ${request["approvedBy"]}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),

                // Accept/Reject Checkboxes with Confirm & Delete buttons below (only for pending requests)
                if (isPending)
                  Column(
                    children: [
                      // Accept/Reject Row
                      Row(
                        children: [
                          Text('accept'.tr(), style: const TextStyle(fontSize: 12)),
                          Checkbox(
                            value: request["accepted"],
                            onChanged: (request["processing"] || request["deleting"])
                                ? null
                                : (value) {
                              setState(() {
                                if (value == true) request["rejected"] = false;
                                request["accepted"] = value;
                              });
                            },
                            activeColor: Colors.green,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('reject'.tr(), style: const TextStyle(fontSize: 12)),
                          Checkbox(
                            value: request["rejected"],
                            onChanged: (request["processing"] || request["deleting"])
                                ? null
                                : (value) {
                              setState(() {
                                if (value == true) request["accepted"] = false;
                                request["rejected"] = value;
                              });
                            },
                            activeColor: Colors.red,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),

                      // Confirm & Delete buttons positioned exactly under checkboxes
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Confirm Button
                          ElevatedButton(
                            onPressed: (request["processing"] || request["deleting"])
                                ? null
                                : () => _confirmIndividualRequest(request),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (request["accepted"] || request["rejected"])
                                  ? Colors.blue
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: const Size(70, 30),
                            ),
                            child: request["processing"]
                                ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : Text(
                              'confirm'.tr(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                // Show status badge and remove button for processed requests
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEnrolled ? Icons.check_circle : Icons.cancel,
                        color: isEnrolled ? Colors.green : Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEnrolled ? 'enrolled'.tr() : 'rejected'.tr(),
                        style: TextStyle(
                          color: isEnrolled ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Remove Button for processed requests
                      ElevatedButton(
                        onPressed: (request["deleting"]) ? null : () => _deleteRequest(request),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(70, 30),
                        ),
                        child: request["deleting"]
                            ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(
                          'remove'.tr(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Student Details & Payment Details Buttons
            const SizedBox(height: 8),
            Row(
              children: [
                // Student Details Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showStudentDetails(request);
                    },
                    icon: const Icon(Icons.person_outline, size: 16),
                    label: Text(
                      'studentDetails'.tr(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[800],
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Payment Details Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showPaymentDetails(request);
                    },
                    icon: const Icon(Icons.payment_outlined, size: 16),
                    label: Text(
                      'paymentInfo'.tr(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[800],
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOldStudentRequestsView() {
    if (oldStudentRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'noOldStudentRequests'.tr(),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            )
          ],
        ),
      );
    }

    return ListView(
      children: oldStudentRequests.map((request) => _buildRequestCard(request, false)).toList(),
    );
  }

  Widget _buildNewStudentRequestsView() {
    if (newStudentRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'noNewStudentRequests'.tr(),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            )
          ],
        ),
      );
    }

    return ListView(
      children: newStudentRequests.map((request) => _buildRequestCard(request, true)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.people_outline),
              text: '${'oldStudent'.tr()} (${oldStudentRequests.length})',
            ),
            Tab(
              icon: const Icon(Icons.person_add_outlined),
              text: '${'newStudent'.tr()} (${newStudentRequests.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOldStudentRequestsView(),
          _buildNewStudentRequestsView(),
        ],
      ),
    );
  }
}