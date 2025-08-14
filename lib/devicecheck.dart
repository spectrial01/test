import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'homepage.dart';
import 'package:flutter/material.dart';

class DeviceCheckPage extends StatelessWidget {
  const DeviceCheckPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Device Status")),
      body: Center(
        child: Text("Welcome to DeviceCheck!"),
      ),
    );
  }
}


class DeviceStatusService {
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  static const MethodChannel _platform = MethodChannel('device_status');

  // --- Stream Controllers ---
  final StreamController<int> _batteryController = StreamController<int>.broadcast();
  final StreamController<Map<String, dynamic>?> _locationController = StreamController<Map<String, dynamic>?>.broadcast();
  final StreamController<String> _internetController = StreamController<String>.broadcast();
  final StreamController<int?> _signalController = StreamController<int?>.broadcast();
  final StreamController<double> _internetSpeedController = StreamController<double>.broadcast();
  final StreamController<Map<String, dynamic>> _statusController = StreamController<Map<String, dynamic>>.broadcast();

  // Current state cache
  Map<String, dynamic>? _location;
  String _internet = "Unknown";
  int? _signal;
  double _internetSpeed = 0.0;

  DeviceStatusService() {
    _init();
  }

 void _init() {
    // --- Battery changes ---
    _battery.onBatteryStateChanged.listen((batteryState) async {
      int batteryLevel = await getBatteryLevel(); // Get the actual battery level
      _batteryController.add(batteryLevel);
      _emitCombinedStatus();
    });

    // --- Internet changes ---
    _connectivity.onConnectivityChanged.listen((_) async {
      _internet = await getInternetStatus();
      _internetController.add(_internet);
      _emitCombinedStatus();
    });

    // --- Periodic updates for location, signal, and internet speed ---
    Timer.periodic(Duration(seconds: 3), (_) async {
      _location = await getLocationData();
      _locationController.add(_location);

      _signal = await getSignalDbm();
      _signalController.add(_signal);

      _internetSpeed = await getInternetSpeedKbps();
      _internetSpeedController.add(_internetSpeed);

      _emitCombinedStatus();
    });
  }

  // --- Individual fetch methods ---
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
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
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
      await for (var chunk in response) totalBytes += chunk.length;

      stopwatch.stop();
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      return (totalBytes / 1024) / (seconds == 0 ? 1 : seconds);
    } catch (_) {
      return 0.0;
    }
  }

  // --- Streams getters ---
  Stream<int> get batteryStream => _batteryController.stream;
  Stream<Map<String, dynamic>?> get locationStream => _locationController.stream;
  Stream<String> get internetStream => _internetController.stream;
  Stream<int?> get signalStream => _signalController.stream;
  Stream<double> get internetSpeedStream => _internetSpeedController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  // --- Emit combined status ---
  void _emitCombinedStatus() async {
  final batteryLevel = await getBatteryLevel(); // Fetch the battery level
  final combined = {
    "battery": batteryLevel,
    "internet": _internet,
    "location": _location,
    "signalDbm": _signal,
    "internetSpeedKbps": _internetSpeed,
  };
  _statusController.add(combined);
}

  // --- Dispose streams ---
  void dispose() {
    _batteryController.close();
    _locationController.close();
    _internetController.close();
    _signalController.close();
    _internetSpeedController.close();
    _statusController.close();
  }
}
