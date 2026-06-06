import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart'; // 🔹 Required for web
import 'package:path_provider/path_provider.dart'; // Add this

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // Test path_provider before initializing Firebase
  try {
    print('🔧 Testing path_provider...');
    final tempDir = await getTemporaryDirectory();
    print('✅ Temporary directory: ${tempDir.path}');
  } catch (e) {
    print('❌ path_provider error: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 🔹 Required for web
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('my'),
      ],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      child: const MIITApp(),
    ),
  );
}

class MIITApp extends StatelessWidget {
  const MIITApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIIT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const MIITHomePage(),
    );
  }
}
