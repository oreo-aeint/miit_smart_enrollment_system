import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';
import 'my_drawer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:miit_project/screens/old_student_payment.dart';

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
  // Define the list of majors for the dropdown
  final List<String> _majorList = ['CSE', 'ECE'];
  List<String?> _selectedMajors = [];
// This variable will hold the major chosen in the first row.
// It's declared at the level of your Widget's State class.

  bool studentInProcess = false;
  NRCType studentSelectedNRCType = NRCType.nrc;

  final List<String> years =
  List.generate(10, (index) => (2025 + index).toString());
  @override
  void initState() {
    super.initState();
    // Initialize the list with null values for all rows
    _populateFormData();
    _selectedMajors = List.filled(_semesterList.length, null);
    for (int i = 0; i < _semesterList.length; i++) {
      _yearControllers.add(TextEditingController());
      _gradeControllers.add(TextEditingController());
    }
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
    "master1".tr(),
    "master2".tr(),
  ];
  String? selectedCourseYear;





  // Student Controllers
  final TextEditingController courseYearController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController registrationNoController = TextEditingController();
  final TextEditingController yearOfUniversityController =
  TextEditingController();
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
  final TextEditingController fatherNameMyanmarController =
  TextEditingController();
  final TextEditingController fatherNameEnglishController =
  TextEditingController();
  final TextEditingController fatherReligionController =
  TextEditingController();
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
  final TextEditingController motherNameMyanmarController =
  TextEditingController();
  final TextEditingController motherNameEnglishController =
  TextEditingController();
  final TextEditingController motherReligionController =
  TextEditingController();
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
    "eight".tr(), // Magway
    "nine".tr(), // Mandalay
    "twelve".tr(), // Yangon
  ];

  // Fixed township codes with unique values
  final Map<String, List<String>> townshipCodes = {
    "nine".tr(): [
      // Mandalay
      "mdy1".tr(),
      "mdy2".tr(),
      "mdy3".tr(),
      "mdy4".tr(),
      "mdy5".tr(),
      "mdy6".tr(),
      "mdy7".tr(),
      "mdy8".tr(),
      "mdy9".tr(),
      "mdy10".tr(),
      "mdy11".tr(),
      "mdy12".tr(),
      "mdy13".tr(),
      "mdy14".tr(),
      "mdy15".tr(),
      "mdy16".tr(),
      "mdy17".tr(),
      "mdy18".tr(),
      "mdy19".tr(),
      "mdy20".tr(),
      "mdy21".tr(),
      "mdy22".tr(),
      "mdy23".tr(),
      "mdy24".tr(),
      "mdy25".tr(),
      "mdy26".tr(),
      "mdy27".tr(),
      "mdy28".tr(),
      "mdy29".tr(),
      "mdy30".tr(),
      "mdy31".tr(),
      "mdy32".tr(),
      "mdy33".tr(),
      "mdy34".tr(),
      "mdy35".tr(),
      "mdy36".tr(),
      "mdy37".tr(),
      "mdy38".tr(),
      "mdy39".tr(),
      "mdy40".tr(),
      "mdy41".tr(),
      "mdy42".tr(),
      "mdy43".tr(),
      "mdy44".tr(),
      "mdy45".tr(),
    ],
    "twelve".tr(): [
      // Yangon
      "ygn1".tr(),
      "ygn2".tr(),
      "ygn3".tr(),
      "ygn4".tr(),
      "ygn5".tr(),
      "ygn6".tr(),
      "ygn7".tr(),
      "ygn8".tr(),
      "ygn9".tr(),
      "ygn10".tr(),
      "ygn11".tr(),
      "ygn12".tr(),
      "ygn13".tr(),
      "ygn14".tr(),
      "ygn15".tr(),
      "ygn16".tr(),
      "ygn17".tr(),
      "ygn18".tr(),
      "ygn19".tr(),
      "ygn20".tr(),
      "ygn21".tr(),
      "ygn22".tr(),
      "ygn23".tr(),
      "ygn24".tr(),
      "ygn25".tr(),
      "ygn26".tr(),
      "ygn27".tr(),
      "ygn28".tr(),
      "ygn29".tr(),
      "ygn30".tr(),
      "ygn31".tr(),
      "ygn32".tr(),
      "ygn33".tr(),
      "ygn34".tr(),
      "ygn35".tr(),
      "ygn36".tr(),
      "ygn37".tr(),
      "ygn38".tr(),
      "ygn39".tr(),
      "ygn40".tr(),
      "ygn41".tr(),
      "ygn42".tr(),
      "ygn43".tr(),
      "ygn44".tr(),
      "ygn45".tr(),
      "ygn46".tr(),
    ],
    "eight".tr(): [
      // Magway
      "mg1".tr(),
      "mg2".tr(),
      "mg3".tr(),
      "mg4".tr(),
      "mg5".tr(),
      "mg6".tr(),
      "mg7".tr(),
      "mg8".tr(),
      "mg9".tr(),
      "mg10".tr(),
      "mg11".tr(),
      "mg12".tr(),
      "mg13".tr(),
      "mg14".tr(),
      "mg15".tr(),
      "mg16".tr(),
      "mg17".tr(),
      "mg18".tr(),
      "mg19".tr(),
      "mg20".tr(),
      "mg21".tr(),
      "mg22".tr(),
      "mg23".tr(),
      "mg24".tr(),
      "mg25".tr(),
      "mg26".tr(),
      "mg27".tr(),
    ],
  };
  final List<Map<String, String>> nrcTypeCodes = [
    {"code": "C", "myanmar": "နိုင်"},
    {"code": "NC", "myanmar": "ပြု"},
    {"code": "AC", "myanmar": "ဧည့်"},
    {"code": "AMT", "myanmar": "အ�မတ"},
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
    // Dispose of all controllers
    for (var controller in _yearControllers) {
      controller.dispose();
    }
    for (var controller in _gradeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.lightBlue[100],
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
  );

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
                Color(0xFF87CEFA), // Light Sky Blue
                Color(0xFFADD8E6), // Light Blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            // Drawer / Logo
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

            // Title Text (localized)
            Expanded(
              child: Text(
                tr("enrollment"),
                style: AppTextStyles.heading,
              ),
            ),

            // Language Switch Dropdown (Top-Right)
            Padding(
              padding:
              const EdgeInsets.only(right: 16.0), // moves dropdown left a bit
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

                Column(
                  children: [
                    Container(
                      width: 70,
                      height: 90,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person,
                          size: 50, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text("yourPhoto".tr(),
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text("studentEnrollment".tr(),
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _buildHorizontalDropdown(
                "cYear".tr(),
                selectedCourseYear,
                courseYears,
                    (value) {
                  setState(() => selectedCourseYear = value);
                },
                icon: Icons.school, isRequired: true
            ),
            _buildHorizontalTextField("rollNo".tr(), rollNoController,
                icon: Icons.badge),
            _buildHorizontalTextField(
              "registrationNo".tr(), // Localized label
              registrationNoController,
              icon: Icons.confirmation_num,
            ),
            _buildHorizontalTextField(
                "yearOfUni".tr(), yearOfUniversityController,
                icon: Icons.school),
            const SizedBox(height: 14),
            // Major Subject
            /* Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 140,
                    child: Text("Major Subject:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Expanded(
                    child: RadioSelector(
                      groupValue: selectedMajor,
                      onChanged: (val) =>
                          setState(() => selectedMajor = val ?? "CSE"),
                      labelStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ), */
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
            ),

            const SizedBox(height: 35),

            _buildExamInformationSection(),

            const SizedBox(height: 20),
            Center(
              child: ActionButton(text: "payment".tr(), onPressed: _submitForm),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildInput(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
        ],
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
        bool isReadOnly = false,
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
                    onChanged: isReadOnly ? null : onChanged, // FIXED: Removed selectedValue check
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

  Widget _buildHorizontalTextField(
      String label,
      TextEditingController controller, {
        IconData? icon,
        bool isRequired = false,
        bool isReadOnly = false, // Add this parameter
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
          Expanded(
            child: SizedBox(
              height: 45,
              child: TextField(
                controller: controller,
                readOnly: isReadOnly || controller.text.isNotEmpty, // Make read-only if data exists
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.lightBlue[100],
                  prefixIcon: icon != null ? Icon(icon) : null,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 140,
              child: Text("Date of Birth:",
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: SizedBox(
              height: 45,
              child: TextField(
                controller: controller,
                readOnly: true, // Always read-only for date fields
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.lightBlue[100],
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                ),
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
                        onChanged: _studentDataFound
                            ? null  // Disable if data exists
                            : (value) {
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
                        onChanged: _studentDataFound
                            ? null  // Disable if data exists
                            : (value) {
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
            icon: Icons.person),
        _buildHorizontalTextField("eName".tr(), nameEnglishController,
            icon: Icons.person_outline),
        _buildHorizontalTextField("religion".tr(), religionController,
            icon: Icons.favorite),
        _buildHorizontalTextField("phoneNo".tr(), phoneController,
            icon: Icons.phone, isRequired: true),
        _buildDateOfBirthField(controller: dobController),
        _buildHorizontalTextField("address".tr(), addressController,
            icon: Icons.home, isRequired: true),

        // Add gender selector only for student section
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AbsorbPointer(
          absorbing: _studentDataFound,
          child: Row(
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
              const SizedBox(width: 16),
              Row(
                children: [
                  Checkbox(
                    value: inProcess,
                    onChanged: (val) {
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
          ),
        ),
        const SizedBox(height: 10),
        // NRC input - Only show if NRC is selected and NOT in process
        if (selectedNRCType == NRCType.nrc && !inProcess)
          AbsorbPointer(
            absorbing: _studentDataFound,
            child: Column(
              children: [
                Row(
                  children: [
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
                        onChanged: (val) => onUpdate(
                            inProcess, selectedNRCType, val, selectedTownshipCode, selectedNRCTypeCode),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        decoration: dropdownDecoration(),
                        initialValue: selectedTownshipCode, // auto-fill from previous page
                        readOnly: true,                     // prevent manual edit
                      ),
                    ),


                    const SizedBox(width: 4),
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
                const SizedBox(height: 10),
                // NRC Number field - only show if not in process

                if (!inProcess)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: SizedBox(
                      height: 45,
                      child: TextField(
                        controller: nrcController,
                        readOnly: _studentDataFound,
                        decoration: InputDecoration(
                          hintText: "nrcNumber".tr(),
                          filled: true,
                          fillColor: Colors.lightBlue[100],
                          prefixIcon: const Icon(Icons.badge),
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
// Add these to your state class
  List<TextEditingController> _yearControllers = [];
  List<TextEditingController> _gradeControllers = [];

  Widget _buildExamInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            "examInformation".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),

        // Horizontal scroll for the table
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Table(
              border: TableBorder.all(color: Colors.grey, width: 1.0),
              defaultColumnWidth: const FixedColumnWidth(180.0),
              columnWidths: const {
                0: FixedColumnWidth(150.0),
              },
              children: [
                // Table header row
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  children: [
                    "answeredExam".tr(),
                    "majorSubject".tr(),
                    "year".tr(),
                    "grade".tr(),
                  ].map((columnName) {
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        columnName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                ),

                // Generate rows for each semester
                for (int i = 0; i < _semesterList.length; i++)
                  TableRow(
                    children: [
                      // Semester Cell (Read-only)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(_semesterList[i]),
                      ),

                      // Major Subject Dropdown Cell
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: DropdownButtonFormField<String>(
                          // Use the value from the _selectedMajors list for this specific row
                          value: _selectedMajors[i],
                          items: _majorList.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedMajors[i] = newValue;
                              // If the first row is changed, update all null values to match
                              if (i == 0 && newValue != null) {
                                for (int j = 0; j < _selectedMajors.length; j++) {
                                  if (_selectedMajors[j] == null) {
                                    _selectedMajors[j] = newValue;
                                  }
                                }
                              }
                            });
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                            isDense: true,
                          ),
                          isExpanded: true,
                        ),
                      ),

                      // Year Text Field
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextFormField(
                          controller: _yearControllers[i],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                            isDense: true,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Fail/Pass Text Field
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextFormField(
                          controller: _gradeControllers[i],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                            isDense: true,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _updateStudentData() async {
    try {
      // Get the roll number from the controller
      final String rollNo = rollNoController.text.trim();

      print('Attempting to update student with roll number: $rollNo');

      if (rollNo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Roll number is required')),
        );
        return;
      }

      // Use roll number as document ID
      final studentDoc = FirebaseFirestore.instance.collection('students').doc(rollNo);

      // Check if document exists first
      final docSnapshot = await studentDoc.get();
      if (!docSnapshot.exists) {
        print('Document does not exist for roll number: $rollNo');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student record not found')),
        );
        return;
      }

      final Map<String, dynamic> updateData = {};

      // Debug: Print current values
      print('Current address: ${addressController.text}');
      print('Current contact: ${phoneController.text}');
      print('From Year: $fromYear');
      print('To Year: $toYear');
      print('Current course year: $selectedCourseYear');
      print('Father address: ${fatherAddressController.text}');
      print('Father contact: ${fatherPhoneController.text}');
      print('Mother address: ${motherAddressController.text}');
      print('Mother contact: ${motherPhoneController.text}');

      // Update student address and contact only if new input is provided
      if (addressController.text.isNotEmpty) {
        updateData['saddress'] = addressController.text;
      }
      if (phoneController.text.isNotEmpty) {
        updateData['scontactNumber'] = phoneController.text;
      }

      // Update academic info
      if (fromYear != null && toYear != null) {
        updateData['academicInfo.academicYear'] = "$fromYear-$toYear";
        updateData['academicInfo.start_year'] = int.parse(fromYear!);
        updateData['academicInfo.end_year'] = int.parse(toYear!);
      } else if (fromYear != null) {
        // If only fromYear is selected, keep the existing toYear part
        final existingData = docSnapshot.data();
        final existingAcademicYear = existingData?['academicInfo']?['academicYear'] as String?;
        if (existingAcademicYear != null && existingAcademicYear.contains('-')) {
          final existingToYear = existingAcademicYear.split('-')[1];
          updateData['academicInfo.academicYear'] = "$fromYear-$existingToYear";
        } else {
          updateData['academicInfo.academicYear'] = "$fromYear-";
        }
        updateData['academicInfo.start_year'] = int.parse(fromYear!);
      } else if (toYear != null) {
        // If only toYear is selected, keep the existing fromYear part
        final existingData = docSnapshot.data();
        final existingAcademicYear = existingData?['academicInfo']?['academicYear'] as String?;
        if (existingAcademicYear != null && existingAcademicYear.contains('-')) {
          final existingFromYear = existingAcademicYear.split('-')[0];
          updateData['academicInfo.academicYear'] = "$existingFromYear-$toYear";
        } else {
          updateData['academicInfo.academicYear'] = "-$toYear";
        }
        updateData['academicInfo.end_year'] = int.parse(toYear!);
      }

      // Update course year if selected
      if (selectedCourseYear != null && selectedCourseYear!.isNotEmpty) {
        updateData['academicInfo.courseYear'] = selectedCourseYear;
      }

      // Update parent data using dot notation
      if (fatherAddressController.text.isNotEmpty) {
        updateData['parents.father.faddress'] = fatherAddressController.text;
      }
      if (fatherPhoneController.text.isNotEmpty) {
        updateData['parents.father.fphone'] = fatherPhoneController.text;
      }

      if (motherAddressController.text.isNotEmpty) {
        updateData['parents.mother.maddress'] = motherAddressController.text;
      }
      if (motherPhoneController.text.isNotEmpty) {
        updateData['parents.mother.mphone'] = motherPhoneController.text;
      }

      // FIXED: Determine student type based on academic year comparison
      final existingData = docSnapshot.data();
      final existingStartYear = existingData?['academicInfo']?['start_year'] as int?;

      // Get current admin academic year
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin_academic_year')
          .doc('admin')
          .get();

      if (adminDoc.exists) {
        final adminStartYear = adminDoc.get('astart_year') as int;

        // Compare student's original start year with admin's current start year
        if (existingStartYear != null && existingStartYear < adminStartYear) {
          updateData['stype'] = 'old';
          print('Setting stype to "old": Student start year ($existingStartYear) < Admin start year ($adminStartYear)');
        } else {
          updateData['stype'] = 'new';
          print('Setting stype to "new": Student start year ($existingStartYear) >= Admin start year ($adminStartYear)');
        }
      }

      // Debug: Print what we're about to update
      print('Update data: $updateData');

      // Update Firebase only if there are changes
      if (updateData.isNotEmpty) {
        print('Updating Firestore document...');
        await studentDoc.update(updateData);
        print('Update successful!');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data updated successfully!')),
        );

        // Navigate to payment screen after successful update
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OldStudentPaymentQR(
              rollNo: rollNoController.text.trim(),
              studentName: nameEnglishController.text.trim(),
            ),
          ),
        );
      } else {
        print('No data to update');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No changes to update.')),
        );
      }

    } catch (e) {
      print('Error updating data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating data: $e')),
      );
    }
  }

  void _submitForm() {
    // Implement form submission logic here
    // Get the roll number and name from controllers
    final String rollNo = rollNoController.text.trim();
    final String studentName = nameEnglishController.text.trim();

    // Validate that we have the required data
    if (rollNo.isEmpty || studentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields".tr())),
      );
      return;
    }

    _updateStudentData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Updating data...".tr())),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OldStudentPaymentQR(
          rollNo: rollNo,
          studentName: studentName,
        ),
      ),
    );
  }
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Loading state
  bool _isLoading = true;
  bool _studentDataFound = false;



  int? _studentYear;
  int? _adminYear;
  String? _studentUid; // Add this to store the student UID

  void _populateFormData() {
    if (widget.studentData != null) {
      final data = widget.studentData!;
      _studentUid = data['uid'];

      setState(() {
        _studentDataFound = true;
        // Auto-fill student data (read-only fields)
        nameMyanmarController.text = data['sname_myanmar'] ?? '';
        nameEnglishController.text = data['sname'] ?? '';
        religionController.text = data['sreligion'] ?? '';
        dobController.text = data['sdob'] ?? '';
        nrcNumberController.text = data['snrc'] ?? '';
        selectedGender = data['sgender'] ?? 'Male';
        rollNoController.text = data['srollno'] ?? '';

        // Set NRC components if available
        if (data['snrc_state_division'] != null) {
          studentSelectedStateDivisionCode = data['snrc_state_division'];
        }
        if (data['snrc_township'] != null) {
          studentSelectedTownshipCode = data['snrc_township'];
        }
        if (data['snrc_type'] != null) {
          studentSelectedNRCTypeCode = data['snrc_type'];
        }

        // Academic info
        final academicInfo = data['academicInfo'] as Map<String, dynamic>?;
        if (academicInfo != null) {
          if (academicInfo['registrationNumber'] != null) {
            registrationNoController.text =
                academicInfo['registrationNumber'].toString();
          }
          if (academicInfo['yearOfUniversity'] != null) {
            yearOfUniversityController.text =
                academicInfo['yearOfUniversity'].toString();
                _studentYear = int.tryParse(academicInfo['yearOfUniversity'].toString());
          }
        }

        // Parents info
        final parents = data['parents'] as Map<String, dynamic>?;
        if (parents != null) {
          final father = parents['father'] as Map<String, dynamic>?;
          final mother = parents['mother'] as Map<String, dynamic>?;

          // Father data
          if (father != null) {
            if (father['fname_mm'] != null) {
              fatherNameMyanmarController.text = father['fname_mm'];
            }
            if (father['fname_eng'] != null) {
              fatherNameEnglishController.text = father['fname_eng'];
            }
            if (father['freligion'] != null) {
              fatherReligionController.text = father['freligion'];
            }
            if (father['fdob'] != null) {
              fatherDobController.text = father['fdob'];
            }
            if (father['fnrc'] != null) {
              fatherNRCController.text = father['fnrc'];
            }
            if (father['fnrc_state_division'] != null) {
              fatherSelectedStateDivisionCode = father['fnrc_state_division'];
            }
            if (father['fnrc_township'] != null) {
              fatherSelectedTownshipCode = father['fnrc_township'];
            }
            if (father['fnrc_type'] != null) {
              fatherSelectedNRCTypeCode = father['fnrc_type'];
            }
            if (father['fnrc_in_process'] != null) {
              fatherInProcess = father['fnrc_in_process'];
            }
          }

          // Mother data
          if (mother != null) {
            if (mother['mname_mm'] != null) {
              motherNameMyanmarController.text = mother['mname_mm'];
            }
            if (mother['mname_eng'] != null) {
              motherNameEnglishController.text = mother['mname_eng'];
            }
            if (mother['mreligion'] != null) {
              motherReligionController.text = mother['mreligion'];
            }
            if (mother['mdob'] != null) {
              motherDobController.text = mother['mdob'];
            }
            if (mother['mnrc'] != null) {
              motherNRCController.text = mother['mnrc'];
            }
            if (mother['mnrc_state_division'] != null) {
              motherSelectedStateDivisionCode = mother['mnrc_state_division'];
            }
            if (mother['mnrc_township'] != null) {
              motherSelectedTownshipCode = mother['mnrc_township'];
            }
            if (mother['mnrc_type'] != null) {
              motherSelectedNRCTypeCode = mother['mnrc_type'];
            }
            if (mother['mnrc_in_process'] != null) {
              motherInProcess = mother['mnrc_in_process'];
            }
          }
        }
      });

      _fetchExamData();
      _fetchAdminAcademicYear();
      setState(() {
        _isLoading = false;
      }
     );
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
        final startYear = academicYearData?['astart_year']?.toString();
        final endYear = academicYearData?['aend_year']?.toString();

        if (startYear != null && endYear != null) {
          setState(() {
            _adminStartYear = int.tryParse(startYear);
            _adminEndYear = int.tryParse(endYear);
            _adminYear = _adminStartYear; // Set _adminYear for comparison
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


  Future<void> _fetchExamData() async {
    try {
      final String rollNo = rollNoController.text.trim();

      if (rollNo.isNotEmpty) {
        final examDoc = await FirebaseFirestore.instance
            .collection('exams')
            .doc(rollNo)
            .get();

        if (examDoc.exists) {
          final examData = examDoc.data();
          final courseYear = examData?['courseYear']?.toString();
          final overallGrade = examData?['overallGrade']?.toString();

          setState(() {
            // Populate the first row of the exam table with these values
            if (_yearControllers.isNotEmpty && courseYear != null) {
              _yearControllers[0].text = courseYear;
            }

            if (_gradeControllers.isNotEmpty && overallGrade != null) {
              _gradeControllers[0].text = overallGrade;
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching exam data: $e');
    }
  }
}