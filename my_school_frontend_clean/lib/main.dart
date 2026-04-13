import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MySchoolApp());
}

class MySchoolApp extends StatelessWidget {
  const MySchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My School',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFF2D5F8B),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const LoginScreen(),
    );
  }
}