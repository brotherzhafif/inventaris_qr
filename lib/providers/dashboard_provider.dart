import 'package:flutter/foundation.dart';
import '../models/activity_log.dart';
import '../services/database_service.dart';

class DashboardProvider extends ChangeNotifier {
  Map<String, int> _stats = {};
  List<ActivityLog> _recentActivities = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, int> get stats => _stats;
  List<ActivityLog> get recentActivities => _recentActivities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load statistics
      _stats = await _databaseService.getDashboardStats();

      // Load recent activities
      _recentActivities = await _databaseService.getRecentActivityLogs(10);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat data dashboard: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  int get totalItems => _stats['totalItems'] ?? 0;
  int get totalStock => _stats['totalStock'] ?? 0;
  int get lowStockItems => _stats['lowStockItems'] ?? 0;
  int get outOfStockItems => _stats['outOfStockItems'] ?? 0;
  int get totalCategories => _stats['totalCategories'] ?? 0;
  int get todayIncoming => _stats['todayIncoming'] ?? 0;
  int get todayOutgoing => _stats['todayOutgoing'] ?? 0;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
