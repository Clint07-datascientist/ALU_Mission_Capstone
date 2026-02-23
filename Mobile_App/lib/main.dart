import 'package:flutter/material.dart';
import 'package:agro_insight/screens/dashboard_screen.dart';
import 'package:agro_insight/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SQLite before the app runs
  await DatabaseHelper.instance.database; 
  runApp(const AgroInsightApp());
}

class AgroInsightApp extends StatelessWidget {
  const AgroInsightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroInsight',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade800),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}