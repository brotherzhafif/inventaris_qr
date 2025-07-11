import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../models/user.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/activity_log.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'inventaris.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onOpen: (db) async {
          // Enable foreign key constraints
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      debugPrint('Database initialization error: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_login TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Items table
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE NOT NULL,
        image_path TEXT,
        category_id INTEGER NOT NULL,
        location TEXT NOT NULL,
        date_added TEXT NOT NULL,
        current_stock INTEGER NOT NULL DEFAULT 0,
        description TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_barcode TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        date TEXT NOT NULL,
        supplier TEXT,
        recipient TEXT,
        notes TEXT,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (item_barcode) REFERENCES items (barcode),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Activity logs table
    await db.execute('''
      CREATE TABLE activity_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        description TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Insert default admin user
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123', // In production, this should be hashed
      'full_name': 'System Administrator',
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Insert default categories
    final defaultCategories = [
      {'name': 'Elektronik', 'description': 'Peralatan elektronik'},
      {'name': 'Alat Tulis', 'description': 'Peralatan tulis kantor'},
      {'name': 'Furniture', 'description': 'Perabotan kantor'},
      {'name': 'Lainnya', 'description': 'Kategori lainnya'},
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', {
        ...category,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> authenticateUser(String username, String password) async {
    try {
      final db = await database;
      final maps = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );

      if (maps.isNotEmpty) {
        final user = User.fromMap(maps.first);
        // Update last login with error handling
        try {
          await updateUserLastLogin(user.id!);
        } catch (e) {
          debugPrint('Failed to update last login: $e');
          // Don't fail authentication if last login update fails
        }
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return null;
    }
  }

  Future<int> updateUserLastLogin(int userId) async {
    final db = await database;
    return await db.update(
      'users',
      {'last_login': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Category operations
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Item operations
  Future<int> insertItem(Item item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  Future<List<Item>> getAllItems() async {
    final db = await database;
    final maps = await db.query('items', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  Future<Item?> getItemById(int id) async {
    final db = await database;
    final maps = await db.query('items', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Item.fromMap(maps.first);
    }
    return null;
  }

  Future<Item?> getItemByCode(String code) async {
    final db = await database;
    final maps = await db.query('items', where: 'code = ?', whereArgs: [code]);

    if (maps.isNotEmpty) {
      return Item.fromMap(maps.first);
    }
    return null;
  }

  Future<Item?> getItemByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(
      'items',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) {
      return Item.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Item>> getItemsByCategory(int categoryId) async {
    final db = await database;
    final maps = await db.query(
      'items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  Future<List<Item>> getLowStockItems() async {
    final db = await database;
    final maps = await db.query(
      'items',
      where: 'current_stock <= ?',
      whereArgs: [5],
      orderBy: 'current_stock ASC',
    );
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> updateItemStock(int itemId, int newStock) async {
    final db = await database;
    return await db.update(
      'items',
      {'current_stock': newStock},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> updateItemStockByBarcode(String barcode, int newStock) async {
    final db = await database;
    return await db.update(
      'items',
      {'current_stock': newStock},
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // Transaction operations
  Future<int> insertTransaction(app_transaction.Transaction transaction) async {
    final db = await database;

    // Insert transaction
    final transactionId = await db.insert('transactions', transaction.toMap());

    // Update item stock
    final item = await getItemByBarcode(transaction.itemBarcode);
    if (item != null) {
      int newStock = item.currentStock;
      if (transaction.type == app_transaction.TransactionType.incoming) {
        newStock += transaction.quantity;
      } else {
        newStock -= transaction.quantity;
      }
      await updateItemStockByBarcode(transaction.itemBarcode, newStock);
    }

    return transactionId;
  }

  Future<List<app_transaction.Transaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return List.generate(
      maps.length,
      (i) => app_transaction.Transaction.fromMap(maps[i]),
    );
  }

  Future<List<app_transaction.Transaction>> getTransactionsByItemBarcode(
    String itemBarcode,
  ) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'item_barcode = ?',
      whereArgs: [itemBarcode],
      orderBy: 'date DESC',
    );
    return List.generate(
      maps.length,
      (i) => app_transaction.Transaction.fromMap(maps[i]),
    );
  }

  Future<List<app_transaction.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return List.generate(
      maps.length,
      (i) => app_transaction.Transaction.fromMap(maps[i]),
    );
  }

  Future<List<app_transaction.Transaction>> getTransactionsByType(
    app_transaction.TransactionType type,
  ) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'date DESC',
    );
    return List.generate(
      maps.length,
      (i) => app_transaction.Transaction.fromMap(maps[i]),
    );
  }

  Future<app_transaction.Transaction?> getTransactionById(int id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return app_transaction.Transaction.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTransaction(app_transaction.Transaction transaction) async {
    final db = await database;

    // Get the old transaction to revert stock changes
    final oldTransaction = await getTransactionById(transaction.id!);
    if (oldTransaction != null) {
      // Revert old transaction stock changes
      final item = await getItemByBarcode(oldTransaction.itemBarcode);
      if (item != null) {
        int newStock = item.currentStock;
        // Reverse the old transaction effect
        if (oldTransaction.type == app_transaction.TransactionType.incoming) {
          newStock -= oldTransaction.quantity;
        } else {
          newStock += oldTransaction.quantity;
        }

        // Apply new transaction effect
        if (transaction.type == app_transaction.TransactionType.incoming) {
          newStock += transaction.quantity;
        } else {
          newStock -= transaction.quantity;
        }

        await updateItemStockByBarcode(transaction.itemBarcode, newStock);
      }
    }

    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;

    // Get the transaction to revert stock changes
    final transaction = await getTransactionById(id);
    if (transaction != null) {
      final item = await getItemByBarcode(transaction.itemBarcode);
      if (item != null) {
        int newStock = item.currentStock;
        // Reverse the transaction effect
        if (transaction.type == app_transaction.TransactionType.incoming) {
          newStock -= transaction.quantity;
        } else {
          newStock += transaction.quantity;
        }
        await updateItemStockByBarcode(transaction.itemBarcode, newStock);
      }
    }

    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Activity log operations
  Future<int> insertActivityLog(ActivityLog log) async {
    final db = await database;
    return await db.insert('activity_logs', log.toMap());
  }

  Future<List<ActivityLog>> getRecentActivityLogs([int limit = 50]) async {
    try {
      final db = await database;
      final maps = await db.query(
        'activity_logs',
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      return List.generate(maps.length, (i) => ActivityLog.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting recent activity logs: $e');
      return [];
    }
  }

  Future<List<ActivityLog>> getActivityLogsByUser(int userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'activity_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
      );
      return List.generate(maps.length, (i) => ActivityLog.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting activity logs by user: $e');
      return [];
    }
  }

  // Dashboard statistics
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final db = await database;

      // Initialize default values
      Map<String, int> stats = {
        'totalItems': 0,
        'totalStock': 0,
        'lowStockItems': 0,
        'outOfStockItems': 0,
        'totalCategories': 0,
        'todayIncoming': 0,
        'todayOutgoing': 0,
      };

      // Total items
      try {
        final totalItems =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM items'),
            ) ??
            0;
        stats['totalItems'] = totalItems;
      } catch (e) {
        debugPrint('Error getting total items: $e');
      }

      // Total stock
      try {
        final totalStock =
            Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COALESCE(SUM(current_stock), 0) FROM items',
              ),
            ) ??
            0;
        stats['totalStock'] = totalStock;
      } catch (e) {
        debugPrint('Error getting total stock: $e');
      }

      // Low stock items
      try {
        final lowStockItems =
            Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COUNT(*) FROM items WHERE current_stock <= 5 AND current_stock > 0',
              ),
            ) ??
            0;
        stats['lowStockItems'] = lowStockItems;
      } catch (e) {
        debugPrint('Error getting low stock items: $e');
      }

      // Out of stock items
      try {
        final outOfStockItems =
            Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COUNT(*) FROM items WHERE current_stock = 0',
              ),
            ) ??
            0;
        stats['outOfStockItems'] = outOfStockItems;
      } catch (e) {
        debugPrint('Error getting out of stock items: $e');
      }

      // Total categories
      try {
        final totalCategories =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM categories'),
            ) ??
            0;
        stats['totalCategories'] = totalCategories;
      } catch (e) {
        debugPrint('Error getting total categories: $e');
      }

      // Today's transactions
      try {
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final todayIncoming =
            Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COALESCE(SUM(quantity), 0) FROM transactions WHERE type = ? AND date >= ? AND date < ?',
                [
                  'incoming',
                  todayStart.toIso8601String(),
                  todayEnd.toIso8601String(),
                ],
              ),
            ) ??
            0;
        stats['todayIncoming'] = todayIncoming;

        final todayOutgoing =
            Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COALESCE(SUM(quantity), 0) FROM transactions WHERE type = ? AND date >= ? AND date < ?',
                [
                  'outgoing',
                  todayStart.toIso8601String(),
                  todayEnd.toIso8601String(),
                ],
              ),
            ) ??
            0;
        stats['todayOutgoing'] = todayOutgoing;
      } catch (e) {
        debugPrint('Error getting today transactions: $e');
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      return {
        'totalItems': 0,
        'totalStock': 0,
        'lowStockItems': 0,
        'outOfStockItems': 0,
        'totalCategories': 0,
        'todayIncoming': 0,
        'todayOutgoing': 0,
      };
    }
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<String> getDatabasePath() async {
    String path = join(await getDatabasesPath(), 'inventaris.db');
    return path;
  }

  Future<void> close() async {
    await closeDatabase();
  }

  Future<void> initDatabase() async {
    _database = await _initDatabase();
  }
}
