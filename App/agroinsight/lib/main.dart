import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding_1.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase must not block the first frame. On Android, missing
  // `google-services.json` / Gradle wiring can make `initializeApp` fail or
  // misbehave; the app is still usable offline without cloud sync until fixed.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Firebase.initializeApp timed out'),
      );
    } catch (e, st) {
      debugPrint('Firebase init skipped or failed (UI will still run): $e');
      debugPrint('$st');
    }
  }
  runApp(const AgroInsightApp());
}

class AgroInsightApp extends StatelessWidget {
  const AgroInsightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroInsight Edge',
      debugShowCheckedModeBanner: false, // Removes the red debug banner
      
      // THE SLEEK UI THEME ENGINE
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Deep organic green
          brightness: Brightness.light,
          secondary: const Color(0xFFD84315), // Earthy accent for scan buttons
        ),
        
        // Apply modern typography globally
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.light().textTheme,
        ),
        
        // Force all cards to have soft, modern rounded corners
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        
        // Style the main action buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Pill-shaped buttons
            ),
          ),
        ),
      ),
      home: const Onboarding1Widget(),
    );
  }
}