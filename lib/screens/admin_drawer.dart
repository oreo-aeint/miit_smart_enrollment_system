import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_info.dart';
import 'profile_screen.dart';
import 'enrollment_request_page.dart';
import 'excel_uploader.dart';
import 'student_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('my')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    child: const AdminDrawer(),
  ));
}

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.indigo,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'studentInfo'.tr(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<String> _appBarTitles = [
    'StudentInfo',
    'EnrollRequest',
    'UploadData',
    'StudentResults',
    'Profile',
  ];

  final List<Widget> _screens = [
    const StudentInfoScreen(),
    const EnrollmentRequestPage(),
    ExcelUploader(),
    StudentResultsPage(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Custom App Bar with dynamic title
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Color(0xFF87CEFA),
                  Color(0xFFADD8E6),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 30.0, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Language Dropdown with Icon and Text on LEFT
                  // Language Dropdown with Icon and Text on LEFT
                  DropdownButton<Locale>(
                    underline: const SizedBox(),
                    // Remove the icon parameter from here
                    value: context.locale,
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) context.setLocale(newLocale);
                    },
                    items: const [
                      DropdownMenuItem(
                        value: Locale('en'),
                        child: Row(
                          children: [
                            Icon(Icons.language, color: Colors.indigo, size: 20),
                            SizedBox(width: 8),
                            Text("English"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Locale('my'),
                        child: Row(
                          children: [
                            Icon(Icons.language, color: Colors.indigo, size: 20),
                            SizedBox(width: 8),
                            Text("မြန်မာ"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Notification Icon on RIGHT
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('enrollment_requests')
                        .where('status', isEqualTo: 'Pending')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int count = snapshot.data?.docs.length ?? 0;
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Colors.indigo),
                            onPressed: () {
                              _pageController.jumpToPage(1);
                              setState(() => _currentIndex = 1);
                            },
                          ),
                          if (count > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor: Colors.red,
                                child: Text(
                                  count > 9 ? '9+' : count.toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: PageView(
              controller: _pageController,
              children: _screens,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavItem(Icons.dashboard, 'Students Info'.tr(), 0),
            _buildNavItem(Icons.add_circle_outline, 'Enroll Request'.tr(), 1),
            _buildNavItem(Icons.upload_file, 'Upload'.tr(), 2),
            _buildNavItem(Icons.people, 'Students List'.tr(), 3),
            _buildNavItem(Icons.account_circle, 'Profile'.tr(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = index == _currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
            _pageController.jumpToPage(index);
          });
        },
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.indigo.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.indigo : Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.indigo : Colors.black,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}