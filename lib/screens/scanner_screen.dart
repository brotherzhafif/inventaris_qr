import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Barcode/QR'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: _isScanning ? _onDetect : null,
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    setState(() {
      _isScanning = false;
    });

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        // Check if this barcode exists in items
        final itemProvider = Provider.of<ItemProvider>(context, listen: false);
        final existingItem = itemProvider.items
            .where((item) => item.barcode == code || item.code == code)
            .firstOrNull;

        if (existingItem != null) {
          // Show item details
          _showItemDetails(existingItem.name, code);
        } else {
          // Show option to add new item with this barcode
          _showAddItemOption(code);
        }
      }
    }
  }

  void _showItemDetails(String itemName, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barang Ditemukan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Nama: $itemName'), Text('Kode: $code')],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanning();
            },
            child: const Text('Scan Lagi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  void _showAddItemOption(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barcode Tidak Ditemukan'),
        content: Text(
          'Kode: $code\n\nApakah Anda ingin menambahkan barang baru dengan barcode ini?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanning();
            },
            child: const Text('Scan Lagi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(code); // Return the scanned code
            },
            child: const Text('Tambah Barang'),
          ),
        ],
      ),
    );
  }

  void _resetScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
