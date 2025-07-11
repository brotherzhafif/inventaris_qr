import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/item_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/item.dart';
import '../screens/scanner_screen.dart';

class TransactionFormDialog extends StatefulWidget {
  final app_transaction.Transaction? transaction; // null for add mode
  final String? selectedItemBarcode; // for pre-selecting item

  const TransactionFormDialog({
    super.key,
    this.transaction,
    this.selectedItemBarcode,
  });

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _supplierController = TextEditingController();
  final _recipientController = TextEditingController();
  final _notesController = TextEditingController();

  app_transaction.TransactionType _selectedType =
      app_transaction.TransactionType.incoming;
  String? _selectedItemBarcode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      // Edit mode - populate fields
      final transaction = widget.transaction!;
      _selectedType = transaction.type;
      _selectedItemBarcode = transaction.itemBarcode;
      _quantityController.text = transaction.quantity.toString();
      _supplierController.text = transaction.supplier ?? '';
      _recipientController.text = transaction.recipient ?? '';
      _notesController.text = transaction.notes ?? '';
    } else if (widget.selectedItemBarcode != null) {
      // Add mode with pre-selected item
      _selectedItemBarcode = widget.selectedItemBarcode;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _supplierController.dispose();
    _recipientController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.transaction == null ? 'Tambah Transaksi' : 'Edit Transaksi',
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Transaction Type
                DropdownButtonFormField<app_transaction.TransactionType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Transaksi*',
                  ),
                  items: app_transaction.TransactionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            type == app_transaction.TransactionType.incoming
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color:
                                type == app_transaction.TransactionType.incoming
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Item Selection
                Consumer<ItemProvider>(
                  builder: (context, itemProvider, child) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedItemBarcode,
                                decoration: const InputDecoration(
                                  labelText: 'Pilih Barang*',
                                ),
                                items: itemProvider.items.map((item) {
                                  return DropdownMenuItem<String>(
                                    value: item.barcode,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name),
                                        Text(
                                          'Stok: ${item.currentStock} - ${item.barcode}',
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedItemBarcode = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Pilih barang';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: _scanItemQR,
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white,
                                ),
                                tooltip: 'Scan QR Barang',
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Quantity
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah*',
                    hintText: 'Masukkan jumlah',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah tidak boleh kosong';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Masukkan jumlah yang valid';
                    }

                    // Check stock for outgoing transactions
                    if (_selectedType ==
                            app_transaction.TransactionType.outgoing &&
                        _selectedItemBarcode != null) {
                      final itemProvider = Provider.of<ItemProvider>(
                        context,
                        listen: false,
                      );
                      final item = itemProvider.items.firstWhere(
                        (item) => item.barcode == _selectedItemBarcode,
                        orElse: () => Item(
                          name: '',
                          barcode: '',
                          categoryId: 0,
                          location: '',
                          dateAdded: DateTime.now(),
                          currentStock: 0,
                        ),
                      );

                      if (quantity > item.currentStock) {
                        return 'Stok tidak mencukupi (tersedia: ${item.currentStock})';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Supplier (for incoming) / Recipient (for outgoing)
                if (_selectedType == app_transaction.TransactionType.incoming)
                  TextFormField(
                    controller: _supplierController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier',
                      hintText: 'Masukkan nama supplier',
                    ),
                  )
                else
                  TextFormField(
                    controller: _recipientController,
                    decoration: const InputDecoration(
                      labelText: 'Penerima',
                      hintText: 'Masukkan nama penerima',
                    ),
                  ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    hintText: 'Masukkan catatan (opsional)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTransaction,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final transaction = app_transaction.Transaction(
        id: widget.transaction?.id, // Keep ID for edit mode
        itemBarcode: _selectedItemBarcode!,
        type: _selectedType,
        quantity: int.parse(_quantityController.text),
        date:
            widget.transaction?.date ??
            DateTime.now(), // Keep original date for edit mode
        supplier: _selectedType == app_transaction.TransactionType.incoming
            ? _supplierController.text.trim().isEmpty
                  ? null
                  : _supplierController.text.trim()
            : null,
        recipient: _selectedType == app_transaction.TransactionType.outgoing
            ? _recipientController.text.trim().isEmpty
                  ? null
                  : _recipientController.text.trim()
            : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        userId: authProvider.currentUser!.id!,
      );

      bool success;
      String successMessage;

      if (widget.transaction == null) {
        // Add mode
        success = await transactionProvider.addTransaction(
          transaction,
          authProvider.currentUser!.id!,
        );
        successMessage = 'Transaksi berhasil ditambahkan';
      } else {
        // Edit mode
        success = await transactionProvider.updateTransaction(
          transaction,
          authProvider.currentUser!.id!,
        );
        successMessage = 'Transaksi berhasil diupdate';
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                transactionProvider.errorMessage ?? 'Gagal menyimpan transaksi',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scanItemQR() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );

      if (result != null && mounted) {
        String? scannedCode;

        if (result is String) {
          scannedCode = result;
        } else if (result is Map<String, dynamic>) {
          scannedCode = result['code'];
        }

        if (scannedCode != null) {
          // Check if item with this barcode exists
          final itemProvider = Provider.of<ItemProvider>(
            context,
            listen: false,
          );
          final existingItem = itemProvider.items.firstWhere(
            (item) => item.barcode == scannedCode,
            orElse: () => Item(
              name: '',
              barcode: '',
              categoryId: 0,
              location: '',
              dateAdded: DateTime.now(),
              currentStock: 0,
            ),
          );

          if (existingItem.name.isNotEmpty) {
            setState(() {
              _selectedItemBarcode = scannedCode;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Barang "${existingItem.name}" dipilih'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Barang dengan kode "$scannedCode" tidak ditemukan',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
