import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/item_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/item.dart';
import '../widgets/transaction_form_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  app_transaction.TransactionType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  final _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
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
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Type Filter
                Row(
                  children: [
                    Expanded(
                      child:
                          DropdownButtonFormField<
                            app_transaction.TransactionType?
                          >(
                            value: _selectedType,
                            decoration: InputDecoration(
                              labelText: 'Filter Jenis',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<
                                app_transaction.TransactionType?
                              >(value: null, child: Text('Semua Jenis')),
                              ...app_transaction.TransactionType.values.map(
                                (type) =>
                                    DropdownMenuItem<
                                      app_transaction.TransactionType?
                                    >(
                                      value: type,
                                      child: Text(type.displayName),
                                    ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value;
                              });
                            },
                          ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showDateRangePicker,
                      icon: const Icon(Icons.date_range),
                      label: const Text('Periode'),
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

                if (_selectedType != null) {
                  filteredTransactions = filteredTransactions
                      .where((t) => t.type == _selectedType)
                      .toList();
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
                          _selectedType != null || _startDate != null
                              ? 'Tidak ada transaksi yang sesuai filter'
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
          (item) => item.id == transaction.itemId,
          orElse: () => Item(
            id: 0,
            name: 'Item Tidak Ditemukan',
            code: '-',
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
              _buildDetailRow('Kode Barang', item.code),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
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

  void _showTransactionForm() {
    showDialog(
      context: context,
      builder: (context) => const TransactionFormDialog(),
    );
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
}
