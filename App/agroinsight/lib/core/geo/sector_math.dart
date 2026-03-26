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
}
