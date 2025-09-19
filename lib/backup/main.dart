import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This will be generated automatically
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase
  await _initializeFirebase();

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

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // You might want to show an error screen or retry logic here
  }
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