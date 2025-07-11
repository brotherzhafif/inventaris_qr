import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../providers/auth_provider.dart';
import '../models/item.dart';
import '../services/barcode_service.dart';

class ItemFormDialog extends StatefulWidget {
  final Item? item;

  const ItemFormDialog({super.key, this.item});

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _locationController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _barcodeController.text = widget.item!.barcode;
      _locationController.text = widget.item!.location;
      _stockController.text = widget.item!.currentStock.toString();
      _descriptionController.text = widget.item!.description ?? '';
      _selectedCategoryId = widget.item!.categoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _locationController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Tambah Barang' : 'Edit Barang'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang*',
                    hintText: 'Masukkan nama barang',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama barang tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Barcode field
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode*',
                    hintText: 'Masukkan barcode atau scan',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: _scanBarcode,
                        ),
                        IconButton(
                          icon: const Icon(Icons.auto_awesome),
                          onPressed: _generateBarcode,
                        ),
                      ],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Barcode tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category dropdown
                Consumer<ItemProvider>(
                  builder: (context, itemProvider, child) {
                    return DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Kategori*'),
                      items: itemProvider.categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Pilih kategori';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Location field
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi Penyimpanan*',
                    hintText: 'Masukkan lokasi penyimpanan',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lokasi penyimpanan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Stock field
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stok Awal*',
                    hintText: 'Masukkan jumlah stok',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Stok tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Stok harus berupa angka';
                    }
                    if (int.parse(value) < 0) {
                      return 'Stok tidak boleh negatif';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Masukkan deskripsi (opsional)',
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
          onPressed: _isLoading ? null : _saveItem,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.item == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }

  Future<void> _scanBarcode() async {
    try {
      final barcode = await BarcodeService().scanBarcode();
      if (barcode != null && mounted) {
        setState(() {
          _barcodeController.text = barcode;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memindai barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generateBarcode() {
    final barcode = BarcodeService().generateBarcode();
    setState(() {
      _barcodeController.text = barcode;
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final item = Item(
        id: widget.item?.id,
        name: _nameController.text.trim(),
        barcode: _barcodeController.text.trim(),
        categoryId: _selectedCategoryId!,
        location: _locationController.text.trim(),
        dateAdded: widget.item?.dateAdded ?? DateTime.now(),
        currentStock: int.parse(_stockController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      bool success;
      if (widget.item == null) {
        success = await itemProvider.addItem(
          item,
          authProvider.currentUser!.id!,
        );
      } else {
        success = await itemProvider.updateItem(
          item,
          authProvider.currentUser!.id!,
        );
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.item == null
                    ? 'Barang berhasil ditambahkan'
                    : 'Barang berhasil diupdate',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(itemProvider.errorMessage ?? 'Terjadi kesalahan'),
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
}
