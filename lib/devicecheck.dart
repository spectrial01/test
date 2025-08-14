import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

// Assuming your DeviceStatusService is in the same file or can be imported.
// If it's in another file, you would use:
// import 'path/to/device_status_service.dart';

// --- (Your existing DeviceStatusService class code goes here) ---
// I've included the class here for clarity. Make sure it's present in your file.
class DeviceStatusService {
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  static const MethodChannel _platform = MethodChannel('device_status');

  final StreamController<Map<String, dynamic>> _statusController =
      StreamController<Map<String, dynamic>>.broadcast();

  Map<String, dynamic>? _location;
  String _internet = "Unknown";
  int? _signal;
  double _internetSpeed = 0.0;
  int _batteryLevel = 0;

  DeviceStatusService() {
    _init();
  }

  void _init() async {
    // Initial fetch
    _internet = await getInternetStatus();
    _batteryLevel = await getBatteryLevel();
    _emitCombinedStatus();

    _battery.onBatteryStateChanged.listen((batteryState) async {
      _batteryLevel = await getBatteryLevel();
      _emitCombinedStatus();
    });

    _connectivity.onConnectivityChanged.listen((_) async {
      _internet = await getInternetStatus();
      _emitCombinedStatus();
    });

    Timer.periodic(const Duration(seconds: 3), (_) async {
      _location = await getLocationData();
      _signal = await getSignalDbm();
      _internetSpeed = await getInternetSpeedKbps();
      _emitCombinedStatus();
    });
  }

  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return -1;
    }
  }

  Future<Map<String, dynamic>?> getLocationData() async {
    var status = await Permission.location.request();
    if (!status.isGranted) return null;
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      return {
        "latitude": pos.latitude,
        "longitude": pos.longitude,
        "accuracy": pos.accuracy,
      };
    } catch (_) {
      return null;
    }
  }

  Future<String> getInternetStatus() async {
    try {
      var result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.mobile) return "Mobile Data";
      if (result == ConnectivityResult.wifi) return "Wi-Fi";
      return "No Internet";
    } catch (_) {
      return "Unknown";
    }
  }

  Future<int?> getSignalDbm() async {
    try {
      return await _platform.invokeMethod<int>('getSignalStrength');
    } catch (_) {
      return null;
    }
  }

  Future<double> getInternetSpeedKbps() async {
    const testUrl = 'https://speed.hetzner.de/100KB.bin';
    final stopwatch = Stopwatch()..start();
    try {
      final request = await HttpClient().getUrl(Uri.parse(testUrl));
      final response = await request.close();
      if (response.statusCode != 200) return 0.0;
      int totalBytes = 0;
      await for (var chunk in response) {
        totalBytes += chunk.length;
      }
      stopwatch.stop();
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      return (totalBytes / 1024) / (seconds == 0 ? 1 : seconds);
    } catch (_) {
      return 0.0;
    }
  }

  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  void _emitCombinedStatus() {
    final combined = {
      "battery": _batteryLevel,
      "internet": _internet,
      "location": _location,
      "signalDbm": _signal,
      "internetSpeedKbps": _internetSpeed,
    };
    _statusController.add(combined);
  }

  void dispose() {
    _statusController.close();
  }
}

// --- Enhanced UI for DeviceCheckPage ---
class DeviceCheckPage extends StatelessWidget {
  const DeviceCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceStatusService = DeviceStatusService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Status', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<Map<String, dynamic>>(
            stream: deviceStatusService.statusStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return const Text('An error occurred.', style: TextStyle(color: Colors.red));
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Text('No data available.', style: TextStyle(color: Colors.grey));
              }

              final data = snapshot.data!;
              final location = data['location'];
              final signalStrength = data['signalDbm'] ?? 'N/A';
              final internetSpeed = data['internetSpeedKbps'] as double;
              
              String getSignalText(int? signal) {
                if (signal == null) return "Unknown";
                if (signal >= -70) return "Strong";
                if (signal >= -85) return "Good";
                if (signal >= -100) return "Fair";
                return "Weak";
              }

              return Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusRow(
                        icon: Icons.battery_charging_full,
                        label: 'Battery Level:',
                        value: '${data['battery']}%',
                        color: data['battery'] > 20 ? Colors.green : Colors.red,
                      ),
                      _buildDivider(),
                      _buildStatusRow(
                        icon: Icons.network_cell,
                        label: 'Signal Strength:',
                        value: '${getSignalText(signalStrength is int ? signalStrength : null)} (${signalStrength} dBm)',
                        color: getSignalText(signalStrength is int ? signalStrength : null) == "Strong" ? Colors.green : Colors.orange,
                      ),
                      _buildDivider(),
                      _buildStatusRow(
                        icon: Icons.wifi,
                        label: 'Internet Status:',
                        value: data['internet'],
                        color: data['internet'] == "No Internet" ? Colors.red : Colors.green,
                      ),
                      _buildDivider(),
                      _buildStatusRow(
                        icon: Icons.speed,
                        label: 'Internet Speed:',
                        value: '${internetSpeed.toStringAsFixed(2)} Kbps',
                        color: internetSpeed > 500 ? Colors.green : Colors.orange,
                      ),
                      _buildDivider(),
                      _buildStatusRow(
                        icon: Icons.location_on,
                        label: 'Location:',
                        value: location != null
                            ? 'Lat: ${location['latitude'].toStringAsFixed(4)}, Lng: ${location['longitude'].toStringAsFixed(4)}'
                            : 'Location not available',
                        color: location != null ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 20, color: Colors.blueGrey);
  }
}