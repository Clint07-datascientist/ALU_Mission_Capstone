import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FarmHeatmapScreen extends StatelessWidget {
  const FarmHeatmapScreen({super.key});

  // Simulated MVP Data: 12 Farm Sectors (A1 to C4)
  // 0 = Healthy, 1 = Miner (Warning), 2 = Leaf Rust (Critical)
  final List<Map<String, dynamic>> farmSectors = const [
    {'id': 'A1', 'status': 0, 'lastScan': 'Today, 08:30 AM'},
    {'id': 'A2', 'status': 0, 'lastScan': 'Today, 09:15 AM'},
    {'id': 'A3', 'status': 1, 'lastScan': 'Today, 10:00 AM'}, // Miner
    {'id': 'A4', 'status': 0, 'lastScan': 'Yesterday'},
    {'id': 'B1', 'status': 0, 'lastScan': 'Today, 07:45 AM'},
    {'id': 'B2', 'status': 2, 'lastScan': 'Today, 11:30 AM'}, // Rust
    {'id': 'B3', 'status': 2, 'lastScan': 'Today, 11:45 AM'}, // Rust Spreading
    {'id': 'B4', 'status': 1, 'lastScan': 'Yesterday'},       // Miner
    {'id': 'C1', 'status': 0, 'lastScan': '2 days ago'},
    {'id': 'C2', 'status': 0, 'lastScan': 'Today, 06:20 AM'},
    {'id': 'C3', 'status': 0, 'lastScan': 'Yesterday'},
    {'id': 'C4', 'status': 0, 'lastScan': '3 days ago'},
  ];

  Color _getSectorColor(int status) {
    if (status == 0) return const Color(0xFF2E7D32).withOpacity(0.8); // Green
    if (status == 1) return const Color(0xFF795548).withOpacity(0.9); // Brown
    return const Color(0xFFD84315).withOpacity(0.9); // Red/Orange
  }

  String _getStatusText(int status) {
    if (status == 0) return 'Healthy';
    if (status == 1) return 'Miner Detected';
    return 'Leaf Rust Detected';
  }

  void _showSectorDetails(BuildContext context, Map<String, dynamic> sector) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sector ${sector['id']}', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Last Scanned: ${sector['lastScan']}', style: GoogleFonts.inter(color: Colors.grey[600])),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(color: _getSectorColor(sector['status']), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getStatusText(sector['status']),
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: _getSectorColor(sector['status'])),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('CLOSE', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: Text('Rutsiro Zone Map', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Farm Heatmap', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tap a grid sector to view recent pathology logs.', style: GoogleFonts.inter(color: Colors.grey[600])),
            const SizedBox(height: 32),
            
            // The Grid Layout
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(), // Keeps it locked as a static map
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 columns wide
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0, // Perfect squares
                ),
                itemCount: farmSectors.length,
                itemBuilder: (context, index) {
                  final sector = farmSectors[index];
                  return GestureDetector(
                    onTap: () => _showSectorDetails(context, sector),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getSectorColor(sector['status']),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          sector['id'],
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Legend
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LegendItem(color: const Color(0xFF2E7D32), label: 'Healthy'),
                  _LegendItem(color: const Color(0xFF795548), label: 'Miner'),
                  _LegendItem(color: const Color(0xFFD84315), label: 'Rust'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}