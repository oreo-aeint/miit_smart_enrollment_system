import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:miit_project/components/button.dart';
import 'package:miit_project/components/text.dart';
import 'package:miit_project/screens/enroll_button_screen.dart';
import 'admin_login_screen.dart';
import 'package:miit_project/screens/exam_service.dart';

class MIITHomePage extends StatelessWidget {
  const MIITHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/img_3.png',
              fit: BoxFit.cover,
              color: Colors.white.withOpacity(0.7),
              colorBlendMode: BlendMode.modulate,
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Top Row: Logo + Title + Language Switch
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/img_2.png', width: 60, height: 60),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('miit'),
                          style: AppTextStyles.heading,
                        ),
                      ),

                      // Language Switch Button (top-right)
                      DropdownButton<Locale>(
                        underline: const SizedBox(),
                        icon: const Icon(Icons.language, color: Colors.black),
                        value: context.locale,
                        onChanged: (Locale? newLocale) {
                          if (newLocale != null) {
                            context.setLocale(newLocale);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: Locale('en'),
                            child: Text("English"),
                          ),
                          DropdownMenuItem(
                            value: Locale('my'),
                            child: Text("မြန်မာ"),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // MIIT Description Text (localized)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        children: [
                          // Text border
                          Text(
                            tr('miitDescription'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.6,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..color = Colors.white, // border color
                            ),
                            textAlign: TextAlign.left,
                          ),
                          // Filled text
                          Text(
                            tr('miitDescription'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.6,
                              color: Colors.black, // main text color
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom-right buttons
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Enroll Button
                        SizedBox(
                          width: 200,
                          child: ActionButton(
                            text: tr('enroll'),
                            icon: Icons.school,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EnrollButtonScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Admin Login Button
                        SizedBox(
                          width: 200,
                          child: ActionButton(
                            text: tr('adminLogin'),
                            icon: Icons.person_2_rounded,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminLoginScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                       //exam data
                       /* ElevatedButton(
                          onPressed: () async {
                            await ExamService.createExamsForAllStudents(); // Add class name
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Exam records created successfully!')),
                            );
                          },
                          child: Text('Create Exam Records'),
                        ),*/
                       /* ElevatedButton(
                          onPressed: () async {
                            final students = [
                             {
                                "semail": "2025-miit-cse-011@miit.edu.mm",
                                "rollNumber": "2025-miit-cse-011",
                                "academicYear": "2025-2026",
                                "courseYear": "First Year",
                                "grade": "A",
                                "examResult": "Pass",
                              },
                              {
                                "semail": "2025-miit-cse-029@miit.edu.mm", // Fixed email domain
                                "rollNumber": "2025-miit-cse-029",
                                "academicYear": "2025-2026",
                                "courseYear": "First Year",
                                "grade": "A",
                                "examResult": "Pass",
                              },
                              {
                                "semail": "2025-miit-cse-023@miit.edu.mm", // Fixed email domain
                                "rollNumber": "2025-miit-cse-023",
                                "academicYear": "2025-2026",
                                "courseYear": "First Year",
                                "grade": "A",
                                "examResult": "Pass",
                              },
                              {
                                "semail": "2025-miit-cse-010@miit.edu.mm", // Fixed email domain
                                "rollNumber": "2025-miit-cse-010",
                                "academicYear": "2025-2026",
                                "courseYear": "First Year",
                                "grade": "C",
                                "examResult": "Fail",
                              },
                              {
                                "semail": "2025-miit-ece-015@miit.edu.mm", // Fixed email domain
                                "rollNumber": "2025-miit-ece-015",
                                "academicYear": "2025-2026",
                                "courseYear": "First Year",
                                "grade": "B",
                                "examResult": "Pass",
                              },
                            ];

                            final collection = FirebaseFirestore.instance.collection("student_list");

                            for (var student in students) {
                              final rollNumber = student["rollNumber"] as String;
                              await collection.doc(rollNumber).set(student); // Use rollNumber as document ID
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ Sample students added")),
                            );
                          },
                          child: const Text("Add Sample Students"),
                        )*/
                        //Adding entrance passed students
                       /* ElevatedButton(
                          onPressed: () async {
                            final entrance_pass_stu = [
                              {
                                "fullName": "Aeint Chit Thu",
                                "rollNumber": "2025-miit-cse-011",
                              },
                              {
                                "fullName": "Phyo Myat Htoo Sint",
                                "rollNumber": "2025-miit-cse-023",
                              },
                              {
                                "fullName": "Win Pa Pa Phyo",
                                "rollNumber": "2025-miit-cse-029",
                              },
                            ];

                            final collection = FirebaseFirestore.instance.collection("entrance_pass_stu");

                            for (var student in entrance_pass_stu) {
                              // Use rollNumber as the document ID
                              await collection.doc(student["rollNumber"]).set(student);
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ Sample students added")),
                            );
                          },
                          child: const Text("Add Sample Students"),
                        )*/
                        // Adding exam data for 2026-miit-cse-001 to 2026-miit-cse-010
                      /*  ElevatedButton(
                          onPressed: () async {
                            final examsCollection = FirebaseFirestore.instance.collection("exams");

                            for (int i = 1; i <= 10; i++) {
                              final rollNumber = "2026-miit-cse-${i.toString().padLeft(3, '0')}";

                              final examData = {
                                "firstYear": {
                                  "firstSemester": "—",
                                  "secondSemester": "—",
                                },
                                "secondYear": {
                                  "firstSemester": "—",
                                  "secondSemester": "—",
                                },
                                "thirdYear": {
                                  "firstSemester": "—",
                                  "secondSemester": "—",
                                },
                                "fourthYear": {
                                  "firstSemester": "—",
                                  "secondSemester": "—",
                                },
                                "finalYear": {
                                  "firstSemester": "—",
                                  "secondSemester": "—",
                                },
                                "MEFirstYear": {
                                  "firstSemester": "—",
                                  "secondSemester": "—",
                                },
                                "MESecondYear": {
                                  "firstSemester": "—",
                                  "secondSemester": "—",
                                },
                              };

                              // Use roll number as document ID
                              await examsCollection.doc(rollNumber).set(examData);
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ Exam data added with default '—' semesters")),
                            );
                          },
                          child: const Text("Add Exam Data"),
                        ),*/


                        /*ElevatedButton(
                          onPressed: () async {
                            final examsCollection = FirebaseFirestore.instance.collection("exams");

                            for (int i = 1; i <= 5; i++) {
                              final rollNumber = "2026-miit-cse-${i.toString().padLeft(3, '0')}";

                              final examData = {
                                "firstYear": {
                                  "firstSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                  "secondSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                },
                                "secondYear": {
                                  "firstSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                  "secondSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                },
                                "thirdYear": {
                                  "firstSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                  "secondSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                },
                                "fourthYear": {
                                  "firstSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                  "secondSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                },
                                "finalYear": {
                                  "firstSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                  "secondSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                },
                                "MEFirstYear": {
                                  "firstSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                  "secondSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                },
                                "MESecondYear": {
                                  "firstSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                  "secondSemester": {
                                    "CGPA": "—",
                                    "SGPA": "—",
                                  },
                                },
                              };

                              try {
                                await examsCollection.doc(rollNumber).set(examData);
                                print("✅ Added exam record for $rollNumber");
                              } catch (e) {
                                print("❌ Error adding $rollNumber: $e");
                              }
                            }

                            print("🎓 All exam data uploaded successfully!");
                          },
                          child: const Text("Upload Exam Data"),
                        )*/

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
