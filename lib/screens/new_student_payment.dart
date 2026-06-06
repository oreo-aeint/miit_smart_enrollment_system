import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'my_drawer.dart';
import 'package:miit_project/components/text.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/screens/pdf_voucher_screen.dart';
import 'package:miit_project/screens/home_screen.dart';

class NewStudentPaymentQR extends StatefulWidget {
  final String rollNo;
  final String studentName;
  final String? courseYear;

  const NewStudentPaymentQR({
    super.key,
    required this.rollNo,
    required this.studentName,
    this.courseYear,
    required Map<String, dynamic> studentData,  // ✅ Fixed: 'required' keyword properly placed
  });

  @override
  State<NewStudentPaymentQR> createState() => _NewStudentPaymentQRState();
}

class _NewStudentPaymentQRState extends State<NewStudentPaymentQR> {
  final _formKey = GlobalKey<FormState>();

  final rollNoController = TextEditingController();
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final referenceController = TextEditingController();
  final dateController = TextEditingController();

  String _date = "";
  String? _qrData;
  bool _isSubmitting = false;

  // Academic year and payment amounts from admin settings
  String _academicYear = "Invalid";
  String _bePayment = "Invalid";
  String _mePayment = "Invalid";
  bool _isLoadingSettings = true;

  // Course year logic
  String? _selectedCourseYear;
  bool _isBECourse = false;
  bool _isMECourse = false;
  bool _isAmountAutoFilled = false;

  @override
  void initState() {
    super.initState();
    referenceController.text = _generateReference();
    final today = DateTime.now();
    _date =
    "${today.year.toString().padLeft(4, '0')}-"
        "${today.month.toString().padLeft(2, '0')}-"
        "${today.day.toString().padLeft(2, '0')}";

    // Auto-fill student data from passed parameters
    dateController.text = _date;
    rollNoController.text = widget.rollNo;
    nameController.text = widget.studentName;

    // Store the course year
    _selectedCourseYear = widget.courseYear;
    print('Received course year: $_selectedCourseYear');

    // Load academic settings
    _loadAcademicSettings();
  }

  // Method to analyze course year and determine B.E or M.E
  // Method to analyze course year and determine B.E or M.E
  void _analyzeCourseYear() {
    if (_selectedCourseYear == null) {
      print('No course year provided');
      return;
    }

    final courseYear = _selectedCourseYear!.toLowerCase().trim();
    print('Analyzing course year: "$courseYear"');

    // Reset flags
    _isBECourse = false;
    _isMECourse = false;

    // First check for M.E patterns (more specific)
    final mePatterns = [
      'master first year', 'master first', 'master1',
      'မဟာသိပ္ပံပထမနှစ်', 'မဟာပထမနှစ်', // Burmese for master first year
      'postgraduate first year', 'graduate first year',
      'm.e', 'm. e', 'me',
      'master\'s', 'masters'
    ];

    // Check for B.E patterns
    final bePatterns = [
      'first year', 'first',
      'ပထမနှစ်', // Burmese for first year
      '1', // Year number
      'be', 'bachelor', 'b.e', 'b. e'
    ];

    // Check if it's M.E (Master's) first
    bool isME = false;
    for (var pattern in mePatterns) {
      if (courseYear.contains(pattern)) {
        isME = true;
        print('Matched M.E pattern: $pattern');
        break;
      }
    }

    // Check if it's B.E (Bachelor's) - only if not M.E
    bool isBE = false;
    if (!isME) {
      for (var pattern in bePatterns) {
        if (courseYear.contains(pattern)) {
          isBE = true;
          print('Matched B.E pattern: $pattern');
          break;
        }
      }
    }

    setState(() {
      _isMECourse = isME;
      _isBECourse = isBE;
    });

    print('Course Year Analysis Result:');
    print('  Selected Course: $_selectedCourseYear');
    print('  Is B.E Course: $_isBECourse');
    print('  Is M.E Course: $_isMECourse');

    // Auto-fill amount based on course year
    _autoFillAmount();
  }

// Auto-fill amount based on course year
  void _autoFillAmount() {
    if (_isMECourse && _mePayment != 'Invalid') {
      amountController.text = _mePayment;
      _isAmountAutoFilled = true;
      print('Auto-filled M.E amount: $_mePayment');
    } else if (_isBECourse && _bePayment != 'Invalid') {
      amountController.text = _bePayment;
      _isAmountAutoFilled = true;
      print('Auto-filled B.E amount: $_bePayment');
    } else {
      _isAmountAutoFilled = false;
      print('No auto-fill - course year not recognized');
    }
  }

  // Load academic settings from Firestore
  // Load academic settings from Firestore
  Future<void> _loadAcademicSettings() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('admin_academic_year')
          .doc('admin')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final startYear = (data['astart_year'] as int?)?.toString() ?? '';
        final endYear = (data['aend_year'] as int?)?.toString() ?? '';
        final beAmount = (data['set_amount'] as num?)?.toString() ?? '0';
        final meAmount = (data['set_amount_master'] as num?)?.toString() ?? '0';

        // Validate and set values
        setState(() {
          _academicYear = (startYear.isNotEmpty && endYear.isNotEmpty)
              ? '$startYear - $endYear'
              : 'Invalid';
          _bePayment =
          (beAmount != '0' && beAmount.isNotEmpty) ? beAmount : 'Invalid';
          _mePayment =
          (meAmount != '0' && meAmount.isNotEmpty) ? meAmount : 'Invalid';
        });

        print('Loaded payment amounts:');
        print('  B.E Payment: $_bePayment');
        print('  M.E Payment: $_mePayment');

        // Analyze course year after loading settings
        _analyzeCourseYear();
        setState(() {
          _isLoadingSettings = false;
        });
      } else {
        print('Admin settings document not found');
        setState(() {
          _academicYear = 'Invalid';
          _bePayment = 'Invalid';
          _mePayment = 'Invalid';
          _isLoadingSettings = false;
        });
        amountController.text = "80000"; // Fallback default
      }
    } catch (e) {
      print('Error loading academic settings: $e');
      setState(() {
        _academicYear = 'Invalid';
        _bePayment = 'Invalid';
        _mePayment = 'Invalid';
        _isLoadingSettings = false;
      });
      amountController.text = "85000"; // Fallback default
    }
  }

  String _generateReference() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final part =
    List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
    final today = DateTime.now();
    final ymd =
        "${today.year}${today.month.toString().padLeft(2, '0')}${today.day
        .toString().padLeft(2, '0')}";
    return "MIIT-$ymd-$part";
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text("warning".tr()),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                    "ok".tr(), style: const TextStyle(color: Colors.indigo)),
              ),
            ],
          ),
    );
  }

  void _generateQR() {
    if (!_formKey.currentState!.validate()) {
      _showAlert("fillAllFields".tr());
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null) {
      _showAlert("invalidAmount".tr());
      return;
    }

    final payload = [
      "MIITPAY",
      "ref=${referenceController.text.trim()}",
      "roll=${rollNoController.text.trim()}",
      "name=${nameController.text.trim()}",
      "amt=${amount.toStringAsFixed(2)}",
      "date=$_date",
    ].join("|");

    setState(() {
      _qrData = payload;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("qrGenerated".tr())),
    );
  }

  // Custom validator for amount field
  String? _validateAmount(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return "required".tr();
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return "invalidAmount".tr();
    }

    return null;
  }

  OutlineInputBorder get inputBorder =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black26),
      );

  Widget _buildBoxField({required Widget child, Color? backgroundColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
      ),
      child: child,
    );
  }

  // Build payment notes UI
  // Build payment notes UI
  Widget _buildPaymentNotes() {
    if (_isLoadingSettings) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              const Icon(Icons.payment, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Payment Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Academic Year
          Text(
            'Academic Year: $_academicYear',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          // Show selected course year
          if (_selectedCourseYear != null &&
              _selectedCourseYear!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Course Year: $_selectedCourseYear',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],

          const SizedBox(height: 8),
          // Divider
          const Divider(color: Colors.grey),
          const SizedBox(height: 8),

          // Payment instructions
          Text(
            'paymentInstruction'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),

          // B.E Student payment with indicator if selected
          // B.E Student payment with indicator if selected
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${"be".tr()} : ${"ks".tr()} "
                      "${_bePayment != 'Invalid' ? _bePayment : "Not Set"}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _isBECourse ? FontWeight.bold : FontWeight.w500,
                    color: _isBECourse ? Colors.green : Colors.black,
                  ),
                ),

              ),
              if (_isBECourse)
                const Icon(Icons.check, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 4),

          // M.E Student payment with indicator if selected
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${"me".tr()} : ${"ks".tr()} "
                      "${_mePayment != 'Invalid' ? _mePayment : "Not Set"}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _isMECourse ? FontWeight.bold : FontWeight.w500,
                    color: _isMECourse ? Colors.green : Colors.black,
                  ),
                ),

              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  void dispose() {
    rollNoController.dispose();
    nameController.dispose();
    amountController.dispose();
    referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const MyDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
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
              builder: (context) =>
                  GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child:
                      Image.asset('assets/img_2.png', width: 50, height: 50),
                    ),
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tr("paymentForm"), style: AppTextStyles.heading),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: DropdownButton<Locale>(
                underline: const SizedBox(),
                icon: const Icon(Icons.language, color: Colors.black),
                value: context.locale,
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) context.setLocale(newLocale);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Payment Notes
            _buildPaymentNotes(),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildBoxField(
                    child: TextFormField(
                      controller: referenceController,
                      decoration: InputDecoration(
                        labelText: "reference".tr(),
                        border: inputBorder,
                      ),
                      validator: (v) =>
                      (v == null || v
                          .trim()
                          .isEmpty)
                          ? "required".tr()
                          : null,
                    ),
                  ),
                  _buildBoxField(
                    child: TextFormField(
                      controller: rollNoController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "rollNo".tr(),
                        border: inputBorder,
                      ),
                      validator: (v) =>
                      (v == null || v
                          .trim()
                          .isEmpty)
                          ? "required".tr()
                          : null,
                    ),
                  ),
                  _buildBoxField(
                    child: TextFormField(
                      controller: nameController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "studentName".tr(),
                        border: inputBorder,
                      ),
                      validator: (v) =>
                      (v == null || v
                          .trim()
                          .isEmpty)
                          ? "required".tr()
                          : null,
                    ),
                  ),
                  _buildBoxField(
                    child: TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: "amount".tr(),
                        border: inputBorder,
                        suffixText: "MMK",
                        prefixIcon: _isAmountAutoFilled
                            ? const Icon(Icons.lock)
                            : const Icon(Icons.payment),
                      ),
                      keyboardType: _isAmountAutoFilled
                          ? TextInputType.none
                          : const TextInputType.numberWithOptions(
                          decimal: true),
                      readOnly: _isAmountAutoFilled,
                      validator: _validateAmount,
                    ),
                  ),
                  _buildBoxField(
                    child: TextFormField(
                      initialValue: _date,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "paymentDate".tr(),
                        border: inputBorder,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _generateQR,
              icon: const Icon(Icons.qr_code),
              label: Text("generateQR".tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_qrData != null) ...[
              QrImageView(
                data: _qrData!,
                version: QrVersions.auto,
                size: 200,
              ),
              const SizedBox(height: 10),
              Text(
                "kPayNote1".tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("paymentHistory".tr(),
                        style: AppTextStyles.heading),
                    const Divider(),
                    Text("QR No  : ${referenceController.text}"),
                    Text("Roll No: ${rollNoController.text}"),
                    Text("Name   : ${nameController.text}"),
                    Text("Amount : ${amountController
                        .text} MMK ${_isAmountAutoFilled
                        ? '(Auto-filled)'
                        : ''}"),
                    if (_selectedCourseYear != null &&
                        _selectedCourseYear!.isNotEmpty)
                      Text("Course : $_selectedCourseYear"),
                    if (_isBECourse || _isMECourse)
                      Text("Program: ${_isBECourse
                          ? 'B.E (Bachelor)'
                          : 'M.E (Master)'}"),
                    Text("Date   : $_date"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ActionButton(
                text: tr("submit"),
                icon: Icons.fact_check_rounded,
                onPressed: _submitForm,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_isSubmitting) return;

    // Validate amount again before submission
    final amountValidation = _validateAmount(amountController.text);
    if (amountValidation != null) {
      _showAlert(amountValidation);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();

      final String rollNo = rollNoController.text.trim();
      final String qrCode = referenceController.text.trim();
      final String payDate = dateController.text.trim();
      final String payAmount = amountController.text.trim();
      final String studentName = nameController.text.trim();

      // Add seconds and AM/PM format
      final hour = now.hour;
      final minute = now.minute;
      final second = now.second;
      final amPm = hour < 12 ? 'AM' : 'PM';
      final hour12 = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;

      final String paymentTime = "${hour12.toString().padLeft(2, '0')}:${minute
          .toString().padLeft(2, '0')}:${second.toString().padLeft(
          2, '0')} $amPm";

      // Get student document to check if it exists
      final studentDoc = await firestore
          .collection('students')
          .doc(rollNo)
          .get();


      // Get the academic year from student or use default
      String academicYear;
      if (studentDoc.exists &&
          studentDoc.data()?['academicInfo']?['academicYear'] != null) {
        academicYear = studentDoc.data()?['academicInfo']?['academicYear'];
      } else {
        academicYear = _academicYear != 'Invalid' ? _academicYear : '2026-2027';
      }

      // Create the composite document ID for paymentInfo
      final paymentDocId = '${academicYear.replaceAll(' ', '_')}_$rollNo';

      // ✅ 1. Create enrollment request
      await firestore.collection('enrollment_requests').add({
        "studentId": rollNo,
        "studentName": studentName,
        "studentType": "new",
        "courseYear": _selectedCourseYear,
        "programType": _isBECourse ? "B.E" : (_isMECourse ? "M.E" : "Unknown"),
        "major": studentDoc.exists
            ? (studentDoc.data()?['smajor'] ?? 'N/A')
            : 'N/A',
        "academicYear": academicYear,
        "paymentAmount": double.parse(payAmount),
        "paymentReference": qrCode,
        "paymentDate": payDate,
        "paymentTime": paymentTime,
        "paymentStatus": "paid",
        "status": "Pending",
        "requestDate": FieldValue.serverTimestamp(),
        "lastUpdated": FieldValue.serverTimestamp(),
        "approvedBy": null,
        "approvedDate": null,
      });

      // ✅ 2. Update student's enrollment and payment status
      await firestore.collection('students').doc(rollNo).update({
        'academicInfo.enrollStatus': 'pending',
        'academicInfo.courseYear': _selectedCourseYear,
        'academicInfo.programType': _isBECourse ? "B.E" : (_isMECourse
            ? "M.E"
            : "Unknown"),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // ✅ 3. Update paymentInfo collection
      await firestore.collection('paymentInfo').doc(paymentDocId).set({
        "studentId": rollNo,
        "studentName": studentName,
        "academicYear": academicYear,
        "courseYear": _selectedCourseYear,
        "programType": _isBECourse ? "B.E" : (_isMECourse ? "M.E" : "Unknown"),
        "qr_code": qrCode,
        "pay_date": payDate,
        "pay_time": paymentTime,
        "pay_amount": double.parse(payAmount),
        "paymentStatus": "paid",
        "studentType": "new",
        "lastUpdated": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Show success dialog with option to go to PDF voucher
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    "Payment Successful!".tr(),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Generate PDF Voucher?".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // No button - goes to Home Screen
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MIITHomePage()),
                                (route) => false,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "No".tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Yes button - goes to PDF Voucher Screen DIRECTLY
                    Expanded(
                      child: TextButton(
                        // In the success dialog's "Yes" button:
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PdfVoucherScreen(
                                rollNo: rollNo,
                                studentName: studentName,
                                referenceNo: qrCode,
                                amount: payAmount,
                                date: payDate,
                                time: paymentTime,
                                courseYear: _selectedCourseYear,
                                programType: _isBECourse ? "B.E (Bachelor)" : "M.E (Master)",
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Yes".tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("✅ Payment and enrollment submitted successfully")),
      );
    } catch (e) {
      print("Firebase Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Payment update error: $e")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}