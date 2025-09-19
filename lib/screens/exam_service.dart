// exam_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ExamService {
  // Add 'static' keyword here
  static Future<void> createExamsForAllStudents() async {
    try {
      // Get students from BOTH collections
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .get();

      final studentListSnapshot = await FirebaseFirestore.instance
          .collection('student_list')
          .get();

      // Combine all students
      final allStudents = [
        ...studentsSnapshot.docs.map((doc) => doc.data()),
        ...studentListSnapshot.docs.map((doc) => doc.data()),
      ];

      final examsCollection = FirebaseFirestore.instance.collection('exams');
      int createdCount = 0;

      for (var student in allStudents) {
        final email = student['semail'];
        final rollNumber = student['srollno'] ?? student['rollNumber'];
        final academicYear = student['academicInfo']?['academicYear'] ?? '2024-2025';
        final courseYear = student['academicInfo']?['courseYear'] ?? 'Second Year';

        if (email != null && rollNumber != null) {
          // ✅ Use roll number as document ID
          await examsCollection.doc(rollNumber).set({
            "semail": email,
            "rollNumber": rollNumber,
            "academicYear": academicYear,
            "courseYear": courseYear,
            "passOrFail": "Pass",
            "overallGrade": "A",
            "timestamp": FieldValue.serverTimestamp(),
          });
          createdCount++;
        }
      }

      print("✅ Created $createdCount exam records");

    } catch (e) {
      print("❌ Error creating exams: $e");
    }
  }
}