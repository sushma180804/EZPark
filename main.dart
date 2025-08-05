// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ezpark/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const EZParkApp());
}

class EZParkApp extends StatelessWidget {
  const EZParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EZPark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF23395d), // Deep elegant blue
          primary: const Color(0xFF23395d), // Deep elegant blue
          secondary: const Color(0xFFb8b5ff), // Soft lavender accent
          surface: const Color(0xFFF7F8FA), // Gentle off-white
          onPrimary: Colors.white,
          onSecondary: const Color(0xFF23395d),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA), // Gentle off-white
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF23395d)),
          headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF23395d)),
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F5D75)),
          bodyMedium: TextStyle(color: Color(0xFF4F5D75)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FA),
          elevation: 0,
          foregroundColor: Color(0xFF23395d),
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFEDECF3), // Soft background for inputs
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          hintStyle: TextStyle(color: Color(0xFFb8b5ff)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF23395d),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            shadowColor: Color(0xFFb8b5ff),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 3,
          color: Color(0xFFEDECF3), // Soft card background
          shadowColor: Color(0xFFb8b5ff),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
      home: const AuthGate(),
    );
  }
}