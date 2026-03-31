import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/database/database_helper.dart';
import '../core/geo/sector_math.dart';
import 'demo_farm_seed.dart';

enum BleConnectionStateUi {
  disconnectedSearching,
  connectedIdle,
  receivingData,
}

class BleTriggerResult {
  const BleTriggerResult({
    required this.sectorId,
    required this.recordId,
    required this.diseaseName,
    required this.confidenceScore,
    required this.deviceId,
  });

  final String sectorId;
  final int recordId;
  final String diseaseName;
  final double confidenceScore;
  final String deviceId;
}

class BleScannerService extends ChangeNotifier {
  BleScannerService._();
  static final BleScannerService instance = BleScannerService._();

  /// When `true`, skips BLE scan/connect/write/notify and uses [simulateHardwareScan]
  /// for demos (e.g. failed Pi radio). Set to `false` when hardware is restored.
  static bool useHardwareSimulation = true;

  static const String targetDeviceName = 'AgroInsight-Probe';
  static const String serviceUuid = '80323644-3537-4F0B-A53B-CF494ECEAABF';
  static const String characteristicUuid = '80323645-3537-4F0B-A53B-CF494ECEAABF';
  static const String writeCharacteristicUuid = '80323646-3537-4F0B-A53B-CF494ECEAABF';

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  Timer? _reconnectTimer;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  Completer<BleTriggerResult>? _pendingTrigger;
  bool _starting = false;

  BleConnectionStateUi uiState = BleConnectionStateUi.disconnectedSearching;
  String statusText = 'Searching for Probe...';
  String? lastDeviceId;
  DateTime? lastPayloadAt;

  Color get statusColor {
    switch (uiState) {
      case BleConnectionStateUi.connectedIdle:
        return const Color(0xFF2E7D32);
      case BleConnectionStateUi.receivingData:
        return const Color(0xFFD84315);
      case BleConnectionStateUi.disconnectedSearching:
        return Colors.grey;
    }
  }

  Future<void> start() async {
    if (_starting) return;
    _starting = true;
    debugPrint('[BLE] start() called');
    try {
      if (useHardwareSimulation) {
        debugPrint('[BLE] Simulation mode: skipping Bluetooth scan/connect.');
        _setUi(
          BleConnectionStateUi.connectedIdle,
          'Demo: probe simulated (no BLE)',
        );
        await DemoFarmSeed.seedFullFarmGrid();
        return;
      }
      // Real hardware path (flutter_blue_plus).
      await _startScanAndConnect();
    } finally {
      _starting = false;
    }
  }

  Future<void> manualRescan() async {
    debugPrint('[BLE] manualRescan() called by UI');
    if (useHardwareSimulation) {
      debugPrint('[BLE] Simulation mode: refreshing demo farm grid.');
      _setUi(
        BleConnectionStateUi.connectedIdle,
        'Demo: probe simulated (no BLE)',
      );
      await DemoFarmSeed.seedFullFarmGrid();
      return;
    }
    await stop();
    await start();
  }

  /// Mock probe: ~MobileNetV3 inference delay, then the demo JSON (see also [_normalizeProbePayload]).
  Future<String> simulateHardwareScan() async {
    await Future.delayed(const Duration(seconds: 2));
    return '{"disease": "Coffee Leaf Rust", "confidence": 0.94}';
  }

  /// Accepts Pi-style (`disease_name`, `confidence_score`) or demo keys (`disease`, `confidence`).
  /// [confidence] in (0,1] is treated as a fraction and scaled to 0–100 for SQLite / heatmap rules.
  Map<String, Object> _normalizeProbePayload(Map<String, dynamic> raw) {
    final diseaseRaw = raw['disease_name'] ?? raw['disease'];
    final diseaseName = diseaseRaw is String
        ? diseaseRaw
        : (diseaseRaw?.toString() ?? 'Unknown');

    final confRaw = raw['confidence_score'] ?? raw['confidence'];
    var confidenceScore = (confRaw is num ? confRaw.toDouble() : 0.0);
    if (confidenceScore > 0 && confidenceScore <= 1.0) {
      confidenceScore *= 100.0;
    }

    final deviceId = (raw['device_id'] is String && (raw['device_id'] as String).isNotEmpty)
        ? raw['device_id'] as String
        : 'simulated-probe';

    return {
      'disease_name': diseaseName,
      'confidence_score': confidenceScore,
      'device_id': deviceId,
    };
  }

  /// Shared path: GPS + sector + SQLite insert (+ optional completer for BLE trigger).
  /// Returns `null` if no farm is registered (same as legacy notify-only behaviour).
  Future<BleTriggerResult?> _ingestProbeData(
    String diseaseName,
    double confidenceScore,
    String deviceId,
  ) async {
    final farm = await DatabaseHelper.instance.getLatestFarm();
    if (farm == null) {
      debugPrint('[BLE] No farm in SQLite. Cannot map sector.');
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    debugPrint('[BLE] GPS position lat=${position.latitude} lng=${position.longitude}');

    final sectorId = SectorGrid.computeSectorId(
      minLat: (farm['min_lat'] as num).toDouble(),
      maxLat: (farm['max_lat'] as num).toDouble(),
      minLng: (farm['min_lng'] as num).toDouble(),
      maxLng: (farm['max_lng'] as num).toDouble(),
      latitude: position.latitude,
      longitude: position.longitude,
    );

    final recordId = await DatabaseHelper.instance.insertDiseaseRecord({
      'farm_id': farm['id'],
      'disease_name': diseaseName,
      'confidence_score': confidenceScore,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'sector_id': sectorId,
      'device_id': deviceId,
      'recorded_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
    });

    debugPrint('[BLE] SQLite insert success id=$recordId sector=$sectorId');
    lastPayloadAt = DateTime.now();

    final result = BleTriggerResult(
      sectorId: sectorId,
      recordId: recordId,
      diseaseName: diseaseName,
      confidenceScore: confidenceScore,
      deviceId: deviceId,
    );

    final completer = _pendingTrigger;
    if (completer != null && !completer.isCompleted) {
      _pendingTrigger = null;
      debugPrint('[BLE] Completing trigger with sector=$sectorId recordId=$recordId');
      completer.complete(result);
    } else {
      debugPrint('[BLE] No pending trigger waiting; payload stored only.');
    }

    return result;
  }

  Future<void> _startScanAndConnect() async {
    final hasPermission = await _ensureAndroidBlePermissions();
    if (!hasPermission) {
      debugPrint('[BLE] Required Android permissions denied.');
      _setUi(BleConnectionStateUi.disconnectedSearching, 'Searching for Probe...');
      _scheduleReconnect();
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    debugPrint('[BLE] adapterState=$adapterState');
    if (adapterState != BluetoothAdapterState.on) {
      _setUi(BleConnectionStateUi.disconnectedSearching, 'Searching for Probe...');
      _scheduleReconnect();
      return;
    }

    _setUi(BleConnectionStateUi.disconnectedSearching, 'Searching for Probe...');
    debugPrint('[BLE] Starting scan for $targetDeviceName, service $serviceUuid');
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 12),
      withServices: [Guid(serviceUuid)],
    );

    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final result in results) {
        final advName = result.advertisementData.advName;
        final platformName = result.device.platformName;
        final nameMatch = platformName == targetDeviceName || advName == targetDeviceName;
        final hasTargetService = result.advertisementData.serviceUuids
            .contains(Guid(serviceUuid));

        debugPrint(
          '[BLE] Scan hit name=$platformName adv=$advName serviceMatch=$hasTargetService rssi=${result.rssi}',
        );

        if (!nameMatch || !hasTargetService) continue;
        debugPrint('[BLE] Target probe found. Stopping scan and connecting...');
        await FlutterBluePlus.stopScan();
        await _connectAndSubscribe(result.device);
        break;
      }
    }, onDone: () {
      debugPrint('[BLE] scanResults stream ended');
      _scheduleReconnect();
    }, onError: (error) {
      debugPrint('[BLE] scanResults error: $error');
      _scheduleReconnect();
    });
  }

  Future<bool> _ensureAndroidBlePermissions() async {
    if (!Platform.isAndroid) return true;

    debugPrint('[BLE] Requesting Android permissions: location + bluetooth');
    final locationStatus = await Permission.location.request();
    final bluetoothStatus = await Permission.bluetooth.request();

    debugPrint(
      '[BLE] Permission results location=$locationStatus bluetooth=$bluetoothStatus',
    );

    final granted = locationStatus.isGranted && bluetoothStatus.isGranted;
    return granted;
  }

  Future<void> _connectAndSubscribe(BluetoothDevice device) async {
    _connectedDevice = device;
    debugPrint('[BLE] Connecting to device id=${device.remoteId} name=${device.platformName}');
    await device.connect(timeout: const Duration(seconds: 12));
    lastDeviceId = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.str;
    _setUi(BleConnectionStateUi.connectedIdle, 'Hardware Probe Ready');
    debugPrint('[BLE] Connected. lastDeviceId=$lastDeviceId');

    await _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((state) {
      debugPrint('[BLE] Connection state update: $state');
      if (state == BluetoothConnectionState.disconnected) {
        _writeCharacteristic = null;
        _connectedDevice = null;
        _setUi(BleConnectionStateUi.disconnectedSearching, 'Searching for Probe...');
        _scheduleReconnect();
      }
    });

    try {
      final mtu = await device.requestMtu(247);
      debugPrint('[BLE] Requested MTU=247, negotiated MTU=$mtu');
    } catch (e) {
      debugPrint('[BLE] requestMtu failed: $e');
    }

    final services = await device.discoverServices();
    debugPrint('[BLE] Discovered ${services.length} services');

    final targetService = services.firstWhere(
      (s) => s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase(),
      orElse: () => throw Exception('BLE service UUID not found: $serviceUuid'),
    );

    final targetCharacteristic = targetService.characteristics.firstWhere(
      (c) => c.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase(),
      orElse: () => throw Exception('BLE characteristic UUID not found: $characteristicUuid'),
    );
    final targetWriteCharacteristic = targetService.characteristics.firstWhere(
      (c) => c.uuid.toString().toLowerCase() == writeCharacteristicUuid.toLowerCase(),
      orElse: () => throw Exception(
        'BLE write characteristic UUID not found: $writeCharacteristicUuid',
      ),
    );
    debugPrint('[BLE] Subscribing to characteristic ${targetCharacteristic.uuid}');

    _writeCharacteristic = targetWriteCharacteristic;
    debugPrint('[BLE] Stored WRITE characteristic ${_writeCharacteristic!.uuid}');

    await targetCharacteristic.setNotifyValue(true);
    await targetCharacteristic.read();

    await _notifySub?.cancel();
    _notifySub = targetCharacteristic.lastValueStream.listen(
      _handlePayload,
      onError: (error) {
        debugPrint('[BLE] Notify stream error: $error');
        _setUi(BleConnectionStateUi.disconnectedSearching, 'Searching for Probe...');
        _scheduleReconnect();
      },
    );
  }

  Future<void> _handlePayload(List<int> bytes) async {
    if (bytes.isEmpty) return;
    _setUi(BleConnectionStateUi.receivingData, 'Analyzing Leaf...');

    try {
      final payloadString = utf8.decode(bytes, allowMalformed: true).trim();
      debugPrint('[BLE] Raw payload bytes=${bytes.length} content=$payloadString');

      final payload = jsonDecode(payloadString) as Map<String, dynamic>;
      final norm = _normalizeProbePayload(payload);
      final diseaseName = norm['disease_name']! as String;
      final confidenceScore = norm['confidence_score']! as double;
      final deviceId = norm['device_id']! as String;

      debugPrint(
        '[BLE] Parsed payload disease_name=$diseaseName confidence_score=$confidenceScore device_id=$deviceId',
      );

      await _ingestProbeData(diseaseName, confidenceScore, deviceId);
    } catch (e, stack) {
      debugPrint('[BLE] Payload handling error: $e');
      debugPrint('[BLE] Stack: $stack');
    } finally {
      _setUi(
        BleConnectionStateUi.connectedIdle,
        useHardwareSimulation
            ? 'Demo: probe simulated (no BLE)'
            : 'Hardware Probe Ready',
      );
    }
  }

  Future<BleTriggerResult> triggerProbe({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    debugPrint('[BLE] triggerProbe() called with timeout=${timeout.inSeconds}s');
    if (_pendingTrigger != null && !_pendingTrigger!.isCompleted) {
      throw StateError('A probe trigger is already in progress.');
    }

    if (useHardwareSimulation) {
      _setUi(BleConnectionStateUi.receivingData, 'Analyzing Leaf...');
      try {
        final payloadString = await simulateHardwareScan();
        debugPrint('[BLE] Simulated payload: $payloadString');
        final payload = jsonDecode(payloadString) as Map<String, dynamic>;
        final norm = _normalizeProbePayload(payload);
        final diseaseName = norm['disease_name']! as String;
        final confidenceScore = norm['confidence_score']! as double;
        final deviceId = norm['device_id']! as String;

        final result = await _ingestProbeData(
          diseaseName,
          confidenceScore,
          deviceId,
        );
        if (result == null) {
          throw StateError(
            'No farm registered offline. Register a farm before scanning.',
          );
        }
        return result;
      } finally {
        _setUi(
          BleConnectionStateUi.connectedIdle,
          'Demo: probe simulated (no BLE)',
        );
      }
    }

    // --- Real BLE trigger (write char + await notify) ---
    final startedAt = DateTime.now();
    await start();

    Duration remaining() {
      final elapsed = DateTime.now().difference(startedAt);
      final remaining = timeout - elapsed;
      return remaining.isNegative ? Duration.zero : remaining;
    }

    final ready = await _waitForWriteCharacteristic(timeout: remaining());
    if (!ready) {
      throw TimeoutException('BLE write characteristic not ready (no connection).');
    }

    final writeChar = _writeCharacteristic;
    if (writeChar == null) {
      throw StateError('WRITE characteristic not available.');
    }

    final completer = Completer<BleTriggerResult>();
    _pendingTrigger = completer;
    _setUi(BleConnectionStateUi.receivingData, 'Analyzing Leaf...');

    debugPrint('[BLE] Writing trigger byte 0x01 to WRITE characteristic ${writeChar.uuid}');
    try {
      // Prefer write-without-response for lower latency (common in notify/write designs).
      await writeChar.write([0x01], withoutResponse: true);
    } catch (e) {
      debugPrint('[BLE] write(withoutResponse:true) failed: $e. Retrying without flag...');
      await writeChar.write([0x01], withoutResponse: false);
    }

    debugPrint('[BLE] Trigger write sent. Waiting for NOTIFY payload...');

    final remainingAfterWrite = remaining();
    if (remainingAfterWrite == Duration.zero) {
      _pendingTrigger = null;
      throw TimeoutException('Timed out waiting for probe payload (no remaining time).');
    }

    return await completer.future.timeout(
      remainingAfterWrite,
      onTimeout: () {
        _pendingTrigger = null;
        throw TimeoutException(
          'Timed out waiting for probe payload after ${timeout.inSeconds}s.',
        );
      },
    );
  }

  Future<bool> _waitForWriteCharacteristic({required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_writeCharacteristic != null && _connectedDevice != null) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return false;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    debugPrint('[BLE] Scheduling reconnect in 5 seconds...');
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      start();
    });
  }

  void _setUi(BleConnectionStateUi state, String text) {
    uiState = state;
    statusText = text;
    notifyListeners();
  }

  Future<void> stop() async {
    debugPrint('[BLE] stop() called');
    if (useHardwareSimulation) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _pendingTrigger = null;
      _setUi(
        BleConnectionStateUi.disconnectedSearching,
        'Demo: probe simulated (no BLE)',
      );
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _scanSub?.cancel();
    _scanSub = null;
    await _notifySub?.cancel();
    _notifySub = null;
    await _connectionSub?.cancel();
    _connectionSub = null;
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      debugPrint('[BLE] disconnect ignored: $e');
    }
    _connectedDevice = null;
    _writeCharacteristic = null;
    _pendingTrigger = null;
    _setUi(BleConnectionStateUi.disconnectedSearching, 'Searching for Probe...');
  }
}
