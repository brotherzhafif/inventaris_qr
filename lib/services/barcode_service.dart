import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
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
        throw Exception('Camera permission not granted');
      }

      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', // Color for the scan line
        'Cancel', // Cancel button text
        true, // Show flash icon
        ScanMode.BARCODE, // Scan mode
      );

      // Check if user cancelled the scan
      if (barcodeScanRes == '-1') {
        return null;
      }

      return barcodeScanRes;
    } catch (e) {
      print('Error scanning barcode: $e');
      return null;
    }
  }

  Future<String?> scanQRCode() async {
    try {
      // Check and request camera permission
      if (!await requestCameraPermission()) {
        throw Exception('Camera permission not granted');
      }

      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', // Color for the scan line
        'Cancel', // Cancel button text
        true, // Show flash icon
        ScanMode.QR, // QR Code scan mode
      );

      // Check if user cancelled the scan
      if (barcodeScanRes == '-1') {
        return null;
      }

      return barcodeScanRes;
    } catch (e) {
      print('Error scanning QR code: $e');
      return null;
    }
  }

  String generateBarcode() {
    // Generate a simple barcode based on timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'BRC$timestamp';
  }

  bool isValidBarcode(String barcode) {
    // Basic validation for barcode format
    if (barcode.isEmpty) return false;

    // Check minimum length
    if (barcode.length < 3) return false;

    // Additional validation rules can be added here
    return true;
  }
}
