import 'package:flutter/foundation.dart' hide Category;
import '../models/item.dart';
import '../models/category.dart';
import '../models/activity_log.dart';
import '../services/database_service.dart';

class ItemProvider extends ChangeNotifier {
  List<Item> _items = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Item> get items => _items;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _databaseService.getAllItems();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat data barang: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _databaseService.getAllCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Gagal memuat kategori: $e';
      notifyListeners();
    }
  }

  Future<bool> addItem(Item item, int userId) async {
    try {
      // Check if code or barcode already exists
      final existingItemByCode = await _databaseService.getItemByCode(
        item.code,
      );
      if (existingItemByCode != null) {
        _errorMessage = 'Kode barang sudah digunakan';
        notifyListeners();
        return false;
      }

      if (item.barcode != null && item.barcode!.isNotEmpty) {
        final existingItemByBarcode = await _databaseService.getItemByBarcode(
          item.barcode!,
        );
        if (existingItemByBarcode != null) {
          _errorMessage = 'Barcode sudah digunakan';
          notifyListeners();
          return false;
        }
      }

      await _databaseService.insertItem(item);

      // Log activity
      await _databaseService.insertActivityLog(
        ActivityLog(
          userId: userId,
          action: 'Add Item',
          description: 'Added new item: ${item.name}',
          timestamp: DateTime.now(),
        ),
      );

      await loadItems();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah barang: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(Item item, int userId) async {
    try {
      await _databaseService.updateItem(item);

      // Log activity
      await _databaseService.insertActivityLog(
        ActivityLog(
          userId: userId,
          action: 'Update Item',
          description: 'Updated item: ${item.name}',
          timestamp: DateTime.now(),
        ),
      );

      await loadItems();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate barang: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(int itemId, int userId) async {
    try {
      await _databaseService.deleteItem(itemId);

      // Log activity
      await _databaseService.insertActivityLog(
        ActivityLog(
          userId: userId,
          action: 'Delete Item',
          description: 'Deleted item with ID: $itemId',
          timestamp: DateTime.now(),
        ),
      );

      await loadItems();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus barang: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Item?> getItemByBarcode(String barcode) async {
    try {
      return await _databaseService.getItemByBarcode(barcode);
    } catch (e) {
      _errorMessage = 'Gagal mencari barang: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Item?> getItemByCode(String code) async {
    try {
      return await _databaseService.getItemByCode(code);
    } catch (e) {
      _errorMessage = 'Gagal mencari barang: $e';
      notifyListeners();
      return null;
    }
  }

  List<Item> getLowStockItems() {
    return _items.where((item) => item.isLowStock).toList();
  }

  List<Item> getOutOfStockItems() {
    return _items.where((item) => item.isOutOfStock).toList();
  }

  List<Item> getItemsByCategory(int categoryId) {
    return _items.where((item) => item.categoryId == categoryId).toList();
  }

  List<Item> searchItems(String query) {
    if (query.isEmpty) return _items;

    final lowercaseQuery = query.toLowerCase();
    return _items.where((item) {
      return item.name.toLowerCase().contains(lowercaseQuery) ||
          item.code.toLowerCase().contains(lowercaseQuery) ||
          (item.barcode?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          item.location.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Future<bool> addCategory(Category category, int userId) async {
    try {
      await _databaseService.insertCategory(category);

      // Log activity
      await _databaseService.insertActivityLog(
        ActivityLog(
          userId: userId,
          action: 'Add Category',
          description: 'Added new category: ${category.name}',
          timestamp: DateTime.now(),
        ),
      );

      await loadCategories();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah kategori: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(Category category, int userId) async {
    try {
      await _databaseService.updateCategory(category);

      // Log activity
      await _databaseService.insertActivityLog(
        ActivityLog(
          userId: userId,
          action: 'Update Category',
          description: 'Updated category: ${category.name}',
          timestamp: DateTime.now(),
        ),
      );

      await loadCategories();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate kategori: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int categoryId, int userId) async {
    try {
      await _databaseService.deleteCategory(categoryId);

      // Log activity
      await _databaseService.insertActivityLog(
        ActivityLog(
          userId: userId,
          action: 'Delete Category',
          description: 'Deleted category with ID: $categoryId',
          timestamp: DateTime.now(),
        ),
      );

      await loadCategories();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus kategori: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
