import 'dart:math' as math;

class SectorGrid {
  static const int rows = 4;
  static const int cols = 3;

  static List<String> allSectorIds() {
    final ids = <String>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        ids.add(_idFromIndex(r, c));
      }
    }
    return ids;
  }

  static String computeSectorId({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required double latitude,
    required double longitude,
  }) {
    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    if (latSpan == 0 || lngSpan == 0) return 'A1';

    final north = math.max(minLat, maxLat);
    final south = math.min(minLat, maxLat);
    final west = math.min(minLng, maxLng);
    final east = math.max(minLng, maxLng);

    final normalizedRow = ((north - latitude) / (north - south)).clamp(0.0, 0.999999);
    final normalizedCol = ((longitude - west) / (east - west)).clamp(0.0, 0.999999);

    final rowIndex = (normalizedRow * rows).floor();
    final colIndex = (normalizedCol * cols).floor();
    return _idFromIndex(rowIndex, colIndex);
  }

  static bool isInsideBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required double latitude,
    required double longitude,
  }) {
    final south = math.min(minLat, maxLat);
    final north = math.max(minLat, maxLat);
    final west = math.min(minLng, maxLng);
    final east = math.max(minLng, maxLng);
    return latitude >= south &&
        latitude <= north &&
        longitude >= west &&
        longitude <= east;
  }

  static String _idFromIndex(int row, int col) {
    final rowLetter = String.fromCharCode('A'.codeUnitAt(0) + row.clamp(0, rows - 1));
    return '$rowLetter${col.clamp(0, cols - 1) + 1}';
  }

  /// Presentation pairing: **heatmap tile / UI sector label** ↔ **SQLite `sector_id`**.
  ///
  /// Example: data stored for **B3** (e.g. coffee berry borer) is shown on tile **B1** and
  /// in "Sector B1" overview; **B1**'s stored data appears on **B3**. Same for **A1↔D3**.
  /// GPS / [computeSectorId] / inserts are unchanged — only display and queries use this map.
  static String pairedSectorId(String sectorId) {
    switch (sectorId) {
      case 'A1':
        return 'D3';
      case 'D3':
        return 'A1';
      case 'B1':
        return 'B3';
      case 'B3':
        return 'B1';
      default:
        return sectorId;
    }
  }

  /// Geographic center of a grid cell — matches [computeSectorId] binning.
  static ({double latitude, double longitude}) cellCenterLatLng({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required String sectorId,
  }) {
    final north = math.max(minLat, maxLat);
    final south = math.min(minLat, maxLat);
    final west = math.min(minLng, maxLng);
    final east = math.max(minLng, maxLng);

    if (sectorId.length < 2) {
      return (
        latitude: (north + south) / 2,
        longitude: (west + east) / 2,
      );
    }

    final rowLetter = sectorId.codeUnitAt(0);
    final row = (rowLetter - 'A'.codeUnitAt(0)).clamp(0, rows - 1);
    final col = (int.tryParse(sectorId.substring(1)) ?? 1) - 1;
    final colIndex = col.clamp(0, cols - 1);

    final normalizedRow = (row + 0.5) / rows;
    final latitude = north - normalizedRow * (north - south);
    final normalizedCol = (colIndex + 0.5) / cols;
    final longitude = west + normalizedCol * (east - west);

    return (latitude: latitude, longitude: longitude);
  }
}
