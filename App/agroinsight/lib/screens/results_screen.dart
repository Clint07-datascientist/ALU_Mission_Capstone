import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ResultsScreen extends StatelessWidget {
  final String diseaseClass;
  final double confidenceScore;

  const ResultsScreen({
    super.key, 
    required this.diseaseClass, 
    required this.confidenceScore,
  });

  // Dynamic Treatment Logic
  List<String> _getInsights(String disease) {
    if (disease == 'Healthy') {
      return [
        'Continue standard care and maintenance.',
        'Maintain current watering and fertilizer schedule.',
        'Monitor weekly for any sudden changes.'
      ];
    } else if (disease == 'Leaf rust') {
      return [
        '⚠️ HIGHLY CONTAGIOUS: Prune affected branches immediately.',
        'Apply copper-based fungicides to halt spore spread.',
        'Check neighboring trees within a 10-meter radius today.',
        'Ensure proper canopy airflow to reduce humidity.'
      ];
    } else {
      return [
        'Remove and destroy heavily mined/damaged leaves.',
        'Avoid broad-spectrum sprays that kill natural predators (wasps).',
        'For severe infestations, apply targeted systemic insecticides.',
        'Clear fallen debris at the base of the tree.'
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    List<String> insights = _getInsights(diseaseClass);

    if (diseaseClass == 'Healthy') {
      statusColor = const Color(0xFF2E7D32); 
      statusIcon = FontAwesomeIcons.leaf;
    } else if (diseaseClass == 'Leaf rust') {
      statusColor = const Color(0xFFD84315); 
      statusIcon = FontAwesomeIcons.triangleExclamation;
    } else {
      statusColor = const Color(0xFF795548); 
      statusIcon = FontAwesomeIcons.bug;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: Text('Diagnostic Results', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView( // Added to allow scrolling for the new content
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Results Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
                boxShadow: [BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(statusIcon, color: statusColor, size: 60),
                  ),
                  const SizedBox(height: 24),
                  Text('AI Pathogen Analysis', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500], letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(diseaseClass.toUpperCase(), style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: statusColor)),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Confidence Score', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      Text('${(confidenceScore * 100).toStringAsFixed(1)}%', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: confidenceScore,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // NEW: Actionable Insights Card
            Text('Recommended Actions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(FontAwesomeIcons.circleCheck, color: statusColor, size: 16),
                      const SizedBox(width: 12),
                      Expanded(child: Text(insight, style: GoogleFonts.inter(fontSize: 14, height: 1.4))),
                    ],
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 32),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('LOG SCAN & RETURN', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}