import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/database/database_helper.dart';

/// Outcome of a manual “sync offline records” run from the Dashboard.
class FirebaseSyncResult {
  const FirebaseSyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
  });

  final bool success;
  final String message;

  /// Number of rows marked `is_synced = 1` after a successful run (0 on failure / empty).
  final int syncedCount;
}

/// Offline-first bridge: SQLite `disease_records` → Firestore `farm_scans`.
///
/// Uses [WriteBatch] chunks for flaky rural connectivity and
/// `doc(localRecordId)` for idempotent retries.
class FirebaseSyncService {
  FirebaseSyncService({
    FirebaseFirestore? firestore,
    DatabaseHelper? databaseHelper,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final FirebaseFirestore _firestore;
  final DatabaseHelper _databaseHelper;

  /// Firestore allows up to 500 operations per batch; stay well under for safety.
  static const int _batchSize = 50;

  /// Fetches `is_synced = 0` rows, uploads each batch, then marks those rows synced.
  Future<FirebaseSyncResult> syncOfflineRecords() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      final online = connectivityResults.any((r) => r != ConnectivityResult.none);
      if (!online) {
        return const FirebaseSyncResult(
          success: false,
          message: 'Sync failed. Please check your Wi-Fi connection.',
        );
      }

      final pending = await _databaseHelper.getUnsyncedRecords();
      if (pending.isEmpty) {
        return const FirebaseSyncResult(
          success: true,
          message: 'All records are already synced.',
        );
      }

      var syncedCount = 0;

      for (var i = 0; i < pending.length; i += _batchSize) {
        final chunk = pending.skip(i).take(_batchSize).toList();
        final batch = _firestore.batch();

        for (final record in chunk) {
          final id = record['id'];
          if (id is! int) {
            throw FormatException('Invalid local record id: $id');
          }
          final localRecordId = id.toString();
          final docRef = _firestore.collection('farm_scans').doc(localRecordId);

          batch.set(docRef, {
            'local_record_id': localRecordId,
            'farm_id': record['farm_id'],
            'sector_id': record['sector_id'],
            'disease_name': record['disease_name'],
            'confidence_score': record['confidence_score'],
            'latitude': record['latitude'],
            'longitude': record['longitude'],
            'device_id': record['device_id'] ?? 'Unknown',
            'recorded_at': record['recorded_at'],
            'synced_at': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();

        for (final record in chunk) {
          final id = record['id'] as int;
          await _databaseHelper.markAsSynced(id);
          syncedCount++;
        }
      }

      return FirebaseSyncResult(
        success: true,
        message: 'Successfully synced $syncedCount record${syncedCount == 1 ? '' : 's'}.',
        syncedCount: syncedCount,
      );
    } catch (_) {
      // Keep the SnackBar friendly; avoid dumping stack traces to the user.
      return const FirebaseSyncResult(
        success: false,
        message: 'Sync failed. Please check your Wi-Fi connection.',
      );
    }
  }
}
