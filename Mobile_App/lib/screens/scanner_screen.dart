import 'package:flutter/material.dart';
import 'package:agro_insight/services/ble_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late BleController _bleController;
  String _statusMessage = "Press 'Scan' to find the probe";

  @override
  void initState() {
    super.initState();
    _bleController = BleController(
      onStatusUpdate: (status) {
        setState(() {
          _statusMessage = status;
        });
      }
    );
  }

  Future<void> _requestPermissionsAndScan() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    _bleController.scanAndConnect();
  }

  @override
  void dispose() {
    _bleController.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Probe Scanner'),
        backgroundColor: Colors.green.shade800,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sensors, size: 100, color: Colors.grey),
              const SizedBox(height: 30),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 50),
              ElevatedButton.icon(
                onPressed: _requestPermissionsAndScan,
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text("Scan for Hardware", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}