import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../providers/item_provider.dart';
import '../providers/auth_provider.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../widgets/item_form_dialog.dart';
import 'scanner_screen.dart';
import 'transactions_screen.dart';

class ItemsScreen extends StatefulWidget {
  final String? searchCode;
  final Function(Map<String, dynamic>)? onScanResult;

  const ItemsScreen({super.key, this.searchCode, this.onScanResult});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set search code if provided
    if (widget.searchCode != null) {
      _searchController.text = widget.searchCode!;
      _searchQuery = widget.searchCode!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ItemProvider>(context, listen: false).loadItems();
      Provider.of<ItemProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar with QR Scan
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari barang, kategori dan kode...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // QR Scan Button
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _scanQR,
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                        ),
                        tooltip: 'Scan QR Code',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: Consumer<ItemProvider>(
              builder: (context, itemProvider, child) {
                if (itemProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (itemProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text(
                          itemProvider.errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            itemProvider.loadItems();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                // Filter items based on search
                List<Item> filteredItems = itemProvider.items;

                if (_searchQuery.isNotEmpty) {
                  filteredItems = itemProvider.searchItems(_searchQuery);
                }

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Tidak ada barang yang sesuai pencarian'
                              : 'Belum ada barang',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await itemProvider.loadItems();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final category = itemProvider.categories.firstWhere(
                        (cat) => cat.id == item.categoryId,
                        orElse: () => Category(
                          id: 0,
                          name: 'Unknown',
                          createdAt: DateTime.now(),
                        ),
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _showItemDetails(item, category),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // QR Code
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: QrImageView(
                                    data: item.barcode,
                                    version: QrVersions.auto,
                                    size: 60,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Item Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Kode: ${item.barcode}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Kategori: ${category.name}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Lokasi: ${item.location}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Stock Info and Actions
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.isOutOfStock
                                            ? Colors.red.shade100
                                            : item.isLowStock
                                            ? Colors.orange.shade100
                                            : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Stok: ${item.currentStock}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: item.isOutOfStock
                                              ? Colors.red.shade700
                                              : item.isLowStock
                                              ? Colors.orange.shade700
                                              : Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                    if (item.isLowStock)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.isOutOfStock
                                              ? Colors.red
                                              : Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          item.isOutOfStock
                                              ? 'Habis'
                                              : 'Menipis',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, child) {
                                        if (!authProvider
                                            .currentUser!
                                            .canManageItems) {
                                          return const SizedBox.shrink();
                                        }
                                        return PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showItemForm(item);
                                            } else if (value == 'delete') {
                                              _deleteItem(item);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 16),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    size: 16,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Hapus',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.currentUser!.canManageItems) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton(
            heroTag: "items_fab",
            onPressed: () => _showItemForm(),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _showItemForm([Item? item]) {
    showDialog(
      context: context,
      builder: (context) => ItemFormDialog(item: item),
    );
  }

  void _showItemDetails(Item item, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Barcode', item.barcode),
              _buildDetailRow('Kategori', category.name),
              _buildDetailRow('Lokasi', item.location),
              _buildDetailRow('Stok Saat Ini', item.currentStock.toString()),
              _buildDetailRow(
                'Tanggal Ditambah',
                '${item.dateAdded.day}/${item.dateAdded.month}/${item.dateAdded.year}',
              ),
              if (item.description != null && item.description!.isNotEmpty)
                _buildDetailRow('Deskripsi', item.description!),
            ],
          ),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.currentUser!.canManageItems) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _downloadQR(item),
                      child: const Text('Download QR'),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _downloadQR(item),
                    child: const Text('Download QR'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showItemForm(item);
                    },
                    child: const Text('Edit'),
                  ),
                  TextButton(
                    onPressed: () => _confirmDelete(item),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Hapus'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _confirmDelete(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close item details dialog

              final itemProvider = Provider.of<ItemProvider>(
                context,
                listen: false,
              );
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );

              // Store context before async operation
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final success = await itemProvider.deleteItem(
                item.id!,
                authProvider.currentUser!.id!,
              );

              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Barang berhasil dihapus'
                          : 'Gagal menghapus barang',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _scanQR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (result != null) {
      if (result is String) {
        // Legacy support for direct string return
        setState(() {
          _searchController.text = result;
          _searchQuery = result;
        });
      } else if (result is Map<String, dynamic>) {
        final action = result['action'];
        final code = result['code'];

        if (action == 'items') {
          // Fill search for items (current screen)
          setState(() {
            _searchController.text = code;
            _searchQuery = code;
          });
        } else if (action == 'transactions') {
          // Navigate to transactions screen and pass the search code
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionsScreen(searchCode: code),
              ),
            );
          }
        }
      }
    }
  }

  void _downloadQR(Item item) async {
    try {
      // Create QR code painter
      final painter = QrPainter(
        data: item.barcode,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
        color: const Color(0xFF000000),
        gapless: false,
      );

      // Create a canvas with white background and QR code
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const size = 512.0;
      const totalHeight = 600.0;

      // Draw white background
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, size, totalHeight),
        Paint()..color = Colors.white,
      );

      // Draw QR code
      painter.paint(canvas, const Size(size, size));

      // Draw item info text
      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${item.name}\n',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: 'Kode: ${item.barcode}',
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: size - 32);
      textPainter.paint(canvas, const Offset(16, size + 16));

      // Convert to image
      final picture = pictureRecorder.endRecording();
      final img = await picture.toImage(size.toInt(), totalHeight.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_${item.barcode}.png');
      await file.writeAsBytes(pngBytes);

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code untuk ${item.name} (${item.barcode})',
        subject: 'QR Code Inventaris',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.status == ShareResultStatus.success
                  ? 'QR code berhasil dibagikan'
                  : 'QR code siap didownload',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteItem(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final itemProvider = Provider.of<ItemProvider>(
                context,
                listen: false,
              );
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );

              // Store context before async operation
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final success = await itemProvider.deleteItem(
                item.id!,
                authProvider.currentUser!.id!,
              );

              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Barang berhasil dihapus'
                          : 'Gagal menghapus barang',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
