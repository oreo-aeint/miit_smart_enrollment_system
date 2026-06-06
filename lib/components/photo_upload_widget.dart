import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

class PhotoUploadWidget extends StatelessWidget {
  final File? imageFile;
  final Function(File) onImagePicked;
  final String label;
  final double width;
  final double height;
  final bool isRequired;

  const PhotoUploadWidget({
    Key? key,
    required this.imageFile,
    required this.onImagePicked,
    required this.label,
    this.width = 100,
    this.height = 120,
    this.isRequired = false,
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      onImagePicked(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: isRequired && imageFile == null ? Colors.red : Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        child: imageFile != null
            ? Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                imageFile!,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}