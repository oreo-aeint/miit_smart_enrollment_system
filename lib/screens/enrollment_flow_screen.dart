import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../components/enrollment_photo_controller.dart';
import '../components/photo_upload_widget.dart';
import '../components/upload_progress_bar.dart';
import 'old_student_enrollment_app.dart';

class EnrollmentFlowScreen extends StatefulWidget {
  final Map<String, dynamic>? studentData;
  final String? studentId;

  const EnrollmentFlowScreen({
    Key? key,
    this.studentData,
    this.studentId,
  }) : super(key: key);

  @override
  State<EnrollmentFlowScreen> createState() => _EnrollmentFlowScreenState();
}

class _EnrollmentFlowScreenState extends State<EnrollmentFlowScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    print("EnrollmentFlowScreen initialized with data: ${widget.studentData}");
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EnrollmentPhotoController>(
      create: (context) => EnrollmentPhotoController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
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
          title: Text(
            _getPageTitle(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: _currentPage > 0
              ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _goToPreviousPage,
          )
              : null,
        ),
        body: Consumer<EnrollmentPhotoController>(
          builder: (context, photoController, child) {
            return Column(
              children: [
                // Progress Bar - Always visible
                UploadProgressBar(
                  progress: photoController.uploadProgress,
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                ),

                // Page Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      // PAGE 1: STUDENT PHOTO UPLOAD
                      _buildStudentPhotoPage(photoController),

                      // PAGE 2: ID CARD PHOTOS UPLOAD (FRONT & BACK)
                      _buildIdPhotosPage(photoController),

                      // PAGE 3: ENROLLMENT FORM
                      OldStudentEnrollmentApp(
                        studentData: widget.studentData,
                        studentId: widget.studentId,
                       /* photoController: photoController,*/
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case 0:
        return "uploadStudentPhoto".tr();
      case 1:
        return "uploadIdPhotos".tr();
      case 2:
        return "enrollmentForm".tr();
      default:
        return "enrollment".tr();
    }
  }

  // PAGE 1: STUDENT PHOTO UPLOAD
  Widget _buildStudentPhotoPage(EnrollmentPhotoController controller) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // Title
            Text(
              "studentPhoto".tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            Text(
              "pleaseUploadStudentPhoto".tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Photo Upload Widget
            Center(
              child: PhotoUploadWidget(
                imageFile: controller.studentPhoto,
                onImagePicked: (file) {
                  controller.setStudentPhoto(file);
                },
                label: "tapToUploadPhoto".tr(),
                width: 250,
                height: 300,
                isRequired: true,
              ),
            ),

            const SizedBox(height: 20),

            // Status message
            if (controller.studentPhoto != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      "photoUploaded".tr(),
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // Continue Button
            Center(
              child: ElevatedButton(
                onPressed: controller.hasStudentPhoto
                    ? () {
                  print("Student photo uploaded, moving to next page");
                  _goToNextPage();
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 55),
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "continue".tr(),
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PAGE 2: ID CARD PHOTOS UPLOAD (FRONT & BACK)
  Widget _buildIdPhotosPage(EnrollmentPhotoController controller) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // Title
            Text(
              "idCardPhotos".tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            Text(
              "pleaseUploadFrontAndBack".tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Two photos side by side
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Front ID Card
                Expanded(
                  child: Column(
                    children: [
                      PhotoUploadWidget(
                        imageFile: controller.idFrontPhoto,
                        onImagePicked: (file) {
                          controller.setIdFrontPhoto(file);
                        },
                        label: "tapToUpload".tr(),
                        width: 150,
                        height: 200,
                        isRequired: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "frontId".tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (controller.idFrontPhoto != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "uploaded".tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Back ID Card
                Expanded(
                  child: Column(
                    children: [
                      PhotoUploadWidget(
                        imageFile: controller.idBackPhoto,
                        onImagePicked: (file) {
                          controller.setIdBackPhoto(file);
                        },
                        label: "tapToUpload".tr(),
                        width: 150,
                        height: 200,
                        isRequired: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "backId".tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (controller.idBackPhoto != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "uploaded".tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Status message when both photos are uploaded
            if (controller.hasBothIdPhotos)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      "bothPhotosUploaded".tr(),
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Back Button
                OutlinedButton(
                  onPressed: _goToPreviousPage,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(150, 50),
                    side: const BorderSide(color: Colors.indigo),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        "back".tr(),
                        style: const TextStyle(color: Colors.indigo),
                      ),
                    ],
                  ),
                ),

                // Continue Button
                ElevatedButton(
                  onPressed: controller.hasBothIdPhotos
                      ? () {
                    print("Both ID photos uploaded, moving to form page");
                    _goToNextPage();
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(150, 50),
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "continue".tr(),
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }
}