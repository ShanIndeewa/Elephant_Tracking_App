import 'package:flutter/material.dart';
import 'package:elephant_tracker_app/views/login/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gaja-Mithra',
      theme: ThemeData(
        // Using a light theme as the background is light
        brightness: Brightness.light,
        // Applying the new color palette
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5A827E),      // Tealish Green
          secondary: Color(0xFF84AE92),   // Lighter Green
          background: Color(0xFFFAFFCA),  // Light Cream/Yellow
          surface: Color(0xFFB9D4AA),     // Even Lighter Green
          error: Colors.red,              // Danger alerts remain red
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.black,
          onSurface: Colors.black,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFFCA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5A827E),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF5A827E), width: 2.0),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
