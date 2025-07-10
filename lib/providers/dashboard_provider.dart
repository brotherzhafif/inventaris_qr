import 'package:flutter/foundation.dart';
import '../models/activity_log.dart';
import '../services/database_service.dart';

class DashboardProvider extends ChangeNotifier {
  Map<String, int> _stats = {};
  List<ActivityLog> _recentActivities = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  Map<String, int> get stats => _stats;
  List<ActivityLog> get recentActivities => _recentActivities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  final DatabaseService _databaseService = DatabaseService();

  Future<void> loadDashboardData() async {
    if (_isLoading) return; // Prevent concurrent loading

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Initialize default values first
      _stats = {
        'totalItems': 0,
        'totalStock': 0,
        'lowStockItems': 0,
        'outOfStockItems': 0,
        'totalCategories': 0,
        'todayIncoming': 0,
        'todayOutgoing': 0,
      };
      _recentActivities = [];

      // Load statistics with timeout
      final statsResult = await Future.any([
        _databaseService.getDashboardStats(),
        Future.delayed(const Duration(seconds: 10), () => _stats),
      ]);

      if (statsResult.isNotEmpty) {
        _stats = statsResult;
      }

      // Load recent activities with timeout
      try {
        final activitiesResult = await Future.any([
          _databaseService.getRecentActivityLogs(10),
          Future.delayed(const Duration(seconds: 5), () => <ActivityLog>[]),
        ]);
        _recentActivities = activitiesResult;
      } catch (e) {
        debugPrint('Failed to load activities: $e');
        _recentActivities = [];
      }

      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      _errorMessage = 'Gagal memuat data dashboard: $e';
      _isInitialized = true; // Mark as initialized even on error
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
