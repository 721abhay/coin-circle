import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/services/admin_service.dart';

// Import sub‑screens used in the main navigation
import '../widgets/admin_users_view.dart';
import '../widgets/admin_pools_view.dart';
import '../widgets/admin_financials_view.dart';
import '../widgets/admin_settings_view.dart';
import '../widgets/admin_tickets_view.dart';
import 'admin_more_screen.dart';
import 'admin_deposit_requests_screen.dart';

/// Mobile‑friendly Admin Dashboard
/// Uses a BottomNavigationBar for navigation (no side bar).
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate a short loading period – replace with real data fetch if needed.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E2C),
        elevation: 2,
        title: const Text(
          'Admin Command Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Emergency Stop',
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              // TODO: implement emergency stop logic
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E2C),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.pool_outlined), label: 'Pools'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Finance'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return _buildOverviewDashboard();
      case 1:
        return const AdminUsersView();
      case 2:
        return const AdminPoolsView();
      case 3:
        return const AdminFinancialsView();
      case 4:
        return const AdminSettingsView();
      case 5:
        return const AdminTicketsView();
      case 6:
        return const AdminMoreScreen();
      default:
        return _buildOverviewDashboard();
    }
  }

  // ---------------------------------------------------------------------
  // Overview Dashboard (same as before)
  // ---------------------------------------------------------------------
  Widget _buildOverviewDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildRevenueChart(),
              const SizedBox(height: 24),
              _buildRecentActions(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickActionButton(
                'Deposit Requests',
                Icons.account_balance,
                Colors.teal,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDepositRequestsScreen()),
                  );
                },
              ),
              _buildQuickActionButton(
                'Approve KYC',
                Icons.verified_user,
                Colors.green,
                () {
                  context.push('/admin/kyc-verification');
                },
              ),
              _buildQuickActionButton(
                'Review Disputes',
                Icons.gavel,
                Colors.orange,
                () {
                  setState(() => _selectedIndex = 6); // Navigate to More
                },
              ),
              _buildQuickActionButton(
                'Process Withdrawals',
                Icons.money_off,
                Colors.blue,
                () {
                  context.push('/admin/withdrawal-requests');
                },
              ),
              _buildQuickActionButton(
                'View Analytics',
                Icons.analytics,
                Colors.purple,
                () {
                  setState(() => _selectedIndex = 6); // Navigate to More
                },
              ),
              _buildQuickActionButton(
                'Broadcast Message',
                Icons.campaign,
                Colors.red,
                () {
                  _showBroadcastDialog();
                },
              ),
              _buildQuickActionButton(
                'System Health',
                Icons.health_and_safety,
                Colors.teal,
                () {
                  setState(() => _selectedIndex = 4); // Navigate to Settings
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Broadcast Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              initialValue: 'Info',
              items: const [
                DropdownMenuItem(value: 'Info', child: Text('Info')),
                DropdownMenuItem(value: 'Warning', child: Text('Warning')),
                DropdownMenuItem(value: 'Critical', child: Text('Critical')),
              ],
              onChanged: (v) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement broadcast functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message broadcasted to all users')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E2C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Command Center',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E1E2C),
              ),
            ),
            Text(
              'Welcome back, Super Admin',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        // Emergency button is in the AppBar actions.
      ],
    );
  }

  Widget _buildStatsCards() {
    return FutureBuilder<Map<String, dynamic>>(
      future: AdminService.getAdminStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final stats = snapshot.data!;
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 180,
                child: _buildStatCard(
                  'Total Users', 
                  '${stats['total_users'] ?? 0}', 
                  '${stats['user_growth_rate'] ?? 0}%', 
                  Icons.people, 
                  Colors.blue
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 180,
                child: _buildStatCard(
                  'Active Pools', 
                  '${stats['active_pools'] ?? 0}', 
                  '${stats['pool_growth_rate'] ?? 0}%', 
                  Icons.pool, 
                  Colors.purple
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 180,
                child: _buildStatCard(
                  'System Volume', 
                  '₹${stats['total_volume'] ?? 0}', 
                  '${stats['volume_growth_rate'] ?? 0}%', 
                  Icons.currency_rupee, 
                  Colors.green
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 180,
                child: _buildStatCard(
                  'Pending KYC', 
                  '${stats['pending_kyc'] ?? 0}', 
                  'Urgent', 
                  Icons.verified_user, 
                  Colors.orange
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String trend, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Revenue (Last 7 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: AdminService.getRevenueChartData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No revenue data available'));
                }
                
                final revenueData = snapshot.data!;
                final barGroups = revenueData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                  return _makeGroupData(index, amount / 1000); // Convert to thousands
                }).toList();
                
                return BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFF1E1E2C),
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildRecentActions() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Activity Log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: AdminService.getRecentActivities(limit: 10),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final activities = snapshot.data!;
                if (activities.isEmpty) {
                  return const Center(child: Text('No recent activities'));
                }
                
                return ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildLogItem(
                      activity['title'] ?? 'Activity',
                      activity['description'] ?? '',
                      activity['time'] ?? '',
                      activity['color'] ?? Colors.grey,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(String title, String subtitle, String time, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        radius: 16,
        child: Icon(Icons.circle, color: color, size: 12),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}
