import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../core/geo/sector_math.dart';

/// Demo-only: one synthetic scan per grid sector so heatmaps and sector views
/// show full-farm variety (healthy, rust, miner, borer) with mixed confidences.
class DemoFarmSeed {
  DemoFarmSeed._();

  static const String deviceIdMarker = 'agroinsight-demo-grid-v1';

  /// (sectorId, disease_name, confidence 0–100 for SQLite / heatmap rules)
  static const List<({String sectorId, String diseaseName, double confidence})>
      _profile = [
    (sectorId: 'A1', diseaseName: 'Healthy', confidence: 96.0),
    (sectorId: 'A2', diseaseName: 'Leaf Rust', confidence: 91.0),
    (sectorId: 'A3', diseaseName: 'Coffee Leaf Miner', confidence: 68.0),
    (sectorId: 'B1', diseaseName: 'Healthy', confidence: 94.0),
    (sectorId: 'B2', diseaseName: 'Leaf Rust', confidence: 77.0),
    (sectorId: 'B3', diseaseName: 'Coffee Berry Borer', confidence: 88.0),
    (sectorId: 'C1', diseaseName: 'Healthy', confidence: 91.0),
    (sectorId: 'C2', diseaseName: 'Coffee Leaf Miner', confidence: 84.0),
    (sectorId: 'C3', diseaseName: 'Leaf Rust', confidence: 72.0),
    (sectorId: 'D1', diseaseName: 'Healthy', confidence: 89.0),
    (sectorId: 'D2', diseaseName: 'Leaf Miner', confidence: 71.0),
    (sectorId: 'D3', diseaseName: 'Leaf Rust', confidence: 90.0),
  ];

  /// Replaces prior demo-grid rows for the latest farm, then inserts 12 sector rows.
  static Future<void> seedFullFarmGrid() async {
    final farm = await DatabaseHelper.instance.getLatestFarm();
    if (farm == null) {
      debugPrint('[DemoFarmSeed] No farm — skip seed.');
      return;
    }

    final farmId = farm['id'] as int;
    final minLat = (farm['min_lat'] as num).toDouble();
    final maxLat = (farm['max_lat'] as num).toDouble();
    final minLng = (farm['min_lng'] as num).toDouble();
    final maxLng = (farm['max_lng'] as num).toDouble();

    await DatabaseHelper.instance.deleteDiseaseRecordsForFarmByDeviceId(
      farmId,
      deviceIdMarker,
    );

    final now = DateTime.now();
    for (var i = 0; i < _profile.length; i++) {
      final row = _profile[i];
      final ll = SectorGrid.cellCenterLatLng(
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
        sectorId: row.sectorId,
      );

      await DatabaseHelper.instance.insertDiseaseRecord({
        'farm_id': farmId,
        'disease_name': row.diseaseName,
        'confidence_score': row.confidence,
        'latitude': ll.latitude,
        'longitude': ll.longitude,
        'sector_id': row.sectorId,
        'device_id': deviceIdMarker,
        'recorded_at': now.subtract(Duration(seconds: i)).toIso8601String(),
        'is_synced': 0,
      });
    }

    debugPrint('[DemoFarmSeed] Inserted ${_profile.length} demo rows for farm $farmId.');
  }
}
