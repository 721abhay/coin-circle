import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildWalletSummary(context),
              const SizedBox(height: 32),
              _buildQuickActions(context),
              const SizedBox(height: 32),
              _buildProgressCard(context),
              const SizedBox(height: 32),
              _buildUpcomingDraws(context),
              const SizedBox(height: 32),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFFCCBC), // Light orange
            child: const Icon(Icons.person, color: Colors.black87),
          ),
        ),
        Text(
          'Welcome, Alex',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
        Row(
          children: [
            Stack(
              children: [
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications, size: 28),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings, size: 28),
            ),
          ],
        ),
      ],
    );
  }

  // ... (WalletSummary and QuickActions remain unchanged)

  Widget _buildActivePoolsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Active Pools',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _ActivePoolCard(
          name: 'Office Savings Circle',
          status: 'Paid',
          nextDraw: 'Oct 24',
          amount: '\$500',
          members: 10,
          progress: 0.3,
          onTap: () => context.push('/pool-details/1'),
          onContribute: () => context.push('/payment', extra: {'poolId': '1', 'amount': 50.0}),
        ),
        const SizedBox(height: 16),
        _ActivePoolCard(
          name: 'Family Vacation Fund',
          status: 'Pending',
          nextDraw: 'Oct 28',
          amount: '\$1,200',
          members: 5,
          progress: 0.66,
          onTap: () => context.push('/pool-details/2'),
          onContribute: () => context.push('/payment', extra: {'poolId': '2', 'amount': 100.0}),
        ),
      ],
    );
  }

  Widget _buildWalletSummary(BuildContext context) {
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
          _buildSummaryRow(context, 'Total Balance', '\$1,234.56', isTotal: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),
          _buildSummaryRow(context, 'Amount in Active Pools', '\$500.00'),
          const SizedBox(height: 12),
          _buildSummaryRow(context, 'Pending Contributions', '\$100.00'),
          const SizedBox(height: 12),
          _buildSummaryRow(context, 'Total Winnings (all-time)', '\$2,000.00'),
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
                  onPressed: () {},
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
          icon: Icons.folder,
          label: 'My Pools',
          onTap: () => context.go('/my-pools'),
        ),
        _QuickActionButton(
          icon: Icons.history,
          label: 'History',
          onTap: () => context.push('/transactions'),
        ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context) {
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
              Text('3 months 15 days', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 10,
              backgroundColor: const Color(0xFFFFCCBC),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cycle: 9 of 12', style: TextStyle(color: Colors.grey)),
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
        _DrawCard(
          name: 'Office Savings Circle',
          odds: '1 in 10 (10%)',
          daysLeft: '2',
          onTap: () => context.push('/pool-details/1'),
        ),
        const SizedBox(height: 16),
        _DrawCard(
          name: 'Family Fun Pool',
          odds: '1 in 5 (20%)',
          daysLeft: '5',
          onTap: () => context.push('/pool-details/2'),
        ),
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
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFFFCCBC),
            child: const Icon(Icons.group_add, color: Colors.white),
          ),
          title: const Text('Alice joined your "Office Savings Circle" pool.'),
          subtitle: const Text('2 hours ago'),
        ),
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
