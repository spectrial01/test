import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart'; // 👈 barcode scanner package
import 'package:flutter/material.dart';

// 👇 QR Code Scanner
Future<String?> scanQRCode() async {
  // 👈 function opens the device's camera to scan QR code
  try {
    final scannedCode = await FlutterBarcodeScanner.scanBarcode(
      '#ffffff',
      'Cancel',
      true,
      ScanMode.QR, // 👈 tells to look for QR codes only
    );

    if (scannedCode == '-1') {
      // 👈 if user tapped cancel
      return null;
    }
    return scannedCode;
  } catch (e) {
    debugPrint('QR Scan Error: $e');
    return null;
  }
}
