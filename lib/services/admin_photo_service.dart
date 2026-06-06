import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AdminPhotoService {
  static final AdminPhotoService _instance = AdminPhotoService._internal();
  factory AdminPhotoService() => _instance;
  AdminPhotoService._internal();

  Future<String> saveStudentPhotoToLocal(dynamic imageData, String studentId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final studentPhotosDir = Directory('${appDir.path}/UniversityEnrollment/StudentIDPhotos');

      if (!await studentPhotosDir.exists()) {
        await studentPhotosDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${studentId}_$timestamp.jpg';
      final localPath = '${studentPhotosDir.path}/$fileName';

      // Handle both File and Uint8List
      if (imageData is File) {
        await imageData.copy(localPath);
      } else if (imageData is Uint8List) {
        final file = File(localPath);
        await file.writeAsBytes(imageData);
      } else {
        throw Exception('Unsupported image data type');
      }

      print('✅ Photo saved locally: $localPath');
      return fileName;
    } catch (e) {
      print('❌ Error saving photo: $e');
      throw Exception('Failed to save photo: $e');
    }
  }

  Future<File?> getStudentPhoto(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/UniversityEnrollment/StudentIDPhotos/$fileName';
      final file = File(localPath);

      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('❌ Error getting photo: $e');
      return null;
    }
  }

  Future<void> deleteStudentPhoto(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photoPath = '${appDir.path}/UniversityEnrollment/StudentIDPhotos/$fileName';
      final photoFile = File(photoPath);

      if (await photoFile.exists()) {
        await photoFile.delete();
        print('✅ Photo deleted: $fileName');
      }
    } catch (e) {
      print('❌ Error deleting photo: $e');
    }
  }
}