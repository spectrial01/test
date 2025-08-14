import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:battery_plus/battery_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Initialize and configure the background service
Future<void> initializeService() async {
  // First request both foreground + background permissions
  bool canTrack = await _requestLocationPermissions();

  if (!canTrack) {
    print("⚠️ Cannot start location tracking — permissions denied.");
    return;
  }

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      foregroundServiceNotificationId: 888,
      initialNotificationTitle: "Project Nexus Tracking",
      initialNotificationContent: "Location tracking is running...",
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

/// Ask for both foreground and background location permissions
Future<bool> _requestLocationPermissions() async {
  // Foreground
  var fgStatus = await Permission.location.status;
  if (!fgStatus.isGranted) {
    fgStatus = await Permission.location.request();
    if (!fgStatus.isGranted) {
      print("❌ Foreground location denied.");
      return false;
    }
  }
  print("✅ Foreground location granted.");

  // Background
  var bgStatus = await Permission.locationAlways.status;
  if (!bgStatus.isGranted) {
    bgStatus = await Permission.locationAlways.request();
    if (!bgStatus.isGranted) {
      print(
        "⚠️ Background location denied — tracking will only run in foreground mode.",
      );
      return true; // Still allow foreground mode
    }
  }
  print("✅ Background location granted.");
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
    service.setAsForegroundService();
  }

  // Run every 10 seconds
  Timer.periodic(const Duration(seconds: 2), (timer) async {
    bool hasPermission = await _checkLocationPermissions();
    if (!hasPermission) {
      print("⛔ No location permission, skipping update.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 👇 Print to terminal for testing
      print(
        "📍 Current Location => Lat: ${position.latitude}, Long: ${position.longitude}",
      );

      // ===============================
      // API CONNECTION (STANDBY CODE)
      // ===============================
      /*
      final response = await http.post(
        Uri.parse("https://asia-southeast1nexuspolice-13560.cloudfunctions.net/updateLocation"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer YOUR_API_TOKEN", // Replace
        },
        body: jsonEncode({
          "deploymentCode": "DEPLOY-2024-001", // Replace
          "location": {
            "latitude": position.latitude,
            "longitude": position.longitude,
            "accuracy": position.accuracy,
          },
          "batteryStatus": await getBatteryLevel(),
          "signal": "strong", // TODO: Replace with real signal data
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Location updated on server");
      } else {
        print("⚠️ Failed to update server: ${response.statusCode} - ${response.body}");
      }
      */
    } catch (e) {
      print("❌ Error getting location: $e");
    }
  });
}

extension on ServiceInstance {
  void setAsForegroundService() {}
}

class AndroidServiceInstance {
}

/// iOS background entry-point
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

/// Check if location permission is granted
Future<bool> _checkLocationPermissions() async {
  LocationPermission permission = await Geolocator.checkPermission();
  return permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
}

/// Get battery percentage
Future<int> getBatteryLevel() async {
  Battery battery = Battery();
  return await battery.batteryLevel;
}
