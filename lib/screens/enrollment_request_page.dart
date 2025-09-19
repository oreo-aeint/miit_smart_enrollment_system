import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class EnrollmentRequestPage extends StatefulWidget {
  const EnrollmentRequestPage({super.key});

  @override
  State<EnrollmentRequestPage> createState() => _EnrollmentRequestPageState();
}

class _EnrollmentRequestPageState extends State<EnrollmentRequestPage> with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;

  // Old student requests
  List<Map<String, dynamic>> oldStudentRequests = [
    {
      "name": "Aeint Chit Thu",
      "rollNo1": "2022-MIIT-CSE-011",
      "dob": "21.8.2005",
      "father": "U Chit San Maung",
      "mother": "Daw Than Than Win",
      "address": "Pyi, Myanmar",
      "accepted": false,
      "rejected": false,
      "isNewStudent": false,
      "email": "2022-miit-cse-011@miit.edu.mm",
      "paymentStatus": "paid", // Added missing field
      "paymentAmount": "100,000 MMK", // Added missing field
      "paymentDate": "15.10.2023", // Added missing field
    },
    {
      "name": "Phyo Myat Htoo Sint",
      "rollNo1": "2022-MIIT-CSE-023",
      "dob": "8.12.2004",
      "father": "U Win Swe Htoo",
      "mother": "Daw Than Than Nwe",
      "address": "Amarapura, Myanmar",
      "accepted": false,
      "rejected": false,
      "isNewStudent": true,
      "email": "2022-miit-cse-023@miit.edu.mm",
      "paymentStatus": "pending", // Added missing field
      "paymentAmount": "150,000 MMK", // Added missing field
      "paymentDate": "Not paid", // Added missing field
    },
    {
      "name": "Win Pa Pa Phyo",
      "rollNo1": "2022-MIIT-CSE-029",
      "dob": "5.1.2025",
      "father": "U Win Ko",
      "mother": "Daw Thida Aye",
      "address": "Mandalay",
      "accepted": false,
      "rejected": false,
      "isNewStudent": false,
      "email": "2022-miit-cse-029@miit.edu.mm",
      "paymentStatus": "paid", // Added missing field
      "paymentAmount": "100,000 MMK", // Added missing field
      "paymentDate": "20.10.2023", // Added missing field
    },
  ];

  // New student requests
  List<Map<String, dynamic>> newStudentRequests = [
    {
      "name": "Min Khant Maung",
      "rollNo1": "2025-MIIT-CSE-001",
      "dob": "12.5.2005",
      "father": "U Khant Maung",
      "mother": "Daw Hla Myint",
      "address": "Mandalay, Myanmar",
      "accepted": false,
      "rejected": false,
      "isNewStudent": true,
      "email": "2025-miit-cse-001@miit.edu.mm",
      "paymentStatus": "pending", // Added missing field
      "paymentAmount": "150,000 MMK", // Added missing field
      "paymentDate": "Not paid", // Added missing field
    },
    {
      "name": "Aye Sandar Myint",
      "rollNo1": "2025-MIIT-CSE-021",
      "dob": "15.8.2007",
      "father": "U Myint",
      "mother": "Daw Aye",
      "address": "Mandalay, Myanmar",
      "accepted": false,
      "rejected": false,
      "isNewStudent": true,
      "email": "2025-miit-cse-021@miit.edu.mm",
      "paymentStatus": "pending", // Added missing field
      "paymentAmount": "150,000 MMK", // Added missing field
      "paymentDate": "Not paid", // Added missing field
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Submit all selections
  void _submitSelections() {
    List<String> acceptedStudents = [];
    List<String> rejectedStudents = [];

    // Process old student requests
    for (var request in oldStudentRequests) {
      if (request["accepted"] == true) {
        acceptedStudents.add("${request["name"]} (${'oldStudent'.tr()})");
      } else if (request["rejected"] == true) {
        rejectedStudents.add("${request["name"]} (${'oldStudent'.tr()})");
      }
    }

    // Process new student requests
    for (var request in newStudentRequests) {
      if (request["accepted"] == true) {
        acceptedStudents.add("${request["name"]} (${'newStudent'.tr()})");
      } else if (request["rejected"] == true) {
        rejectedStudents.add("${request["name"]} (${'newStudent'.tr()})");
      }
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('confirmation'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (acceptedStudents.isNotEmpty) ...[
              Text('acceptedStudents'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ...acceptedStudents.map((name) => Text("• $name")),
              const SizedBox(height: 16),
            ],
            if (rejectedStudents.isNotEmpty) ...[
              Text('rejectedStudents'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ...rejectedStudents.map((name) => Text("• $name")),
            ],
            if (acceptedStudents.isEmpty && rejectedStudents.isEmpty)
              Text('noSelections'.tr()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              // Remove processed requests
              setState(() {
                oldStudentRequests.removeWhere((request) =>
                request["accepted"] == true || request["rejected"] == true);
                newStudentRequests.removeWhere((request) =>
                request["accepted"] == true || request["rejected"] == true);
              });
              Navigator.pop(context);

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'processedRequests'.tr(args: ['${acceptedStudents.length + rejectedStudents.length}']),
                  ),
                ),
              );
            },
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }

  // Show email dialog for sending outlook email
  void _showEmailDialog(Map<String, dynamic> request, bool isAccepted) {
    final TextEditingController messageController = TextEditingController();
    final String subject = isAccepted
        ? 'acceptText'.tr()
        : 'rejectText'.tr();

    final String defaultMessage = isAccepted
        ? 'acceptanceEmailMessage'.tr(args: [request["name"] ?? 'Student'])
        : 'rejectionEmailMessage'.tr(args: [request["name"] ?? 'Student']);

    messageController.text = defaultMessage;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAccepted ? 'sendAcceptanceEmail'.tr() : 'sendRejectionEmail'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('to'.tr() + ': ${request["email"] ?? "No email provided"}'),
            const SizedBox(height: 8),
            Text('subject'.tr() + ': $subject'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'message'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulate sending email
              _sendEmail(request["email"] ?? "", subject, messageController.text);
              Navigator.pop(context);

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'emailSentTo'.tr(args: [request["name"] ?? "Student"]),
                  ),
                ),
              );
            },
            child: Text('sendEmail'.tr()),
          ),
        ],
      ),
    );
  }

  // Simulate sending email (in a real app, you would integrate with an email service)
  void _sendEmail(String email, String subject, String message) {
    print('Sending email to: $email');
    print('Subject: $subject');
    print('Message: $message');
    // In a real app, you would integrate with an email service like mailto, SendGrid, etc.
  }

  // Show student details in an alert dialog
  void _showStudentDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('studentDetailsWithName'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('rollNo1'.tr(), request["rollNo1"] ?? "N/A"),
              _buildDetailRow('type'.tr(), (request["isNewStudent"] ?? false) ? 'newStudent'.tr() : 'oldStudent'.tr()),
              _buildDetailRow('bDate'.tr(), request["dob"] ?? "N/A"),
              _buildDetailRow('fatherName'.tr(), request["father"] ?? "N/A"),
              _buildDetailRow('motherName'.tr(), request["mother"] ?? "N/A"),
              _buildDetailRow('address'.tr(), request["address"] ?? "N/A"),
              _buildDetailRow('email'.tr(), request["email"] ?? "N/A"),
            ],
          ),
        ),
      ),
    );
  }

  // Show payment details dialog
  void _showPaymentDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('paymentDetailsWithName'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('rollNo1'.tr(), request["rollNo1"] ?? "N/A"),
              _buildDetailRow('name'.tr(), request["name"] ?? "N/A"),
              _buildDetailRow('type'.tr(), (request["isNewStudent"] ?? false) ? 'newStudent'.tr() : 'oldStudent'.tr()),
              _buildDetailRow('paymentStatus'.tr(), request["paymentStatus"] ?? "N/A"),
              _buildDetailRow('amount'.tr(), request["paymentAmount"] ?? "N/A"),
              _buildDetailRow('paymentDate'.tr(), request["paymentDate"] ?? "N/A"),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  // Build a request card
  Widget _buildRequestCard(Map<String, dynamic> request, bool isNewStudent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNewStudent ? Colors.orange[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isNewStudent ? Colors.orange[100]! : Colors.blue[100]!),
      ),
      child: Column(
        children: [
          // Student info and action buttons
          Row(
            children: [
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request["name"] ?? "Unknown",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${request["rollNo1"] ?? "N/A"} • ${isNewStudent ? 'newStudent'.tr() : 'oldStudent'.tr()}",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${'payment1'.tr()}: ${request["paymentStatus"] ?? "N/A"}",
                      style: TextStyle(
                        fontSize: 14,
                        color: (request["paymentStatus"] ?? "") == "paid".tr()
                            ? Colors.green
                            : (request["paymentStatus"] ?? "") == "pending1".tr()
                            ? Colors.orange
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Accept and Reject Checkboxes
              Column(
                children: [
                  // Accept Checkbox
                  Row(
                    children: [
                      Text('accept'.tr(), style: const TextStyle(fontSize: 12)),
                      Checkbox(
                        value: request["accepted"] ?? false,
                        onChanged: (value) {
                          setState(() {
                            // If accepting, make sure rejected is false
                            if (value == true) {
                              request["rejected"] = false;
                            }
                            request["accepted"] = value;
                          });
                        },
                        activeColor: Colors.green,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),

                  // Reject Checkbox
                  Row(
                    children: [
                      Text('reject'.tr(), style: const TextStyle(fontSize: 12)),
                      Checkbox(
                        value: request["rejected"] ?? false,
                        onChanged: (value) {
                          setState(() {
                            // If rejecting, make sure accepted is false
                            if (value == true) {
                              request["accepted"] = false;
                            }
                            request["rejected"] = value;
                          });
                        },
                        activeColor: Colors.red,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),

                  // Confirm Button
                  ElevatedButton(
                    onPressed: () {
                      if (request["accepted"] == true) {
                        _showEmailDialog(request, true);
                      } else if (request["rejected"] == true) {
                        _showEmailDialog(request, false);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('pleaseSelectAcceptOrReject'.tr()),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 30),
                    ),
                    child: Text('confirm'.tr(), style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // View Student Details Button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showStudentDetails(request);
                    },
                    icon: const Icon(Icons.person_outline, size: 16),
                    label: Text('studentDetails'.tr(), style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[800],
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ),

              // View Payment Details Button
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showPaymentDetails(request);
                    },
                    icon: const Icon(Icons.payment_outlined, size: 16),
                    label: Text('paymentDetails'.tr(), style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[800],
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build old student requests view
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
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        ...oldStudentRequests.map((request) => _buildRequestCard(request, false)).toList(),
      ],
    );
  }

  // Build new student requests view
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
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        ...newStudentRequests.map((request) => _buildRequestCard(request, true)).toList(),
      ],
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
              text: 'oldStudent'.tr(),
            ),
            Tab(
              icon: const Icon(Icons.person_add_outlined),
              text: 'newStudent'.tr(),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Old Students Tab
          _buildOldStudentRequestsView(),

          // New Students Tab
          _buildNewStudentRequestsView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitSelections,
        child: const Icon(Icons.check),
      ),
    );
  }
}