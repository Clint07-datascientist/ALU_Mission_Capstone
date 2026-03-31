import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/database/database_helper.dart';
import '../core/geo/sector_math.dart';
import 'sector_overview.dart';

class FarmHeatmapScreen extends StatefulWidget {
  const FarmHeatmapScreen({super.key});

  static String routeName = 'Updated_FarmHeat_Map';
  static String routePath = '/updatedFarmHeatMap';

  @override
  State<FarmHeatmapScreen> createState() => _FarmHeatmapScreenState();
}

class _FarmHeatmapScreenState extends State<FarmHeatmapScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _farm;
  Map<String, int> _sectorScores = {
    for (final id in SectorGrid.allSectorIds()) id: -1,
  };
  Position? _myPosition;
  bool _showMyLocation = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHeatmap();
  }

  Future<void> _loadHeatmap() async {
    setState(() => _loading = true);
    final farm = await DatabaseHelper.instance.getLatestFarm();
    if (farm == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final records = await DatabaseHelper.instance.getRecordsForFarm(farm['id'] as int);
    final scores = {for (final id in SectorGrid.allSectorIds()) id: -1};
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));

    for (final row in records) {
      final dbSector = (row['sector_id'] as String?) ?? 'A1';
      final uiSector = SectorGrid.pairedSectorId(dbSector);
      final recordedAtRaw = (row['recorded_at'] as String?) ?? '';
      final recordedAt = DateTime.tryParse(recordedAtRaw);
      if (recordedAt == null || recordedAt.isBefore(cutoff)) {
        continue;
      }

      final name = ((row['disease_name'] as String?) ?? '').trim().toLowerCase();
      final confidence = ((row['confidence_score'] as num?) ?? 0).toDouble();

      var score = -1;
      if (name == 'healthy') {
        score = 0;
      } else if ((name == 'leaf rust' ||
              name == 'coffee berry borer' ||
              name == 'coffee leaf miner' ||
              name == 'leaf miner') &&
          confidence >= 80.0) {
        score = 2;
      } else if (name.isNotEmpty) {
        score = 1;
      }
      final previous = scores[uiSector] ?? -1;
      if (score > previous) scores[uiSector] = score;
    }

    if (mounted) {
      setState(() {
        _farm = farm;
        _sectorScores = scores;
        _loading = false;
      });
    }
  }

  Future<void> _toggleMyLocation() async {
    if (_showMyLocation) {
      setState(() {
        _showMyLocation = false;
        _myPosition = null;
      });
      return;
    }

    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _snack('Location permission denied.');
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() {
      _myPosition = position;
      _showMyLocation = true;
    });
  }

  void _onHeatmapTap(TapUpDetails details, Size size) {
    final cellW = size.width / 3;
    final cellH = size.height / 4;
    final col = (details.localPosition.dx / cellW).floor().clamp(0, 2);
    final row = (details.localPosition.dy / cellH).floor().clamp(0, 3);
    final sectorId = '${String.fromCharCode(65 + row)}${col + 1}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SectorOverviewScreen(
          sectorId: sectorId,
          queryPairedDbSector: true,
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Farm Heatmap',
          style: FlutterFlowTheme.of(context).titleLarge.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
                color: const Color(0xFF212121),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _farm == null
                ? const Center(child: Text('No farm registered yet.'))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sector Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                Text('Farm: ${_farm!['name']}'),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _loadHeatmap,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final mapSize = Size(constraints.maxWidth, constraints.maxHeight);
                              Offset? blueDot;
                              if (_showMyLocation && _myPosition != null) {
                                final minLat = (_farm!['min_lat'] as num).toDouble();
                                final maxLat = (_farm!['max_lat'] as num).toDouble();
                                final minLng = (_farm!['min_lng'] as num).toDouble();
                                final maxLng = (_farm!['max_lng'] as num).toDouble();
                                final north = maxLat > minLat ? maxLat : minLat;
                                final south = maxLat > minLat ? minLat : maxLat;
                                final west = maxLng > minLng ? minLng : maxLng;
                                final east = maxLng > minLng ? maxLng : minLng;
                                final dx = ((_myPosition!.longitude - west) / (east - west)).clamp(0.0, 1.0);
                                final dy = ((north - _myPosition!.latitude) / (north - south)).clamp(0.0, 1.0);
                                blueDot = Offset(dx * mapSize.width, dy * mapSize.height);
                              }

                              return GestureDetector(
                                onTapUp: (d) => _onHeatmapTap(d, mapSize),
                                child: CustomPaint(
                                  size: mapSize,
                                  painter: _HeatmapPainter(
                                    sectorScores: _sectorScores,
                                    blueDot: blueDot,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        FFButtonWidget(
                          onPressed: _toggleMyLocation,
                          text: _showMyLocation ? 'HIDE MY LOCATION' : 'SHOW MY LOCATION',
                          icon: Icon(_showMyLocation ? Icons.location_on : Icons.location_off, size: 22),
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 52,
                            color: _showMyLocation ? const Color(0xFFD84315) : const Color(0xFFE0E0E0),
                            iconColor: _showMyLocation ? Colors.white : const Color(0xFF424242),
                            textStyle: TextStyle(
                              color: _showMyLocation ? Colors.white : const Color(0xFF424242),
                              fontWeight: FontWeight.bold,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  const _HeatmapPainter({required this.sectorScores, this.blueDot});

  final Map<String, int> sectorScores;
  final Offset? blueDot;

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 4;
    const cols = 3;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final sectorId = '${String.fromCharCode(65 + r)}${c + 1}';
        final score = sectorScores[sectorId] ?? -1;
        final color = score < 0
            ? const Color(0xFFBDBDBD)
            : score >= 2
                ? const Color(0xFFF44336)
                : score == 1
                    ? const Color(0xFFFFC107)
                    : const Color(0xFF2E7D32);

        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW - 2, cellH - 2);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

        final fillPaint = Paint()..color = color;
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, borderPaint);

        final labelColor = score == 1 ? const Color(0xFF212121) : Colors.white;
        final textPainter = TextPainter(
          text: TextSpan(
            text: sectorId,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            rect.center.dx - textPainter.width / 2,
            rect.center.dy - textPainter.height / 2,
          ),
        );
      }
    }

    if (blueDot != null) {
      final shadow = Paint()..color = const Color(0x661565C0);
      final fill = Paint()..color = const Color(0xFF1565C0);
      final stroke = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(blueDot!, 14, shadow);
      canvas.drawCircle(blueDot!, 10, fill);
      canvas.drawCircle(blueDot!, 10, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.sectorScores != sectorScores || oldDelegate.blueDot != blueDot;
  }
}
