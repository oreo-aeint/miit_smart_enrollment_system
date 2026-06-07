import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miit_project/screens/student_transcript.dart';

class EnrollmentRequestPage extends StatefulWidget {
  const EnrollmentRequestPage({super.key});

  @override
  State<EnrollmentRequestPage> createState() => _EnrollmentRequestPageState();
}

class _EnrollmentRequestPageState extends State<EnrollmentRequestPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> oldStudentRequests = [];
  List<Map<String, dynamic>> newStudentRequests = [];
  List<Map<String, dynamic>> pendingTranscriptRequests = [];
  List<Map<String, dynamic>> acceptedTranscriptRequests = [];
  List<Map<String, dynamic>> rejectedTranscriptRequests = [];
  StreamSubscription<QuerySnapshot>? _enrollmentSubscription;
  StreamSubscription<QuerySnapshot>? _transcriptSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupEnrollmentListener();
    _setupTranscriptListener();
  }

  @override
  void dispose() {
    _enrollmentSubscription?.cancel();
    _transcriptSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupEnrollmentListener() {
    _enrollmentSubscription = FirebaseFirestore.instance
        .collection('enrollment_requests')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .listen((snapshot) {
      print('Found ${snapshot.docs.length} pending enrollment requests');
      _processEnrollmentRequests(snapshot.docs);
    });
  }

  void _setupTranscriptListener() {
    _transcriptSubscription = FirebaseFirestore.instance
        .collection('transcript_requests')
        .orderBy('requestDate', descending: true)
        .snapshots()
        .listen((snapshot) {
      print('Found ${snapshot.docs.length} total transcript requests');
      _processAllTranscriptRequests(snapshot.docs);
    });
  }

  void _processEnrollmentRequests(List<QueryDocumentSnapshot> docs) {
    final oldRequests = <Map<String, dynamic>>[];
    final newRequests = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final studentType = data['studentType'] ?? 'new';

      final request = {
        "id": doc.id,
        "studentId": data['studentId'] ?? 'N/A',
        "name": data['studentName'] ?? 'Unknown',
        "rollNo1": data['studentId'] ?? 'N/A',
        "courseYear": data['courseYear'] ?? 'N/A',
        "major": data['major'] ?? 'N/A',
        "paymentStatus": data['paymentStatus'] ?? 'pending',
        "paymentAmount": data['paymentAmount'] ?? 0,
        "paymentReference": data['paymentReference'] ?? 'N/A',
        "paymentDate": data['paymentDate'],
        "isNewStudent": studentType == 'new',
        "status": data['status'] ?? 'Pending',
        "approvedBy": data['approvedBy'],
        "approvedDate": data['approvedDate'],
        "requestDate": data['requestDate'],
        "accepted": false,
        "rejected": false,
        "processing": false,
        "deleting": false,
        "enrollmentData": data,
        "type": "enrollment",
      };

      if (studentType == 'old') {
        oldRequests.add(request);
      } else {
        newRequests.add(request);
      }
    }

    setState(() {
      oldStudentRequests = oldRequests;
      newStudentRequests = newRequests;
    });
  }

  void _processAllTranscriptRequests(List<QueryDocumentSnapshot> docs) {
    final pendingRequests = <Map<String, dynamic>>[];
    final acceptedRequests = <Map<String, dynamic>>[];
    final rejectedRequests = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'Pending';

      // Get the student name - prioritize studentNameEnglish from UserTranscript form
      // This will display "Khaing Thazin Htun" from the English name field
      String studentName = 'Unknown';

      if (data['studentNameEnglish'] != null && data['studentNameEnglish'].toString().isNotEmpty) {
        studentName = data['studentNameEnglish'];
      } else if (data['studentName'] != null && data['studentName'].toString().isNotEmpty) {
        studentName = data['studentName'];
      } else if (data['fullName'] != null && data['fullName'].toString().isNotEmpty) {
        studentName = data['fullName'];
      }

      final request = {
        "id": doc.id,
        "studentId": data['studentId'] ?? 'N/A',
        "name": studentName,
        "rollNo1": data['studentId'] ?? 'N/A',
        "requestType": data['documentType'] ?? 'Transcript',
        "purpose": data['purpose'] ?? 'N/A',
        "deliveryMethod": data['deliveryMethod'] ?? 'Pickup',
        "status": status,
        "approvedBy": data['approvedBy'],
        "approvedDate": data['approvedDate'],
        "requestDate": data['requestDate'] ?? data['createdAt'],
        "accepted": status == 'Approved',
        "rejected": status == 'Rejected',
        "processing": false,
        "deleting": false,
        "requestData": data,
        "type": "transcript",
        "documentType": data['documentType'] ?? 'အမှတ်စာရင်း',
        "academicYear": data['academicYear'] ?? 'N/A',
        "examYear": data['examYear'] ?? 'N/A',
        "classSubject": data['classSubject'] ?? 'N/A',
        "nrc": data['nrc'] ?? 'N/A',
        "fatherName": data['fatherName'] ?? 'N/A',
        "address": data['address'] ?? 'N/A',
        "studentYears": data['studentYears'] ?? 'N/A',
        "studentNameEnglish": data['studentNameEnglish'] ?? studentName,
        "signature": data['signature'] ?? 'N/A',
        "gender": data['gender'] ?? 'N/A',
        "examResult": data['examResult'] ?? 'N/A',
        "paymentStatus": data['paymentStatus'] ?? 'pending',
        "paymentAmount": data['paymentAmount'] ?? 0,
        "bDate": data['bDate'] ?? data['dateOfBirth'] ?? 'N/A',
      };

      if (status == 'Pending') {
        pendingRequests.add(request);
      } else if (status == 'Approved') {
        acceptedRequests.add(request);
      } else if (status == 'Rejected') {
        rejectedRequests.add(request);
      }
    }

    setState(() {
      pendingTranscriptRequests = pendingRequests;
      acceptedTranscriptRequests = acceptedRequests;
      rejectedTranscriptRequests = rejectedRequests;
    });
  }

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

      if (request["type"] == "enrollment") {
        if (request["accepted"]) {
          await FirebaseFirestore.instance
              .collection('enrollment_requests')
              .doc(request["id"])
              .update({
            'status': 'Approved',
            'approvedBy': currentUser?.email ?? 'Admin',
            'approvedDate': currentTime,
            'lastUpdated': currentTime,
          });

          await FirebaseFirestore.instance
              .collection('students')
              .doc(request["studentId"])
              .update({
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

          setState(() {
            if (request["isNewStudent"]) {
              newStudentRequests.removeWhere((req) => req["id"] == request["id"]);
            } else {
              oldStudentRequests.removeWhere((req) => req["id"] == request["id"]);
            }
          });

        } else if (request["rejected"]) {
          await FirebaseFirestore.instance
              .collection('enrollment_requests')
              .doc(request["id"])
              .update({
            'status': 'Rejected',
            'approvedBy': currentUser?.email ?? 'Admin',
            'approvedDate': currentTime,
            'lastUpdated': currentTime,
          });

          await FirebaseFirestore.instance
              .collection('students')
              .doc(request["studentId"])
              .update({
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

          setState(() {
            if (request["isNewStudent"]) {
              newStudentRequests.removeWhere((req) => req["id"] == request["id"]);
            } else {
              oldStudentRequests.removeWhere((req) => req["id"] == request["id"]);
            }
          });
        }
      } else if (request["type"] == "transcript") {
        final newStatus = request["accepted"] ? "Approved" : "Rejected";

        await FirebaseFirestore.instance
            .collection('transcript_requests')
            .doc(request["id"])
            .update({
          'status': newStatus,
          'approvedBy': currentUser?.email ?? 'Admin',
          'approvedDate': currentTime,
          'lastUpdated': currentTime,
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${request["name"]} ${newStatus == "Approved" ? 'acceptedSuccessfully'.tr() : 'rejectedSuccessfully'.tr()}'),
              backgroundColor: newStatus == "Approved" ? Colors.green : Colors.red,
            )
        );

        setState(() {
          request["status"] = newStatus;
          request["accepted"] = newStatus == "Approved";
          request["rejected"] = newStatus == "Rejected";
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
      if (request["type"] == "enrollment") {
        await FirebaseFirestore.instance
            .collection('enrollment_requests')
            .doc(request["id"])
            .delete();

        await FirebaseFirestore.instance
            .collection('students')
            .doc(request["studentId"])
            .update({
          'academicInfo.enrollStatus': 'Removed',
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        setState(() {
          if (request["isNewStudent"]) {
            newStudentRequests.removeWhere((req) => req["id"] == request["id"]);
          } else {
            oldStudentRequests.removeWhere((req) => req["id"] == request["id"]);
          }
        });

      } else if (request["type"] == "transcript") {
        await FirebaseFirestore.instance
            .collection('transcript_requests')
            .doc(request["id"])
            .delete();

        setState(() {
          if (request["status"] == "Approved") {
            acceptedTranscriptRequests.removeWhere((req) => req["id"] == request["id"]);
          } else if (request["status"] == "Rejected") {
            rejectedTranscriptRequests.removeWhere((req) => req["id"] == request["id"]);
          } else {
            pendingTranscriptRequests.removeWhere((req) => req["id"] == request["id"]);
          }
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${request["name"]} ${'removedSuccessfully'.tr()}'), backgroundColor: Colors.green)
      );

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

  void _showStudentDetails(Map<String, dynamic> request) async {
    try {
      if (request["type"] == "transcript") {
        final requestData = request["requestData"];
        final bDate = request["bDate"] ?? 'N/A';

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('transcriptDetails'.tr()),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('studentRollNo'.tr(), request["rollNo1"]),
                  _buildDetailRow('bDate'.tr(), request["bDate"]),
                  _buildDetailRow('requestStatus'.tr(), request["status"]),
                  _buildDetailRow('documentType'.tr(), requestData['documentType'] ?? 'အမှတ်စာရင်း'),
                  _buildDetailRow('eName'.tr(), requestData['studentNameEnglish'] ?? request["name"]),
                  _buildDetailRow('academicYear'.tr(), requestData['academicYear'] ?? 'N/A'),
                  _buildDetailRow('major'.tr(), requestData['classSubject'] ?? 'N/A'),
                  _buildDetailRow('nrc'.tr(), requestData['nrc'] ?? 'N/A'),
                  _buildDetailRow('fatherName'.tr(), requestData['fatherName'] ?? 'N/A'),
                  _buildDetailRow('address'.tr(), requestData['address'] ?? 'N/A'),
                  _buildDetailRow('email'.tr(), requestData['email'] ?? 'N/A'),
                  _buildDetailRow('studentYears'.tr(), requestData['studentYears'] ?? 'N/A'),
                  _buildDetailRow('examResult'.tr(), requestData['examResult'] ?? 'N/A'),
                  _buildDetailRow('purpose'.tr(), requestData['purpose'] ?? 'N/A'),
                ],
              ),
            ),

          ),
        );
      } else {
        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(request["studentId"])
            .get();

        if (!studentDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('studentNotFound'.tr()), backgroundColor: Colors.red),
          );
          return;
        }

        final studentData = studentDoc.data() as Map<String, dynamic>;
        final enrollmentData = request["enrollmentData"];
        final bDate = studentData['sdob'] ?? 'N/A';

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
                  _buildDetailRow('bDate'.tr(), bDate),
                  _buildDetailRow('fatherName'.tr(), studentData['parents']?['father']?['fname_eng'] ?? 'N/A'),
                  _buildDetailRow('motherName'.tr(), studentData['parents']?['mother']?['mname_eng'] ?? 'N/A'),
                  _buildDetailRow('address'.tr(), studentData['saddress'] ?? 'N/A'),
                  _buildDetailRow('religion'.tr(), studentData['sreligion'] ?? 'N/A'),
                  _buildDetailRow('gender'.tr(), studentData['sgender'] ?? 'N/A'),
                  const SizedBox(height: 16),
                  Text('requestInformation'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  _buildDetailRow('courseYear'.tr(), enrollmentData['courseYear'] ?? 'N/A'),
                  _buildDetailRow('programType'.tr(), enrollmentData['programType'] ?? 'N/A'),
                  _buildDetailRow('major'.tr(), enrollmentData['major'] ?? 'N/A'),
                  _buildDetailRow('academicYear'.tr(), enrollmentData['academicYear'] ?? 'N/A'),
                  _buildDetailRow('paymentStatus'.tr(), enrollmentData['paymentStatus'] ?? 'N/A'),
                ],
              ),
            ),

          ),
        );
      }
    } catch (e) {
      print("Error fetching student details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errorLoadingDetails'.tr()), backgroundColor: Colors.red),
      );
    }
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

  Widget _buildRequestCard(Map<String, dynamic> request, bool isAcceptedTranscript) {
    final bool isPending = request["status"] == 'Pending';
    final bool isAccepted = request["status"] == 'Approved';
    final bool isRejected = request["status"] == 'Rejected';
    final bool isTranscript = request["type"] == "transcript";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
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
                        request["rollNo1"]!,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPending ? Colors.orange[100] :
                              isAccepted ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request["status"]!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isPending ? Colors.orange[800] :
                                isAccepted ? Colors.green[800] : Colors.red[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                        ],
                      ),
                      if (isTranscript) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Purpose: ${request["purpose"] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 12, color: Colors.purple),
                        ),

                      ],


                    ],
                  ),
                ),

                if (isPending)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Accept checkbox (above)
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          ),
                        ],
                      ),
                      // Reject checkbox (below)
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // Space between checkboxes and buttons
                      // Buttons row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          const SizedBox(width: 8),
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
                              'delete'.tr(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],

                  )
                else if (isTranscript && isAccepted)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request["status"]!,
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (request["approvedDate"] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(request["approvedDate"]),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 8),
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
                          'delete'.tr(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  )
                else if (isTranscript && isRejected)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cancel,
                          color: Colors.red,
                          size: 40,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request["status"]!,
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                            'delete'.tr(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    )
                  else if (!isPending && !isTranscript)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            request["status"] == 'Approved' ? Icons.check_circle : Icons.cancel,
                            color: request["status"] == 'Approved' ? Colors.green : Colors.red,
                            size: 40,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request["status"]!,
                            style: TextStyle(
                              color: request["status"] == 'Approved' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
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
                if (isTranscript && isAccepted)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _navigateToSendTranscript(request);
                      },
                      icon: const Icon(Icons.send_outlined, size: 16),
                      label: Text(
                        'sendTranscript'.tr(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[100],
                        foregroundColor: Colors.purple[800],
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                    ),
                  )
                else
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

  void _showPaymentDetails(Map<String, dynamic> request) {
    final requestData = request["type"] == "enrollment"
        ? request["enrollmentData"]
        : request["requestData"];

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
              _buildDetailRow('requestType'.tr(), request["type"] == "enrollment"
                  ? 'enrollment'.tr()
                  : 'transcript'.tr()),
              _buildDetailRow('status'.tr(), request["status"]),
              _buildDetailRow('paymentAmount'.tr(), 'Ks ${requestData['paymentAmount']?.toString() ?? '0'}'),
              _buildDetailRow('paymentReference'.tr(), requestData['paymentReference'] ?? 'N/A'),
              _buildDetailRow('paymentDate'.tr(), requestData['paymentDate'] ?? 'N/A'),
              _buildDetailRow('paymentTime'.tr(), requestData['paymentTime'] ?? 'N/A'),
              _buildDetailRow('paymentStatus'.tr(), requestData['paymentStatus'] ?? 'N/A'),
            ],
          ),
        ),

      ),
    );
  }

  void _navigateToSendTranscript(Map<String, dynamic> request) {
    String studentName = request["name"];

    if (studentName == 'Unknown' || studentName == 'N/A') {
      final requestData = request["requestData"];
      studentName = requestData['studentNameEnglish'] ??
          requestData['studentName'] ??
          requestData['fullName'] ??
          'Unknown';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentTranscript(
          transcriptRequestId: request["id"],
          studentId: request["studentId"],
          studentName: studentName,
          rollNumber: request["rollNo1"],
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

    return ListView.builder(
      itemCount: oldStudentRequests.length,
      itemBuilder: (context, index) => _buildRequestCard(oldStudentRequests[index], false),
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

    return ListView.builder(
      itemCount: newStudentRequests.length,
      itemBuilder: (context, index) => _buildRequestCard(newStudentRequests[index], false),
    );
  }

  Widget _buildTranscriptRequestsView() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(
                  text: '${'pending'.tr()} (${pendingTranscriptRequests.length})',
                ),
                Tab(
                  text: '${'accepted'.tr()} (${acceptedTranscriptRequests.length})',
                ),
                Tab(
                  text: '${'rejected'.tr()} (${rejectedTranscriptRequests.length})',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                pendingTranscriptRequests.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'noPendingTranscripts'.tr(),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      )
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: pendingTranscriptRequests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(pendingTranscriptRequests[index], false);
                  },
                ),
                acceptedTranscriptRequests.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'noAcceptedTranscripts'.tr(),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      )
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: acceptedTranscriptRequests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(acceptedTranscriptRequests[index], true);
                  },
                ),
                rejectedTranscriptRequests.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cancel_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'noRejectedTranscripts'.tr(),
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      )
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: rejectedTranscriptRequests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(rejectedTranscriptRequests[index], false);
                  },
                ),
              ],
            ),
          ),
        ],
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
            Tab(
              icon: const Icon(Icons.people_outline),
              text: '${'oldStudent'.tr()} (${oldStudentRequests.length})',
            ),
            Tab(
              icon: const Icon(Icons.person_add_outlined),
              text: '${'newStudent'.tr()} (${newStudentRequests.length})',
            ),
            Tab(
              icon: const Icon(Icons.description),
              text: '${'transcript'.tr()} (${pendingTranscriptRequests.length + acceptedTranscriptRequests.length + rejectedTranscriptRequests.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOldStudentRequestsView(),
          _buildNewStudentRequestsView(),
          _buildTranscriptRequestsView(),
        ],
      ),
    );
  }
}