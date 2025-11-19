import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyPoolsScreen extends StatefulWidget {
  const MyPoolsScreen({super.key});

  @override
  State<MyPoolsScreen> createState() => _MyPoolsScreenState();
}

class _MyPoolsScreenState extends State<MyPoolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('My Pools'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Drafts'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PoolList(status: 'Active'),
          _PoolList(status: 'Pending'),
          _PoolList(status: 'Completed'),
          _PoolList(status: 'Drafts'),
        ],
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('Sort by Next Payment'), onTap: () => context.pop()),
          ListTile(title: const Text('Sort by Next Draw'), onTap: () => context.pop()),
          ListTile(title: const Text('Sort by Name'), onTap: () => context.pop()),
          ListTile(title: const Text('Sort by Amount'), onTap: () => context.pop()),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Pools', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Payment Status'),
            Wrap(
              spacing: 8,
              children: ['Paid', 'Pending', 'Overdue'].map((e) => FilterChip(label: Text(e), onSelected: (v) {})).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Role'),
            Wrap(
              spacing: 8,
              children: ['Creator', 'Member'].map((e) => FilterChip(label: Text(e), onSelected: (v) {})).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => context.pop(), child: const Text('Apply Filters')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoolList extends StatelessWidget {
  final String status;

  const _PoolList({required this.status});

  @override
  Widget build(BuildContext context) {
    // Mock data based on status
    final pools = List.generate(3, (index) => index);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pools.length,
      itemBuilder: (context, index) {
        return _ActivePoolCard(
          name: '$status Pool ${index + 1}',
          status: index == 0 ? 'Paid' : (index == 1 ? 'Pending' : 'Overdue'),
          nextDraw: 'Oct ${24 + index}',
          amount: (index + 1) * 100,
          cycle: '${index + 1} of 10',
          progress: (index + 1) / 10,
          onTap: () => context.push('/pool-details/${index + 1}'),
        );
      },
    );
  }
}

class _ActivePoolCard extends StatelessWidget {
  final String name;
  final String status;
  final String nextDraw;
  final int amount;
  final String cycle;
  final double progress;
  final VoidCallback onTap;

  const _ActivePoolCard({
    required this.name,
    required this.status,
    required this.nextDraw,
    required this.amount,
    required this.cycle,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'Paid' ? Colors.green : (status == 'Pending' ? Colors.orange : Colors.red);
    final statusIcon = status == 'Paid' ? Icons.check_circle : (status == 'Pending' ? Icons.access_time : Icons.warning);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(Icons.groups, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Cycle $cycle', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(Icons.calendar_today, 'Next Draw', nextDraw),
                  _buildInfoItem(Icons.attach_money, 'Total Pool', '\$${amount * 10}'), // Assuming 10 members
                  _buildInfoItem(Icons.pie_chart, 'Your Odds', '10%'),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: Theme.of(context).primaryColor,
                  minHeight: 6,
                ),
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
                  if (status != 'Paid')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push('/payment', extra: {'poolId': '1', 'amount': amount.toDouble()}),
                        child: const Text('Pay Now'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
