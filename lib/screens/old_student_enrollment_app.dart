import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';
import 'my_drawer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:miit_project/screens/old_student_payment.dart';
import 'old_stu_photo.dart';

enum NRCType { nrc, oldNrc, none }

class OldStudentEnrollmentApp extends StatefulWidget {
  final Map<String, dynamic>? studentData;
  final String? studentId;

  const OldStudentEnrollmentApp({
    Key? key,
    this.studentData,
    this.studentId,
  }) : super(key: key);

  @override
  State<OldStudentEnrollmentApp> createState() => _OldStudentEnrollmentAppState();
}

class _OldStudentEnrollmentAppState extends State<OldStudentEnrollmentApp> {
  List<Map<String, dynamic>> _examResults = [];

  // Define the list of majors for the dropdown
  final List<String> _majorList = ['CSE', 'ECE'];
  List<String?> _selectedMajors = [];

  bool studentInProcess = false;
  NRCType studentSelectedNRCType = NRCType.nrc;

  final List<String> years = List.generate(10, (index) => (2025 + index).toString());

  @override
  void initState() {
    super.initState();
    _selectedMajors = List.filled(_semesterList.length, null);
    for (int i = 0; i < _semesterList.length; i++) {
      _yearControllers.add(TextEditingController());
      _gradeControllers.add(TextEditingController());
    }
    _populateFormData();
  }

  String? fromYear;
  String? toYear;
  int? _adminStartYear;
  int? _adminEndYear;
  String selectedGender = 'Male';

  final List<String> courseYears = [
    "secYear".tr(),
    "thirdYear".tr(),
    "fourthYear".tr(),
    "finalYear".tr(),
    "master2".tr(),
  ];

  String? selectedCourseYear;

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
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController fatherContactController = TextEditingController();
  final TextEditingController motherContactController = TextEditingController();
  final TextEditingController academicYearController = TextEditingController();

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

  final List<String> _semesterList = [
    "1year1sem".tr(),
    "1year2sem".tr(),
    "2year1sem".tr(),
    "2year2sem".tr(),
    "3year1sem".tr(),
    "3year2sem".tr(),
    "4year1sem".tr(),
    "4year2sem".tr(),
    "final1sem".tr(),
    "final2sem".tr(),
    "master1sem".tr(),
    "master2sem".tr(),
    "master2year1sem".tr(),
    "master2year2sem".tr(),
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
    for (var controller in _yearControllers) {
      controller.dispose();
    }
    for (var controller in _gradeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  final Color _dimTextColor = Colors.grey[600]!;

  InputDecoration dropdownDecoration({bool isReadOnly = false}) => InputDecoration(
    filled: true,
    fillColor: Colors.lightBlue[100],
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
  );

  // Helper method for responsive width
  double _getLabelWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return 110;
    if (screenWidth < 400) return 130;
    return 140;
  }

  // Helper method for responsive text size
  double _getResponsiveTextSize(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return size * 0.85;
    if (screenWidth < 400) return size * 0.9;
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final labelWidth = _getLabelWidth(context);
    final textScale = _getResponsiveTextSize(context, 1.0);

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
                      width: screenWidth < 360 ? 40 : 50,
                      height: screenWidth < 360 ? 40 : 50,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr("enrollment"),
                style: AppTextStyles.heading.copyWith(
                  fontSize: screenWidth < 360 ? 18 : 20,
                ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth < 360 ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Academic Year + Passport Photo
            // In the build method, replace the academic year section with this original Row layout:

// Academic Year Row - KEPT EXACTLY AS ORIGINAL
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
                          onChanged: _studentDataFound ? null : (value) =>
                              setState(() => fromYear = value),
                          items: _adminStartYear != null && fromYear != null
                              ? [DropdownMenuItem(
                              value: fromYear, child: Text(fromYear!))
                          ]
                              : <DropdownMenuItem<String>>[],
                        ),
                        const SizedBox(width: 8),
                        Text("to".tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          hint: Text("y".tr()),
                          value: toYear,
                          onChanged: _studentDataFound ? null : (value) =>
                              setState(() => toYear = value),
                          items: _adminEndYear != null && toYear != null
                              ? [DropdownMenuItem(
                              value: toYear, child: Text(toYear!))
                          ]
                              : <DropdownMenuItem<String>>[],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text("studentEnrollment".tr(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth < 360 ? 16 : 18)),
            const SizedBox(height: 16),

            _buildHorizontalDropdown(
              "cYear".tr(),
              selectedCourseYear,
              courseYears,
                  (value) {
                setState(() => selectedCourseYear = value);
              },
              icon: Icons.school,
              isRequired: true,
              isEditableField: true,
              labelWidth: labelWidth,
            ),

            _buildHorizontalTextField("rollNo".tr(), rollNoController,
                icon: Icons.badge, labelWidth: labelWidth),
            _buildHorizontalTextField(
              "registrationNo".tr(),
              registrationNoController,
              icon: Icons.confirmation_num,
              labelWidth: labelWidth,
            ),
            _buildHorizontalTextField(
                "yearOfUni".tr(), yearOfUniversityController,
                icon: Icons.school, labelWidth: labelWidth),
            const SizedBox(height: 14),
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
              labelWidth: labelWidth,
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
                  fatherInProcess = val1;
                  fatherSelectedNRCType = val2;
                  fatherSelectedStateDivisionCode = val3;
                  fatherSelectedTownshipCode = val4;
                  fatherSelectedNRCTypeCode = val5;
                });
              },
              isStudentSection: false,
              labelWidth: labelWidth,
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
              isStudentSection: false,
              labelWidth: labelWidth,
            ),

            const SizedBox(height: 35),

            _buildExamInformationSection(),

            const SizedBox(height: 20),
            Center(
              child: _isSubmitting
                  ? CircularProgressIndicator()
                  : ActionButton(
                  text: "uploadPhoto".tr(),
                  onPressed: _submitForm
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalDropdown(String label,
      String? selectedValue,
      List<String> items,
      ValueChanged<String?> onChanged, {
        IconData? icon,
        bool isRequired = false,
        bool isReadOnly = false,
        bool isEditableField = false,
        required double labelWidth,
      }) {
    final bool isFieldReadOnly = (isReadOnly || _studentDataFound) &&
        !isEditableField;
    final screenWidth = MediaQuery.of(context).size.width;

    String? validSelectedValue;
    if (selectedValue != null && items.contains(selectedValue)) {
      validSelectedValue = selectedValue;
    } else if (selectedValue != null) {
      for (String item in items) {
        if (item == selectedValue ||
            item == selectedValue.tr() ||
            selectedValue == item.tr()) {
          validSelectedValue = item;
          break;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: screenWidth < 360 ? 12 : 14,
                    ),
                  ),
                  if (isRequired)
                    const TextSpan(
                      text: ' ***',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: screenWidth < 360 ? 40 : 45,
              child: InputDecorator(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.lightBlue[100],
                  prefixIcon: icon != null ? Icon(icon, size: screenWidth < 360 ? 18 : 24) : null,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: screenWidth < 360 ? 8 : 12,
                      horizontal: 8
                  ),
                  border: const OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: validSelectedValue,
                    isExpanded: true,
                    onChanged: isFieldReadOnly ? null : onChanged,
                    items: items
                        .map((y) =>
                        DropdownMenuItem(
                          value: y,
                          child: Text(
                            y,
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 12 : 14,
                              color: isFieldReadOnly ? _dimTextColor : null,
                            ),
                          ),
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

  Widget _buildHorizontalTextField(String label,
      TextEditingController controller, {
        IconData? icon,
        bool isRequired = false,
        bool isReadOnly = false,
        bool isEditableField = false,
        required double labelWidth,
      }) {
    final bool isFieldReadOnly = (isReadOnly ||
        (controller.text.isNotEmpty && _studentDataFound)) && !isEditableField;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: screenWidth < 360 ? 12 : 14,
                    ),
                  ),
                  if (isRequired)
                    const TextSpan(
                      text: ' ***',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: screenWidth < 360 ? 40 : 45,
              child: TextField(
                controller: controller,
                readOnly: isFieldReadOnly,
                style: TextStyle(
                  fontSize: screenWidth < 360 ? 12 : 14,
                  color: isFieldReadOnly ? _dimTextColor : null,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.lightBlue[100],
                  prefixIcon: icon != null ? Icon(icon, size: screenWidth < 360 ? 18 : 24) : null,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: screenWidth < 360 ? 8 : 12,
                      horizontal: 8
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateOfBirthField({required TextEditingController controller}) {
    final labelWidth = _getLabelWidth(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: labelWidth,
              child: Text("Date of Birth:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth < 360 ? 12 : 14))),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: screenWidth < 360 ? 40 : 45,
              child: TextField(
                controller: controller,
                readOnly: true,
                style: TextStyle(fontSize: screenWidth < 360 ? 12 : 14, color: _dimTextColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.lightBlue[100],
                  prefixIcon: Icon(Icons.calendar_today, size: screenWidth < 360 ? 18 : 24),
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      vertical: screenWidth < 360 ? 8 : 12,
                      horizontal: 8
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    final labelWidth = _getLabelWidth(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              "gender".tr(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth < 360 ? 12 : 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 5,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: 'Male',
                      groupValue: selectedGender,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: _studentDataFound
                          ? null
                          : (value) {
                        setState(() {
                          selectedGender = value!;
                        });
                      },
                    ),
                    Flexible(
                      child: Text(
                        "male".tr(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: screenWidth < 360 ? 12 : 14,
                          color: _studentDataFound ? _dimTextColor : null,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: 'Female',
                      groupValue: selectedGender,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: _studentDataFound
                          ? null
                          : (value) {
                        setState(() {
                          selectedGender = value!;
                        });
                      },
                    ),
                    Flexible(
                      child: Text(
                        "female".tr(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: screenWidth < 360 ? 12 : 14,
                          color: _studentDataFound ? _dimTextColor : null,
                        ),
                      ),
                    ),
                  ],
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
    required double labelWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.indigo,
          padding: const EdgeInsets.all(8),
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        _buildHorizontalTextField("mName".tr(), nameMyanmarController,
            icon: Icons.person, labelWidth: labelWidth),
        _buildHorizontalTextField("eName".tr(), nameEnglishController,
            icon: Icons.person_outline, labelWidth: labelWidth),
        _buildHorizontalTextField("religion".tr(), religionController,
            icon: Icons.favorite, labelWidth: labelWidth),
        _buildHorizontalTextField("phoneNo".tr(), phoneController,
            icon: Icons.phone, isRequired: true, isEditableField: true, labelWidth: labelWidth),
        _buildDateOfBirthField(controller: dobController),
        _buildHorizontalTextField("address".tr(), addressController,
            icon: Icons.home, isRequired: true, isEditableField: true, labelWidth: labelWidth),

        if (isStudentSection) _buildGenderSelector(),

        const SizedBox(height: 20),
        _buildParentNRCSection(
          inProcess: inProcess,
          selectedNRCType: selectedNRCType,
          selectedStateDivisionCode: selectedStateDivisionCode,
          selectedTownshipCode: selectedTownshipCode,
          selectedNRCTypeCode: selectedNRCTypeCode,
          nrcController: nrcController,
          onUpdate: onUpdate,
          isStudentSection: isStudentSection,
          labelWidth: labelWidth,
        ),
      ],
    );
  }

  Widget _buildParentNRCSection({
    required bool inProcess,
    required NRCType selectedNRCType,
    required String? selectedStateDivisionCode,
    required String? selectedTownshipCode,
    required String? selectedNRCTypeCode,
    required TextEditingController nrcController,
    required Function(bool, NRCType, String?, String?, String?) onUpdate,
    required bool isStudentSection,
    required double labelWidth,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isStudentSection)
          Column(
            children: [
              if (selectedNRCType == NRCType.nrc && !inProcess)
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: screenWidth < 360 ? 1 : 1,
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            child: DropdownButtonFormField<String>(
                              decoration: dropdownDecoration(),
                              value: selectedStateDivisionCode,
                              isExpanded: true,
                              items: stateDivisionCodes
                                  .map(
                                    (state) => DropdownMenuItem(
                                  value: state,
                                  child: Text(
                                    state,
                                    style: TextStyle(fontSize: screenWidth < 360 ? 11 : 14),
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: _studentDataFound
                                  ? null
                                  : (val) {
                                onUpdate(
                                  inProcess,
                                  selectedNRCType,
                                  val,
                                  null,
                                  selectedNRCTypeCode,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: screenWidth < 360 ? 2 : 2,
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            child: DropdownButtonFormField<String>(
                              decoration: dropdownDecoration(),
                              value: selectedTownshipCode,
                              isExpanded: true,
                              items: (townshipCodes[selectedStateDivisionCode] ?? [])
                                  .map(
                                    (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: TextStyle(fontSize: screenWidth < 360 ? 11 : 14),
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: _studentDataFound
                                  ? null
                                  : (val) {
                                onUpdate(
                                  inProcess,
                                  selectedNRCType,
                                  selectedStateDivisionCode,
                                  val,
                                  selectedNRCTypeCode,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: screenWidth < 360 ? 1 : 1,
                          child: DropdownButtonFormField<String>(
                            decoration: dropdownDecoration(),
                            value: selectedNRCTypeCode,
                            isExpanded: true,
                            items: nrcTypeCodes
                                .map(
                                  (t) => DropdownMenuItem(
                                value: t['code'],
                                child: Text(
                                  t['code'] ?? '',
                                  style: TextStyle(fontSize: screenWidth < 360 ? 11 : 14),
                                ),
                              ),
                            )
                                .toList(),
                            onChanged: _studentDataFound
                                ? null
                                : (val) {
                              onUpdate(
                                inProcess,
                                selectedNRCType,
                                selectedStateDivisionCode,
                                selectedTownshipCode,
                                val,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: nrcController,
                      readOnly: _studentDataFound,
                      style: TextStyle(
                        fontSize: screenWidth < 360 ? 12 : 14,
                        color: _studentDataFound ? _dimTextColor : null,
                      ),
                      decoration: InputDecoration(
                        hintText: "nrcNumber".tr(),
                        filled: true,
                        fillColor: Colors.lightBlue[100],
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: screenWidth < 360 ? 8 : 12,
                            horizontal: 8
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

        if (!isStudentSection)
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: screenWidth < 360 ? 1 : 1,
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: DropdownButtonFormField<String>(
                        decoration: dropdownDecoration(),
                        value: selectedStateDivisionCode,
                        isExpanded: true,
                        items: stateDivisionCodes
                            .map(
                              (state) => DropdownMenuItem(
                            value: state,
                            child: Text(
                              state,
                              style: TextStyle(fontSize: screenWidth < 360 ? 11 : 14),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: _studentDataFound
                            ? null
                            : (val) {
                          onUpdate(
                            inProcess,
                            selectedNRCType,
                            val,
                            null,
                            selectedNRCTypeCode,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: screenWidth < 360 ? 2 : 2,
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: DropdownButtonFormField<String>(
                        decoration: dropdownDecoration(),
                        value: selectedTownshipCode,
                        isExpanded: true,
                        items: (townshipCodes[selectedStateDivisionCode] ?? [])
                            .map(
                              (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t,
                              style: TextStyle(fontSize: screenWidth < 360 ? 11 : 14),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: _studentDataFound
                            ? null
                            : (val) {
                          onUpdate(
                            inProcess,
                            selectedNRCType,
                            selectedStateDivisionCode,
                            val,
                            selectedNRCTypeCode,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: screenWidth < 360 ? 1 : 1,
                    child: DropdownButtonFormField<String>(
                      decoration: dropdownDecoration(),
                      value: selectedNRCTypeCode,
                      isExpanded: true,
                      items: nrcTypeCodes
                          .map(
                            (t) => DropdownMenuItem(
                          value: t['code'],
                          child: Text(
                            t['code'] ?? '',
                            style: TextStyle(fontSize: screenWidth < 360 ? 11 : 14),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: _studentDataFound
                          ? null
                          : (val) {
                        onUpdate(
                          inProcess,
                          selectedNRCType,
                          selectedStateDivisionCode,
                          selectedTownshipCode,
                          val,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              TextField(
                controller: nrcController,
                readOnly: _studentDataFound,
                style: TextStyle(
                  fontSize: screenWidth < 360 ? 12 : 14,
                  color: _studentDataFound ? _dimTextColor : null,
                ),
                decoration: InputDecoration(
                  hintText: "nrcNumber".tr(),
                  filled: true,
                  fillColor: Colors.lightBlue[100],
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      vertical: screenWidth < 360 ? 8 : 12,
                      horizontal: 8
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _getRawValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  List<TextEditingController> _yearControllers = [];
  List<TextEditingController> _gradeControllers = [];

  String _getStringValue(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) {
      try {
        return value.toDate().toString();
      } catch (e) {
        return value.toString();
      }
    }
    return value.toString();
  }

  String? _getNullableString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  Map<String, dynamic>? _getMapValue(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        print('Error converting map: $e');
        return null;
      }
    }
    return null;
  }

  Widget _buildExamInformationSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = screenWidth < 500 ? 100.0 : 150.0;
    const fixedColumns = {
      0: FixedColumnWidth(150.0),
      1: FixedColumnWidth(180.0),
      2: FixedColumnWidth(120.0),
      3: FixedColumnWidth(120.0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.indigo,
          padding: const EdgeInsets.all(8),
          child: Text(
            "examResultInformation".tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('exams')
                .doc(widget.studentId ?? rollNoController.text.trim())
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "noExamDataFound".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: screenWidth < 360 ? 12 : 14),
                  ),
                );
              }

              final data = snapshot.data!.data();
              if (data == null) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "noExamDataFound".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: screenWidth < 360 ? 12 : 14),
                  ),
                );
              }

              try {
                Map<String, dynamic> examData = {};
                if (data is Map<String, dynamic>) {
                  examData = data;
                } else {
                  examData = Map<String, dynamic>.from(data as Map);
                }

                final years = examData.entries.where((entry) {
                  return entry.key != 'uid' &&
                      entry.key != 'studentId' &&
                      entry.key != 'createdAt' &&
                      entry.key != 'updatedAt';
                }).toList();

                if (years.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "noExamDataFound".tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: screenWidth < 360 ? 12 : 14),
                    ),
                  );
                }

                List<TableRow> tableRows = [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                    ),
                    children: [
                      "year".tr(),
                      "semester".tr(),
                      "CGPA".tr(),
                      "SGPA".tr(),
                    ].map((columnName) {
                      return Padding(
                        padding: EdgeInsets.all(screenWidth < 360 ? 6.0 : 12.0),
                        child: Text(
                          columnName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: screenWidth < 360 ? 11 : 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  ),
                ];

                for (final yearEntry in years) {
                  if (yearEntry.value is Map<String, dynamic>) {
                    final yearMap = yearEntry.value as Map<String, dynamic>;

                    for (final semesterEntry in yearMap.entries) {
                      if (semesterEntry.value is Map<String, dynamic>) {
                        final semesterData = semesterEntry.value as Map<String, dynamic>;

                        tableRows.add(
                          TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(screenWidth < 360 ? 6.0 : 12.0),
                                child: Text(
                                  _formatYearText(yearEntry.key),
                                  style: TextStyle(
                                    fontSize: screenWidth < 360 ? 11 : 14,
                                    color: _studentDataFound ? _dimTextColor : null,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(screenWidth < 360 ? 6.0 : 12.0),
                                child: Text(
                                  _formatSemesterText(semesterEntry.key),
                                  style: TextStyle(
                                    fontSize: screenWidth < 360 ? 11 : 14,
                                    color: _studentDataFound ? _dimTextColor : null,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(screenWidth < 360 ? 6.0 : 12.0),
                                child: Text(
                                  semesterData['CGPA']?.toString() ?? '—',
                                  style: TextStyle(
                                    fontSize: screenWidth < 360 ? 11 : 14,
                                    color: _studentDataFound ? _dimTextColor : null,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(screenWidth < 360 ? 6.0 : 12.0),
                                child: Text(
                                  semesterData['SGPA']?.toString() ?? '—',
                                  style: TextStyle(
                                    fontSize: screenWidth < 360 ? 11 : 14,
                                    color: _studentDataFound ? _dimTextColor : null,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  }
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Table(
                      border: TableBorder.all(color: Colors.grey, width: 1.0),
                      defaultColumnWidth: FixedColumnWidth(columnWidth),
                      columnWidths: {
                        0: FixedColumnWidth(screenWidth < 360 ? 120.0 : 150.0),
                        1: FixedColumnWidth(screenWidth < 360 ? 140.0 : 180.0),
                        2: FixedColumnWidth(screenWidth < 360 ? 90.0 : 120.0),
                        3: FixedColumnWidth(screenWidth < 360 ? 90.0 : 120.0),
                      },
                      children: tableRows,
                    ),
                  ),
                );
              } catch (e, stackTrace) {
                print('Error building exam table: $e');
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Error loading exam data".tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[600], fontSize: screenWidth < 360 ? 12 : 14),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Error: ${e.toString()}",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: screenWidth < 360 ? 10 : 12),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _formatYearText(String yearKey) {
    switch (yearKey) {
      case 'firstYear':
        return "First Year";
      case 'secondYear':
        return "Second Year";
      case 'thirdYear':
        return "Third Year";
      case 'fourthYear':
        return "Fourth Year";
      case 'finalYear':
        return "Final Year";
      case 'master1':
        return "Master First Year";
      case 'master2':
        return "Master Second Year";
      default:
        return yearKey;
    }
  }

  String _formatSemesterText(String semesterKey) {
    switch (semesterKey) {
      case 'firstSemester':
        return "First Semester";
      case 'secondSemester':
        return "Second Semester";
      default:
        return semesterKey;
    }
  }

  Future<void> _submitForm() async {
    if (selectedCourseYear == null || selectedCourseYear!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select course year".tr())),
      );
      return;
    }

    if (rollNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter roll number".tr())),
      );
      return;
    }

    final String rollNo = rollNoController.text.trim();
    final String studentName = nameEnglishController.text.trim();
    final String courseYear = selectedCourseYear!;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _saveStudentDataToFirebase(rollNo);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OldStudentPhotoUpload(
            rollNo: rollNo,
            studentName: studentName,
            courseYear: courseYear,
            studentData: {
              'rollNo': rollNo,
              'srollno': rollNo,
              'studentName': studentName,
              'sname': studentName,
              'courseYear': courseYear,
              ...?widget.studentData,
            },
            studentId: widget.studentId ?? '',
          ),
        ),
      );
    } catch (e) {
      print('Error saving student data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e".tr())),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _saveStudentDataToFirebase(String rollNo) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = Timestamp.now();

      String academicYearStr = '${_adminStartYear ?? 2024}-${_adminEndYear ?? 2025}';

      if (academicYearController.text.isNotEmpty) {
        academicYearStr = academicYearController.text.trim();
      }

      int? parsedStartYear;
      int? parsedEndYear;

      final parts = academicYearStr.split('-');
      if (parts.length == 2) {
        parsedStartYear = int.tryParse(parts[0].trim());
        parsedEndYear = int.tryParse(parts[1].trim());
      }

      if (parsedStartYear != null && parsedEndYear != null) {
        await firestore.collection('admin_academic_year').doc('admin').set({
          'academicYear': academicYearStr,
          'astart_year': parsedStartYear,
          'aend_year': parsedEndYear,
          'updatedAt': now,
        }, SetOptions(merge: true));

        print('✅ Updated admin academic year: $academicYearStr');
      }

      Map<String, dynamic> studentData = {
        'srollno': rollNo,
        'sname_myanmar': nameMyanmarController.text.trim(),
        'sname': nameEnglishController.text.trim(),
        'sreligion': religionController.text.trim(),
        'scontactNumber': phoneController.text.trim(),
        'sdob': dobController.text.trim(),
        'sgender': selectedGender,
        'saddress': addressController.text.trim(),
        'snrc': nrcNumberController.text.trim(),
        'snrc_state_division': studentSelectedStateDivisionCode,
        'snrc_township': studentSelectedTownshipCode,
        'snrc_type': studentSelectedNRCTypeCode,
        'snrc_in_process': studentInProcess,
        'academicInfo': {
          'registrationNumber': registrationNoController.text.trim(),
          'yearOfUniversity': yearOfUniversityController.text.trim(),
          'courseYear': selectedCourseYear,
          'academicYear': '${_adminStartYear ?? 2024}-${_adminEndYear ?? 2025}',
          'start_year': parsedStartYear ?? _adminStartYear,
          'end_year': parsedEndYear ?? _adminEndYear,
          'enrollStatus': 'incomplete',
          'updatedAt': now,
        },
        'parents': {
          'father': {
            'fname_mm': fatherNameMyanmarController.text.trim(),
            'fname_eng': fatherNameEnglishController.text.trim(),
            'freligion': fatherReligionController.text.trim(),
            'fphone': fatherPhoneController.text.trim(),
            'fdob': fatherDobController.text.trim(),
            'fnrc': fatherNRCController.text.trim(),
            'faddress': fatherAddressController.text.trim(),
            'fnrc_state_division': fatherSelectedStateDivisionCode,
            'fnrc_township': fatherSelectedTownshipCode,
            'fnrc_type': fatherSelectedNRCTypeCode,
            'fnrc_in_process': fatherInProcess,
          },
          'mother': {
            'mname_mm': motherNameMyanmarController.text.trim(),
            'mname_eng': motherNameEnglishController.text.trim(),
            'mreligion': motherReligionController.text.trim(),
            'mphone': motherPhoneController.text.trim(),
            'mdob': motherDobController.text.trim(),
            'mnrc': motherNRCController.text.trim(),
            'maddress': motherAddressController.text.trim(),
            'mnrc_state_division': motherSelectedStateDivisionCode,
            'mnrc_township': motherSelectedTownshipCode,
            'mnrc_type': motherSelectedNRCTypeCode,
            'mnrc_in_process': motherInProcess,
          },
        },
        'stype': 'old',
        'updatedAt': now,
        'lastUpdated': now,
      };

      if (!_studentDataFound) {
        studentData['createdAt'] = now;
        studentData['uid'] = FirebaseAuth.instance.currentUser?.uid ?? '';
      }

      await firestore.collection('students').doc(rollNo).set(studentData, SetOptions(merge: true));
      print('✅ Student data saved to Firebase: $rollNo');

      await firestore.collection('student_academic_years').doc(rollNo).set({
        'academicYear': '${_adminStartYear ?? 2024}-${_adminEndYear ?? 2025}',
        'start_year': _adminStartYear ?? 2024,
        'end_year': _adminEndYear ?? 2025,
        'studentId': rollNo,
        'studentName': nameEnglishController.text.trim(),
        'courseYear': selectedCourseYear,
        'updatedAt': now,
      }, SetOptions(merge: true));

      print('✅ Academic year info saved');
    } catch (e) {
      print('❌ Error saving to Firebase: $e');
      rethrow;
    }
  }

  bool _isSubmitting = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _studentDataFound = false;
  int? _studentYear;
  int? _adminYear;
  String? _studentUid;

  void _populateFormData() async {
    if (widget.studentData != null) {
      final data = widget.studentData!;
      await _fetchAdminAcademicYear();

      setState(() {
        _studentDataFound = true;
        _studentUid = _getStringValue(data['uid']);

        nameMyanmarController.text = _getStringValue(data['sname_myanmar']);
        nameEnglishController.text = _getStringValue(data['sname']);
        religionController.text = _getStringValue(data['sreligion']);
        dobController.text = _getStringValue(data['sdob']);
        nrcNumberController.text = _getStringValue(data['snrc']);
        selectedGender = _getStringValue(data['sgender']).isEmpty
            ? 'Male'
            : _getStringValue(data['sgender']);
        rollNoController.text = _getStringValue(data['srollno']);
        phoneController.text = _getStringValue(data['scontactNumber']);
        addressController.text = _getStringValue(data['saddress']);

        final stateDivisionFromDB = _getNullableString(
            data['snrc_state_division'] ??
                data['snrcStateDivision'] ??
                data['stateDivision'] ??
                data['state_division']);

        if (stateDivisionFromDB != null) {
          for (String stateDivision in stateDivisionCodes) {
            if (stateDivisionFromDB == stateDivision ||
                stateDivisionFromDB.tr() == stateDivision ||
                stateDivision == stateDivisionFromDB.tr()) {
              studentSelectedStateDivisionCode = stateDivision;
              break;
            }
          }
        }

        studentSelectedTownshipCode = _getNullableString(
            data['snrc_township'] ??
                data['snrcTownship'] ??
                data['township']);

        studentSelectedNRCTypeCode = _getNullableString(
            data['snrc_type'] ??
                data['snrcType'] ??
                data['nrc_type']);

        final academicInfo = _getMapValue(data['academicInfo']);
        if (academicInfo != null) {
          if (academicInfo['registrationNumber'] != null) {
            registrationNoController.text =
                _getStringValue(academicInfo['registrationNumber']);
          }
          if (academicInfo['yearOfUniversity'] != null) {
            yearOfUniversityController.text =
                _getStringValue(academicInfo['yearOfUniversity']);
            _studentYear =
                int.tryParse(_getStringValue(academicInfo['yearOfUniversity']));
          }

          if (academicInfo['courseYear'] != null) {
            final courseYearFromDB = _getStringValue(academicInfo['courseYear']);

            for (String courseYear in courseYears) {
              if (courseYearFromDB == courseYear ||
                  courseYearFromDB.tr() == courseYear ||
                  courseYear == courseYearFromDB.tr()) {
                selectedCourseYear = courseYear;
                break;
              }
            }

            if (selectedCourseYear == null && courseYearFromDB.isNotEmpty) {
              selectedCourseYear = courseYearFromDB;
            }
          }
        }

        final parents = _getMapValue(data['parents']);
        if (parents != null) {
          final father = _getMapValue(parents['father']);
          final mother = _getMapValue(parents['mother']);

          if (father != null) {
            fatherNameMyanmarController.text = _getStringValue(father['fname_mm']);
            fatherNameEnglishController.text = _getStringValue(father['fname_eng']);
            fatherReligionController.text = _getStringValue(father['freligion']);
            fatherDobController.text = _getStringValue(father['fdob']);
            fatherNRCController.text = _getStringValue(father['fnrc']);
            fatherPhoneController.text = _getStringValue(father['fphone']);
            fatherAddressController.text = _getStringValue(father['faddress']);

            final fatherStateDivisionFromDB = _getNullableString(
                father['fnrc_state_division'] ??
                    father['fnrcStateDivision'] ??
                    father['stateDivision']);

            if (fatherStateDivisionFromDB != null) {
              for (String stateDivision in stateDivisionCodes) {
                if (fatherStateDivisionFromDB == stateDivision ||
                    fatherStateDivisionFromDB.tr() == stateDivision ||
                    stateDivision == fatherStateDivisionFromDB.tr()) {
                  fatherSelectedStateDivisionCode = stateDivision;
                  break;
                }
              }
            }

            fatherSelectedTownshipCode = _getNullableString(
                father['fnrc_township'] ??
                    father['fnrcTownship'] ??
                    father['township']);

            fatherSelectedNRCTypeCode = _getNullableString(
                father['fnrc_type'] ??
                    father['fnrcType'] ??
                    father['nrc_type']);

            fatherInProcess = father['fnrc_in_process'] == true;
          }

          if (mother != null) {
            motherNameMyanmarController.text = _getStringValue(mother['mname_mm']);
            motherNameEnglishController.text = _getStringValue(mother['mname_eng']);
            motherReligionController.text = _getStringValue(mother['mreligion']);
            motherDobController.text = _getStringValue(mother['mdob']);
            motherNRCController.text = _getStringValue(mother['mnrc']);
            motherPhoneController.text = _getStringValue(mother['mphone']);
            motherAddressController.text = _getStringValue(mother['maddress']);

            final motherStateDivisionFromDB = _getNullableString(
                mother['mnrc_state_division'] ??
                    mother['mnrcStateDivision'] ??
                    mother['stateDivision']);

            if (motherStateDivisionFromDB != null) {
              for (String stateDivision in stateDivisionCodes) {
                if (motherStateDivisionFromDB == stateDivision ||
                    motherStateDivisionFromDB.tr() == stateDivision ||
                    stateDivision == motherStateDivisionFromDB.tr()) {
                  motherSelectedStateDivisionCode = stateDivision;
                  break;
                }
              }
            }

            motherSelectedTownshipCode = _getNullableString(
                mother['mnrc_township'] ??
                    mother['mnrcTownship'] ??
                    mother['township']);

            motherSelectedNRCTypeCode = _getNullableString(
                mother['mnrc_type'] ??
                    mother['mnrcType'] ??
                    mother['nrc_type']);

            motherInProcess = mother['mnrc_in_process'] == true;
          }
        }

        _isLoading = false;
      });
    } else {
      await _fetchAdminAcademicYear();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAdminAcademicYear() async {
    try {
      final academicYearDoc = await FirebaseFirestore.instance
          .collection('admin_academic_year')
          .doc('admin')
          .get();

      if (academicYearDoc.exists) {
        final academicYearData = academicYearDoc.data();
        final academicYear = academicYearData?['academicYear']?.toString();

        if (academicYear != null) {
          final parts = academicYear.split('-');
          if (parts.length == 2) {
            final startYear = parts[0].trim();
            final endYear = parts[1].trim();

            setState(() {
              _adminStartYear = int.tryParse(startYear);
              _adminEndYear = int.tryParse(endYear);
              fromYear = startYear;
              toYear = endYear;
            });
            return;
          }
        }

        final startYear = academicYearData?['astart_year']?.toString();
        final endYear = academicYearData?['aend_year']?.toString();

        if (startYear != null && endYear != null) {
          setState(() {
            _adminStartYear = int.tryParse(startYear);
            _adminEndYear = int.tryParse(endYear);
            fromYear = startYear;
            toYear = endYear;
          });
        }
      } else {
        print('Admin academic year document does not exist');
      }
    } catch (e) {
      print('Error fetching admin academic year data: $e');
    }
  }
}