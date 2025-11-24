import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/pool_service.dart';

class PoolDetailsScreen extends ConsumerStatefulWidget {
  final String poolId;

  const PoolDetailsScreen({super.key, required this.poolId});

  @override
  ConsumerState<PoolDetailsScreen> createState() => _PoolDetailsScreenState();
}

class _PoolDetailsScreenState extends ConsumerState<PoolDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _pool;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadPoolDetails();
  }

  Future<void> _loadPoolDetails() async {
    try {
      final pool = await PoolService.getPoolDetails(widget.poolId);
      if (mounted) {
        setState(() {
          _pool = pool;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pool: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(_pool?['name'] ?? 'Loading...', style: const TextStyle(color: Colors.white)),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_pool?['image_url'] != null)
                      Image.network(
                        _pool!['image_url'],
                        fit: BoxFit.cover,
                      )
                    else
                      Image.network(
                        'https://picsum.photos/seed/${widget.poolId}/800/400',
                        fit: BoxFit.cover,
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
                PopupMenuButton(
                  itemBuilder: (context) {
                    final isCreator = _pool?['creator_id'] == Supabase.instance.client.auth.currentUser?.id;
                    return [
                      if (isCreator)
                        const PopupMenuItem(value: 'manage', child: Text('Manage Pool (Admin)')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit Pool')),
                      const PopupMenuItem(value: 'mute', child: Text('Mute Notifications')),
                      const PopupMenuItem(value: 'leave', child: Text('Leave Pool')),
                      const PopupMenuItem(value: 'report', child: Text('Report Issue')),
                      const PopupMenuItem(value: 'demo_draw', child: Text('Simulate Draw (Demo)')),
                      const PopupMenuItem(value: 'demo_vote', child: Text('View Vote Request (Demo)')),
                    ];
                  },
                  onSelected: (value) {
                    if (value == 'manage') {
                      context.push('/creator-dashboard/${widget.poolId}');
                    } else if (value == 'demo_draw') {
                      context.push('/winner-selection/${widget.poolId}');
                    } else if (value == 'demo_vote') {
                      context.push('/voting/${widget.poolId}');
                    }
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Members'),
                  Tab(text: 'Schedule'),
                  Tab(text: 'Winners'),
                  Tab(text: 'Chat'),
                  Tab(text: 'Docs'),
                  Tab(text: 'Stats'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(pool: _pool),
            _MembersTab(poolId: widget.poolId),
            _ScheduleTab(poolId: widget.poolId),
            _WinnersTab(poolId: widget.poolId),
            _ChatTab(poolId: widget.poolId),
            _DocsTab(poolId: widget.poolId),
            _StatsTab(poolId: widget.poolId),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic>? pool;

  const _OverviewTab({this.pool});

  @override
  Widget build(BuildContext context) {
    if (pool == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(context),
          const SizedBox(height: 24),
          _buildInviteCodeCard(context),
          const SizedBox(height: 24),
          _buildPaymentSection(context),
          const SizedBox(height: 24),
          _buildMembersSection(context),
          const SizedBox(height: 24),
          _buildContributionSchedule(context),
          const SizedBox(height: 24),
          _buildWinnerHistory(context),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pool Balance', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(pool!['total_amount'] ?? 0),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Cycle 1 of ${pool!['total_rounds'] ?? 10}', // TODO: Calculate current cycle
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem('Next Draw', '2 Days'), // TODO: Calculate
              _buildStatusItem(
                'Your Contribution',
                NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(pool!['contribution_amount'] ?? 0),
              ),
              _buildStatusItem('Time Left', '3M 15D'), // TODO: Calculate
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar for Time Remaining
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pool Progress', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                  const Text('30%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.3,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInviteCodeCard(BuildContext context) {
    final inviteCode = pool!['invite_code'];
    if (inviteCode == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invite Code',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.copy, color: Colors.orange, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              inviteCode,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Colors.orange.shade900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this code with friends to join the pool.',
            style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Payment Due', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),
              const Spacer(),
              const Text('Due in 2 days', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount Due:', style: TextStyle(color: Colors.grey)),
              Text(
                NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(pool!['contribution_amount'] ?? 0),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/payment', extra: {'poolId': pool!['id'], 'amount': (pool!['contribution_amount'] as num).toDouble()}),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Pay Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Members (${pool!['current_members']}/${pool!['max_members']})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 8),
        // Capacity Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.8,
            backgroundColor: Colors.grey.shade200,
            color: Colors.green,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 8, // Updated count
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${index + 10}'),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: index % 3 == 0 ? Colors.green : (index % 3 == 1 ? Colors.orange : Colors.red),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              index % 3 == 0 ? Icons.check : (index % 3 == 1 ? Icons.access_time : Icons.warning),
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Member ${index + 1}', style: const TextStyle(fontSize: 12)),
                    if (index == 0) const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContributionSchedule(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contribution Schedule', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildScheduleItem(context, 1, 'Paid on Oct 10', 'Paid', Colors.green),
        _buildScheduleItem(context, 2, 'Paid on Nov 12 (Late)', 'Late', Colors.orange),
        _buildScheduleItem(context, 3, 'Due Dec 10', 'Pending', Colors.red),
        _buildScheduleItem(context, 4, 'Due Jan 10', 'Future', Colors.blue),
      ],
    );
  }

  Widget _buildScheduleItem(BuildContext context, int cycle, String date, String status, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Text('C$cycle', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(date),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildWinnerHistory(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Winner History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.casino, color: Colors.purple),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next Draw: Dec 15', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                    Text('Your chances: 15%', style: TextStyle(color: Colors.purple)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                child: const Text('Details'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildWinnerItem('Cycle 2', 'Sarah Smith', 'Nov 15', '₹2,500'),
        _buildWinnerItem('Cycle 1', 'Mike Johnson', 'Oct 15', '₹2,500'),
      ],
    );
  }

  Widget _buildWinnerItem(String cycle, String name, String date, String amount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.emoji_events, color: Colors.amber)),
        title: Text(name),
        subtitle: Text('$cycle • Won on $date'),
        trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
      ),
    );
  }
}

class _RulesTab extends StatelessWidget {
  final Map<String, dynamic>? pool;

  const _RulesTab({this.pool});

  @override
  Widget build(BuildContext context) {
    if (pool == null) return const Center(child: CircularProgressIndicator());
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRuleSection(
          context,
          'Time Limits',
          Icons.timer,
          [
            _buildRuleRow('Duration', '${pool!['total_rounds']} Cycles (${pool!['total_rounds']} Months)'),
            _buildRuleRow('Frequency', pool!['frequency'].toString().toUpperCase()),
            _buildRuleRow('End Date', DateFormat('MMM d, yyyy').format(DateTime.parse(pool!['start_date']).add(Duration(days: 30 * (pool!['total_rounds'] as int))))),
            _buildRuleRow('Extension', 'Requires 100% Vote'),
          ],
        ),
        const SizedBox(height: 16),
        _buildRuleSection(
          context,
          'Contributions',
          Icons.attach_money,
          [
            _buildRuleRow('Fixed Amount', '${NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(pool!['contribution_amount'])} per cycle'),
            _buildRuleRow('Late Fee', '₹5.00 after 3 days'),
            _buildRuleRow('Prorated', 'Not allowed for mid-cycle'),
          ],
        ),
        const SizedBox(height: 16),
        _buildRuleSection(
          context,
          'Membership',
          Icons.group,
          [
            _buildRuleRow('Max Members', '${pool!['max_members']} Members'),
            _buildRuleRow('Start Condition', 'When full (${pool!['max_members']}/${pool!['max_members']})'),
            _buildRuleRow('Mid-pool Join', 'Allowed (Next cycle start)'),
          ],
        ),
      ],
    );
  }

  Widget _buildRuleSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// _StatsTab moved to end of file

// Members Tab - Grid view of pool members
class _MembersTab extends StatelessWidget {
  final String poolId;
  const _MembersTab({required this.poolId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Members', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (context, i) => Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.primaries[i % Colors.primaries.length],
                child: Text('M${i + 1}', style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 4),
              Text('Member ${i + 1}', style: const TextStyle(fontSize: 12)),
              Icon(Icons.check_circle, size: 16, color: i < 3 ? Colors.green : Colors.grey),
            ],
          ),
        ),
      ],
    );
  }
}

// Schedule Tab - Contribution calendar
class _ScheduleTab extends StatelessWidget {
  final String poolId;
  const _ScheduleTab({required this.poolId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Contribution Schedule', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...List.generate(5, (i) => Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: i == 0 ? Colors.green : Colors.grey.shade300,
              child: Text('${i + 1}', style: TextStyle(color: i == 0 ? Colors.white : Colors.black)),
            ),
            title: Text('Cycle ${i + 1}'),
            subtitle: Text('Due: ${DateFormat('MMM d, yyyy').format(DateTime.now().add(Duration(days: i * 30)))}'),
            trailing: Chip(
              label: Text(i == 0 ? 'Paid' : i == 1 ? 'Upcoming' : 'Pending'),
              backgroundColor: i == 0 ? Colors.green.shade50 : Colors.grey.shade200,
            ),
          ),
        )),
      ],
    );
  }
}

// Winners Tab - Winner history list
class _WinnersTab extends StatelessWidget {
  final String poolId;
  const _WinnersTab({required this.poolId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Winner History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...List.generate(3, (i) => Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(Icons.emoji_events, color: Colors.white),
            ),
            title: Text('Cycle ${i + 1} Winner'),
            subtitle: Text('Member ${i + 1} • ₹5,000'),
            trailing: Text(
              DateFormat('MMM d').format(DateTime.now().subtract(Duration(days: (3 - i) * 30))),
              style: TextStyle(color: Colors.grey),
            ),
          ),
        )),
        const SizedBox(height: 16),
        Text('Current Cycle', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Draw in 15 days', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Your chances: 1 in 6 (17%)', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatTab extends StatelessWidget {
  final String poolId;
  
  const _ChatTab({required this.poolId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Chat functionality coming soon'),
    );
  }
}

class _DocsTab extends StatelessWidget {
  final String poolId;
  
  const _DocsTab({required this.poolId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Documents functionality coming soon'),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final String poolId;
  
  const _StatsTab({required this.poolId});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Statistics functionality coming soon'),
    );
  }
}
