import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';
import 'my_drawer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:miit_project/screens/new_student_payment.dart';
import 'package:flutter/services.dart';

import 'new_stu_photo.dart';

enum NRCType { nrc, oldNrc, none }

class NewStudentEnrollmentApp extends StatefulWidget {
  final Map<String, dynamic>? studentData;
  final String? studentId;
  final String admissionNo;
  final String fullName;

  const NewStudentEnrollmentApp({
    super.key,
    this.studentData,
    this.studentId,
    required this.admissionNo,
    required this.fullName,
  });

  @override
  State<NewStudentEnrollmentApp> createState() => _NewStudentEnrollmentAppState();
}

class _NewStudentEnrollmentAppState extends State<NewStudentEnrollmentApp> {
  bool _studentDataFound = false;

  String selectedGender = 'Male';
  final List<String> courseYears = [
    "firstYear".tr(),
    "master1".tr(),
  ];
  String? selectedCourseYear;

  bool studentInProcess = false;
  NRCType studentSelectedNRCType = NRCType.nrc;

  String? fromYear;
  String? toYear;
  int? _adminStartYear;
  int? _adminEndYear;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminAcademicYear();

    if (widget.admissionNo.isNotEmpty) {
      rollNoController.text = widget.admissionNo;
    }

    if (widget.fullName.isNotEmpty) {
      nameEnglishController.text = widget.fullName;
    }
  }

  bool _formSubmitted = false;

  final TextEditingController courseYearController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController registrationNoController = TextEditingController();
  final TextEditingController yearOfUniversityController = TextEditingController();
  final TextEditingController nameMyanmarController = TextEditingController();
  final TextEditingController nameEnglishController = TextEditingController();
  final TextEditingController religionController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController nrcNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  String? studentSelectedStateDivisionCode;
  String? studentSelectedTownshipCode;
  String? studentSelectedNRCTypeCode;

  final TextEditingController fatherNameMyanmarController = TextEditingController();
  final TextEditingController fatherNameEnglishController = TextEditingController();
  final TextEditingController fatherReligionController = TextEditingController();
  final TextEditingController fatherPhoneController = TextEditingController();
  final TextEditingController fatherDobController = TextEditingController();
  final TextEditingController fatherNRCController = TextEditingController();
  final TextEditingController fatherAddressController = TextEditingController();

  String? fatherSelectedStateDivisionCode;
  String? fatherSelectedTownshipCode;
  String? fatherSelectedNRCTypeCode;
  bool fatherInProcess = false;
  NRCType fatherSelectedNRCType = NRCType.nrc;

  final TextEditingController motherNameMyanmarController = TextEditingController();
  final TextEditingController motherNameEnglishController = TextEditingController();
  final TextEditingController motherReligionController = TextEditingController();
  final TextEditingController motherPhoneController = TextEditingController();
  final TextEditingController motherDobController = TextEditingController();
  final TextEditingController motherNRCController = TextEditingController();
  final TextEditingController motherAddressController = TextEditingController();

  String? motherSelectedStateDivisionCode;
  String? motherSelectedTownshipCode;
  String? motherSelectedNRCTypeCode;
  bool motherInProcess = false;
  NRCType motherSelectedNRCType = NRCType.nrc;

  final List<String> stateDivisionCodes = [
    "one".tr(), "two".tr(), "three".tr(), "four".tr(), "five".tr(),
    "six".tr(), "seven".tr(), "eight".tr(), "nine".tr(), "ten".tr(),
    "eleven".tr(), "twelve".tr(), "thirteen".tr(), "fourteen".tr(),
  ];

  final Map<String, List<String>> townshipCodes = {
    "one".tr(): List.generate(30, (i) => "kachin${i+1}".tr()),
    "two".tr(): List.generate(9, (i) => "kayah${i+1}".tr()),
    "three".tr(): List.generate(17, (i) => "kayin${i+1}".tr()),
    "four".tr(): List.generate(13, (i) => "chin${i+1}".tr()),
    "five".tr(): List.generate(47, (i) => "sagaing${i+1}".tr()),
    "six".tr(): List.generate(18, (i) => "ta${i+1}".tr()),
    "seven".tr(): List.generate(34, (i) => "bago${i+1}".tr()),
    "eight".tr(): List.generate(27, (i) => "mg${i+1}".tr()),
    "nine".tr(): List.generate(45, (i) => "mdy${i+1}".tr()),
    "ten".tr(): List.generate(13, (i) => "mon${i+1}".tr()),
    "eleven".tr(): List.generate(20, (i) => "yakine${i+1}".tr()),
    "twelve".tr(): List.generate(46, (i) => "ygn${i+1}".tr()),
    "thirteen".tr(): List.generate(63, (i) => "shan${i+1}".tr()),
    "fourteen".tr(): List.generate(21, (i) => "ayawady${i+1}".tr()),
  };

  final List<Map<String, String>> nrcTypeCodes = [
    {"code": "C", "myanmar": "နိုင်"},
    {"code": "NC", "myanmar": "ပြု"},
    {"code": "AC", "myanmar": "ဧည့်"},
    {"code": "AMT", "myanmar": "အမတ"},
    {"code": "FRC", "myanmar": "FRC"},
    {"code": "V", "myanmar": "စ"},
    {"code": "M", "myanmar": "သ"},
    {"code": "N", "myanmar": "သီ"},
  ];

  @override
  void dispose() {
    courseYearController.dispose();
    rollNoController.dispose();
    registrationNoController.dispose();
    yearOfUniversityController.dispose();
    nameMyanmarController.dispose();
    nameEnglishController.dispose();
    religionController.dispose();
    phoneController.dispose();
    dobController.dispose();
    nrcNumberController.dispose();
    addressController.dispose();
    fatherNameMyanmarController.dispose();
    fatherNameEnglishController.dispose();
    fatherReligionController.dispose();
    fatherPhoneController.dispose();
    fatherDobController.dispose();
    fatherNRCController.dispose();
    fatherAddressController.dispose();
    motherNameMyanmarController.dispose();
    motherNameEnglishController.dispose();
    motherReligionController.dispose();
    motherPhoneController.dispose();
    motherDobController.dispose();
    motherNRCController.dispose();
    motherAddressController.dispose();
    super.dispose();
  }

  InputDecoration dropdownDecoration({bool isCompact = false}) => InputDecoration(
    filled: true,
    fillColor: Colors.lightBlue[100],
    border: const OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 8,
        vertical: isCompact ? 8 : 12
    ),
    isDense: true,
  );

  List<String> getTownshipsForState(String? stateDivisionCode) {
    if (stateDivisionCode == null) return [];
    return townshipCodes[stateDivisionCode] ?? [];
  }

  bool _validateAcademicSection() {
    if (fromYear == null || toYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('academicYearRequired'))),
      );
      return false;
    }
    if (selectedCourseYear == null || selectedCourseYear!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('courseYearRequired'))),
      );
      return false;
    }
    if (rollNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('rollNoRequired'))),
      );
      return false;
    }
    if (registrationNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('registrationNoRequired'))),
      );
      return false;
    }
    if (yearOfUniversityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('yearOfUniRequired'))),
      );
      return false;
    }
    return true;
  }

  bool _validateStudentSection() {
    if (nameMyanmarController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('nameMyanmarRequired'))));
      return false;
    }
    if (nameEnglishController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('nameEnglishRequired'))));
      return false;
    }
    if (religionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('religionRequired'))));
      return false;
    }
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('phoneRequired'))));
      return false;
    }
    final cleanPhone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length < 9 || cleanPhone.length > 11) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('phoneMustBe9to11Digits'))));
      return false;
    }
    if (dobController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('dobRequired'))));
      return false;
    }
    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('addressRequired'))));
      return false;
    }
    if (!studentInProcess) {
      if (studentSelectedStateDivisionCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('stateDivisionRequired'))));
        return false;
      }
      if (studentSelectedTownshipCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('townshipRequired'))));
        return false;
      }
      if (studentSelectedNRCTypeCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('nrcTypeRequired'))));
        return false;
      }
      if (nrcNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('nrcNumberRequired'))));
        return false;
      }
      if (nrcNumberController.text.trim().length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('nrcMustBe6Digits'))));
        return false;
      }
    }
    return true;
  }

  bool _validateParentSection(String parentType,
      TextEditingController nameMyanmarController,
      TextEditingController nameEnglishController,
      TextEditingController religionController,
      TextEditingController phoneController,
      TextEditingController dobController,
      TextEditingController addressController,
      TextEditingController nrcController,
      bool inProcess,
      String? stateDivisionCode,
      String? townshipCode,
      String? nrcTypeCode) {

    if (nameMyanmarController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('${parentType}NameMyanmarRequired'))));
      return false;
    }
    if (nameEnglishController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('${parentType}NameEnglishRequired'))));
      return false;
    }
    if (religionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('${parentType}ReligionRequired'))));
      return false;
    }
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('${parentType}PhoneRequired'))));
      return false;
    }
    final cleanPhone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length < 9 || cleanPhone.length > 11) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('phoneMustBe9to11Digits'))));
      return false;
    }
    if (dobController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('${parentType}DobRequired'))));
      return false;
    }
    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('${parentType}AddressRequired'))));
      return false;
    }
    if (!inProcess) {
      if (stateDivisionCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('${parentType}StateDivisionRequired'))));
        return false;
      }
      if (townshipCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('${parentType}TownshipRequired'))));
        return false;
      }
      if (nrcTypeCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('${parentType}NrcTypeRequired'))));
        return false;
      }
      if (nrcController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('${parentType}NrcNumberRequired'))));
        return false;
      }
      if (nrcController.text.trim().length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('${parentType}NrcMustBe6Digits'))));
        return false;
      }
    }
    return true;
  }

  bool _validateForm() {
    setState(() => _formSubmitted = true);
    if (!_validateAcademicSection()) return false;
    if (!_validateStudentSection()) return false;
    if (!_validateParentSection('father', fatherNameMyanmarController, fatherNameEnglishController,
        fatherReligionController, fatherPhoneController, fatherDobController, fatherAddressController,
        fatherNRCController, fatherInProcess, fatherSelectedStateDivisionCode,
        fatherSelectedTownshipCode, fatherSelectedNRCTypeCode)) return false;
    if (!_validateParentSection('mother', motherNameMyanmarController, motherNameEnglishController,
        motherReligionController, motherPhoneController, motherDobController, motherAddressController,
        motherNRCController, motherInProcess, motherSelectedStateDivisionCode,
        motherSelectedTownshipCode, motherSelectedNRCTypeCode)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

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
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.asset('assets/img_2.png', width: 50, height: 50),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tr("enrollment"), style: AppTextStyles.heading),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Academic Year
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: isSmallScreen ? 80 : 100,
                        child: Text("academicYear".tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Text("from".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          hint: Text("y".tr()),
                          value: fromYear,
                          underline: const SizedBox(),
                          onChanged: (value) => setState(() => fromYear = value),
                          items: _adminStartYear != null && fromYear != null
                              ? [DropdownMenuItem(value: fromYear, child: Text(fromYear!))]
                              : [],
                        ),
                      ),
                      Text("to".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          hint: Text("y".tr()),
                          value: toYear,
                          underline: const SizedBox(),
                          onChanged: (value) => setState(() => toYear = value),
                          items: _adminEndYear != null && toYear != null
                              ? [DropdownMenuItem(value: toYear, child: Text(toYear!))]
                              : [],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_formSubmitted && (fromYear == null || toYear == null))
                  Padding(
                    padding: const EdgeInsets.only(left: 100, top: 4),
                    child: Text(tr('academicYearRequired'),
                        style: const TextStyle(color: Colors.red, fontSize: 11)),
                  ),

                const SizedBox(height: 12),
                Text("studentEnrollment".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                _buildResponsiveDropdown("cYear".tr(), selectedCourseYear, courseYears, (value) => setState(() => selectedCourseYear = value), icon: Icons.school),
                if (_formSubmitted && (selectedCourseYear == null || selectedCourseYear!.isEmpty))
                  Padding(
                    padding: const EdgeInsets.only(left: 100, top: 4),
                    child: Text(tr('courseYearRequired'),
                        style: const TextStyle(color: Colors.red, fontSize: 11)),
                  ),

                _buildResponsiveTextField("rollNo".tr(), rollNoController, icon: Icons.badge, readOnly: true),
                _buildResponsiveTextField("registrationNo".tr(), registrationNoController, icon: Icons.confirmation_num),
                if (_formSubmitted && registrationNoController.text.trim().isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 100, top: 4),
                    child: Text(tr('registrationNoRequired'),
                        style: const TextStyle(color: Colors.red, fontSize: 11)),
                  ),

                _buildResponsiveTextField("yearOfUni".tr(), yearOfUniversityController, icon: Icons.perm_contact_cal_outlined),
                if (_formSubmitted && yearOfUniversityController.text.trim().isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 100, top: 4),
                    child: Text(tr('yearOfUniRequired'),
                        style: const TextStyle(color: Colors.red, fontSize: 11)),
                  ),

                const SizedBox(height: 25),

                // Student Information Section
                _buildResponsiveInfoSection(
                  title: "studentInformation".tr(),
                  nameMyanmarController: nameMyanmarController,
                  nameEnglishController: nameEnglishController,
                  religionController: religionController,
                  phoneController: phoneController,
                  dobController: dobController,
                  addressController: addressController,
                  nrcController: nrcNumberController,
                  inProcess: studentInProcess,
                  selectedNRCType: studentSelectedNRCType,
                  selectedStateDivisionCode: studentSelectedStateDivisionCode,
                  selectedTownshipCode: studentSelectedTownshipCode,
                  selectedNRCTypeCode: studentSelectedNRCTypeCode,
                  onUpdate: (val1, val2, val3, val4, val5) => setState(() {
                    studentInProcess = val1;
                    studentSelectedNRCType = val2;
                    studentSelectedStateDivisionCode = val3;
                    studentSelectedTownshipCode = val4;
                    studentSelectedNRCTypeCode = val5;
                  }),
                  isStudentSection: true,
                  formSubmitted: _formSubmitted,
                ),

                const SizedBox(height: 25),

                // Father's Information Section
                _buildResponsiveInfoSection(
                  title: "fInformation".tr(),
                  nameMyanmarController: fatherNameMyanmarController,
                  nameEnglishController: fatherNameEnglishController,
                  religionController: fatherReligionController,
                  phoneController: fatherPhoneController,
                  dobController: fatherDobController,
                  addressController: fatherAddressController,
                  nrcController: fatherNRCController,
                  inProcess: fatherInProcess,
                  selectedNRCType: fatherSelectedNRCType,
                  selectedStateDivisionCode: fatherSelectedStateDivisionCode,
                  selectedTownshipCode: fatherSelectedTownshipCode,
                  selectedNRCTypeCode: fatherSelectedNRCTypeCode,
                  onUpdate: (val1, val2, val3, val4, val5) => setState(() {
                    fatherSelectedNRCType = val2;
                    fatherSelectedStateDivisionCode = val3;
                    fatherSelectedTownshipCode = val4;
                    fatherSelectedNRCTypeCode = val5;
                  }),
                  formSubmitted: _formSubmitted,
                ),

                const SizedBox(height: 25),

                // Mother's Information Section
                _buildResponsiveInfoSection(
                  title: "mInformation".tr(),
                  nameMyanmarController: motherNameMyanmarController,
                  nameEnglishController: motherNameEnglishController,
                  religionController: motherReligionController,
                  phoneController: motherPhoneController,
                  dobController: motherDobController,
                  addressController: motherAddressController,
                  nrcController: motherNRCController,
                  inProcess: motherInProcess,
                  selectedNRCType: motherSelectedNRCType,
                  selectedStateDivisionCode: motherSelectedStateDivisionCode,
                  selectedTownshipCode: motherSelectedTownshipCode,
                  selectedNRCTypeCode: motherSelectedNRCTypeCode,
                  onUpdate: (val1, val2, val3, val4, val5) => setState(() {
                    motherInProcess = val1;
                    motherSelectedNRCType = val2;
                    motherSelectedStateDivisionCode = val3;
                    motherSelectedTownshipCode = val4;
                    motherSelectedNRCTypeCode = val5;
                  }),
                  formSubmitted: _formSubmitted,
                ),

                const SizedBox(height: 30),

                Center(
                  child: ActionButton(
                    text: "payment".tr(),
                    onPressed: _submitForm,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // Responsive Dropdown
  Widget _buildResponsiveDropdown(String label, String? selectedValue, List<String> items, ValueChanged<String?> onChanged, {IconData? icon}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: isSmallScreen ? 90 : 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.lightBlue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedValue,
                  isExpanded: true,
                  hint: Text(label, overflow: TextOverflow.ellipsis),
                  onChanged: onChanged,
                  items: items.map((y) => DropdownMenuItem(value: y, child: Text(y, overflow: TextOverflow.ellipsis))).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Responsive TextField
  Widget _buildResponsiveTextField(String label, TextEditingController controller, {IconData? icon, bool readOnly = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: isSmallScreen ? 90 : 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            child: Container(
              height: 42,
              child: TextFormField(
                controller: controller,
                readOnly: readOnly,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: readOnly ? Colors.grey[200] : Colors.lightBlue[100],
                  prefixIcon: icon != null ? Icon(icon, size: 18) : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Date of Birth Field
  Widget _buildResponsiveDateOfBirthField({required TextEditingController controller, int? maxAgeYears}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: isSmallScreen ? 90 : 100,
            child: const Text("bDate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            child: Container(
              height: 42,
              child: TextField(
                controller: controller,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.lightBlue[100],
                  prefixIcon: const Icon(Icons.calendar_today, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                onTap: () async {
                  DateTime lastDate = maxAgeYears != null
                      ? DateTime(DateTime.now().year - maxAgeYears, DateTime.now().month, DateTime.now().day)
                      : DateTime.now();
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: lastDate,
                  );
                  if (pickedDate != null) {
                    controller.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gender Selector
  Widget _buildResponsiveGenderSelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: isSmallScreen ? 90 : 100,
            child: const Text("gender", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'Male',
                        groupValue: selectedGender,
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        onChanged: (value) => setState(() => selectedGender = value!),
                      ),
                      Flexible(child: Text("male".tr())),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'Female',
                        groupValue: selectedGender,
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        onChanged: (value) => setState(() => selectedGender = value!),
                      ),
                      Flexible(child: Text("female".tr())),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Responsive Info Section
  Widget _buildResponsiveInfoSection({
    required String title,
    required TextEditingController nameMyanmarController,
    required TextEditingController nameEnglishController,
    required TextEditingController religionController,
    required TextEditingController phoneController,
    required TextEditingController dobController,
    required TextEditingController addressController,
    required TextEditingController nrcController,
    required bool inProcess,
    required NRCType selectedNRCType,
    required String? selectedStateDivisionCode,
    required String? selectedTownshipCode,
    required String? selectedNRCTypeCode,
    required Function(bool, NRCType, String?, String?, String?) onUpdate,
    bool isStudentSection = false,
    required bool formSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.indigo,
          padding: const EdgeInsets.all(10),
          child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),

        _buildResponsiveTextField("mName".tr(), nameMyanmarController, icon: Icons.person),
        if (formSubmitted && nameMyanmarController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 100, top: 2),
            child: Text(tr('nameMyanmarRequired'), style: const TextStyle(color: Colors.red, fontSize: 11)),
          ),

        _buildResponsiveTextField("eName".tr(), nameEnglishController, icon: Icons.person_outline),
        if (formSubmitted && nameEnglishController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 100, top: 2),
            child: Text(tr('nameEnglishRequired'), style: const TextStyle(color: Colors.red, fontSize: 11)),
          ),

        _buildResponsiveTextField("religion".tr(), religionController, icon: Icons.temple_buddhist),
        if (formSubmitted && religionController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 100, top: 2),
            child: Text(tr('religionRequired'), style: const TextStyle(color: Colors.red, fontSize: 11)),
          ),

        _buildResponsiveTextField("phoneNo".tr(), phoneController, icon: Icons.phone),
        if (formSubmitted && phoneController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 100, top: 2),
            child: Text(tr('phoneRequired'), style: const TextStyle(color: Colors.red, fontSize: 11)),
          ),

        isStudentSection
            ? _buildResponsiveDateOfBirthField(controller: dobController, maxAgeYears: 16)
            : _buildResponsiveDateOfBirthField(controller: dobController),
        if (formSubmitted && dobController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 100, top: 2),
            child: Text(tr('dobRequired'), style: const TextStyle(color: Colors.red, fontSize: 11)),
          ),

        _buildResponsiveTextField("address".tr(), addressController, icon: Icons.home_work_outlined),
        if (formSubmitted && addressController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 100, top: 2),
            child: Text(tr('addressRequired'), style: const TextStyle(color: Colors.red, fontSize: 11)),
          ),

        if (isStudentSection) _buildResponsiveGenderSelector(),

        const SizedBox(height: 15),

        // NRC Section with responsive layout
        _buildResponsiveNRCSection(
          inProcess: inProcess,
          selectedNRCType: selectedNRCType,
          selectedStateDivisionCode: selectedStateDivisionCode,
          selectedTownshipCode: selectedTownshipCode,
          selectedNRCTypeCode: selectedNRCTypeCode,
          nrcController: nrcController,
          onUpdate: onUpdate,
          formSubmitted: formSubmitted,
          showInProcessCheckbox: isStudentSection,
        ),
      ],
    );
  }

  // Responsive NRC Section - FIXED OVERFLOW
  Widget _buildResponsiveNRCSection({
    required bool inProcess,
    required NRCType selectedNRCType,
    required String? selectedStateDivisionCode,
    required String? selectedTownshipCode,
    required String? selectedNRCTypeCode,
    required TextEditingController nrcController,
    required Function(bool, NRCType, String?, String?, String?) onUpdate,
    required bool formSubmitted,
    bool showInProcessCheckbox = true,
  }) {
    List<String> availableTownships = getTownshipsForState(selectedStateDivisionCode);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isVerySmall = screenWidth < 340;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NRC Button and In Process checkbox
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => onUpdate(false, NRCType.nrc, selectedStateDivisionCode, selectedTownshipCode, selectedNRCTypeCode),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedNRCType == NRCType.nrc ? Colors.lightBlue[100] : null,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text("nrc".tr()),
            ),
            if (showInProcessCheckbox)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: inProcess,
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                    onChanged: (val) {
                      onUpdate(val ?? false, NRCType.none, null, null, null);
                      if (val == true) nrcController.clear();
                    },
                  ),
                  Text("inProcess".tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
          ],
        ),

        if (selectedNRCType == NRCType.nrc && !inProcess)
          Column(
            children: [
              const SizedBox(height: 10),
              // Responsive NRC dropdowns - wraps on small screens
              Wrap(
                spacing: 6,
                runSpacing: 8,
                children: [
                  // State/Division dropdown
                  SizedBox(
                    width: isVerySmall ? 95 : (isSmallScreen ? 105 : 110),
                    child: DropdownButtonFormField<String>(
                      decoration: dropdownDecoration(isCompact: true),
                      value: selectedStateDivisionCode,
                      hint: const Text("State", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                      items: stateDivisionCodes.map((code) => DropdownMenuItem(
                        value: code,
                        child: Text(code, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      )).toList(),
                      onChanged: (val) => onUpdate(inProcess, selectedNRCType, val, null, selectedNRCTypeCode),
                    ),
                  ),
                  // Township dropdown
                  SizedBox(
                    width: isVerySmall ? 140 : (isSmallScreen ? 150 : 170),
                    child: DropdownButtonFormField<String>(
                      decoration: dropdownDecoration(isCompact: true),
                      value: selectedTownshipCode,
                      hint: const Text("Township", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                      items: availableTownships.map((code) => DropdownMenuItem(
                        value: code,
                        child: Text(code, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      )).toList(),
                      onChanged: (val) => onUpdate(inProcess, selectedNRCType, selectedStateDivisionCode, val, selectedNRCTypeCode),
                    ),
                  ),
                  // NRC Type dropdown
                  SizedBox(
                    width: isVerySmall ? 80 : (isSmallScreen ? 85 : 95),
                    child: DropdownButtonFormField<String>(
                      decoration: dropdownDecoration(isCompact: true),
                      value: selectedNRCTypeCode,
                      hint: const Text("Type", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                      items: nrcTypeCodes.map((type) => DropdownMenuItem(
                        value: type['code'],
                        child: Text(
                          isVerySmall ? (type['code'] ?? '') : "${type['code']}",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      )).toList(),
                      onChanged: (val) => onUpdate(inProcess, selectedNRCType, selectedStateDivisionCode, selectedTownshipCode, val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // NRC Number field
              TextFormField(
                controller: nrcController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.lightBlue[100],
                  prefixIcon: const Icon(Icons.badge, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: "NRC Number (6 digits)",
                  hintStyle: const TextStyle(fontSize: 12),
                  isDense: true,
                ),
              ),
            ],
          ),
      ],
    );
  }

  bool _isSubmitting = false;

  Future<void> _fetchAdminAcademicYear() async {
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
            _adminStartYear = int.tryParse(startYear);
            _adminEndYear = int.tryParse(endYear);
            fromYear = startYear;
            toYear = endYear;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _submitForm() async {
    if (_isSubmitting) return;

    setState(() {
      _formSubmitted = true;
      _isSubmitting = true;
    });

    if (!_validateForm()) {
      setState(() => _isSubmitting = false);
      return;
    }

    if (fromYear != null && toYear != null) {
      int start = int.parse(fromYear!);
      int end = int.parse(toYear!);

      if (start >= end) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('startYearMustBeBeforeEndYear'))),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      try {
        final studentsCollection = FirebaseFirestore.instance.collection('students');
        final String rollNo = rollNoController.text.trim();
        final String smajor = rollNo.split('-')[2].toUpperCase();
        final String email = '$rollNo@miit.edu.mm';
        final String stype = "new";
        final studentDoc = studentsCollection.doc(rollNo);

        final studentData = {
          "srollno": rollNo,
          "semail": email,
          "sname": nameEnglishController.text.trim(),
          "sname_myanmar": nameMyanmarController.text.trim(),
          "sdob": dobController.text.trim(),
          "snrc": nrcNumberController.text.trim(),
          "snrc_state_division": studentSelectedStateDivisionCode,
          "snrc_township": studentSelectedTownshipCode,
          "snrc_type": studentSelectedNRCTypeCode,
          "snrc_in_process": studentInProcess,
          "sreligion": religionController.text.trim(),
          "sgender": selectedGender,
          "saddress": addressController.text.trim(),
          "scontactNumber": phoneController.text.trim(),
          "smajor": smajor,
          "stype": stype,
          "parents": {
            "father": {
              "fname_mm": fatherNameMyanmarController.text.trim(),
              "fname_eng": fatherNameEnglishController.text.trim(),
              "freligion": fatherReligionController.text.trim(),
              "fphone": fatherPhoneController.text.trim(),
              "fdob": fatherDobController.text.trim(),
              "faddress": fatherAddressController.text.trim(),
              "fnrc": fatherNRCController.text.trim(),
              "fnrc_state_division": fatherSelectedStateDivisionCode,
              "fnrc_township": fatherSelectedTownshipCode,
              "fnrc_type": fatherSelectedNRCTypeCode,
              "fnrc_in_process": false,
            },
            "mother": {
              "mname_mm": motherNameMyanmarController.text.trim(),
              "mname_eng": motherNameEnglishController.text.trim(),
              "mreligion": motherReligionController.text.trim(),
              "mphone": motherPhoneController.text.trim(),
              "mdob": motherDobController.text.trim(),
              "maddress": motherAddressController.text.trim(),
              "mnrc": motherNRCController.text.trim(),
              "mnrc_state_division": motherSelectedStateDivisionCode,
              "mnrc_township": motherSelectedTownshipCode,
              "mnrc_type": motherSelectedNRCTypeCode,
              "mnrc_in_process": false,
            }
          },
          "academicInfo": {
            "rollNumber": rollNo,
            "registrationNumber": registrationNoController.text.trim(),
            'start_year': start,
            'end_year': end,
            'academicYear': '$fromYear-$toYear',
            "courseYear": selectedCourseYear ?? "",
            "yearOfUniversity": yearOfUniversityController.text.trim(),
            "eduMail": email,
            "academicStatus": "Active",
            "enrollStatus": "Pending",
          },
          "timestamp": FieldValue.serverTimestamp(),
          "lastUpdated": FieldValue.serverTimestamp(),
        };

        await studentDoc.set(studentData);

        final enrollmentRequestsCollection = FirebaseFirestore.instance.collection('enrollment_requests');
        await enrollmentRequestsCollection.add({
          "studentId": rollNo,
          "semail": email,
          "rollNumber": rollNo,
          "courseYear": selectedCourseYear ?? "",
          "major": smajor,
          "enrolDate": DateTime.now(),
          "status": "pending",
          "paymentStatus": "pending",
          "approvedBy": null,
          "approvedDate": null,
          "timestamp": FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${tr('enrollmentSuccess')}")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewStudentPhotoUpload(
              studentData: {},
              rollNo: rollNoController.text.trim(),
              studentName: nameEnglishController.text.trim(),
              courseYear: selectedCourseYear,
            ),
          ),
        );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${tr('enrollmentError')}: $e")),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    } else {
      setState(() => _isSubmitting = false);
    }
  }
}