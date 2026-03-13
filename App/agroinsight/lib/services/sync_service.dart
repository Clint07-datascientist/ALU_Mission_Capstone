import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This function is triggered when the Lead Farmer returns to town
  Future<Map<String, dynamic>> syncOfflineDataToCloud(List<Map<String, dynamic>> localUnsyncedRecords) async {
    // 1. Check if the phone actually has internet right now
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return {'status': 'error', 'message': 'No internet connection. Keeping data local.'};
    }

    if (localUnsyncedRecords.isEmpty) {
      return {'status': 'success', 'message': 'All records are already synced!'};
    }

    int syncedCount = 0;

    try {
      // 2. Loop through the unsynced local SQLite records
      for (var record in localUnsyncedRecords) {
        // Push to Firebase Cloud Firestore
        await _firestore.collection('farm_scans').add({
          'farm_id': record['farm_id'],
          'disease_class': record['disease_class'],
          'confidence_score': record['confidence_score'],
          'gps_latitude': record['gps_latitude'],
          'gps_longitude': record['gps_longitude'],
          'timestamp': FieldValue.serverTimestamp(), // Tags it with the exact sync time
        });
        
        // Note: In your actual SQLite helper, you would now run an UPDATE query
        // to set is_synced = true for this specific record_id 
        syncedCount++;
      }

      return {'status': 'success', 'message': 'Successfully backed up $syncedCount records to the cloud!'};

    } catch (e) {
      return {'status': 'error', 'message': 'Failed to sync to cloud: $e'};
    }
  }
}