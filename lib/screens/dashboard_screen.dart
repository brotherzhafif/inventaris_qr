import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/item_provider.dart';
import '../providers/transaction_provider.dart';
import 'items_screen.dart';
import 'transactions_screen.dart';
import 'reports_screen.dart';
import 'users_screen.dart';
import 'scanner_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String? _searchQuery;

  void _handleScanResult(Map<String, dynamic> result) {
    final action = result['action'];
    final code = result['code'];

    setState(() {
      _searchQuery = code;
      if (action == 'items') {
        // Find items tab index
        _currentIndex = _getItemsTabIndex();
      } else if (action == 'transactions') {
        // Find transactions tab index
        _currentIndex = _getTransactionsTabIndex();
      }
    });
  }

  int _getItemsTabIndex() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser!;

    int index = 1; // Start after dashboard (index 0)
    if (user.canViewItems) return index;
    return 0; // Fallback to dashboard
  }

  int _getTransactionsTabIndex() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser!;

    int index = 1; // Start after dashboard (index 0)
    if (user.canViewItems) index++; // Skip items if available
    if (user.canViewTransactions) return index;
    return 0; // Fallback to dashboard
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      final dashboardProvider = Provider.of<DashboardProvider>(
        context,
        listen: false,
      );
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      // Load data with timeout and error handling
      await Future.wait([
        dashboardProvider.loadDashboardData(),
        itemProvider.loadItems().catchError((e) {
          debugPrint('Failed to load items: $e');
          return Future.value();
        }),
        itemProvider.loadCategories().catchError((e) {
          debugPrint('Failed to load categories: $e');
          return Future.value();
        }),
        transactionProvider.loadTransactions().catchError((e) {
          debugPrint('Failed to load transactions: $e');
          return Future.value();
        }),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Data loading timeout');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Loading timeout, some data may not be available',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return <void>[];
        },
      );
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) {
          return const LoginScreen();
        }

        return Consumer<DashboardProvider>(
          builder: (context, dashboardProvider, child) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Inventaris QR'),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                actions: [
                  if (user.canScanBarcode)
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScannerScreen(),
                          ),
                        );
                      },
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        _showLogoutDialog();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 8),
                            Text(user.fullName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.badge),
                            const SizedBox(width: 8),
                            Text(user.role.name),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: IndexedStack(
                index: _currentIndex,
                children: [
                  const DashboardContent(),
                  if (user.canViewItems)
                    ItemsScreen(
                      key: ValueKey('items_$_searchQuery'),
                      searchCode: _searchQuery,
                      onScanResult: _handleScanResult,
                    ),
                  if (user.canViewTransactions)
                    TransactionsScreen(
                      key: ValueKey('transactions_$_searchQuery'),
                      searchCode: _searchQuery,
                      onScanResult: _handleScanResult,
                    ),
                  if (user.canViewReports) const ReportsScreen(),
                  if (user.canManageUsers) const UsersScreen(),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                    // Clear search query when changing tabs manually
                    if (_searchQuery != null) {
                      _searchQuery = null;
                    }
                  });
                },
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  if (user.canViewItems)
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2),
                      label: 'Barang',
                    ),
                  if (user.canViewTransactions)
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.swap_horiz),
                      label: 'Transaksi',
                    ),
                  if (user.canViewReports)
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.assessment),
                      label: 'Laporan',
                    ),
                  if (user.canManageUsers)
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.people),
                      label: 'Pengguna',
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              authProvider.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final dashboardProvider = Provider.of<DashboardProvider>(
          context,
          listen: false,
        );
        await dashboardProvider.loadDashboardData();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Stats Cards
            Consumer<DashboardProvider>(
              builder: (context, dashboardProvider, child) {
                if (dashboardProvider.isLoading &&
                    !dashboardProvider.isInitialized) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (dashboardProvider.errorMessage != null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${dashboardProvider.errorMessage}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              dashboardProvider.loadDashboardData();
                            },
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatsCard(
                            title: 'Total Barang',
                            value: dashboardProvider.totalItems.toString(),
                            icon: Icons.inventory_2,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatsCard(
                            title: 'Total Stok',
                            value: dashboardProvider.totalStock.toString(),
                            icon: Icons.storage,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatsCard(
                            title: 'Stok Menipis',
                            value: dashboardProvider.lowStockItems.toString(),
                            icon: Icons.warning,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatsCard(
                            title: 'Stok Habis',
                            value: dashboardProvider.outOfStockItems.toString(),
                            icon: Icons.error,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatsCard(
                            title: 'Masuk Hari Ini',
                            value: dashboardProvider.todayIncoming.toString(),
                            icon: Icons.arrow_downward,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatsCard(
                            title: 'Keluar Hari Ini',
                            value: dashboardProvider.todayOutgoing.toString(),
                            icon: Icons.arrow_upward,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Recent Activities
            Text(
              'Aktivitas Terbaru',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Consumer<DashboardProvider>(
              builder: (context, dashboardProvider, child) {
                if (dashboardProvider.recentActivities.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          const Text('Belum ada aktivitas'),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dashboardProvider.recentActivities.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final activity =
                          dashboardProvider.recentActivities[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getActivityColor(activity.action),
                          child: Icon(
                            _getActivityIcon(activity.action),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(activity.action),
                        subtitle: Text(activity.description ?? ''),
                        trailing: Text(
                          DateFormat('HH:mm').format(activity.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String action) {
    switch (action) {
      case 'Login':
        return Colors.green;
      case 'Logout':
        return Colors.grey;
      case 'Add Item':
        return Colors.blue;
      case 'Update Item':
        return Colors.orange;
      case 'Delete Item':
        return Colors.red;
      case 'Add Transaction':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String action) {
    switch (action) {
      case 'Login':
        return Icons.login;
      case 'Logout':
        return Icons.logout;
      case 'Add Item':
        return Icons.add;
      case 'Update Item':
        return Icons.edit;
      case 'Delete Item':
        return Icons.delete;
      case 'Add Transaction':
        return Icons.swap_horiz;
      default:
        return Icons.info;
    }
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
