import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addSampleStudents() async {
  final students = [
    {
      "semail": "2022-miit-ece-001@miit.edu.mm",
      "rollNumber": "2022-miit-ece-001",
      "academicYear": "2024-2025",
      "courseYear": "First Year First Sem",
      "grade": "A",
      "examResult": "Pass",
    },
    {
      "semail": "2022-miit-cse-002@miit.edu.m",
      "rollNumber": "2022-miit-cse-002",
      "academicYear": "2024-2025",
      "courseYear": "First Year First Sem",
      "grade": "B+",
      "examResult": "Pass",
    },
    {
      "semail": "2022-miit-mech-003@miit.edu.m",
      "rollNumber": "2022-miit-mech-003",
      "academicYear": "2024-2025",
      "courseYear": "First Year First Sem",
      "grade": "A-",
      "examResult": "Pass",
    },
    {
      "semail": "2022-miit-ece-004@miit.edu.m",
      "rollNumber": "2022-miit-ece-004",
      "academicYear": "2024-2025",
      "courseYear": "First Year First Sem",
      "grade": "C",
      "examResult": "Fail",
    },
    {
      "semail": "2022-miit-cse-005@miit.edu.m",
      "rollNumber": "2022-miit-cse-005",
      "academicYear": "2024-2025",
      "courseYear": "First Year First Sem",
      "grade": "B",
      "examResult": "Pass",
    },
  ];

  final collection = FirebaseFirestore.instance.collection("student_list");

  for (var student in students) {
    await collection.add(student); // auto-ID
  }

  print("✅ All sample students added!");
}
