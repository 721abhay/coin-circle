import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/pool_service.dart';
import '../../../../core/services/wallet_management_service.dart';

// Import extra admin widgets
import '../widgets/admin_disputes_tab.dart';
import '../widgets/admin_withdrawals_tab.dart';
import '../widgets/analytics_tab.dart';
import '../widgets/pool_oversight_tab.dart';
import '../widgets/user_management_tab.dart';
import '../../data/models/platform_stats.dart';

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
    // Five extra tabs
    _tabController = TabController(length: 5, vsync: this);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const AdminDisputesTab(),
          const AdminWithdrawalsTab(),
          AnalyticsTab(stats: PlatformStats(
            totalUsers: 0,
            activeUsers: 0,
            suspendedUsers: 0,
            totalPools: 0,
            activePools: 0,
            pendingPools: 0,
            completedPools: 0,
            totalTransactions: 0,
            totalTransactionVolume: 0.0,
            totalPayouts: 0.0,
            averagePoolSize: 0.0,
            averageContribution: 0.0,
          )),
          const PoolOversightTab(),
          const UserManagementTab(),
        ],
      ),
    );
  }
}
