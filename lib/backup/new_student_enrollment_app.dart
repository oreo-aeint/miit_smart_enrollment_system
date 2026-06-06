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

    // Pre-populate the roll number field with data from previous page
    if (widget.admissionNo.isNotEmpty) {
      rollNoController.text = widget.admissionNo;
    }

    // Optional: Pre-populate the English name field
    if (widget.fullName.isNotEmpty) {
      nameEnglishController.text = widget.fullName;
    }
  }

  // Validation flags
  bool _formSubmitted = false;

  // Student Controllers
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

  // Father Controllers
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

  // Mother Controllers
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
    "one".tr(),     // Kachin
    "two".tr(),     // Kayah
    "three".tr(),   // Kayin
    "four".tr(),    // Chin
    "five".tr(),    // Sagaing
    "six".tr(),     // Tanintharyi
    "seven".tr(),   // Bago
    "eight".tr(),   // Magway
    "nine".tr(),    // Mandalay
    "ten".tr(),     // Mon
    "eleven".tr(),  // Rakhine
    "twelve".tr(),  // Yangon
    "thirteen".tr(),// Shan
    "fourteen".tr(),// Ayeyarwady
  ];

  // Fixed township codes with unique values
  final Map<String, List<String>> townshipCodes = {
    "one".tr(): [
      "kachin1".tr(), "kachin2".tr(), "kachin3".tr(), "kachin4".tr(), "kachin5".tr(),
      "kachin6".tr(), "kachin7".tr(), "kachin8".tr(), "kachin9".tr(), "kachin10".tr(),
      "kachin11".tr(), "kachin12".tr(), "kachin13".tr(), "kachin14".tr(), "kachin15".tr(),
      "kachin16".tr(), "kachin17".tr(), "kachin18".tr(), "kachin19".tr(), "kachin20".tr(),
      "kachin21".tr(), "kachin22".tr(), "kachin23".tr(), "kachin24".tr(), "kachin25".tr(),
      "kachin26".tr(), "kachin27".tr(), "kachin28".tr(), "kachin29".tr(), "kachin30".tr(),
    ],
    "two".tr(): [
      "kayah1".tr(), "kayah2".tr(), "kayah3".tr(), "kayah4".tr(), "kayah5".tr(),
      "kayah6".tr(), "kayah7".tr(), "kayah8".tr(), "kayah9".tr(),
    ],
    "three".tr(): [
      "kayin1".tr(), "kayin2".tr(), "kayin3".tr(), "kayin4".tr(), "kayin5".tr(),
      "kayin6".tr(), "kayin7".tr(), "kayin8".tr(), "kayin9".tr(), "kayin10".tr(),
      "kayin11".tr(), "kayin12".tr(), "kayin13".tr(), "kayin14".tr(), "kayin15".tr(),
      "kayin16".tr(), "kayin17".tr(),
    ],
    "four".tr(): [
      "chin1".tr(), "chin2".tr(), "chin3".tr(), "chin4".tr(), "chin5".tr(),
      "chin6".tr(), "chin7".tr(), "chin8".tr(), "chin9".tr(), "chin10".tr(),
      "chin11".tr(), "chin12".tr(), "chin13".tr(),
    ],
    "five".tr(): [
      "sagaing1".tr(), "sagaing2".tr(), "sagaing3".tr(), "sagaing4".tr(), "sagaing5".tr(),
      "sagaing6".tr(), "sagaing7".tr(), "sagaing8".tr(), "sagaing9".tr(), "sagaing10".tr(),
      "sagaing11".tr(), "sagaing12".tr(), "sagaing13".tr(), "sagaing14".tr(), "sagaing15".tr(),
      "sagaing16".tr(), "sagaing17".tr(), "sagaing18".tr(), "sagaing19".tr(), "sagaing20".tr(),
      "sagaing21".tr(), "sagaing22".tr(), "sagaing23".tr(), "sagaing24".tr(), "sagaing25".tr(),
      "sagaing26".tr(), "sagaing27".tr(), "sagaing28".tr(), "sagaing29".tr(), "sagaing30".tr(),
      "sagaing31".tr(), "sagaing32".tr(), "sagaing33".tr(), "sagaing34".tr(), "sagaing35".tr(),
      "sagaing36".tr(), "sagaing37".tr(), "sagaing38".tr(), "sagaing39".tr(), "sagaing40".tr(),
      "sagaing41".tr(), "sagaing42".tr(), "sagaing43".tr(), "sagaing44".tr(), "sagaing45".tr(),
      "sagaing46".tr(), "sagaing47".tr(),
    ],
    "six".tr(): [
      "ta1".tr(), "ta2".tr(), "ta3".tr(), "ta4".tr(), "ta5".tr(),
      "ta6".tr(), "ta7".tr(), "ta8".tr(), "ta9".tr(), "ta10".tr(),
      "ta11".tr(), "ta12".tr(), "ta13".tr(), "ta14".tr(), "ta15".tr(),
      "ta16".tr(), "ta17".tr(), "ta18".tr(),
    ],
    "seven".tr(): [
      "bago1".tr(), "bago2".tr(), "bago3".tr(), "bago4".tr(), "bago5".tr(),
      "bago6".tr(), "bago7".tr(), "bago8".tr(), "bago9".tr(), "bago10".tr(),
      "bago11".tr(), "bago12".tr(), "bago13".tr(), "bago14".tr(), "bago15".tr(),
      "bago16".tr(), "bago17".tr(), "bago18".tr(), "bago19".tr(), "bago20".tr(),
      "bago21".tr(), "bago22".tr(), "bago23".tr(), "bago24".tr(), "bago25".tr(),
      "bago26".tr(), "bago27".tr(), "bago28".tr(), "bago29".tr(), "bago30".tr(),
      "bago31".tr(), "bago32".tr(), "bago33".tr(), "bago34".tr(),
    ],
    "eight".tr(): [
      "mg1".tr(), "mg2".tr(), "mg3".tr(), "mg4".tr(), "mg5".tr(),
      "mg6".tr(), "mg7".tr(), "mg8".tr(), "mg9".tr(), "mg10".tr(),
      "mg11".tr(), "mg12".tr(), "mg13".tr(), "mg14".tr(), "mg15".tr(),
      "mg16".tr(), "mg17".tr(), "mg18".tr(), "mg19".tr(), "mg20".tr(),
      "mg21".tr(), "mg22".tr(), "mg23".tr(), "mg24".tr(), "mg25".tr(),
      "mg26".tr(), "mg27".tr(),
    ],
    "nine".tr(): [
      "mdy1".tr(), "mdy2".tr(), "mdy3".tr(), "mdy4".tr(), "mdy5".tr(),
      "mdy6".tr(), "mdy7".tr(), "mdy8".tr(), "mdy9".tr(), "mdy10".tr(),
      "mdy11".tr(), "mdy12".tr(), "mdy13".tr(), "mdy14".tr(), "mdy15".tr(),
      "mdy16".tr(), "mdy17".tr(), "mdy18".tr(), "mdy19".tr(), "mdy20".tr(),
      "mdy21".tr(), "mdy22".tr(), "mdy23".tr(), "mdy24".tr(), "mdy25".tr(),
      "mdy26".tr(), "mdy27".tr(), "mdy28".tr(), "mdy29".tr(), "mdy30".tr(),
      "mdy31".tr(), "mdy32".tr(), "mdy33".tr(), "mdy34".tr(), "mdy35".tr(),
      "mdy36".tr(), "mdy37".tr(), "mdy38".tr(), "mdy39".tr(), "mdy40".tr(),
      "mdy41".tr(), "mdy42".tr(), "mdy43".tr(), "mdy44".tr(), "mdy45".tr(),
    ],
    "ten".tr(): [
      "mon1".tr(), "mon2".tr(), "mon3".tr(), "mon4".tr(), "mon5".tr(),
      "mon6".tr(), "mon7".tr(), "mon8".tr(), "mon9".tr(), "mon10".tr(),
      "mon11".tr(), "mon12".tr(), "mon13".tr(),
    ],
    "eleven".tr(): [
      "yakine1".tr(), "yakine2".tr(), "yakine3".tr(), "yakine4".tr(), "yakine5".tr(),
      "yakine6".tr(), "yakine7".tr(), "yakine8".tr(), "yakine9".tr(), "yakine10".tr(),
      "yakine11".tr(), "yakine12".tr(), "yakine13".tr(), "yakine14".tr(), "yakine15".tr(),
      "yakine16".tr(), "yakine17".tr(), "yakine18".tr(), "yakine19".tr(), "yakine20".tr(),
    ],
    "twelve".tr(): [
      "ygn1".tr(), "ygn2".tr(), "ygn3".tr(), "ygn4".tr(), "ygn5".tr(),
      "ygn6".tr(), "ygn7".tr(), "ygn8".tr(), "ygn9".tr(), "ygn10".tr(),
      "ygn11".tr(), "ygn12".tr(), "ygn13".tr(), "ygn14".tr(), "ygn15".tr(),
      "ygn16".tr(), "ygn17".tr(), "ygn18".tr(), "ygn19".tr(), "ygn20".tr(),
      "ygn21".tr(), "ygn22".tr(), "ygn23".tr(), "ygn24".tr(), "ygn25".tr(),
      "ygn26".tr(), "ygn27".tr(), "ygn28".tr(), "ygn29".tr(), "ygn30".tr(),
      "ygn31".tr(), "ygn32".tr(), "ygn33".tr(), "ygn34".tr(), "ygn35".tr(),
      "ygn36".tr(), "ygn37".tr(), "ygn38".tr(), "ygn39".tr(), "ygn40".tr(),
      "ygn41".tr(), "ygn42".tr(), "ygn43".tr(), "ygn44".tr(), "ygn45".tr(),
      "ygn46".tr(),
    ],
    "thirteen".tr(): [
      "shan1".tr(), "shan2".tr(), "shan3".tr(), "shan4".tr(), "shan5".tr(),
      "shan6".tr(), "shan7".tr(), "shan8".tr(), "shan9".tr(), "shan10".tr(),
      "shan11".tr(), "shan12".tr(), "shan13".tr(), "shan14".tr(), "shan15".tr(),
      "shan16".tr(), "shan17".tr(), "shan18".tr(), "shan19".tr(), "shan20".tr(),
      "shan21".tr(), "shan22".tr(), "shan23".tr(), "shan24".tr(), "shan25".tr(),
      "shan26".tr(), "shan27".tr(), "shan28".tr(), "shan29".tr(), "shan30".tr(),
      "shan31".tr(), "shan32".tr(), "shan33".tr(), "shan34".tr(), "shan35".tr(),
      "shan36".tr(), "shan37".tr(), "shan38".tr(), "shan39".tr(), "shan40".tr(),
      "shan41".tr(), "shan42".tr(), "shan43".tr(), "shan44".tr(), "shan45".tr(),
      "shan46".tr(), "shan47".tr(), "shan48".tr(), "shan49".tr(), "shan50".tr(),
      "shan51".tr(), "shan52".tr(), "shan53".tr(), "shan54".tr(), "shan55".tr(),
      "shan56".tr(), "shan57".tr(), "shan58".tr(), "shan59".tr(), "shan60".tr(),
      "shan61".tr(), "shan62".tr(), "shan63".tr(),
    ],
    "fourteen".tr(): [
      "ayawady1".tr(), "ayawady2".tr(), "ayawady3".tr(), "ayawady4".tr(), "ayawady5".tr(),
      "ayawady6".tr(), "ayawady7".tr(), "ayawady8".tr(), "ayawady9".tr(), "ayawady10".tr(),
      "ayawady11".tr(), "ayawady12".tr(), "ayawady13".tr(), "ayawady14".tr(), "ayawady15".tr(),
      "ayawady16".tr(), "ayawady17".tr(), "ayawady18".tr(), "ayawady19".tr(), "ayawady20".tr(),
      "ayawady21".tr(),
    ],
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
    // Student Controllers
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

    // Father Controllers
    fatherNameMyanmarController.dispose();
    fatherNameEnglishController.dispose();
    fatherReligionController.dispose();
    fatherPhoneController.dispose();
    fatherDobController.dispose();
    fatherNRCController.dispose();
    fatherAddressController.dispose();

    // Mother Controllers
    motherNameMyanmarController.dispose();
    motherNameEnglishController.dispose();
    motherReligionController.dispose();
    motherPhoneController.dispose();
    motherDobController.dispose();
    motherNRCController.dispose();
    motherAddressController.dispose();
    super.dispose();
  }

  InputDecoration dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.lightBlue[100],
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
  );

  // FIXED: Improved township fetching method
  List<String> getTownshipsForState(String? stateDivisionCode) {
    if (stateDivisionCode == null) return [];
    final townships = townshipCodes[stateDivisionCode] ?? [];
    return townships;
  }

  // Validation methods
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('nameMyanmarRequired'))),
      );
      return false;
    }

    if (nameEnglishController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('nameEnglishRequired'))),
      );
      return false;
    }

    if (religionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('religionRequired'))),
      );
      return false;
    }

    // Phone validation - check if empty or invalid format
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('phoneRequired'))),
      );
      return false;
    }

    // Check phone number format (9-11 digits)
    final cleanPhone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length < 9 || cleanPhone.length > 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('phoneMustBe9to11Digits'))),
      );
      return false;
    }

    if (dobController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('dobRequired'))),
      );
      return false;
    }

    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('addressRequired'))),
      );
      return false;
    }

    // NRC validation
    if (!studentInProcess) {
      if (studentSelectedStateDivisionCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('stateDivisionRequired'))),
        );
        return false;
      }

      if (studentSelectedTownshipCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('townshipRequired'))),
        );
        return false;
      }

      if (studentSelectedNRCTypeCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('nrcTypeRequired'))),
        );
        return false;
      }

      if (nrcNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('nrcNumberRequired'))),
        );
        return false;
      }

      if (nrcNumberController.text.trim().length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('nrcMustBe6Digits'))),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('${parentType}NameMyanmarRequired'))),
      );
      return false;
    }

    if (nameEnglishController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('${parentType}NameEnglishRequired'))),
      );
      return false;
    }

    if (religionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('${parentType}ReligionRequired'))),
      );
      return false;
    }

    // Phone validation for parents
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('${parentType}PhoneRequired'))),
      );
      return false;
    }

    // Check phone number format (9-11 digits) for parents
    final cleanPhone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length < 9 || cleanPhone.length > 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('phoneMustBe9to11Digits'))),
      );
      return false;
    }

    if (dobController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('${parentType}DobRequired'))),
      );
      return false;
    }

    if (addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('${parentType}AddressRequired'))),
      );
      return false;
    }

    // NRC validation for parents
    if (!inProcess) {
      if (stateDivisionCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('${parentType}StateDivisionRequired'))),
        );
        return false;
      }

      if (townshipCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('${parentType}TownshipRequired'))),
        );
        return false;
      }

      if (nrcTypeCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('${parentType}NrcTypeRequired'))),
        );
        return false;
      }

      if (nrcController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('${parentType}NrcNumberRequired'))),
        );
        return false;
      }

      if (nrcController.text.trim().length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('${parentType}NrcMustBe6Digits'))),
        );
        return false;
      }
    }

    return true;
  }

  bool _validateForm() {
    setState(() {
      _formSubmitted = true;
    });

    if (!_validateAcademicSection()) return false;
    if (!_validateStudentSection()) return false;
    if (!_validateParentSection(
      'father',
      fatherNameMyanmarController,
      fatherNameEnglishController,
      fatherReligionController,
      fatherPhoneController,
      fatherDobController,
      fatherAddressController,
      fatherNRCController,
      fatherInProcess,
      fatherSelectedStateDivisionCode,
      fatherSelectedTownshipCode,
      fatherSelectedNRCTypeCode,
    )) return false;

    if (!_validateParentSection(
      'mother',
      motherNameMyanmarController,
      motherNameEnglishController,
      motherReligionController,
      motherPhoneController,
      motherDobController,
      motherAddressController,
      motherNRCController,
      motherInProcess,
      motherSelectedStateDivisionCode,
      motherSelectedTownshipCode,
      motherSelectedNRCTypeCode,
    )) return false;

    return true;
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
              colors: [
                Color(0xFF87CEFA),
                Color(0xFFADD8E6),
              ],
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
              child: Text(
                tr("enrollment"),
                style: AppTextStyles.heading,
              ),
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
                  DropdownMenuItem(
                    value: Locale('en'),
                    child: Text("English"),
                  ),
                  DropdownMenuItem(
                    value: Locale('my'),
                    child: Text("မြန်မာ"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Academic Year + Passport Photo
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text("academicYear".tr(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const SizedBox(width: 5),
                        Text("from".tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          hint: Text("y".tr()),
                          value: fromYear,
                          onChanged: (value) => setState(() => fromYear = value),
                          items: _adminStartYear != null && fromYear != null
                              ? [DropdownMenuItem(value: fromYear, child: Text(fromYear!))]
                              : <DropdownMenuItem<String>>[],
                        ),
                        const SizedBox(width: 8),
                        Text("to".tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          hint: Text("y".tr()),
                          value: toYear,
                          onChanged: (value) => setState(() => toYear = value),
                          items: _adminEndYear != null && toYear != null
                              ? [DropdownMenuItem(value: toYear, child: Text(toYear!))]
                              : <DropdownMenuItem<String>>[],
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            ),
            if (_formSubmitted && (fromYear == null || toYear == null))
              Padding(
                padding: const EdgeInsets.only(left: 140, top: 4),
                child: Text(
                  tr('academicYearRequired'),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 16),
            Text("studentEnrollment".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _buildHorizontalDropdown(
                "cYear".tr(),
                selectedCourseYear,
                courseYears,
                    (value) {
                  setState(() => selectedCourseYear = value);
                },
                icon: Icons.school,
                isRequired: true
            ),
            if (_formSubmitted && (selectedCourseYear == null || selectedCourseYear!.isEmpty))
              Padding(
                padding: const EdgeInsets.only(left: 140, top: 4),
                child: Text(
                  tr('courseYearRequired'),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            // FIXED: Roll Number Field - Read Only
            _buildHorizontalTextField(
              "rollNo".tr(),
              rollNoController,
              icon: Icons.badge,
              isRequired: true,
              readOnly: true,
            ),

            _buildHorizontalTextField(
              "registrationNo".tr(),
              registrationNoController,
              icon: Icons.confirmation_num,
            ),
            if (_formSubmitted && registrationNoController.text.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 140, top: 4),
                child: Text(
                  tr('registrationNoRequired'),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            _buildHorizontalTextField(
                "yearOfUni".tr(), yearOfUniversityController,
                icon: Icons.perm_contact_cal_outlined,
                isRequired: true),
            if (_formSubmitted && yearOfUniversityController.text.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 140, top: 4),
                child: Text(
                  tr('yearOfUniRequired'),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 35),

            // Student Information Section
            _buildInfoSection(
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
              onUpdate: (val1, val2, val3, val4, val5) {
                setState(() {
                  studentInProcess = val1;
                  studentSelectedNRCType = val2;
                  studentSelectedStateDivisionCode = val3;
                  studentSelectedTownshipCode = val4;
                  studentSelectedNRCTypeCode = val5;
                });
              },
              isStudentSection: true,
              formSubmitted: _formSubmitted,
            ),

            const SizedBox(height: 35),
            // Father's Information Section
            _buildInfoSection(
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
              onUpdate: (val1, val2, val3, val4, val5) {
                setState(() {
                  //fatherInProcess = val1;
                  fatherSelectedNRCType = val2;
                  fatherSelectedStateDivisionCode = val3;
                  fatherSelectedTownshipCode = val4;
                  fatherSelectedNRCTypeCode = val5;
                });
              },
              formSubmitted: _formSubmitted,
            ),

            const SizedBox(height: 35),
            // Mother's Information Section
            _buildInfoSection(
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
              onUpdate: (val1, val2, val3, val4, val5) {
                setState(() {
                  motherInProcess = val1;
                  motherSelectedNRCType = val2;
                  motherSelectedStateDivisionCode = val3;
                  motherSelectedTownshipCode = val4;
                  motherSelectedNRCTypeCode = val5;
                });
              },
              formSubmitted: _formSubmitted,
            ),

            const SizedBox(height: 35),
            const SizedBox(height: 20),
            Center(
              child: ActionButton(
                text:"payment".tr(),
                onPressed: _submitForm,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalDropdown(
      String label,
      String? selectedValue,
      List<String> items,
      ValueChanged<String?> onChanged, {
        IconData? icon,
        bool isRequired = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 45,
              child: InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.lightBlue[100],
                  prefixIcon: icon != null ? Icon(icon) : null,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  border: const OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedValue,
                    isExpanded: true,
                    onChanged: onChanged,
                    items: items
                        .map((y) => DropdownMenuItem(
                      value: y,
                      child: Text(y),
                    ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Updated _buildHorizontalTextField to accept readOnly parameter
  Widget _buildHorizontalTextField(
      String label,
      TextEditingController controller, {
        IconData? icon,
        bool isRequired = false,
        TextInputType keyboardType = TextInputType.text,
        int? maxLength,
        List<TextInputFormatter>? inputFormatters,
        String? Function(String?)? validator,
        bool readOnly = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 45,
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLength: maxLength,
                inputFormatters: inputFormatters,
                readOnly: readOnly,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: readOnly ? Colors.grey[200] : Colors.lightBlue[100],
                  prefixIcon: icon != null ? Icon(icon) : null,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  border: const OutlineInputBorder(),
                  counterText: "",
                  errorText: _formSubmitted && validator != null
                      ? validator(controller.text)
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MODIFIED: Added maxAgeYears parameter for student DOB restriction
  Widget _buildDateOfBirthField({
    required TextEditingController controller,
    bool isRequired = false,
    int? maxAgeYears,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "bDate".tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 45,
              child: TextField(
                controller: controller,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.lightBlue[100],
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                ),
                onTap: () async {
                  DateTime lastDate = DateTime.now();
                  if (maxAgeYears != null) {
                    lastDate = DateTime(
                      DateTime.now().year - maxAgeYears,
                      DateTime.now().month,
                      DateTime.now().day,
                    );
                  }

                  DateTime initialDate = DateTime(2000);
                  if (initialDate.isAfter(lastDate)) {
                    initialDate = lastDate;
                  }

                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1950),
                    lastDate: lastDate,
                  );
                  if (pickedDate != null) {
                    controller.text =
                    "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "gender".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value!;
                          });
                        },
                      ),
                      Flexible(
                        child: Text("male".tr(), overflow: TextOverflow.ellipsis),
                      ),
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
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value!;
                          });
                        },
                      ),
                      Flexible(
                        child: Text("female".tr(), overflow: TextOverflow.ellipsis),
                      ),
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

  Widget _buildInfoSection({
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
          padding: const EdgeInsets.all(8),
          child: Text(title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        _buildHorizontalTextField("mName".tr(), nameMyanmarController,
            icon: Icons.person, isRequired: true),
        if (formSubmitted && nameMyanmarController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 140, top: 4),
            child: Text(
              tr('nameMyanmarRequired'),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        _buildHorizontalTextField("eName".tr(), nameEnglishController,
            icon: Icons.person_outline, isRequired: true),
        if (formSubmitted && nameEnglishController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 140, top: 4),
            child: Text(
              tr('nameEnglishRequired'),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        _buildHorizontalTextField("religion".tr(), religionController,
            icon: Icons.temple_buddhist, isRequired: true),
        if (formSubmitted && religionController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 140, top: 4),
            child: Text(
              tr('religionRequired'),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        _buildHorizontalTextField(
          "phoneNo".tr(),
          phoneController,
          icon: Icons.phone,
          isRequired: true,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (cleanPhone.length < 9 || cleanPhone.length > 11) {
                return "phoneMustBe9to11Digits".tr();
              }
            }
            return null;
          },
        ),
        if (formSubmitted && phoneController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 140, top: 4),
            child: Text(
              tr('phoneRequired'),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        // Date of Birth field - with age restriction for student only
        isStudentSection
            ? _buildDateOfBirthField(
          controller: dobController,
          isRequired: true,
          maxAgeYears: 16,
        )
            : _buildDateOfBirthField(
          controller: dobController,
          isRequired: true,
        ),
        if (formSubmitted && dobController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 140, top: 4),
            child: Text(
              tr('dobRequired'),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        _buildHorizontalTextField("address".tr(), addressController,
            icon: Icons.home_work_outlined, isRequired: true),
        if (formSubmitted && addressController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 140, top: 4),
            child: Text(
              tr('addressRequired'),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        if (isStudentSection) _buildGenderSelector(),

        const SizedBox(height: 20),
        // Pass isStudentSection to determine whether to show "In process" checkbox
        _buildParentNRCSection(
          inProcess: inProcess,
          selectedNRCType: selectedNRCType,
          selectedStateDivisionCode: selectedStateDivisionCode,
          selectedTownshipCode: selectedTownshipCode,
          selectedNRCTypeCode: selectedNRCTypeCode,
          nrcController: nrcController,
          onUpdate: onUpdate,
          formSubmitted: formSubmitted,
          showInProcessCheckbox: isStudentSection, // Only show checkbox for student section
        ),
      ],
    );
  }

// Modified NRC section with optional "In process" checkbox
  Widget _buildParentNRCSection({
    required bool inProcess,
    required NRCType selectedNRCType,
    required String? selectedStateDivisionCode,
    required String? selectedTownshipCode,
    required String? selectedNRCTypeCode,
    required TextEditingController nrcController,
    required Function(bool, NRCType, String?, String?, String?) onUpdate,
    required bool formSubmitted,
    bool showInProcessCheckbox = true, // New parameter
  }) {
    // Get townships based on selected state/division
    List<String> availableTownships = getTownshipsForState(selectedStateDivisionCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NRC Button and optional In Process checkbox row
        Row(
          children: [
            ElevatedButton(
              onPressed: () => onUpdate(
                false,
                NRCType.nrc,
                selectedStateDivisionCode,
                selectedTownshipCode,
                selectedNRCTypeCode,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedNRCType == NRCType.nrc
                    ? Colors.lightBlue[100]
                    : null,
              ),
              child: Text("nrc".tr()),
            ),
            // Only show the "In Process" checkbox if showInProcessCheckbox is true
            if (showInProcessCheckbox) ...[
              const SizedBox(width: 16),
              Row(
                children: [
                  Checkbox(
                    value: inProcess,
                    onChanged: _studentDataFound
                        ? null
                        : (val) {
                      onUpdate(val ?? false, NRCType.none, null, null, null);
                      if (val == true) {
                        nrcController.clear();
                      }
                    },
                  ),
                  Text(
                    "inProcess".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),

        const SizedBox(height: 10),

        // NRC input - Only show if NRC is selected and NOT in process
        // For parent sections (showInProcessCheckbox = false), inProcess is always false
        if (selectedNRCType == NRCType.nrc && !inProcess)
          AbsorbPointer(
            absorbing: _studentDataFound,
            child: Column(
              children: [
                Row(
                  children: [
                    // State/Division dropdown
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        decoration: dropdownDecoration(),
                        value: selectedStateDivisionCode,
                        items: stateDivisionCodes
                            .map((code) => DropdownMenuItem(
                          value: code,
                          child: Text(code),
                        ))
                            .toList(),
                        onChanged: (val) {
                          // When state changes, clear township and update
                          onUpdate(inProcess, selectedNRCType, val, null, selectedNRCTypeCode);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Township dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        decoration: dropdownDecoration(),
                        value: selectedTownshipCode,
                        items: availableTownships
                            .map((code) => DropdownMenuItem(
                          value: code,
                          child: Text(code),
                        ))
                            .toList(),
                        onChanged: (val) => onUpdate(inProcess, selectedNRCType,
                            selectedStateDivisionCode, val, selectedNRCTypeCode),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // NRC Type dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        decoration: dropdownDecoration(),
                        value: selectedNRCTypeCode,
                        items: nrcTypeCodes
                            .map((type) => DropdownMenuItem(
                          value: type['code'],
                          child: Text("${type['code']} - ${type['myanmar']}"),
                        ))
                            .toList(),
                        onChanged: (val) => onUpdate(
                            inProcess,
                            selectedNRCType,
                            selectedStateDivisionCode,
                            selectedTownshipCode,
                            val),
                      ),
                    ),
                  ],
                ),

                // Validation errors for NRC dropdowns
                if (formSubmitted && !inProcess)
                  Column(
                    children: [
                      if (selectedStateDivisionCode == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tr('stateDivisionRequired'),
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      if (selectedTownshipCode == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tr('townshipRequired'),
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      if (selectedNRCTypeCode == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tr('nrcTypeRequired'),
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),

                const SizedBox(height: 10),
                // NRC Number field
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    height: 45,
                    child: TextFormField(
                      controller: nrcController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: Colors.lightBlue[100],
                        prefixIcon: const Icon(Icons.badge),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        border: const OutlineInputBorder(),
                        errorText: nrcController.text.isNotEmpty &&
                            nrcController.text.length != 6
                            ? "nrcMustBe6Digits".tr()
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ),

                // Validation error for NRC number
                if (formSubmitted && nrcController.text.trim().isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tr('nrcNumberRequired'),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                if (formSubmitted && nrcController.text.trim().isNotEmpty && nrcController.text.trim().length != 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tr('nrcMustBe6Digits'),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

              ],
            ),
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
        print('Admin academic year document does not exist');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching admin academic year data: $e');
    }
  }

  void _submitForm() async {
    if (_isSubmitting) return;

    setState(() {
      _formSubmitted = true;
      _isSubmitting = true;
    });

    if (!_validateForm()) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    if (fromYear != null && toYear != null) {
      int start = int.parse(fromYear!);
      int end = int.parse(toYear!);

      if (start >= end) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('startYearMustBeBeforeEndYear'))),
        );
        setState(() {
          _isSubmitting = false;
        });
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
          // In _submitForm method, update the parents section:
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
              "fnrc_in_process": false, // Always false for parents
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
              "mnrc_in_process": false, // Always false for parents
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

        // FIXED: Pass courseYear parameter when navigating to payment
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewStudentPhotoUpload(
              studentData: {}, // Pass courseYear here
              rollNo: rollNoController.text.trim(),
              studentName: nameEnglishController.text.trim(),
              courseYear: selectedCourseYear,

            ),
          ),
        );

      } catch (e) {
        print("Firebase Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${tr('enrollmentError')}: $e")),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _formSubmitted = false;
      fromYear = null;
      toYear = null;
      selectedCourseYear = null;
      rollNoController.clear();
      registrationNoController.clear();
      yearOfUniversityController.clear();
      nameMyanmarController.clear();
      nameEnglishController.clear();
      religionController.clear();
      phoneController.clear();
      dobController.clear();
      nrcNumberController.clear();
      addressController.clear();
      selectedGender = 'Male';
      studentInProcess = false;
      studentSelectedNRCType = NRCType.nrc;
      studentSelectedStateDivisionCode = null;
      studentSelectedTownshipCode = null;
      studentSelectedNRCTypeCode = null;
      fatherNameMyanmarController.clear();
      fatherNameEnglishController.clear();
      fatherReligionController.clear();
      fatherPhoneController.clear();
      fatherDobController.clear();
      fatherNRCController.clear();
      fatherAddressController.clear();
      fatherInProcess = false;
      fatherSelectedNRCType = NRCType.nrc;
      fatherSelectedStateDivisionCode = null;
      fatherSelectedTownshipCode = null;
      fatherSelectedNRCTypeCode = null;
      motherNameMyanmarController.clear();
      motherNameEnglishController.clear();
      motherReligionController.clear();
      motherPhoneController.clear();
      motherDobController.clear();
      motherNRCController.clear();
      motherAddressController.clear();
      motherInProcess = false;
      motherSelectedNRCType = NRCType.nrc;
      motherSelectedStateDivisionCode = null;
      motherSelectedTownshipCode = null;
      motherSelectedNRCTypeCode = null;
    });
  }
}