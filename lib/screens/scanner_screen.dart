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
        // Use mounted check before accessing provider
        if (!mounted) return;

        // Check if this barcode exists in items
        final itemProvider = Provider.of<ItemProvider>(context, listen: false);
        final existingItem = itemProvider.items
            .where((item) => item.barcode == code)
            .firstOrNull;

        if (mounted) {
          if (existingItem != null) {
            // Show item details with search options
            _showScanResult(existingItem.name, code, true);
          } else {
            // Show scan result with search options
            _showScanResult('Barang tidak ditemukan', code, false);
          }
        }
      }
    }
  }

  void _showScanResult(String itemName, String code, bool itemFound) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(itemFound ? 'Barang Ditemukan' : 'Hasil Scan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (itemFound) ...[
              Text('Nama: $itemName'),
              const SizedBox(height: 8),
            ],
            Text('Barcode: $code'),
            const SizedBox(height: 16),
            const Text(
              'Pilih tindakan yang ingin dilakukan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetScanning();
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Lagi'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _navigateToItems(code);
                  },
                  icon: const Icon(Icons.inventory),
                  label: const Text('Cari Barang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _navigateToTransactions(code);
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Cari\nTransaksi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (itemFound) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateToAddTransaction(code);
                    },
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Tambah Transaksi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToItems(String code) {
    // Close scanner and return to calling screen with a flag for items
    Navigator.of(context).pop({'action': 'items', 'code': code});
  }

  void _navigateToTransactions(String code) {
    // Close scanner and return to calling screen with a flag for transactions
    Navigator.of(context).pop({'action': 'transactions', 'code': code});
  }

  void _navigateToAddTransaction(String code) {
    // Close scanner and return to calling screen with a flag for adding transaction
    Navigator.of(context).pop({'action': 'add_transaction', 'code': code});
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
