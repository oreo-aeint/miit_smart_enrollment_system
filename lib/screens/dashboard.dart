import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> filteredStudents = [];

  final List<Map<String, dynamic>> _students = [
    {
      "id": 1,
      "name": "May Yu Ya Myet Chare",
      "status": "Pending",
      "major": "Computer Science",
      "batch": "2026",
      "rollNo": "2026-CS-001",
      "studentStatus": "Active",
      "email": "may.yu@example.com",
      "phone": "09-123456789",
    },
    {
      "id": 2,
      "name": "Pai Min Thway",
      "status": "Enrolled",
      "major": "Computer Science",
      "batch": "2026",
      "rollNo": "2026-CS-002",
      "studentStatus": "Active",
      "email": "paimin@example.com",
      "phone": "09-234567890",
    },
    {
      "id": 3,
      "name": "Han Phyo Thaw",
      "status": "Enrolled",
      "major": "Software Engineering",
      "batch": "2025",
      "rollNo": "2025-SE-001",
      "studentStatus": "Active",
      "email": "hanphyo@example.com",
      "phone": "09-345678901",
    },
    {
      "id": 4,
      "name": "Aung Aung",
      "status": "Graduated",
      "major": "Information Technology",
      "batch": "2022",
      "rollNo": "2022-IT-011",
      "studentStatus": "Inactive",
      "email": "aungaung@example.com",
      "phone": "09-456789012",
    },
    {
      "id": 5,
      "name": "Khin Khin",
      "status": "Enrolled",
      "major": "Data Science",
      "batch": "2024",
      "rollNo": "2024-DS-001",
      "studentStatus": "Active",
      "email": "khinkhin@example.com",
      "phone": "09-567890123",
    },
    {
      "id": 6,
      "name": "Zaw Zaw",
      "status": "Withdrawn",
      "major": "Computer Science",
      "batch": "2023",
      "rollNo": "2023-CS-015",
      "studentStatus": "Inactive",
      "email": "zawzaw@example.com",
      "phone": "09-678901234",
    },
    {
      "id": 7,
      "name": "Su Su",
      "status": "Enrolled",
      "major": "Cyber Security",
      "batch": "2025",
      "rollNo": "2025-CY-003",
      "studentStatus": "Active",
      "email": "susu@example.com",
      "phone": "09-789012345",
    },
  ];

  @override
  void initState() {
    super.initState();
    filteredStudents = _students;

    // Listen to search controller changes
    _searchController.addListener(() {
      _performSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredStudents = _students;
      } else {
        filteredStudents = _students.where((student) {
          return student['name'].toString().toLowerCase().contains(query) ||
              student['rollNo'].toString().toLowerCase().contains(query) ||
              student['batch'].toString().toLowerCase().contains(query) ||
              student['major'].toString().toLowerCase().contains(query) ||
              student['status'].toString().toLowerCase().contains(query) ||
              student['studentStatus'].toString().toLowerCase().contains(query) ||
              student['email'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch();
    _searchFocusNode.unfocus();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'enrolled':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'graduated':
        return Colors.purple;
      case 'withdrawn':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and search
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dashboard".tr(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_students.length} Total Students",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Search Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: "Search students...",
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Search hint
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  "Try searching by name, ID, major, or batch",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Results header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Student List",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${filteredStudents.length} results",
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Student List
              Expanded(
                child: filteredStudents.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No students found",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Try a different search term",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: ElevatedButton(
                            onPressed: _clearSearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              "Clear Search",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    : ListView.separated(
                  itemCount: filteredStudents.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return _buildStudentCard(student);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student['rollNo'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(student['studentStatus'])
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    student['studentStatus'],
                    style: TextStyle(
                      color: _getStatusColor(student['studentStatus']),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Student details
            Row(
              children: [
                _buildDetailItem(
                  Icons.school,
                  student['major'],
                ),
                const SizedBox(width: 24),
                _buildDetailItem(
                  Icons.calendar_today,
                  "Batch ${student['batch']}",
                ),
                const SizedBox(width: 24),
                _buildDetailItem(
                  Icons.flag,
                  student['status'],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Contact info
            Row(
              children: [
                _buildContactItem(
                  Icons.email,
                  student['email'],
                ),
                const SizedBox(width: 16),
                _buildContactItem(
                  Icons.phone,
                  student['phone'],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.remove_red_eye, size: 18),
                    label: const Text("View Profile"),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Edit"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}