import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecurringPoolsScreen extends StatefulWidget {
  const RecurringPoolsScreen({super.key});

  @override
  State<RecurringPoolsScreen> createState() => _RecurringPoolsScreenState();
}

class _RecurringPoolsScreenState extends State<RecurringPoolsScreen> {
  final List<Map<String, dynamic>> _recurringPools = [
    {
      'id': '1',
      'name': 'Monthly Family Savings',
      'currentCycle': 3,
      'totalCycles': 0, // 0 means infinite
      'autoRenew': true,
      'nextRenewal': DateTime.now().add(const Duration(days: 15)),
      'members': 6,
      'contribution': 1000.0,
    },
    {
      'id': '2',
      'name': 'Quarterly Office Pool',
      'currentCycle': 2,
      'totalCycles': 4,
      'autoRenew': false,
      'nextRenewal': DateTime.now().add(const Duration(days: 45)),
      'members': 10,
      'contribution': 500.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Pools'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'About Recurring Pools',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recurring pools automatically restart after completion, maintaining the same members and settings. Perfect for ongoing savings goals!',
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Recurring Pools',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._recurringPools.map((pool) => _RecurringPoolCard(
            pool: pool,
            onManage: () => _showManageDialog(pool),
          )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push('/create-pool', extra: {'recurring': true});
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create Recurring Pool'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManageDialog(Map<String, dynamic> pool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage ${pool['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Auto-Renewal'),
              trailing: Switch(
                value: pool['autoRenew'],
                onChanged: (value) {
                  setState(() {
                    pool['autoRenew'] = value;
                  });
                  Navigator.pop(context);
                },
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit
              },
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.stop_circle_outlined),
              title: const Text('Stop Recurring'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _confirmStopRecurring(pool);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmStopRecurring(Map<String, dynamic> pool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Recurring Pool?'),
        content: Text(
          'This will complete the current cycle and prevent automatic renewal. The pool "${pool['name']}" will end after this cycle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                pool['autoRenew'] = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recurring pool will stop after current cycle'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop Recurring'),
          ),
        ],
      ),
    );
  }
}

class _RecurringPoolCard extends StatelessWidget {
  final Map<String, dynamic> pool;
  final VoidCallback onManage;

  const _RecurringPoolCard({
    required this.pool,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilRenewal = pool['nextRenewal'].difference(DateTime.now()).inDays;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.refresh, color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pool['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cycle ${pool['currentCycle']}${pool['totalCycles'] > 0 ? ' of ${pool['totalCycles']}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pool['autoRenew'] ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pool['autoRenew'] ? 'Auto-Renew ON' : 'Auto-Renew OFF',
                    style: TextStyle(
                      fontSize: 10,
                      color: pool['autoRenew'] ? Colors.green.shade900 : Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.people,
                    label: '${pool['members']} Members',
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.account_balance_wallet,
                    label: '₹${pool['contribution']}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next renewal in $daysUntilRenewal days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onManage,
                child: const Text('Manage'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
