import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import 'my_drawer.dart';
import 'old_student_payment.dart' show OldStudentPaymentQR;

class OldStudentPhotoUpload extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const OldStudentPhotoUpload({
    Key? key,
    required this.studentData,
  }) : super(key: key);

  @override
  State<OldStudentPhotoUpload> createState() => _OldStudentPhotoUploadState();
}

class _OldStudentPhotoUploadState extends State<OldStudentPhotoUpload> {
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

  Future<void> uploadImage(int index) async {
    File? fileToUpload;
    Uint8List? bytesToUpload;
    String fileNamePrefix = '';

    // Determine which image to upload based on index
    if (index == 0) {
      fileToUpload = _studentPhoto;
      bytesToUpload = _studentPhotoWeb;
      fileNamePrefix = 'student_photo';
    } else if (index == 1) {
      fileToUpload = _idFrontPhoto;
      bytesToUpload = _idFrontPhotoWeb;
      fileNamePrefix = 'id_front';
    } else if (index == 2) {
      fileToUpload = _idBackPhoto;
      bytesToUpload = _idBackPhotoWeb;
      fileNamePrefix = 'id_back';
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
        // For web, upload bytes
        if (bytesToUpload != null) {
          await Supabase.instance.client.storage
              .from('student_photos')
              .uploadBinary(path, bytesToUpload, fileOptions: FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ));
        }
      } else {
        // For mobile, upload file
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

      // Store the uploaded image URL in your database if needed
      final imageUrl = Supabase.instance.client.storage
          .from('student_photos')
          .getPublicUrl(path);

      print('Uploaded image URL: $imageUrl');

    } catch (e) {
      _showError('Failed to upload image: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Upload all images at once
  Future<void> uploadAllImages() async {
    setState(() => _isUploading = true);

    try {
      List<String> uploadedUrls = [];

      // Upload student photo
      if (_studentPhoto != null || _studentPhotoWeb != null) {
        await uploadImage(0);
        // You might want to store the URL returned here
      }

      // Upload ID front
      if (_idFrontPhoto != null || _idFrontPhotoWeb != null) {
        await uploadImage(1);
      }

      // Upload ID back
      if (_idBackPhoto != null || _idBackPhotoWeb != null) {
        await uploadImage(2);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All images uploaded successfully!"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      _showError('Failed to upload images: $e');
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
            index: 0,
            title: 'Student Photo',
            subtitle: 'Upload a clear portrait photo',
            currentImage: _studentPhoto,
            webImage: _studentPhotoWeb,
          ),
          const SizedBox(height: 20),

          // ID Front Card
          _buildUploadCard(
            index: 1,
            title: 'ID Card (Front)',
            subtitle: 'Upload front side of ID card',
            currentImage: _idFrontPhoto,
            webImage: _idFrontPhotoWeb,
          ),
          const SizedBox(height: 20),

          // ID Back Card
          _buildUploadCard(
            index: 2,
            title: 'ID Card (Back)',
            subtitle: 'Upload back side of ID card',
            currentImage: _idBackPhoto,
            webImage: _idBackPhotoWeb,
          ),

          const SizedBox(height: 20),

          // Upload All Button
          if ((_studentPhoto != null || _studentPhotoWeb != null) ||
              (_idFrontPhoto != null || _idFrontPhotoWeb != null) ||
              (_idBackPhoto != null || _idBackPhotoWeb != null))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : uploadAllImages,
                icon: _isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : const Icon(Icons.cloud_upload),
                label: _isUploading
                    ? const Text('Uploading...')
                    : const Text('Upload All Images to Supabase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
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
          const SizedBox(height: 8),
          Text(
            'Images will be uploaded to Supabase storage bucket: student_photos',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
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
                    onPressed: () => pickImage(index),
                    icon: const Icon(Icons.photo_library, size: 20),
                    label: Text(hasImage ? 'Replace Photo' : 'Pick Photo'),
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
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : () => uploadImage(index),
                    icon: const Icon(Icons.cloud_upload, size: 20),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _clearImage(index),
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
      // Upload all images to Supabase
      await uploadAllImages();

      // Navigate to payment page
      _navigateToPayment();
    } catch (e) {
      _showError('Failed to submit photos: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _navigateToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OldStudentPaymentQR(
          rollNo: _rollNo,
          studentName: _studentName,
          photoId: null, // You can pass the uploaded image URLs here if needed
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