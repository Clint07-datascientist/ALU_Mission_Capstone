import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/database/database_helper.dart';

class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  static const int _batchSize = 50;

  Future<Map<String, dynamic>> syncOfflineDataToCloud() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasConnection =
        connectivityResults.any((result) => result != ConnectivityResult.none);
    if (!hasConnection) {
      return {'status': 'error', 'message': 'No internet connection. Keeping data local.'};
    }

    final localUnsyncedRecords = await _databaseHelper.getUnsyncedRecords();
    if (localUnsyncedRecords.isEmpty) {
      return {'status': 'success', 'message': 'All records are already synced!'};
    }

    int syncedCount = 0;
    try {
      for (var i = 0; i < localUnsyncedRecords.length; i += _batchSize) {
        final chunk = localUnsyncedRecords.skip(i).take(_batchSize).toList();
        final batch = _firestore.batch();
        for (final record in chunk) {
          final localRecordId = record['id'].toString();
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
          await _databaseHelper.markAsSynced(record['id'] as int);
          syncedCount++;
        }
      }

      return {'status': 'success', 'message': 'Successfully backed up $syncedCount records to the cloud!'};
    } catch (e) {
      return {'status': 'error', 'message': 'Failed to sync to cloud: $e'};
    }
  }
}