import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/database/database_helper.dart';
import 'farm_heatmap.dart';

class FarmRegistrationScreen extends StatefulWidget {
  const FarmRegistrationScreen({super.key});

  static String routeName = 'FarmRegistration';
  static String routePath = '/farmRegistration';

  @override
  State<FarmRegistrationScreen> createState() => _FarmRegistrationWidgetState();
}

class _FarmRegistrationWidgetState extends State<FarmRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Position?> _corners = List<Position?>.filled(4, null);
  bool _capturing = false;
  bool _saving = false;

  int get _capturedCount => _corners.whereType<Position>().length;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _captureCorner() async {
    if (_capturing || _capturedCount >= 4) return;
    setState(() => _capturing = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Enable GPS to capture corners.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Location permission is required.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final nextIndex = _corners.indexWhere((item) => item == null);
      if (nextIndex >= 0) {
        setState(() => _corners[nextIndex] = position);
      }
    } catch (e) {
      _showSnack('Failed to capture location: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _finalizeFarm() async {
    if (_saving) return;
    final farmName = _nameController.text.trim();
    if (farmName.isEmpty) {
      _showSnack('Please enter a farm name.');
      return;
    }
    if (_capturedCount < 4) {
      _showSnack('Capture all 4 corners first.');
      return;
    }

    setState(() => _saving = true);
    try {
      final points = _corners.whereType<Position>().toList(growable: false);
      final lats = points.map((e) => e.latitude).toList();
      final lngs = points.map((e) => e.longitude).toList();
      final minLat = lats.reduce((a, b) => a < b ? a : b);
      final maxLat = lats.reduce((a, b) => a > b ? a : b);
      final minLng = lngs.reduce((a, b) => a < b ? a : b);
      final maxLng = lngs.reduce((a, b) => a > b ? a : b);

      final farmId = await DatabaseHelper.instance.insertFarm({
        'name': farmName,
        'min_lat': minLat,
        'max_lat': maxLat,
        'min_lng': minLng,
        'max_lng': maxLng,
      });

      if (!mounted) return;
      _showSnack('Farm saved offline (ID: $farmId).');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FarmHeatmapScreen()),
      );
    } catch (e) {
      _showSnack('Failed to save farm: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Register New Farm',
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
                  color: const Color(0xFF212121),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
          ),
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Farm Name',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Capture Corners',
                        style: FlutterFlowTheme.of(context).titleSmall.override(
                              font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_capturedCount / 4',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemBuilder: (context, index) {
                      final corner = _corners[index];
                      final captured = corner != null;
                      return Container(
                        decoration: BoxDecoration(
                          color: captured ? Colors.white : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: captured ? const Color(0xFF2E7D32) : const Color(0xFFB0B0B0),
                            width: captured ? 2 : 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              captured ? Icons.check_circle_rounded : Icons.location_on,
                              color: captured ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E),
                            ),
                            Text('Corner ${index + 1}'),
                            Text(
                              captured
                                  ? 'Lat: ${corner.latitude.toStringAsFixed(5)}\nLng: ${corner.longitude.toStringAsFixed(5)}'
                                  : 'Awaiting GPS...',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
                            ),
                          ].divide(const SizedBox(height: 6)),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: FFButtonWidget(
                    onPressed: _capturing ? null : _captureCorner,
                    text: _capturing ? 'CAPTURING...' : 'CAPTURE CURRENT LOCATION',
                    icon: const Icon(Icons.gps_fixed, size: 20),
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 54,
                      color: const Color(0xFFD84315),
                      iconColor: Colors.white,
                      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                            font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  child: FFButtonWidget(
                    onPressed: (_capturedCount == 4 && !_saving) ? _finalizeFarm : null,
                    text: _saving ? 'SAVING...' : 'Finalize Registration',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 48,
                      color: (_capturedCount == 4 && !_saving)
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE0E0E0),
                      textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                            color: (_capturedCount == 4 && !_saving)
                                ? Colors.white
                                : const Color(0xFF9E9E9E),
                          ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
