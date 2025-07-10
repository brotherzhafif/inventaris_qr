import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/item_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _dateFormatter = DateFormat('dd/MM/yyyy');
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laporan',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Date Range Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Periode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              _startDate != null && _endDate != null
                                  ? '${_dateFormatter.format(_startDate!)} - ${_dateFormatter.format(_endDate!)}'
                                  : 'Pilih Periode',
                            ),
                          ),
                        ),
                        if (_startDate != null && _endDate != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                              });
                            },
                            icon: const Icon(Icons.clear),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Report Types
            Text(
              'Jenis Laporan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Items Report
            _buildReportCard(
              title: 'Laporan Data Barang',
              subtitle: 'Export daftar semua barang dengan detail lengkap',
              icon: Icons.inventory_2,
              color: Colors.blue,
              onExportPDF: () => _exportItemsToPDF(),
              onExportExcel: () => _exportItemsToExcel(),
            ),

            const SizedBox(height: 16),

            // Transactions Report
            _buildReportCard(
              title: 'Laporan Transaksi',
              subtitle: 'Export data transaksi masuk dan keluar',
              icon: Icons.swap_horiz,
              color: Colors.green,
              onExportPDF: () => _exportTransactionsToPDF(),
              onExportExcel: () => _exportTransactionsToExcel(),
            ),

            const SizedBox(height: 16),

            // Low Stock Report
            _buildReportCard(
              title: 'Laporan Stok Menipis',
              subtitle: 'Export barang dengan stok yang perlu diperhatikan',
              icon: Icons.warning,
              color: Colors.orange,
              onExportPDF: () => _exportLowStockToPDF(),
              onExportExcel: () => _exportLowStockToExcel(),
            ),

            const SizedBox(height: 24),

            // Summary Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Data',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer2<ItemProvider, TransactionProvider>(
                      builder: (context, itemProvider, transactionProvider, child) {
                        return Column(
                          children: [
                            _buildSummaryRow(
                              'Total Barang',
                              '${itemProvider.items.length}',
                            ),
                            _buildSummaryRow(
                              'Total Stok',
                              '${_getTotalStock(itemProvider.items)}',
                            ),
                            _buildSummaryRow(
                              'Stok Menipis',
                              '${_getLowStockCount(itemProvider.items)}',
                            ),
                            _buildSummaryRow(
                              'Total Transaksi',
                              '${transactionProvider.transactions.length}',
                            ),
                            _buildSummaryRow(
                              'Transaksi Hari Ini',
                              '${_getTodayTransactionCount(transactionProvider.transactions)}',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onExportPDF,
    required VoidCallback onExportExcel,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : onExportPDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : onExportExcel,
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export Excel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _selectDateRange() async {
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

  Future<void> _exportItemsToPDF() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final file = await ExportService().exportItemsToPDF(itemProvider.items);
      await ExportService().shareFile(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan PDF berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportItemsToExcel() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final file = await ExportService().exportItemsToExcel(itemProvider.items);
      await ExportService().shareFile(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan Excel berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportTransactionsToPDF() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      var transactions = transactionProvider.transactions;

      // Filter by date range if selected
      if (_startDate != null && _endDate != null) {
        transactions = transactions.where((t) {
          return t.date.isAfter(_startDate!) &&
              t.date.isBefore(_endDate!.add(const Duration(days: 1)));
        }).toList();
      }

      final file = await ExportService().exportTransactionsToPDF(transactions);
      await ExportService().shareFile(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan PDF berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportTransactionsToExcel() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      var transactions = transactionProvider.transactions;

      // Filter by date range if selected
      if (_startDate != null && _endDate != null) {
        transactions = transactions.where((t) {
          return t.date.isAfter(_startDate!) &&
              t.date.isBefore(_endDate!.add(const Duration(days: 1)));
        }).toList();
      }

      final file = await ExportService().exportTransactionsToExcel(
        transactions,
      );
      await ExportService().shareFile(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan Excel berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportLowStockToPDF() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final lowStockItems = itemProvider.getLowStockItems();

      if (lowStockItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada barang dengan stok menipis'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final file = await ExportService().exportItemsToPDF(lowStockItems);
      await ExportService().shareFile(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan PDF berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportLowStockToExcel() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final lowStockItems = itemProvider.getLowStockItems();

      if (lowStockItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada barang dengan stok menipis'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final file = await ExportService().exportItemsToExcel(lowStockItems);
      await ExportService().shareFile(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan Excel berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  int _getTotalStock(List<dynamic> items) {
    return items.fold(0, (sum, item) => sum + (item.currentStock as int));
  }

  int _getLowStockCount(List<dynamic> items) {
    return items.where((item) => item.isLowStock).length;
  }

  int _getTodayTransactionCount(List<dynamic> transactions) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return transactions.where((t) {
      return t.date.isAfter(todayStart) && t.date.isBefore(todayEnd);
    }).length;
  }
}
