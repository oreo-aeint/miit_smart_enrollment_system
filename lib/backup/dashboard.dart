import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Stats
  int total = 0;
  int pending = 0;
  int enrolled = 0;
  int rejected = 0;

  // Student List (Dummy Data for Now)
  List<Map<String, String>> students = [
    {
      "name": "aeintChitThu".tr(),
      "status": "enrolled".tr(),
      "major": "CSE",
      "batch": "2022".tr(),
      "Roll-no": "2022-MIIT-CSE-011",
    },
    {
      "name": "phyoMyatHtooSint".tr(),
      "status": "enrolled".tr(),
      "major": "CSE",
      "batch": "2022".tr(),
      "Roll-no": "2022-MIIT-CSE-023",
    },

    {
      "name": "winPaPaPhyo".tr(),
      "status": "enrolled".tr(),
      "major": "CSE",
      "batch": "2022".tr(),
      "Roll-no": "2022-MIIT-CSE-029",
    },
    {
      "name": "suYadanarWin".tr(),
      "status": "rejected".tr(),
      "major": "CSE",
      "batch": "2018".tr(),
      "Roll-no": "2018-MIIT-CSE-045",
    },
    {
      "name": "minKhantMaung".tr(),
      "status": "pending1".tr(),
      "major": "CSE",
      "batch": "2025".tr(),
      "Roll-no": "2025-MIIT-CSE-001",
    },
  ];
  List<Map<String, String>> filteredStudents = [];

  // Search text
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    updateStats();
    filteredStudents = students; // initially show all students
  }

  void updateStats() {
    total = students.length;
    enrolled = students.where((s) => s["status"] == "enrolled".tr()).length;
    pending = students.where((s) => s["status"] == "pending1".tr()).length;
    rejected = students.where((s) => s["status"] == "rejected".tr()).length;
  }

  void filterStudents(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      if (searchQuery.isEmpty) {
        filteredStudents = students;
      } else {
        filteredStudents = students
            .where(
              (s) =>
          s["major"]!.toLowerCase().contains(searchQuery) ||
              s["name"]!.toLowerCase().contains(searchQuery) ||
              s["batch"]!.toLowerCase().contains(searchQuery) ||
              s["Roll-no"]!.toLowerCase().contains(searchQuery),
        )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoCard(Icons.people, "total".tr(), total.toString()),
                _buildInfoCard(
                  Icons.pending_actions,
                  "pending".tr(),
                  pending.toString(),
                ),
                _buildInfoCard(
                  Icons.assignment_turned_in,
                  "enroll1".tr(),
                  enrolled.toString(),
                ),
                _buildInfoCard(
                  Icons.cancel_presentation,
                  "reject".tr(),
                  rejected.toString(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Student List Section
            Text(
              "studentList".tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 10),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black54),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.black54),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      onChanged: filterStudents, // <-- Search filter applied
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "searchHint".tr(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Student List Display
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.blue.shade100,
                child: filteredStudents.isEmpty
                    ? Center(
                  child: Text(
                    'noStudentsFound'.tr(),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 16,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.person,
                          color: Colors.indigo,
                        ),
                        title: Text(student["name"]!),
                        subtitle: Text(
                          "${"major".tr()}: ${student["major"]}",
                        ),
                        children: [
                          ListTile(
                            title: Text(
                              "${"status".tr()}: ${student["status"]}",
                            ),
                          ),
                          ListTile(
                            title: Text(
                              "${"batch".tr()}: ${student["batch"]}",
                            ),
                          ),
                          if (student.containsKey("Roll-no"))
                            ListTile(
                              title: Text(
                                "${"rollNo".tr()}: ${student["Roll-no"]}",
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for small info cards
  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.black87, size: 28),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
