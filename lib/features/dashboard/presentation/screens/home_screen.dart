import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/pool_service.dart';
import '../../../../core/services/wallet_management_service.dart';
import '../../../../core/services/wallet_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Map<String, dynamic>> _activePools = [];
  List<Map<String, dynamic>> _upcomingDraws = [];
  List<Map<String, dynamic>> _recentActivity = [];
  Map<String, dynamic>? _wallet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final pools = await PoolService.getUserPools();
      final transactions = await WalletManagementService.getTransactions();
      final wallet = await WalletService.getWallet();
      
      if (mounted) {
        setState(() {
          _activePools = pools.where((p) => p['status'] == 'active').toList();
          // Mocking upcoming draws from active pools for now
          _upcomingDraws = _activePools.take(2).toList(); 
          _recentActivity = transactions.take(5).toList();
          _wallet = wallet;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildWalletSummary(context),
                    const SizedBox(height: 32),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    _buildNewFeatures(context),
                    const SizedBox(height: 32),
                    if (_activePools.isNotEmpty) ...[
                      _buildProgressCard(context, _activePools.first),
                      const SizedBox(height: 32),
                    ],
                    if (_upcomingDraws.isNotEmpty) ...[
                      _buildUpcomingDraws(context),
                      const SizedBox(height: 32),
                    ],
                    _buildActivePoolsList(context),
                    const SizedBox(height: 32),
                    _buildRecentActivity(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                  const Text(
                    'Alex',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(Icons.notifications, size: 28, color: Colors.white),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: FutureBuilder<int>(
                      future: NotificationService.getUnreadCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings, size: 28, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewFeatures(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Financial Tools',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFeatureCard(
                context,
                'Smart Savings',
                'AI-powered recommendations',
                Icons.auto_awesome,
                const Color(0xFF6C63FF),
                () => context.push('/smart-savings'),
              ),
              const SizedBox(width: 16),
              _buildFeatureCard(
                context,
                'Financial Goals',
                'Set and achieve goals',
                Icons.flag,
                Colors.green,
                () => context.push('/financial-goals'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Explore',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: color, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSummary(BuildContext context) {
    final availableBalance = _wallet?['available_balance'] ?? 0.0;
    final lockedBalance = _wallet?['locked_balance'] ?? 0.0;
    final totalWinnings = _wallet?['total_winnings'] ?? 0.0;
    final totalBalance = availableBalance + lockedBalance;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildSummaryRow(context, 'Total Balance', NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(totalBalance), isTotal: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),
          _buildSummaryRow(context, 'Available Balance', NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(availableBalance)),
          const SizedBox(height: 12),
          _buildSummaryRow(context, 'Locked in Pools', NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(lockedBalance)),
          const SizedBox(height: 12),
          _buildSummaryRow(context, 'Total Winnings (all-time)', NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(totalWinnings)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/wallet'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Money'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/wallet'),
                  icon: const Icon(Icons.remove),
                  label: const Text('Withdraw'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivePoolsList(BuildContext context) {
    if (_activePools.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Active Pools',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._activePools.map((pool) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _ActivePoolCard(
            name: pool['name'],
            status: 'Paid', // TODO: Fetch real status
            nextDraw: DateFormat('MMM d').format(DateTime.parse(pool['start_date']).add(const Duration(days: 30))),
            amount: '₹${pool['contribution_amount']}',
            members: pool['current_members'],
            progress: 0.3, // TODO: Calculate progress
            onTap: () => context.push('/pool-details/${pool['id']}'),
            onContribute: () => context.push('/payment', extra: {'poolId': pool['id'], 'amount': (pool['contribution_amount'] as num).toDouble()}),
          ),
        )),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black54 : Colors.black54,
            fontSize: isTotal ? 14 : 14,
            fontWeight: isTotal ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 24 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionButton(
          icon: Icons.add_circle,
          label: 'Create Pool',
          onTap: () => context.push('/create-pool'),
        ),
        _QuickActionButton(
          icon: Icons.search,
          label: 'Join Pool',
          onTap: () => context.push('/join-pool'),
        ),
        _QuickActionButton(
          icon: Icons.leaderboard,
          label: 'Leaderboard',
          onTap: () => context.push('/leaderboard'),
        ),
        _QuickActionButton(
          icon: Icons.history,
          label: 'History',
          onTap: () => context.push('/transactions'),
        ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context, Map<String, dynamic> pool) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              const Text('Time Remaining in Pool:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('3 months 15 days', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)), // TODO: Calculate
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.75, // TODO: Calculate
              minHeight: 10,
              backgroundColor: const Color(0xFFFFCCBC),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cycle: 1 of ${pool['total_rounds']}', style: const TextStyle(color: Colors.grey)),
              Text('75% completed', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingDraws(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Draws This Week',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._upcomingDraws.map((pool) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _DrawCard(
            name: pool['name'],
            odds: '1 in ${pool['max_members']} (${(100/pool['max_members']).toStringAsFixed(0)}%)',
            daysLeft: '5', // TODO: Calculate
            onTap: () => context.push('/pool-details/${pool['id']}'),
          ),
        )),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        if (_recentActivity.isEmpty)
          const Text('No recent activity', style: TextStyle(color: Colors.grey))
        else
          ..._recentActivity.map((activity) {
            final type = activity['transaction_type'] ?? 'Transaction';
            final amount = activity['amount'] ?? 0;
            final date = activity['created_at'] != null 
                ? DateFormat('MMM d, h:mm a').format(DateTime.parse(activity['created_at']))
                : 'Unknown date';
            final poolName = activity['pool'] != null ? activity['pool']['name'] : 'Wallet';

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: type == 'deposit' ? Colors.green.shade100 : Colors.orange.shade100,
                child: Icon(
                  type == 'deposit' ? Icons.arrow_downward : Icons.arrow_upward,
                  color: type == 'deposit' ? Colors.green : Colors.orange,
                ),
              ),
              title: Text('$type: ₹$amount'),
              subtitle: Text('$poolName • $date'),
            );
          }),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.black87),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _DrawCard extends StatelessWidget {
  final String name;
  final String odds;
  final String daysLeft;
  final VoidCallback onTap;

  const _DrawCard({
    required this.name,
    required this.odds,
    required this.daysLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFFCCBC),
              child: const Icon(Icons.donut_large, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Your odds: $odds', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFCCBC)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Draw in $daysLeft days',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePoolCard extends StatelessWidget {
  final String name;
  final String status;
  final String nextDraw;
  final String amount;
  final int members;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onContribute;

  const _ActivePoolCard({
    required this.name,
    required this.status,
    required this.nextDraw,
    required this.amount,
    required this.members,
    required this.progress,
    required this.onTap,
    required this.onContribute,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'Paid' ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Paid' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Next Draw: $nextDraw', style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('$members members', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: Theme.of(context).primaryColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}% Complete',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTap,
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContribute,
                    child: Text('Pay $amount'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
