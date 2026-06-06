import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import 'new_student_payment.dart';
import 'my_drawer.dart';
import 'old_student_payment.dart';

class OldStudentIDPhotoUpload extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String rollNo;
  final String studentName;
  final String? courseYear;

  const OldStudentIDPhotoUpload({
    Key? key,
    required this.studentData,
    required this.rollNo,
    required this.studentName,
    this.courseYear,
  }) : super(key: key);

  @override
  State<OldStudentIDPhotoUpload> createState() => _OldStudentIDPhotoUpload();
}

class _OldStudentIDPhotoUpload extends State<OldStudentIDPhotoUpload> {
  // Existing photo URLs from database
  String? _existingIdFrontUrl;
  String? _existingIdBackUrl;

  // New photo files/bytes (temporary - not uploaded yet)
  File? _idFrontPhoto;
  Uint8List? _idFrontPhotoWeb;
  File? _idBackPhoto;
  Uint8List? _idBackPhotoWeb;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploading = false;
  String? _debugMessage;

  // Get student info from passed data
  String get _rollNo => widget.rollNo;
  String get _studentName => widget.studentName;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchExistingPhotos();
  }

  // Fetch existing ID card photos from database
  Future<void> _fetchExistingPhotos() async {
    print('=== FETCHING EXISTING ID CARD PHOTOS ===');
    print('Roll No: $_rollNo');

    if (_rollNo.isEmpty) {
      setState(() {
        _debugMessage = 'No roll number found';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('student_photos')
          .select('id_front_url, id_back_url')
          .eq('roll_no', _rollNo)
          .maybeSingle();

      print('Response: $response');

      if (response != null) {
        setState(() {
          _existingIdFrontUrl = response['id_front_url'];
          _existingIdBackUrl = response['id_back_url'];
          _debugMessage = '';
        });
        print('ID Front URL: $_existingIdFrontUrl');
        print('ID Back URL: $_existingIdBackUrl');
      } else {
        setState(() {
          _debugMessage = 'No existing ID photos found';
        });
      }
    } catch (e) {
      print('Error fetching existing photos: $e');
      setState(() {
        _debugMessage = 'Error fetching photos: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ New photo picked for index $index');
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            if (index == 0) {
              _idFrontPhotoWeb = bytes;
              _idFrontPhoto = null;
            } else if (index == 1) {
              _idBackPhotoWeb = bytes;
              _idBackPhoto = null;
            }
          });
        } else {
          setState(() {
            if (index == 0) {
              _idFrontPhoto = File(image.path);
              _idFrontPhotoWeb = null;
            } else if (index == 1) {
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

  // Upload a single photo - ONLY called when Continue button is clicked
  Future<String?> _uploadSinglePhoto(int index) async {
    File? fileToUpload;
    Uint8List? bytesToUpload;
    String fileNamePrefix = '';

    if (index == 0) {
      fileToUpload = _idFrontPhoto;
      bytesToUpload = _idFrontPhotoWeb;
      fileNamePrefix = 'id_front';
    } else if (index == 1) {
      fileToUpload = _idBackPhoto;
      bytesToUpload = _idBackPhotoWeb;
      fileNamePrefix = 'id_back';
    }

    if (fileToUpload == null && bytesToUpload == null) {
      // No new photo selected, keep existing
      return index == 0 ? _existingIdFrontUrl : _existingIdBackUrl;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${_rollNo}_${fileNamePrefix}_$timestamp.jpg';
      final path = 'uploads/$fileName';

      print('Uploading to path: $path');

      // Upload to Supabase Storage
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

      final imageUrl = Supabase.instance.client.storage
          .from('student_photos')
          .getPublicUrl(path);

      print('✅ Uploaded new image URL: $imageUrl');
      return imageUrl;

    } catch (e) {
      print('❌ Error uploading photo: $e');
      _showError('Failed to upload image: $e');
      return null;
    }
  }

  // Update database with all photo URLs
  Future<void> _updateDatabaseWithUrls({
    String? idFrontUrl,
    String? idBackUrl,
  }) async {
    try {
      // Check if record exists
      final existingRecord = await Supabase.instance.client
          .from('student_photos')
          .select('roll_no')
          .eq('roll_no', _rollNo)
          .maybeSingle();

      Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (idFrontUrl != null) updateData['id_front_url'] = idFrontUrl;
      if (idBackUrl != null) updateData['id_back_url'] = idBackUrl;

      if (existingRecord != null) {
        await Supabase.instance.client
            .from('student_photos')
            .update(updateData)
            .eq('roll_no', _rollNo);
        print('Updated existing record');
      } else {
        updateData['roll_no'] = _rollNo;
        await Supabase.instance.client
            .from('student_photos')
            .insert(updateData);
        print('Created new record');
      }

      // Update local state
      setState(() {
        if (idFrontUrl != null) _existingIdFrontUrl = idFrontUrl;
        if (idBackUrl != null) _existingIdBackUrl = idBackUrl;
      });

    } catch (e) {
      print('Error updating database: $e');
      rethrow;
    }
  }

  // Upload all photos - ONLY called when Continue button is clicked
  Future<void> _uploadAllPhotos() async {
    String? newIdFrontUrl;
    String? newIdBackUrl;

    // Upload ID front if new photo selected
    if (_idFrontPhoto != null || _idFrontPhotoWeb != null) {
      newIdFrontUrl = await _uploadSinglePhoto(0);
      if (newIdFrontUrl == null) {
        throw Exception('Failed to upload ID front photo');
      }
    }

    // Upload ID back if new photo selected
    if (_idBackPhoto != null || _idBackPhotoWeb != null) {
      newIdBackUrl = await _uploadSinglePhoto(1);
      if (newIdBackUrl == null) {
        throw Exception('Failed to upload ID back photo');
      }
    }

    // Update database with all URLs
    await _updateDatabaseWithUrls(
      idFrontUrl: newIdFrontUrl ?? _existingIdFrontUrl,
      idBackUrl: newIdBackUrl ?? _existingIdBackUrl,
    );
  }

  void _submitPhotos() async {
    setState(() => _isSubmitting = true);

    try {
      // Check if both photos exist (either existing or new)
      final hasIdFront = (_idFrontPhoto != null || _idFrontPhotoWeb != null ||
          (_existingIdFrontUrl != null && _existingIdFrontUrl!.isNotEmpty));
      final hasIdBack = (_idBackPhoto != null || _idBackPhotoWeb != null ||
          (_existingIdBackUrl != null && _existingIdBackUrl!.isNotEmpty));

      if (!hasIdFront || !hasIdBack) {
        _showError('Please upload both ID front and back photos');
        setState(() => _isSubmitting = false);
        return;
      }

      // Upload photos (only new ones, existing ones are kept)
      await _uploadAllPhotos();

      // Navigate to payment page after successful upload
      if (mounted) {
        print('Navigating to payment page with courseYear: ${widget.courseYear}'); // Debug print

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OldStudentPaymentQR(
              studentData: widget.studentData,
              rollNo: _rollNo,
              studentName: _studentName,
              courseYear: widget.courseYear ?? '', // Pass the courseYear here
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

  // Helper to check if a photo is available (existing or new)
  bool _hasIdFront() {
    return _idFrontPhoto != null ||
        _idFrontPhotoWeb != null ||
        (_existingIdFrontUrl != null && _existingIdFrontUrl!.isNotEmpty);
  }

  bool _hasIdBack() {
    return _idBackPhoto != null ||
        _idBackPhotoWeb != null ||
        (_existingIdBackUrl != null && _existingIdBackUrl!.isNotEmpty);
  }

  // Build image preview (shows existing or new)
  Widget _buildImagePreview(int index) {
    // Priority 1: Newly picked photo
    if (index == 0) {
      if (_idFrontPhoto != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kIsWeb
              ? Image.network(_idFrontPhoto!.path, fit: BoxFit.cover)
              : Image.file(_idFrontPhoto!, fit: BoxFit.cover),
        );
      }
      if (_idFrontPhotoWeb != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(_idFrontPhotoWeb!, fit: BoxFit.cover),
        );
      }
      // Priority 2: Existing photo
      if (_existingIdFrontUrl != null && _existingIdFrontUrl!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _existingIdFrontUrl!,
            fit: BoxFit.cover,
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
              return _buildEmptyPreview();
            },
          ),
        );
      }
    } else if (index == 1) {
      if (_idBackPhoto != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kIsWeb
              ? Image.network(_idBackPhoto!.path, fit: BoxFit.cover)
              : Image.file(_idBackPhoto!, fit: BoxFit.cover),
        );
      }
      if (_idBackPhotoWeb != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(_idBackPhotoWeb!, fit: BoxFit.cover),
        );
      }
      if (_existingIdBackUrl != null && _existingIdBackUrl!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _existingIdBackUrl!,
            fit: BoxFit.cover,
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
              return _buildEmptyPreview();
            },
          ),
        );
      }
    }
    return _buildEmptyPreview();
  }

  Widget _buildEmptyPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.indigo[100],
            ),
            child: Icon(
              Icons.photo_camera,
              size: 40,
              color: Colors.indigo[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No photo selected',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _clearImage(int index) {
    setState(() {
      if (index == 0) {
        _idFrontPhoto = null;
        _idFrontPhotoWeb = null;
      } else if (index == 1) {
        _idBackPhoto = null;
        _idBackPhotoWeb = null;
      }
    });
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
                'ID Card Upload',
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
    final hasIdFront = _hasIdFront();
    final hasIdBack = _hasIdBack();
    final allPhotosUploaded = hasIdFront && hasIdBack;

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

          // ID Card Front Photo
          _buildUploadCard(
            index: 0,
            title: 'ID Card Front',
            subtitle: 'Upload front side of ID card',
            hasPhoto: hasIdFront,
            photoFile: _idFrontPhoto,
            photoWeb: _idFrontPhotoWeb,
          ),
          const SizedBox(height: 16),

          // ID Card Back Photo
          _buildUploadCard(
            index: 1,
            title: 'ID Card Back',
            subtitle: 'Upload back side of ID card',
            hasPhoto: hasIdBack,
            photoFile: _idBackPhoto,
            photoWeb: _idBackPhotoWeb,
          ),

          const SizedBox(height: 20),
          _buildSubmitButton(allPhotosUploaded),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required int index,
    required String title,
    required String subtitle,
    required bool hasPhoto,
    File? photoFile,
    Uint8List? photoWeb,
  }) {
    final hasNewPhoto = photoFile != null || photoWeb != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasPhoto ? Colors.green : Colors.grey[300]!,
          width: hasPhoto ? 2 : 1,
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
                if (hasPhoto)
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

            // Photo Display Container
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _buildImagePreview(index),
            ),

            const SizedBox(height: 12),

            // Clear button (only shows if new photo was picked)
            if (hasNewPhoto)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _clearImage(index),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear New Photo'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.indigo[50]!,
                        side: BorderSide(color: Colors.indigo[100]!),
                      ),
                    ),
                  ],
                ),
              ),

            // Choose Photo Button (LIKE PREVIOUS PAGE)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => pickImage(index),
                icon: const Icon(Icons.photo_library, color: Colors.white),
                label: Text(
                  hasPhoto ? 'Change Photo' : 'Choose Photo',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            '📸 ID Card Upload Required',
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

  Widget _buildSubmitButton(bool allPhotosUploaded) {
    List<String> missingPhotos = [];
    if (!_hasIdFront()) missingPhotos.add("ID Front");
    if (!_hasIdBack()) missingPhotos.add("ID Back");

    return Column(
      children: [
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please upload all required photos:',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        missingPhotos.join(', '),
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (allPhotosUploaded && !_isSubmitting && !_isUploading)
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