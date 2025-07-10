import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal();

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  Future<String?> scanBarcode() async {
    try {
      // Check and request camera permission
      if (!await requestCameraPermission()) {
        debugPrint('Camera permission not granted');
        return null;
      }

      // This is a placeholder - actual scanning happens in ScannerScreen
      debugPrint('Barcode scanning should be done using ScannerScreen');
      return null;
    } catch (e) {
      debugPrint('Error scanning barcode: $e');
      return null;
    }
  }

  Future<String?> scanQRCode() async {
    try {
      // Check and request camera permission
      if (!await requestCameraPermission()) {
        debugPrint('Camera permission not granted');
        return null;
      }

      // This is a placeholder - actual scanning happens in ScannerScreen
      debugPrint('QR code scanning should be done using ScannerScreen');
      return null;
    } catch (e) {
      debugPrint('Error scanning QR code: $e');
      return null;
    }
  }

  String generateBarcode() {
    // Generate a simple barcode based on timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'BRC$timestamp';
  }

  String generateQRCode() {
    // Generate a simple QR code based on timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'QRC$timestamp';
  }

  bool isValidBarcode(String barcode) {
    // Basic validation for barcode format
    if (barcode.isEmpty) return false;

    // Check minimum length
    if (barcode.length < 3) return false;

    // Check if it contains valid characters (alphanumeric and some special chars)
    final regex = RegExp(r'^[A-Za-z0-9\-_]+$');
    return regex.hasMatch(barcode);
  }

  bool isValidQRCode(String qrCode) {
    // QR codes can contain more varied content
    return qrCode.isNotEmpty;
  }
}
