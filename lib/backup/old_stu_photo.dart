import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import 'new_student_payment.dart';
import 'my_drawer.dart';
import 'new_stu_idcard_photo.dart';
import 'old_stu_idcard_photo.dart';

class OldStudentPhotoUpload extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const OldStudentPhotoUpload({
    Key? key,
    required this.studentData, required String rollNo, required String studentName, required String courseYear,
  }) : super(key: key);

  @override
  State<OldStudentPhotoUpload> createState() => _OldStudentPhotoUpload();
}

class _OldStudentPhotoUpload extends State<OldStudentPhotoUpload> {
  // Image files/bytes storage
  File? _studentPhoto;
  Uint8List? _studentPhotoWeb;

  // Loading state
  bool _isSubmitting = false;
  bool _isUploading = false;

  // Get student info from passed data
  String get _rollNo => widget.studentData['rollNo'] ?? 'N/A';
  String get _studentName => widget.studentData['studentName'] ?? 'N/A';

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            if (index == 0) {
              _studentPhotoWeb = bytes;
              _studentPhoto = null;
            }
          });
        } else {
          setState(() {
            if (index == 0) {
              _studentPhoto = File(image.path);
              _studentPhotoWeb = null;
            }
          });
        }
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> uploadImage(int index) async {
    File? fileToUpload;
    Uint8List? bytesToUpload;
    String fileNamePrefix = '';

    if (index == 0) {
      fileToUpload = _studentPhoto;
      bytesToUpload = _studentPhotoWeb;
      fileNamePrefix = 'student_photo';
    }

    if (fileToUpload == null && bytesToUpload == null) {
      _showError('No image to upload');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rollNo = _rollNo;
      final fileName = '${rollNo}_${fileNamePrefix}_$timestamp.jpg';
      final path = 'uploads/$fileName';

      if (kIsWeb) {
        if (bytesToUpload != null) {
          await Supabase.instance.client.storage
              .from('student_photos')
              .uploadBinary(path, bytesToUpload, fileOptions: FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ));
        }
      } else {
        if (fileToUpload != null) {
          await Supabase.instance.client.storage
              .from('student_photos')
              .upload(path, fileToUpload, fileOptions: FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ));
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image uploaded successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      final imageUrl = Supabase.instance.client.storage
          .from('student_photos')
          .getPublicUrl(path);

      print('Uploaded image URL: $imageUrl');

      // Store URL in student data
      widget.studentData['photoUrl'] = imageUrl;

    } catch (e) {
      _showError('Failed to upload image: $e');
      rethrow;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> uploadAllImages() async {
    setState(() => _isUploading = true);

    try {
      if (_studentPhoto != null || _studentPhotoWeb != null) {
        await uploadImage(0);
      }
    } catch (e) {
      rethrow;
    } finally {
      setState(() => _isUploading = false);
    }
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
    final hasImage = _studentPhoto != null || _studentPhotoWeb != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          _buildUploadCard(
            index: 0,
            title: 'Student Photo',
            subtitle: 'Upload a clear portrait photo',
            currentImage: _studentPhoto,
            webImage: _studentPhotoWeb,
          ),

          // Clear button for when image is selected - MOVED INSIDE CARD
          if (hasImage) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _clearImage(0),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.indigo[50]!,
                      side: BorderSide(color: Colors.indigo[100]!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (!hasImage) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () => pickImage(0),
                icon: const Icon(Icons.photo_library, size: 20),
                label: const Text('Pick Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          _buildSubmitButton(),
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
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
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
    required int index,
    required String title,
    required String subtitle,
    required File? currentImage,
    required Uint8List? webImage,
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
            'No photo selected',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Pick Photo" to add',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _clearImage(int index) {
    setState(() {
      if (index == 0) {
        _studentPhoto = null;
        _studentPhotoWeb = null;
      }
    });
  }

  // FIXED: Submit Button Implementation
  Widget _buildSubmitButton() {
    final hasPhoto = (_studentPhoto != null || _studentPhotoWeb != null);

    return Column(
      children: [
        if (!hasPhoto)
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
                    'Please select a student photo to continue',
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

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (hasPhoto && !_isSubmitting && !_isUploading)
                ? _submitPhotos
                : null,
            icon: _isSubmitting || _isUploading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
                : const Icon(Icons.arrow_forward),
            label: _isSubmitting || _isUploading
                ? const Text('Processing...')
                : const Text('Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPhoto ? Colors.indigo : Colors.grey,
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

  // FIXED: Submit Logic with Navigation
  Future<void> _submitPhotos() async {
    setState(() => _isSubmitting = true);

    try {
      // Upload all images to Supabase
      await uploadAllImages();

      // Navigate to payment page after successful upload
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OldStudentIDPhotoUpload(
              studentData: widget.studentData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to submit photos: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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