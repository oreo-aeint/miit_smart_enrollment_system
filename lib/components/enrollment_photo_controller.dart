import 'package:flutter/material.dart';
import 'dart:io';

class EnrollmentPhotoController extends ChangeNotifier {
  File? _studentPhoto;
  File? _idFrontPhoto;
  File? _idBackPhoto;

  // Getters
  File? get studentPhoto => _studentPhoto;
  File? get idFrontPhoto => _idFrontPhoto;
  File? get idBackPhoto => _idBackPhoto;

  bool get hasBothIdPhotos => _idFrontPhoto != null && _idBackPhoto != null;
  bool get hasStudentPhoto => _studentPhoto != null;

  double get uploadProgress {
    int completed = 0;
    if (_studentPhoto != null) completed++;
    if (_idFrontPhoto != null) completed++;
    if (_idBackPhoto != null) completed++;
    return completed / 3.0;
  }

  void setStudentPhoto(File? photo) {
    _studentPhoto = photo;
    notifyListeners();
  }

  void setIdFrontPhoto(File? photo) {
    _idFrontPhoto = photo;
    notifyListeners();
  }

  void setIdBackPhoto(File? photo) {
    _idBackPhoto = photo;
    notifyListeners();
  }

  void clearAll() {
    _studentPhoto = null;
    _idFrontPhoto = null;
    _idBackPhoto = null;
    notifyListeners();
  }

  Map<String, File?> getAllPhotos() {
    return {
      'studentPhoto': _studentPhoto,
      'idFrontPhoto': _idFrontPhoto,
      'idBackPhoto': _idBackPhoto,
    };
  }
}