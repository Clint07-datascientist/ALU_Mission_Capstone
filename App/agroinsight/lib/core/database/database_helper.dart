import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Singleton access point for AgroInsight's local SQLite database.
///
/// **Platform note:** [sqflite] is supported on Android, iOS, and desktop.
/// It is **not** supported on web; use a different persistence strategy for web.
///
/// Foreign keys (including `ON DELETE CASCADE`) are enforced by enabling
/// `PRAGMA foreign_keys = ON` on every database open.
class DatabaseHelper {
  DatabaseHelper._internal();

  /// Single shared instance (Singleton).
  static final DatabaseHelper instance = DatabaseHelper._internal();

  /// Preferred factory so call sites can use `DatabaseHelper()`.
  factory DatabaseHelper() => instance;

  static const String _dbName = 'agroinsight.db';
  static const int _dbVersion = 2;

  static const String tableFarms = 'farms';
  static const String tableDiseaseRecords = 'disease_records';

  Database? _database;

  /// Lazily opens (or returns) the application database.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// Opens the DB file under the platform documents directory and runs setup.
  Future<Database> _initDatabase() async {
    final dbDir = await getDatabasesPath();
    final filePath = p.join(dbDir, _dbName);

    return openDatabase(
      filePath,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Required so SQLite honors `FOREIGN KEY ... ON DELETE CASCADE`.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Creates schema on first install.
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE $tableFarms (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  min_lat REAL NOT NULL,
  max_lat REAL NOT NULL,
  min_lng REAL NOT NULL,
  max_lng REAL NOT NULL
)
''');

    await db.execute('''
CREATE TABLE $tableDiseaseRecords (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  farm_id INTEGER NOT NULL,
  disease_name TEXT NOT NULL,
  confidence_score REAL NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  sector_id TEXT NOT NULL,
  device_id TEXT NOT NULL DEFAULT 'Unknown',
  is_synced INTEGER NOT NULL DEFAULT 0,
  recorded_at TEXT NOT NULL,
  FOREIGN KEY (farm_id) REFERENCES $tableFarms(id) ON DELETE CASCADE
)
''');

    // Speeds up heatmap / farm-scoped queries and sync polling.
    await db.execute(
      'CREATE INDEX idx_disease_records_farm_id ON $tableDiseaseRecords(farm_id)',
    );
    await db.execute(
      'CREATE INDEX idx_disease_records_is_synced ON $tableDiseaseRecords(is_synced)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE $tableDiseaseRecords ADD COLUMN device_id TEXT NOT NULL DEFAULT 'Unknown'",
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CRUD — Farms
  // ---------------------------------------------------------------------------

  /// Inserts a new farm row.
  ///
  /// Expected keys in [farmData]:
  /// - `name` (String)
  /// - `min_lat`, `max_lat`, `min_lng`, `max_lng` (num / double)
  ///
  /// Returns the generated row id.
  Future<int> insertFarm(Map<String, dynamic> farmData) async {
    final db = await database;
    final row = <String, dynamic>{
      'name': farmData['name'] as String,
      'min_lat': (farmData['min_lat'] as num).toDouble(),
      'max_lat': (farmData['max_lat'] as num).toDouble(),
      'min_lng': (farmData['min_lng'] as num).toDouble(),
      'max_lng': (farmData['max_lng'] as num).toDouble(),
    };
    return db.insert(tableFarms, row);
  }

  // ---------------------------------------------------------------------------
  // CRUD — Disease records (offline-first + sync)
  // ---------------------------------------------------------------------------

  /// Inserts a new disease / scan record.
  ///
  /// Expected keys in [recordData]:
  /// - `farm_id` (int)
  /// - `disease_name` (String)
  /// - `confidence_score` (num)
  /// - `latitude`, `longitude` (num)
  /// - `sector_id` (String)
  /// - `recorded_at` (String) — ISO-8601 timestamp recommended
  /// - `is_synced` (int, optional) — `0` = pending sync, `1` = synced (default `0`)
  ///
  /// Returns the generated row id.
  Future<int> insertDiseaseRecord(Map<String, dynamic> recordData) async {
    final db = await database;
    final row = <String, dynamic>{
      'farm_id': recordData['farm_id'] as int,
      'disease_name': recordData['disease_name'] as String,
      'confidence_score':
          (recordData['confidence_score'] as num).toDouble(),
      'latitude': (recordData['latitude'] as num).toDouble(),
      'longitude': (recordData['longitude'] as num).toDouble(),
      'sector_id': recordData['sector_id'] as String,
      'device_id': (recordData['device_id'] as String?) ?? 'Unknown',
      'recorded_at': recordData['recorded_at'] as String,
      'is_synced': recordData['is_synced'] as int? ?? 0,
    };
    return db.insert(tableDiseaseRecords, row);
  }

  /// All disease records for [farmId] (e.g. heatmap / sector views).
  Future<List<Map<String, dynamic>>> getRecordsForFarm(int farmId) async {
    final db = await database;
    return db.query(
      tableDiseaseRecords,
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'recorded_at DESC',
    );
  }

  /// Latest scan row for a sector (sector-specific overview / insights).
  Future<Map<String, dynamic>?> getLatestRecordForFarmSector({
    required int farmId,
    required String sectorId,
  }) async {
    final db = await database;
    final rows = await db.query(
      tableDiseaseRecords,
      where: 'farm_id = ? AND sector_id = ?',
      whereArgs: [farmId, sectorId],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Count of scans in [sectorId] for [farmId] within the last [within] window.
  Future<int> countRecordsForFarmSectorSince({
    required int farmId,
    required String sectorId,
    required DateTime since,
  }) async {
    final db = await database;
    final sinceStr = since.toIso8601String();
    final rows = await db.rawQuery(
      '''
SELECT COUNT(*) AS c FROM $tableDiseaseRecords
WHERE farm_id = ? AND sector_id = ? AND recorded_at >= ?
''',
      [farmId, sectorId, sinceStr],
    );
    final n = rows.first['c'];
    if (n is int) return n;
    if (n is num) return n.toInt();
    return 0;
  }

  /// Removes rows tagged with [deviceId] (e.g. demo seed) for one farm.
  Future<int> deleteDiseaseRecordsForFarmByDeviceId(
    int farmId,
    String deviceId,
  ) async {
    final db = await database;
    return db.delete(
      tableDiseaseRecords,
      where: 'farm_id = ? AND device_id = ?',
      whereArgs: [farmId, deviceId],
    );
  }

  /// Rows that still need to be pushed to the cloud.
  Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    final db = await database;
    return db.query(
      tableDiseaseRecords,
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'recorded_at ASC',
    );
  }

  /// Marks a single record as successfully synced (`is_synced = 1`).
  ///
  /// Returns the number of rows updated (should be `1` on success).
  Future<int> markAsSynced(int recordId) async {
    final db = await database;
    return db.update(
      tableDiseaseRecords,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<Map<String, dynamic>?> getFarmById(int farmId) async {
    final db = await database;
    final result = await db.query(
      tableFarms,
      where: 'id = ?',
      whereArgs: [farmId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<Map<String, dynamic>?> getLatestFarm() async {
    final db = await database;
    final result = await db.query(
      tableFarms,
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Closes the database (e.g. in tests or before app teardown). Next
  /// [database] getter will reopen the file.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
