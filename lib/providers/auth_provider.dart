import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/activity_log.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  final DatabaseService _databaseService = DatabaseService();

  Future<bool> login(String username, String password) async {
    if (_isLoading) return false; // Prevent concurrent login attempts

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Add timeout to prevent hanging
      final user = await Future.any([
        _databaseService.authenticateUser(username, password),
        Future.delayed(const Duration(seconds: 10), () => null),
      ]);

      if (user != null) {
        _currentUser = user;

        // Log activity with error handling
        try {
          await _databaseService.insertActivityLog(
            ActivityLog(
              userId: user.id!,
              action: 'Login',
              description: 'User logged in successfully',
              timestamp: DateTime.now(),
            ),
          );
        } catch (e) {
          debugPrint('Failed to log activity: $e');
          // Don't fail login if activity logging fails
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Username atau password salah';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      // Log activity
      await _databaseService.insertActivityLog(
        ActivityLog(
          userId: _currentUser!.id!,
          action: 'Logout',
          description: 'User logged out',
          timestamp: DateTime.now(),
        ),
      );
    }

    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> registerUser(User user) async {
    try {
      // Check if username already exists
      final existingUser = await _databaseService.getUserByUsername(
        user.username,
      );
      if (existingUser != null) {
        _errorMessage = 'Username sudah digunakan';
        notifyListeners();
        return false;
      }

      await _databaseService.insertUser(user);

      if (_currentUser != null) {
        // Log activity
        await _databaseService.insertActivityLog(
          ActivityLog(
            userId: _currentUser!.id!,
            action: 'Create User',
            description: 'Created new user: ${user.username}',
            timestamp: DateTime.now(),
          ),
        );
      }

      return true;
    } catch (e) {
      _errorMessage = 'Gagal membuat akun: $e';
      notifyListeners();
      return false;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      return await _databaseService.getAllUsers();
    } catch (e) {
      _errorMessage = 'Gagal memuat data pengguna: $e';
      notifyListeners();
      return [];
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      await _databaseService.updateUser(user);

      if (_currentUser != null) {
        // Log activity
        await _databaseService.insertActivityLog(
          ActivityLog(
            userId: _currentUser!.id!,
            action: 'Update User',
            description: 'Updated user: ${user.username}',
            timestamp: DateTime.now(),
          ),
        );
      }

      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate pengguna: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await _databaseService.deleteUser(userId);

      if (_currentUser != null) {
        // Log activity
        await _databaseService.insertActivityLog(
          ActivityLog(
            userId: _currentUser!.id!,
            action: 'Delete User',
            description: 'Deleted user with ID: $userId',
            timestamp: DateTime.now(),
          ),
        );
      }

      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus pengguna: $e';
      notifyListeners();
      return false;
    }
  }
}
