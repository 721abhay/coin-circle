import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/admin_service.dart';

// Import extra admin widgets
import '../widgets/admin_disputes_tab.dart';
import '../widgets/admin_withdrawals_tab.dart';
import '../widgets/analytics_tab.dart';
import '../widgets/pool_oversight_tab.dart';
import '../widgets/user_management_tab.dart';
import '../../data/models/platform_stats.dart';
import 'admin_legal_screen.dart';

/// Screen that hosts additional admin features not shown in the main bottom navigation.
class AdminMoreScreen extends ConsumerStatefulWidget {
  const AdminMoreScreen({super.key});

  @override
  ConsumerState<AdminMoreScreen> createState() => _AdminMoreScreenState();
}

class _AdminMoreScreenState extends ConsumerState<AdminMoreScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Six extra tabs
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('More Admin Tools'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.gavel), text: 'Disputes'),
            Tab(icon: Icon(Icons.money_off), text: 'Withdrawals'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.layers), text: 'Pool Oversight'),
            Tab(icon: Icon(Icons.group), text: 'User Mgmt'),
            Tab(icon: Icon(Icons.gavel), text: 'Legal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const AdminDisputesTab(),
          const AdminWithdrawalsTab(),
          FutureBuilder<Map<String, dynamic>>(
            future: AdminService.getPlatformStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data ?? {};
              return AnalyticsTab(stats: PlatformStats(
                totalUsers: data['totalUsers'] ?? 0,
                activeUsers: data['activeUsers'] ?? 0,
                suspendedUsers: data['suspendedUsers'] ?? 0,
                totalPools: data['totalPools'] ?? 0,
                activePools: data['activePools'] ?? 0,
                pendingPools: data['pendingPools'] ?? 0,
                completedPools: data['completedPools'] ?? 0,
                totalTransactions: data['totalTransactions'] ?? 0,
                totalTransactionVolume: (data['totalTransactionVolume'] as num?)?.toDouble() ?? 0.0,
                totalPayouts: (data['totalPayouts'] as num?)?.toDouble() ?? 0.0,
                averagePoolSize: (data['averagePoolSize'] as num?)?.toDouble() ?? 0.0,
                averageContribution: (data['averageContribution'] as num?)?.toDouble() ?? 0.0,
              ));
            },
          ),
          const PoolOversightTab(),
          const UserManagementTab(),
          const AdminLegalTab(),
        ],
      ),
    );
  }
}
