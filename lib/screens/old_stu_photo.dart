import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import 'old_stu_idcard_photo.dart';
import 'my_drawer.dart';

class OldStudentPhotoUpload extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String rollNo;
  final String studentName;
  final String courseYear;  // Make sure this is NOT optional if you're always passing it
  final String? studentId;

  const OldStudentPhotoUpload({
    Key? key,
    required this.studentData,
    required this.rollNo,
    required this.studentName,
    required this.courseYear,  // This should be required
    this.studentId,
  }) : super(key: key);

  @override
  State<OldStudentPhotoUpload> createState() => _OldStudentPhotoUploadState();
}

class _OldStudentPhotoUploadState extends State<OldStudentPhotoUpload> {
  // Store current photo URL from database (existing photo)
  String? _currentPhotoUrl;

  // Store new photo to upload (temporary - not uploaded yet)
  File? _newPhotoFile;
  Uint8List? _newPhotoWebBytes;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _debugMessage;

  // Supabase client
  final _supabase = Supabase.instance.client;

  // Get student info from passed data with multiple fallbacks
  String get _rollNo {
    return widget.studentData['rollNo']?.toString() ??
        widget.studentData['srollno']?.toString() ??
        'N/A';
  }

  String get _studentName {
    return widget.studentData['studentName']?.toString() ??
        widget.studentData['sname']?.toString() ??
        'N/A';
  }

  // Note: student_id is not used in this table, we'll use roll_no instead
  String get _studentId {
    return widget.studentData['id']?.toString() ??
        widget.studentData['studentId']?.toString() ??
        widget.studentData['uid']?.toString() ??
        '';
  }

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchExistingPhoto();
  }

  // Fetch existing photo from database - USING ROLL_NO
  Future<void> _fetchExistingPhoto() async {
    print('=== FETCHING EXISTING PHOTO ===');
    print('Roll No: $_rollNo');
    print('Student Name: $_studentName');
    print('Full studentData: ${widget.studentData}');

    if (_rollNo == 'N/A' || _rollNo.isEmpty) {
      print('❌ No roll number found!');
      setState(() {
        _debugMessage = 'No roll number found. Please go back and try again.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Query by roll_no (since your table uses roll_no, not student_id)
      print('Querying by roll_no = $_rollNo');
      final response = await _supabase
          .from('student_photos')
          .select('student_photo_url')  // Get the student_photo_url column
          .eq('roll_no', _rollNo)
          .maybeSingle();

      print('Response: $response');

      if (response != null && response['student_photo_url'] != null) {
        final photoUrl = response['student_photo_url'].toString();
        print('✅ Found existing photo: $photoUrl');
        setState(() {
          _currentPhotoUrl = photoUrl;
          widget.studentData['photoUrl'] = photoUrl;
          _debugMessage = '';
        });
      } else {
        print('❌ No existing photo found for roll_no: $_rollNo');
        setState(() {
          _debugMessage = 'No existing photo found for this student';
        });
      }
    } catch (e) {
      print('❌ Error fetching existing photo: $e');
      setState(() {
        _debugMessage = 'Error fetching photo: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Pick new photo - only stores temporarily, no upload yet
  Future<void> _pickNewPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ New photo picked');
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _newPhotoWebBytes = bytes;
            _newPhotoFile = null;
          });
        } else {
          setState(() {
            _newPhotoFile = File(image.path);
            _newPhotoWebBytes = null;
          });
        }
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  // Upload photo ONLY when Next button is clicked
  Future<String?> _uploadNewPhoto() async {
    if (_newPhotoFile == null && _newPhotoWebBytes == null) {
      // No new photo selected, keep existing
      return _currentPhotoUrl;
    }

    setState(() => _isSubmitting = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${_rollNo}_student_photo_$timestamp.jpg';
      final path = 'uploads/$fileName';

      print('Uploading to path: $path');

      if (kIsWeb) {
        if (_newPhotoWebBytes != null) {
          await _supabase.storage
              .from('student_photos')
              .uploadBinary(path, _newPhotoWebBytes!, fileOptions: FileOptions(
            contentType: 'image/jpeg',
          ));
        }
      } else {
        if (_newPhotoFile != null) {
          await _supabase.storage
              .from('student_photos')
              .upload(path, _newPhotoFile!, fileOptions: FileOptions(
            contentType: 'image/jpeg',
          ));
        }
      }

      final imageUrl = _supabase.storage
          .from('student_photos')
          .getPublicUrl(path);

      print('✅ Uploaded new image URL: $imageUrl');

      // Update database with new URL
      await _updatePhotoUrlInDatabase(imageUrl);

      return imageUrl;

    } catch (e) {
      print('❌ Error uploading photo: $e');
      _showError('Failed to upload image: $e');
      return null;
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updatePhotoUrlInDatabase(String imageUrl) async {
    try {
      print('Updating database with new photo URL...');
      print('Roll No: $_rollNo');

      // Check if record exists by roll_no
      final existingRecord = await _supabase
          .from('student_photos')
          .select('roll_no')
          .eq('roll_no', _rollNo)
          .maybeSingle();

      if (existingRecord != null) {
        print('Updating existing record for roll_no: $_rollNo');
        await _supabase
            .from('student_photos')
            .update({
          'student_photo_url': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('roll_no', _rollNo);
      } else {
        print('Creating new record for roll_no: $_rollNo');
        await _supabase
            .from('student_photos')
            .insert({
          'roll_no': _rollNo,
          'student_photo_url': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      setState(() {
        _currentPhotoUrl = imageUrl;
        widget.studentData['photoUrl'] = imageUrl;
      });

      print('✅ Database updated successfully');

    } catch (e) {
      print('❌ Error updating database: $e');
      rethrow;
    }
  }

  // Go to next page - THIS is where upload happens
  void _goToNextPage() async {
    setState(() => _isSubmitting = true);

    try {
      String? finalPhotoUrl;

      // Only upload if a new photo was selected
      if (_newPhotoFile != null || _newPhotoWebBytes != null) {
        finalPhotoUrl = await _uploadNewPhoto();
        if (finalPhotoUrl == null) {
          throw Exception('Failed to upload photo');
        }
      } else {
        // Keep existing photo URL
        finalPhotoUrl = _currentPhotoUrl;
      }

      // Update studentData with final photo URL
      widget.studentData['photoUrl'] = finalPhotoUrl;

      print('Moving to next page with photo URL: $finalPhotoUrl');

      // Navigate to next page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OldStudentIDPhotoUpload(
              studentData: widget.studentData,
              rollNo: _rollNo,  // ← Use the actual roll number
              studentName: _studentName,  // ← Use the actual student name
              courseYear: widget.studentData['courseYear'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to process: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          // Debug info
         /* if (_debugMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.yellow[100],
              child: Text(
                'Debug: $_debugMessage',
                style: const TextStyle(fontSize: 12),
              ),
            ),*/

          // Photo Frame
          _buildPhotoFrame(),

          const SizedBox(height: 24),

          // Next Button
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildPhotoFrame() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 2),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          // Photo Display
          Container(
            width: double.infinity,
            height: 300,
            child: _buildImagePreview(),
          ),

          // Pick Photo Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: _pickNewPhoto,
              icon: const Icon(Icons.photo_library, color: Colors.white),
              label: const Text(
                'Choose Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    // Priority 1: Show newly picked photo (temporary)
    if (_newPhotoFile != null) {
      print('Showing newly picked mobile photo');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb
            ? Image.network(_newPhotoFile!.path, fit: BoxFit.cover, width: double.infinity)
            : Image.file(_newPhotoFile!, fit: BoxFit.cover, width: double.infinity),
      );
    }

    // Priority 2: Show newly picked web bytes (temporary)
    if (_newPhotoWebBytes != null) {
      print('Showing newly picked web photo');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_newPhotoWebBytes!, fit: BoxFit.cover, width: double.infinity),
      );
    }

    // Priority 3: Show existing photo from database
    if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      print('Showing existing photo from URL: $_currentPhotoUrl');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _currentPhotoUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            return _buildEmptyPreview();
          },
        ),
      );
    }

    // Priority 4: Show empty preview
    print('No photo to show, showing empty preview');
    return _buildEmptyPreview();
  }

  Widget _buildEmptyPreview() {
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
          const SizedBox(height: 8),
          Text(
            'Click "Choose Photo" to select an image',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _goToNextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'Next',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
            '📸 Student Photo',
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