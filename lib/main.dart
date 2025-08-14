// 👇 IMPORT PACKAGES FOR THE APP
import 'package:flutter/material.dart';
import 'homepage.dart';

// 👇 Import our background runner
import 'run_backg.dart';

// 👇 Location permission packages
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Check and request permissions before starting service
  await _handlePermissions();

  // Step 2: Start background service
  await initializeService();

  // Step 3: Launch the app UI
  runApp(const ProjectNexusMobileApp());
}

// Function to handle both foreground & background location permissions
Future<void> _handlePermissions() async {
  // Foreground location permission
  var locationStatus = await Permission.location.status;
  if (!locationStatus.isGranted) {
    locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      debugPrint(
        "❌ Location permission denied. Background service will not start.",
      );
      return;
    }
  }

  // Background location permission (Android 10+)
  var backgroundStatus = await Permission.locationAlways.status;
  if (!backgroundStatus.isGranted) {
    backgroundStatus = await Permission.locationAlways.request();
    if (!backgroundStatus.isGranted) {
      debugPrint(
        "❌ Background location permission denied. Service will run only in foreground.",
      );
    }
  }
}

// 👇 APPLICATION MAIN WIDGET
class ProjectNexusMobileApp extends StatelessWidget {
  const ProjectNexusMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Nexus Mobile App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
