import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/pool_service.dart';

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

class _PoolList extends StatefulWidget {
  final String status;

  const _PoolList({required this.status});

  @override
  State<_PoolList> createState() => _PoolListState();
}

class _PoolListState extends State<_PoolList> {
  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPools();
  }

  Future<void> _loadPools() async {
    setState(() => _isLoading = true);
    try {
      final pools = await PoolService.getUserPools();
      print('📊 Loaded ${pools.length} pools from backend'); // Debug log
      
      if (mounted) {
        setState(() {
          _pools = pools.where((pool) {
            // Get pool status safely and normalize
            final poolStatus = (pool['status'] ?? 'pending').toString().toLowerCase();
            final targetStatus = widget.status.toLowerCase();
            
            print('Checking pool: ${pool['name']} ($poolStatus) vs Target: $targetStatus'); // Debug log
            
            // Handle 'drafts' vs 'draft' mismatch
            if (targetStatus == 'drafts' || targetStatus == 'draft') {
              return poolStatus == 'draft';
            }
            
            // Handle 'active' vs 'paid' mapping if needed, or direct match
            return poolStatus == targetStatus;
          }).toList();
          
          print('✅ Filtered to ${_pools.length} pools for tab ${widget.status}'); // Debug log
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading pools: $e'); // Debug log
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pools: $e')),
        );
      }
    }
  }

  double _calculateProgress(Map<String, dynamic> pool) {
    final currentRound = pool['current_round'] as int? ?? 1;
    final totalRounds = pool['total_rounds'] as int? ?? 1;
    return currentRound / totalRounds;
  }

  Future<String> _getPaymentStatus(String poolId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return 'Pending';

    final transactions = await Supabase.instance.client
        .from('transactions')
        .select()
        .eq('pool_id', poolId)
        .eq('user_id', userId)
        .eq('transaction_type', 'contribution')
        .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String()) // Check recent contribution
        .limit(1);
    
    if (transactions.isEmpty) return 'Pending';
    return 'Paid';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pools.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPools,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.status} pools found',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPools,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pools.length,
        itemBuilder: (context, index) {
          final pool = _pools[index];
          
          return FutureBuilder<String>(
            future: _getPaymentStatus(pool['id']),
            builder: (context, snapshot) {
              final paymentStatus = snapshot.data ?? 'Pending';
              final contributionAmount = (pool['contribution_amount'] as num?)?.toInt() ?? 0;
              final maxMembers = (pool['max_members'] as num?)?.toInt() ?? 1;
              
              return _ActivePoolCard(
                name: pool['name'] ?? 'Unnamed Pool',
                status: pool['status'] == 'active' ? paymentStatus : (pool['status'] == 'pending' ? 'Pending' : 'Overdue'),
                nextDraw: pool['start_date'] != null 
                    ? DateFormat('MMM d').format(DateTime.parse(pool['start_date']).add(const Duration(days: 30)))
                    : 'TBD',
                amount: contributionAmount * maxMembers,
                cycle: '${pool['current_round'] ?? 1} of ${pool['total_rounds'] ?? 12}',
                progress: _calculateProgress(pool),
                onTap: () => context.push('/pool-details/${pool['id']}'),
              );
            },
          );
        },
      ),
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
                  _buildInfoItem(Icons.attach_money, 'Total Pool', '₹${amount * 10}'), // Assuming 10 members
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
