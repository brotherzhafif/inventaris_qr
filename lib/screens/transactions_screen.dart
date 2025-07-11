import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/item_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/item.dart';
import '../widgets/transaction_form_dialog.dart';
import 'scanner_screen.dart';
import 'items_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final String? searchCode;
  final Function(Map<String, dynamic>)? onScanResult;

  const TransactionsScreen({super.key, this.searchCode, this.onScanResult});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();

    // Set search code if provided
    if (widget.searchCode != null) {
      _searchController.text = widget.searchCode!;
      _searchQuery = widget.searchCode!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Section
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
                const SizedBox(width: 12),
                // Date Filter
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showDateRangePicker,
                        icon: const Icon(Icons.date_range),
                        label: const Text('Filter Periode'),
                      ),
                    ),
                  ],
                ),
                if (_startDate != null && _endDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Chip(
                          label: Text(
                            '${_dateFormatter.format(_startDate!)} - ${_dateFormatter.format(_endDate!)}',
                          ),
                          onDeleted: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                if (transactionProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (transactionProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text(
                          transactionProvider.errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            transactionProvider.loadTransactions();
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                // Filter transactions
                List<app_transaction.Transaction> filteredTransactions =
                    transactionProvider.transactions;

                if (_searchQuery.isNotEmpty) {
                  filteredTransactions = filteredTransactions.where((
                    transaction,
                  ) {
                    // Search by item name or barcode
                    final itemProvider = Provider.of<ItemProvider>(
                      context,
                      listen: false,
                    );
                    final item = itemProvider.items.firstWhere(
                      (item) => item.barcode == transaction.itemBarcode,
                      orElse: () => Item(
                        barcode: '',
                        name: '',
                        categoryId: 0,
                        location: '',
                        dateAdded: DateTime.now(),
                        currentStock: 0,
                      ),
                    );

                    return item.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        transaction.itemBarcode.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                  }).toList();
                }

                if (_startDate != null && _endDate != null) {
                  filteredTransactions = filteredTransactions.where((t) {
                    return t.date.isAfter(_startDate!) &&
                        t.date.isBefore(_endDate!.add(const Duration(days: 1)));
                  }).toList();
                }

                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _startDate != null
                              ? 'Tidak ada transaksi yang sesuai pencarian'
                              : 'Belum ada transaksi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await transactionProvider.loadTransactions();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _buildTransactionCard(transaction);
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
          if (!authProvider.currentUser!.canManageTransactions) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton(
            heroTag: "transactions_fab",
            onPressed: () => _showTransactionForm(),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(app_transaction.Transaction transaction) {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        final item = itemProvider.items.firstWhere(
          (item) => item.barcode == transaction.itemBarcode,
          orElse: () => Item(
            name: 'Item Tidak Ditemukan',
            barcode: '-',
            categoryId: 0,
            location: '-',
            dateAdded: DateTime.now(),
            currentStock: 0,
          ),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  transaction.type == app_transaction.TransactionType.incoming
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              child: Icon(
                transaction.type == app_transaction.TransactionType.incoming
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color:
                    transaction.type == app_transaction.TransactionType.incoming
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction.type.displayName} - ${transaction.quantity} unit',
                ),
                Text(_dateFormatter.format(transaction.date)),
                if (transaction.supplier != null ||
                    transaction.recipient != null)
                  Text(
                    transaction.type == app_transaction.TransactionType.incoming
                        ? 'Supplier: ${transaction.supplier}'
                        : 'Penerima: ${transaction.recipient}',
                  ),
                if (transaction.notes != null && transaction.notes!.isNotEmpty)
                  Text('Catatan: ${transaction.notes}'),
              ],
            ),
            onTap: () => _showTransactionDetails(transaction, item),
          ),
        );
      },
    );
  }

  void _showTransactionDetails(
    app_transaction.Transaction transaction,
    Item item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Transaksi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Barang', item.name),
              _buildDetailRow('Barcode', item.barcode),
              _buildDetailRow('Jenis', transaction.type.displayName),
              _buildDetailRow('Jumlah', '${transaction.quantity} unit'),
              _buildDetailRow(
                'Tanggal',
                _dateFormatter.format(transaction.date),
              ),
              if (transaction.supplier != null)
                _buildDetailRow('Supplier', transaction.supplier!),
              if (transaction.recipient != null)
                _buildDetailRow('Penerima', transaction.recipient!),
              if (transaction.notes != null && transaction.notes!.isNotEmpty)
                _buildDetailRow('Catatan', transaction.notes!),
            ],
          ),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.currentUser!.canManageTransactions) {
                return TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showTransactionForm(transaction: transaction);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteTransaction(transaction);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Hapus'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
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

  void _showTransactionForm({app_transaction.Transaction? transaction}) {
    showDialog(
      context: context,
      builder: (context) => TransactionFormDialog(transaction: transaction),
    );
  }

  Future<void> _deleteTransaction(
    app_transaction.Transaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus transaksi ini? Stok barang akan disesuaikan kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await transactionProvider.deleteTransaction(
        transaction.id!,
        authProvider.currentUser!.id!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Transaksi berhasil dihapus'
                  : transactionProvider.errorMessage ??
                        'Gagal menghapus transaksi',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
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

        if (action == 'transactions') {
          // Fill search for transactions (current screen)
          setState(() {
            _searchController.text = code;
            _searchQuery = code;
          });
        } else if (action == 'items') {
          // Use callback to dashboard or fallback to navigation
          if (widget.onScanResult != null) {
            widget.onScanResult!(result);
          } else {
            // Fallback for standalone usage
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemsScreen(searchCode: code),
                ),
              );
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
