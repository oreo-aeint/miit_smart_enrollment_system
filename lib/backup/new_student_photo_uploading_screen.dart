import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

import 'my_drawer.dart';
import 'new_student_payment.dart' show NewStudentPaymentQR;

class NewStudentPhotoUpload extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const NewStudentPhotoUpload({
    Key? key,
    required this.studentData, required String studentName, required String rollNo,
  }) : super(key: key);

  @override
  State<NewStudentPhotoUpload> createState() => _NewStudentPhotoUploadState();
}

class _NewStudentPhotoUploadState extends State<NewStudentPhotoUpload> {
  // Image files/bytes storage
  File? _studentPhoto;
  File? _idFrontPhoto;
  File? _idBackPhoto;

  // For web image picking
  Uint8List? _studentPhotoWeb;
  Uint8List? _idFrontPhotoWeb;
  Uint8List? _idBackPhotoWeb;

  // Loading state
  bool _isSubmitting = false;

  // Get student info from passed data
  String get _rollNo => widget.studentData['rollNo'] ?? 'N/A';
  String get _studentName => widget.studentData['studentName'] ?? 'N/A';

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Input border style to match your other pages
  final InputBorder inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.grey),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const MyDrawer(), // Make sure to import/define MyDrawer
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
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.asset('assets/img_2.png', width: 50, height: 50),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Photo Upload',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          _buildHeader(),
          const SizedBox(height: 24),

          // Student Photo Card
          _buildUploadCard(
            title: 'Student Photo',
            subtitle: 'Upload a clear portrait photo',
            currentImage: _studentPhoto,
            webImage: _studentPhotoWeb,
            onUpload: () => _pickImage(0),
            onClear: () => _clearImage(0),
          ),
          const SizedBox(height: 20),

          // ID Front Card
          _buildUploadCard(
            title: 'ID Card (Front)',
            subtitle: 'Upload front side of ID card',
            currentImage: _idFrontPhoto,
            webImage: _idFrontPhotoWeb,
            onUpload: () => _pickImage(1),
            onClear: () => _clearImage(1),
          ),
          const SizedBox(height: 20),

          // ID Back Card
          _buildUploadCard(
            title: 'ID Card (Back)',
            subtitle: 'Upload back side of ID card',
            currentImage: _idBackPhoto,
            webImage: _idBackPhotoWeb,
            onUpload: () => _pickImage(2),
            onClear: () => _clearImage(2),
          ),

          const SizedBox(height: 40),

          // Submit Button
          _buildSubmitButton(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📸 Photo Upload Required',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please upload all 3 photos to proceed with enrollment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Student: $_studentName | Roll No: $_rollNo',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.indigo,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required File? currentImage,
    required Uint8List? webImage,
    required VoidCallback onUpload,
    required VoidCallback onClear,
  }) {
    final hasImage = currentImage != null || webImage != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasImage ? Colors.green : Colors.grey[300]!,
          width: hasImage ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasImage)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Preview/Placeholder area
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _buildImagePreview(currentImage, webImage),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                    label: Text(hasImage ? 'Replace Photo' : 'Upload Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(File? imageFile, Uint8List? webImage) {
    if (imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: kIsWeb
            ? Image.network(imageFile.path, fit: BoxFit.cover)
            : Image.file(imageFile, fit: BoxFit.cover),
      );
    } else if (webImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(webImage, fit: BoxFit.cover),
      );
    }

    // Placeholder when no image
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.indigo[100],
            ),
            child: Icon(
              Icons.photo_camera,
              size: 48,
              color: Colors.indigo[400],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No photo uploaded',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Upload Photo" to add',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final allPhotosUploaded = (_studentPhoto != null || _studentPhotoWeb != null) &&
        (_idFrontPhoto != null || _idFrontPhotoWeb != null) &&
        (_idBackPhoto != null || _idBackPhotoWeb != null);

    return Column(
      children: [
        // Validation message
        if (!allPhotosUploaded)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please upload all 3 photos to continue',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: allPhotosUploaded && !_isSubmitting ? _submitPhotos : null,
            icon: _isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
                : const Icon(Icons.arrow_forward),
            label: _isSubmitting
                ? const Text('Processing...')
                : const Text('Continue to Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: allPhotosUploaded ? Colors.indigo : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Image Handling Methods ---
  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        // For web, we need to handle differently
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            if (index == 0) {
              _studentPhotoWeb = bytes;
              _studentPhoto = null;
            } else if (index == 1) {
              _idFrontPhotoWeb = bytes;
              _idFrontPhoto = null;
            } else {
              _idBackPhotoWeb = bytes;
              _idBackPhoto = null;
            }
          });
        } else {
          setState(() {
            if (index == 0) {
              _studentPhoto = File(image.path);
              _studentPhotoWeb = null;
            } else if (index == 1) {
              _idFrontPhoto = File(image.path);
              _idFrontPhotoWeb = null;
            } else {
              _idBackPhoto = File(image.path);
              _idBackPhotoWeb = null;
            }
          });
        }
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _clearImage(int index) {
    setState(() {
      if (index == 0) {
        _studentPhoto = null;
        _studentPhotoWeb = null;
      } else if (index == 1) {
        _idFrontPhoto = null;
        _idFrontPhotoWeb = null;
      } else {
        _idBackPhoto = null;
        _idBackPhotoWeb = null;
      }
    });
  }

  // --- Submit Logic ---
  Future<void> _submitPhotos() async {
    setState(() => _isSubmitting = true);

    try {
      // TODO: Replace with your cloud storage upload logic
      await _uploadToCloudStorage();

      // Navigate to payment page
      _navigateToPayment();
    } catch (e) {
      _showError('Failed to submit photos: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _uploadToCloudStorage() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
  }

  void _navigateToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewStudentPaymentQR(
          rollNo: _rollNo,
          studentName: _studentName, studentData: {},

        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}