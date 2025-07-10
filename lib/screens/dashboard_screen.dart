import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/item_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/user.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    await Future.wait([
      dashboardProvider.loadDashboardData(),
      itemProvider.loadItems(),
      itemProvider.loadCategories(),
      transactionProvider.loadTransactions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) {
          return const LoginScreen();
        }

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
                onSelected: (value) async {
                  if (value == 'logout') {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.role.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 12),
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
              const ItemsScreen(),
              const TransactionsScreen(),
              const ReportsScreen(),
              if (user.canManageUsers) const UsersScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue.shade600,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2),
                label: 'Barang',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.swap_horiz),
                label: 'Transaksi',
              ),
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
                if (dashboardProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
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
