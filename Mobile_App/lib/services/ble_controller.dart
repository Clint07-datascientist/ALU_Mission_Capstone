import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:agro_insight/database/database_helper.dart';
import 'package:agro_insight/screens/scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Set<Marker> _markers = {};
  
  // Centers the map map roughly around Kigali / Rutsiro on startup
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(-1.9441, 30.0619), 
    zoom: 8.0,
  );

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  Future<void> _loadHeatmapData() async {
    final records = await DatabaseHelper.instance.fetchAllRecords();
    setState(() {
      _markers.clear();
      for (var record in records) {
        double hue;
        // Color code based on disease class
        if (record['disease_class'] == 'Healthy') {
          hue = BitmapDescriptor.hueGreen;
        } else if (record['disease_class'] == 'Leaf rust') {
          hue = BitmapDescriptor.hueRed;
        } else {
          hue = BitmapDescriptor.hueOrange; // Miner
        }

        _markers.add(
          Marker(
            markerId: MarkerId(record['id'].toString()),
            position: LatLng(record['latitude'], record['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title: record['disease_class'],
              snippet: 'Confidence: ${(record['confidence'] * 100).toStringAsFixed(1)}%',
            ),
          )
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroInsight Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadHeatmapData,
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        markers: _markers,
        myLocationEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to scanner, wait for return, then refresh map
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen()),
          );
          _loadHeatmapData();
        },
        label: const Text('Connect to Probe'),
        icon: const Icon(Icons.bluetooth),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
}