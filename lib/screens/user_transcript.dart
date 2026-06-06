import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:miit_project/screens/home_screen.dart';

class UserTranscript extends StatefulWidget {
  final String fullName;
  final String rollNumber;

  const UserTranscript({
    Key? key,
    required this.fullName,
    required this.rollNumber,
  }) : super(key: key);

  @override
  _UserTranscriptState createState() => _UserTranscriptState();
}

class _UserTranscriptState extends State<UserTranscript> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _academicYearController = TextEditingController();
  final TextEditingController _nameEnglishController = TextEditingController();
  final TextEditingController _classSubjectController = TextEditingController();
  final TextEditingController _nrcController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Additional controllers for personal details section
  final TextEditingController _nameMyanmarPersonalController = TextEditingController();
  final TextEditingController _bDateController = TextEditingController();
  final TextEditingController _scontactController = TextEditingController(); // Contact number

  // Date controller - autofilled with current date
  final TextEditingController _dateController = TextEditingController();

  String _selectedDocumentType = 'အမှတ်စာရင်း';
  String _selectedGender = 'ကျွန်တော်';
  String _selectedExamResult = 'အောင်မြင်';
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Set initial date to current date
    _dateController.text = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    // Pre-fill with data from constructor
    _rollNoController.text = widget.rollNumber;
    _nameEnglishController.text = widget.fullName;

    // Fetch student data from Firestore
    _fetchStudentData();
  }

  // Method to fetch student data from Firestore
  // Method to fetch student data from Firestore
  Future<void> _fetchStudentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the student document using roll number as document ID
      DocumentSnapshot studentDoc = await _firestore
          .collection('students')
          .doc(widget.rollNumber)
          .get();

      if (studentDoc.exists) {
        var studentData = studentDoc.data() as Map<String, dynamic>;

        // 1. Student Name (English) - sname
        if (studentData.containsKey('sname')) {
          _nameEnglishController.text = studentData['sname']?.toString() ?? '';
        }

        // 2. Student Name (Myanmar) - sname_myanmar
        if (studentData.containsKey('sname_myanmar')) {
          _nameMyanmarPersonalController.text = studentData['sname_myanmar']?.toString() ?? '';
        }

        // 3. Class/Subject - smajor_full
        if (studentData.containsKey('smajor_full')) {
          _classSubjectController.text = studentData['smajor_full']?.toString() ?? '';
        }

        // 4. Birth Date - sdob
        if (studentData.containsKey('sdob')) {
          _bDateController.text = studentData['sdob']?.toString() ?? '';
        }

        // 5. Contact Number - scontactNumber
        if (studentData.containsKey('scontactNumber')) {
          _scontactController.text = studentData['scontactNumber']?.toString() ?? '';
        }

        // 6. NRC - Format: snrc_state_division/snrc_township(snrc_type)snrc
        // Example: 9/MaHaMa(C)426193
        String nrcFormatted = '';
        if (studentData.containsKey('snrc_state_division')) {
          nrcFormatted += studentData['snrc_state_division']?.toString() ?? '';
        }
        if (studentData.containsKey('snrc_township')) {
          nrcFormatted += '/${studentData['snrc_township']?.toString() ?? ''}';
        }
        if (studentData.containsKey('snrc_type')) {
          nrcFormatted += '(${studentData['snrc_type']?.toString() ?? ''})';
        }
        if (studentData.containsKey('snrc')) {
          nrcFormatted += studentData['snrc']?.toString() ?? '';
        }
        _nrcController.text = nrcFormatted;

        // 7. Academic Information
        if (studentData.containsKey('academicInfo')) {
          var academicInfo = studentData['academicInfo'] as Map<String, dynamic>;

          // Academic Year
          if (academicInfo.containsKey('academicYear')) {
            _academicYearController.text = academicInfo['academicYear']?.toString() ?? '';
          }
        }


        // 10. Father Name
        if (studentData.containsKey('parents')) {
          var parents = studentData['parents'] as Map<String, dynamic>;
          if (parents.containsKey('father')) {
            var father = parents['father'] as Map<String, dynamic>;
            if (father.containsKey('fname_eng')) {
              _fatherNameController.text = father['fname_eng']?.toString() ?? '';
            }

            // Father's address (fallback for student address)
            if (father.containsKey('faddress') && _addressController.text.isEmpty) {
              _addressController.text = father['faddress']?.toString() ?? '';
            }
          }
        }

        // 11. Student Address (saddress)
        if (studentData.containsKey('saddress')) {
          _addressController.text = studentData['saddress']?.toString() ?? '';
        }

        // 12. Gender detection (if available)
        if (studentData.containsKey('gender')) {
          String gender = studentData['gender']?.toString() ?? '';
          if (gender == 'ကျွန်မ' || gender == 'female' || gender == 'F') {
            _selectedGender = 'ကျွန်မ';
          } else {
            _selectedGender = 'ကျွန်တော်';
          }
        }

        print('Student data loaded successfully for: ${widget.rollNumber}');
        print('NRC formatted: $nrcFormatted');

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
        print('No student document found for roll number: ${widget.rollNumber}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ကျောင်းသားအချက်အလက်များ မတွေ့ရှိပါ။ ကျေးဇူးပြု၍ ကိုယ်တိုင်ဖြည့်သွင်းပါ။'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching student data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ဒေတာရယူရာတွင် အမှားအယွင်းဖြစ်ပွားပါသည်: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ကျေးဇူးပြု၍ အကွက်အားလုံးကို ဖြည့်သွင်းပါ'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final transcriptRequestData = {
        'studentId': widget.rollNumber,
        'studentName': widget.fullName,
        'studentNameEnglish': _nameEnglishController.text,
        'studentNameMyanmar': _nameMyanmarPersonalController.text,
        'academicYear': _academicYearController.text,
        'classSubject': _classSubjectController.text,
        'nrc': _nrcController.text,
        'fatherName': _fatherNameController.text,
        'address': _addressController.text,
        'contactNumber': _scontactController.text,
        'email': _emailController.text,
        'documentType': _selectedDocumentType,
        'gender': _selectedGender,
        'examResult': _selectedExamResult,
        'purpose': '${_selectedDocumentType} Request',
        'deliveryMethod': 'Pickup',
        'paymentStatus': 'pending',
        'paymentAmount': _amountController.text.isNotEmpty ? int.tryParse(_amountController.text) ?? 0 : 0,
        'paymentReference': 'N/A',
        'status': 'Pending',
        'requestDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'bDate': _bDateController.text,
      };

      await _firestore.collection('transcript_requests').add(transcriptRequestData);
      print('Transcript request submitted successfully!');

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('အောင်မြင်ပါသည်'),
            content: const Text('လျှောက်လွှာတင်ပြခြင်း အောင်မြင်ပါသည်။'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => MIITHomePage()),
                        (route) => false,
                  );
                },
                child: const Text('အိုကေ'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error submitting transcript request: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('အမှားအယွင်း'),
            content: Text('လျှောက်လွှာတင်ပြရာတွင် အမှားအယွင်းဖြစ်နေပါသည်။\n\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('အိုကေ'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateRequiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'ကျေးဇူးပြု၍ $fieldName ကို ဖြည့်သွင်းပါ';
    }
    return null;
  }

  String? _validateNumberField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'ကျေးဇူးပြု၍ $fieldName ကို ဖြည့်သွင်းပါ';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      return '$fieldName တွင် နံပါတ်များသာပါဝင်ရမည်';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('အမှတ်စာရင်း လျှောက်လွှာ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: _isLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('ကျောင်းသားအချက်အလက်များ ရယူနေပါသည်...'),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 10),
                _buildDateAndApplicationSection(),
                const SizedBox(height: 15),
                _buildStudentInfoSection(),
                const SizedBox(height: 15),
                const Divider(thickness: 1, color: Colors.black),
                const SizedBox(height: 15),
                _buildPersonalDetailsSection(),
                const SizedBox(height: 20),
                _buildDepartmentSection(),
                const SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 10),
          child: Image.asset(
            'assets/img_2.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(child: Text('Logo')),
              );
            },
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                'ပြည်ထောင်စုသမ္မတမြန်မာနိုင်ငံတော်အစိုးရ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                'သိပ္ပံနှင့်နည်းပညာဝန်ကြီးဌာန',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                'အဆင့်မြင့်သိပ္ပံနှင့်နည်းပညာဦးစီးဌာန',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                'မြန်မာသတင်းအချက်အလက်နည်းပညာတက္ကသိုလ်',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                'မန္တလေးမြို့',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateAndApplicationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black),
            children: [
              const TextSpan(text: 'သို့\n'),
              const TextSpan(
                text: 'ပါမောက္ခချုပ်\nမြန်မာသတင်းအချက်အလက်နည်းပညာတက္ကသိုလ်',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Wrap(
          children: [
            Text(
              'အကြောင်းအရာ။  အမှတ်စာရင်း / Grading Certificate /ထောက်ခံစာ ထုတ်ယူခွင့်ပြုပါရန် လျှောက်ထားခြင်း',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Wrap(
          children: [
            const Text(
              'ရက်စွဲ။  ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildStudentInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            SizedBox(
              width: 100,
              child: _buildStyledDropdown(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'ကျွန်တော်', child: Text('ကျွန်တော်')),
                  DropdownMenuItem(value: 'ကျွန်မ', child: Text('ကျွန်မ')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ကျေးဇူးပြု၍ ကျား/မ ကိုရွေးချယ်ပါ';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 5),
            const Text('မောင်/မ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 5),
            SizedBox(
              width: 180,
              child: TextFormField(
                controller: _nameEnglishController,
                readOnly: true, // Keep read-only (auto-recalled)
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.only(bottom: 5),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                validator: (value) => _validateRequiredField(value, 'အမည်'),
              ),
            ),
            const SizedBox(width: 5),
            const Text('သည်', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _academicYearController,
                readOnly: true, // Keep read-only (auto-recalled)
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 4),
                ),
                style: const TextStyle(fontSize: 14),
                validator: (value) => _validateRequiredField(value, 'ပညာသင်နှစ်'),
              ),
            ),
            const SizedBox(width: 5),
            const Text('ပညာသင်နှစ် ၊ မြန်မာသတင်းအချက်အလက်နည်းပညာတက္ကသိုလ်မှ ကျင်းပသည့်'),
            const SizedBox(width: 5),
            // FIXED: Added controller and made editable (not read-only)
            SizedBox(
              width: 80,
              child: TextFormField(
                readOnly: false, // Make editable - user can type
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 4),
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: TextInputType.number, // For number input
                validator: (value) => _validateRequiredField(value, 'စာမေးပွဲနှစ်'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          children: [
            const Text('နှစ် စာမေးပွဲတွင် ခုံအမှတ်'),
            const SizedBox(width: 5),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _rollNoController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.only(bottom: 4),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                validator: (value) => _validateRequiredField(value, 'ခုံအမှတ်'),
              ),
            ),
            const SizedBox(width: 5),
            const Text('ဖြင့် ဖြေဆို'),
          ],
        ),
        const SizedBox(height: 15),
        Wrap(
          children: [
            SizedBox(
              width: 120,
              child: _buildStyledDropdown(
                value: _selectedExamResult,
                items: const [
                  DropdownMenuItem(value: 'အောင်မြင်', child: Text('အောင်မြင်')),
                  DropdownMenuItem(value: 'ကျရှုံး', child: Text('ကျရှုံး')),
                  DropdownMenuItem(value: 'တက်ရောက်', child: Text('တက်ရောက်')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedExamResult = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ကျေးဇူးပြု၍ ရလဒ်ကိုရွေးချယ်ပါ';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 5),
            const Text('ခဲ့သူ ကျောင်းသား/ကျောင်းသူ တစ်ဦးဖြစ်ပါသည်။'),
            const SizedBox(width: 5),
            const Text('ကျွန်တော်/ကျွန်မ အား'),
            const SizedBox(width: 5),
            // FIXED: Made editable (removed readOnly)
            SizedBox(
              width: 120,
              child: TextFormField(
                readOnly: false, // Make editable - user can type
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 4),
                  hintText: 'e.g., 2022-2023', // Optional hint
                ),
                style: const TextStyle(fontSize: 14),
                validator: (value) => _validateRequiredField(value, 'နှစ်များ'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          children: [
            const Text('နှစ်များ၏ စာမေးပွဲတွင် ရရှိသည့်'),
            const SizedBox(width: 5),
            SizedBox(
              width: 150,
              child: _buildStyledDropdown(
                value: _selectedDocumentType,
                items: const [
                  DropdownMenuItem(value: 'အမှတ်စာရင်း', child: Text('အမှတ်စာရင်း')),
                  DropdownMenuItem(value: 'Grading Certificate', child: Text('Grading Certificate')),
                  DropdownMenuItem(value: 'ထောက်ခံစာ', child: Text('ထောက်ခံစာ')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDocumentType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ကျေးဇူးပြု၍ စာရွက်စာတမ်းအမျိုးအစားရွေးချယ်ပါ';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 5),
            const Text('ထုတ်ယူခွင့်ပြုပါရန် လျှောက်ထားခြင်း လျှောက်ထား အပ်ပါသည်။'),
          ],
        ),
        const SizedBox(height: 25),
      ],
    );
  }
  Widget _buildPersonalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ကိုယ်ရေးအချက်အလက်',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        const SizedBox(height: 25),
        _buildLabelAndInput('အမည်(အင်္ဂလိပ်)', _nameEnglishController, true, 'အမည်(အင်္ဂလိပ်)'),
        _buildLabelAndInput('အမည်(မြန်မာ)', _nameMyanmarPersonalController, true, 'အမည်(မြန်မာ)'),
        _buildLabelAndInput('အတန်း(ဘာသာရပ်)', _classSubjectController, true, 'အတန်း(ဘာသာရပ်)'),
        _buildLabelAndInput('နိုင်ငံသားစိစစ်ရေးမှတ်ပုံတင်အမှတ်', _nrcController, true, 'မှတ်ပုံတင်အမှတ်'),
        _buildLabelAndInput('မွေးနေ့', _bDateController, true, 'မွေးနေ့'),
        _buildLabelAndInput('အဘအမည်', _fatherNameController, true, 'အဘအမည်'),
        _buildLabelAndInput('နေရပ်လိပ်စာ', _addressController, true, 'နေရပ်လိပ်စာ'),
        _buildLabelAndInput('ဖုန်းနံပါတ်', _scontactController, true, 'ဖုန်းနံပါတ်'),
        _buildLabelAndInput('Email', _emailController, false, 'Email'),
      ],
    );
  }

  Widget _buildLabelAndInput(String label, TextEditingController controller, bool isReadOnly, String fieldName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              readOnly: isReadOnly,
              decoration: InputDecoration(
                border: const UnderlineInputBorder(),
                contentPadding: const EdgeInsets.only(bottom: 4),
                isDense: true,
                // Add hint for read-only fields
                hintText: isReadOnly ? 'ဒေတာမှ အလိုအလျောက်ဖြည့်သွင်းပြီး' : null,
              ),
              style: TextStyle(
                fontSize: 14,
                color: isReadOnly ? Colors.black87 : Colors.black,
              ),
              validator: (value) => _validateRequiredField(value, fieldName),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ငွေစာရင်းဌာန / စာကြည့်တိုက်ဌာန / စက်ပစ္စည်းဌာန ဖြည့်သွင်းရန်',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 25),
        Wrap(
          spacing: 5,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 100,
              child: _buildStyledDropdown(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'ကျွန်တော်', child: Text('ကျွန်တော်')),
                  DropdownMenuItem(value: 'ကျွန်မ', child: Text('ကျွန်မ')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
            ),
            const Text('မောင်/မ', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              width: 150,
              child: TextFormField(
                controller: _nameEnglishController,
                readOnly: true,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.only(bottom: 5),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const Text('(ခုံအမှတ်', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              width: 150,
              child: TextFormField(
                controller: _rollNoController,
                readOnly: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.only(bottom: 4),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const Text(')', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              width: 120,
              child: TextFormField(
                readOnly: false, // Make editable - user can type
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 4),
                ),
                style: const TextStyle(fontSize: 14),
                validator: (value) => _validateRequiredField(value, 'နှစ် သင်တန်း သည်'),
              ),
            ),
            const Text('နှစ် သင်တန်း သည်', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),
        Wrap(
          children: [
            const Text('အမှတ်စာရင်း / Grading Certificate / ထောက်ခံစာ ထုတ်ယူခွင့်ရရှိရန်အတွက် ကျသင့်ငွေ ('),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  isDense: true,
                  hintText: 'ကျပ်ငွေ',
                  contentPadding: EdgeInsets.only(bottom: 4),
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: TextInputType.number,
                validator: (value) => _validateNumberField(value, 'ကျသင့်ငွေ'),
              ),
            ),
            const Text(') ကို ပေးသွင်းပြီးဖြစ်ကြောင်းနှင့် ငွေစာရင်းဌာန / စာကြည့်တိုက်ဌာန / စက်ပစ္စည်းဌာန ကြွေးကျန်များ ကင်းရှင်းကြောင်း ထောက်ခံအပ်ပါသည်။',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          backgroundColor: _isSubmitting ? Colors.grey : Colors.lightBlue.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
        )
            : const Text(
          'လျှောက်လွှာတင်ပြရန်',
          style: TextStyle(fontSize: 14, color: Colors.indigo, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
      ),
      items: items,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black,
      ),
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
      isExpanded: true,
      validator: validator,
    );
  }

  @override
  void dispose() {
    _rollNoController.dispose();
    _academicYearController.dispose();
    _nameEnglishController.dispose();
    _classSubjectController.dispose();
    _nrcController.dispose();
    _fatherNameController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _nameMyanmarPersonalController.dispose();
    _bDateController.dispose();
    _scontactController.dispose();
    super.dispose();
  }
}