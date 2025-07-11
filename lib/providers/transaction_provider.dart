import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/activity_log.dart';
import '../services/database_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<app_transaction.Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<app_transaction.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _databaseService.getAllTransactions();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat data transaksi: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTransaction(
    app_transaction.Transaction transaction,
    int userId,
  ) async {
    try {
      // Check if item exists and has enough stock for outgoing transactions
      final item = await _databaseService.getItemByBarcode(
        transaction.itemBarcode,
      );
      if (item == null) {
        _errorMessage = 'Barang tidak ditemukan';
        notifyListeners();
        return false;
      }

      if (transaction.type == app_transaction.TransactionType.outgoing &&
          item.currentStock < transaction.quantity) {
        _errorMessage =
            'Stok tidak mencukupi. Stok tersedia: ${item.currentStock}';
        notifyListeners();
        return false;
      }

      await _databaseService.insertTransaction(transaction);

      // Log activity
      await _databaseService.insertActivityLog(
        ActivityLog(
          userId: userId,
          action: 'Add Transaction',
          description:
              '${transaction.type.displayName} - ${item.name}: ${transaction.quantity}',
          timestamp: DateTime.now(),
        ),
      );

      await loadTransactions();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah transaksi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<List<app_transaction.Transaction>> getTransactionsByItem(
    String itemBarcode,
  ) async {
    try {
      return await _databaseService.getTransactionsByItemBarcode(itemBarcode);
    } catch (e) {
      _errorMessage = 'Gagal memuat riwayat transaksi: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<app_transaction.Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _databaseService.getTransactionsByDateRange(
        startDate,
        endDate,
      );
    } catch (e) {
      _errorMessage = 'Gagal memuat transaksi berdasarkan tanggal: $e';
      notifyListeners();
      return [];
    }
  }

  Future<List<app_transaction.Transaction>> getTransactionsByType(
    app_transaction.TransactionType type,
  ) async {
    try {
      return await _databaseService.getTransactionsByType(type);
    } catch (e) {
      _errorMessage = 'Gagal memuat transaksi berdasarkan jenis: $e';
      notifyListeners();
      return [];
    }
  }

  List<app_transaction.Transaction> getIncomingTransactions() {
    return _transactions
        .where((t) => t.type == app_transaction.TransactionType.incoming)
        .toList();
  }

  List<app_transaction.Transaction> getOutgoingTransactions() {
    return _transactions
        .where((t) => t.type == app_transaction.TransactionType.outgoing)
        .toList();
  }

  List<app_transaction.Transaction> getTodayTransactions() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _transactions.where((t) {
      return t.date.isAfter(todayStart) && t.date.isBefore(todayEnd);
    }).toList();
  }

  int getTotalIncomingToday() {
    final todayTransactions = getTodayTransactions();
    return todayTransactions
        .where((t) => t.type == app_transaction.TransactionType.incoming)
        .fold(0, (total, t) => total + t.quantity);
  }

  int getTotalOutgoingToday() {
    final todayTransactions = getTodayTransactions();
    return todayTransactions
        .where((t) => t.type == app_transaction.TransactionType.outgoing)
        .fold(0, (total, t) => total + t.quantity);
  }

  Future<bool> updateTransaction(
    app_transaction.Transaction transaction,
    int userId,
  ) async {
    try {
      // Check if item exists and has enough stock for outgoing transactions
      final item = await _databaseService.getItemByBarcode(
        transaction.itemBarcode,
      );
      if (item == null) {
        _errorMessage = 'Barang tidak ditemukan';
        notifyListeners();
        return false;
      }

      // Get current transaction to calculate stock difference
      final currentTransaction = await _databaseService.getTransactionById(
        transaction.id!,
      );
      if (currentTransaction == null) {
        _errorMessage = 'Transaksi tidak ditemukan';
        notifyListeners();
        return false;
      }

      // Calculate stock after reverting current transaction
      int availableStock = item.currentStock;
      if (currentTransaction.type == app_transaction.TransactionType.incoming) {
        availableStock -= currentTransaction.quantity;
      } else {
        availableStock += currentTransaction.quantity;
      }

      // Check if new transaction is valid
      if (transaction.type == app_transaction.TransactionType.outgoing &&
          availableStock < transaction.quantity) {
        _errorMessage =
            'Stok tidak mencukupi. Stok tersedia setelah perubahan: $availableStock';
        notifyListeners();
        return false;
      }

      await _databaseService.updateTransaction(transaction);

      // Log activity
      await _databaseService.insertActivityLog(
        ActivityLog(
          userId: userId,
          action: 'Update Transaction',
          description:
              'Update ${transaction.type.displayName} - ${item.name}: ${transaction.quantity}',
          timestamp: DateTime.now(),
        ),
      );

      await loadTransactions();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate transaksi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(int transactionId, int userId) async {
    try {
      // Get transaction details for logging
      final transaction = await _databaseService.getTransactionById(
        transactionId,
      );
      if (transaction == null) {
        _errorMessage = 'Transaksi tidak ditemukan';
        notifyListeners();
        return false;
      }

      final item = await _databaseService.getItemByBarcode(
        transaction.itemBarcode,
      );
      await _databaseService.deleteTransaction(transactionId);

      // Log activity
      await _databaseService.insertActivityLog(
        ActivityLog(
          userId: userId,
          action: 'Delete Transaction',
          description:
              'Delete ${transaction.type.displayName} - ${item?.name ?? 'Unknown'}: ${transaction.quantity}',
          timestamp: DateTime.now(),
        ),
      );

      await loadTransactions();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus transaksi: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
