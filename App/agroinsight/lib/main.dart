import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart'; // This correctly points to your new UI file

void main() {
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
          Theme.of(context).textTheme,
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
      // This now perfectly links to the massive orange button screen!
      home: const DashboardScreen(), 
    );
  }
}