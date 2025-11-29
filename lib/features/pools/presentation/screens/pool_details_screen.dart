import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/pool_service.dart';
import 'pool_chat_screen.dart';
import 'pool_documents_screen.dart';
import 'pool_statistics_screen.dart';

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
                      if (isCreator) ...[
                        const PopupMenuItem(value: 'manage', child: Text('Manage Pool (Admin)')),
                        const PopupMenuItem(
                          value: 'members',
                          child: Row(
                            children: [
                              Icon(Icons.people_outline, size: 20),
                              SizedBox(width: 8),
                              Text('Member Requests'),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuItem(value: 'edit', child: Text('Edit Pool')),
                      const PopupMenuItem(value: 'mute', child: Text('Mute Notifications')),
                      const PopupMenuItem(value: 'leave', child: Text('Leave Pool')),
                      const PopupMenuItem(value: 'report', child: Text('Report Issue')),
                      const PopupMenuItem(value: 'demo_draw', child: Text('Simulate Draw')),
                      const PopupMenuItem(value: 'demo_vote', child: Text('View Vote Request')),
                    ];
                  },
                  onSelected: (value) {
                    if (value == 'manage') {
                      context.push('/creator-dashboard/${widget.poolId}');
                    } else if (value == 'members') {
                      context.push('/member-management/${widget.poolId}');
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
            _OverviewTab(
              pool: _pool,
              onViewMembers: () => _tabController.animateTo(1),
            ),
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

class _OverviewTab extends StatefulWidget {
  final Map<String, dynamic>? pool;
  final VoidCallback? onViewMembers;

  const _OverviewTab({this.pool, this.onViewMembers});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  List<Map<String, dynamic>> _recentWinners = [];
  List<Map<String, dynamic>> _userTransactions = [];

  @override
  void initState() {
    super.initState();
    if (widget.pool != null) {
      _loadData();
    }
  }

  @override
  void didUpdateWidget(_OverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pool != null && oldWidget.pool != widget.pool) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final poolId = widget.pool!['id'];
      final winners = await PoolService.getWinnerHistory(poolId);
      final transactions = await PoolService.getUserPoolTransactions(poolId);

      if (mounted) {
        setState(() {
          _recentWinners = winners.take(2).toList();
          _userTransactions = transactions;
        });
      }
    } catch (e) {
      print('Error loading overview data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pool == null) {
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
    final startDate = DateTime.parse(widget.pool!['start_date']);
    final totalRounds = widget.pool!['total_rounds'] as int;
    final now = DateTime.now();
    final daysSinceStart = now.difference(startDate).inDays;
    final currentRound = ((daysSinceStart / 30).floor() + 1).clamp(1, totalRounds);
    final nextDrawDate = startDate.add(Duration(days: 30 * currentRound));
    final daysLeft = nextDrawDate.difference(now).inDays;
    final progress = currentRound / totalRounds;

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
                    NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(widget.pool!['total_amount'] ?? 0),
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
                  'Cycle $currentRound of $totalRounds',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem('Next Draw', '${daysLeft > 0 ? daysLeft : 0} Days'),
              _buildStatusItem(
                'Your Contribution',
                NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(widget.pool!['contribution_amount'] ?? 0),
              ),
              _buildStatusItem('Time Left', '${totalRounds - currentRound} Months'),
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
                  Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
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
    final inviteCode = widget.pool!['invite_code'];
    if (inviteCode == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: inviteCode));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Invite code "$inviteCode" copied to clipboard!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
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
              'Tap anywhere to copy • Share this code with friends to join the pool.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ],
        ),
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
                NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(widget.pool!['contribution_amount'] ?? 0),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/payment', extra: {'poolId': widget.pool!['id'], 'amount': (widget.pool!['contribution_amount'] as num).toDouble()}),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Pay Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context) {
    final members = List<Map<String, dynamic>>.from(widget.pool!['members'] ?? []);
    final maxMembers = widget.pool!['max_members'] as int;
    final currentMembers = members.length;
    final progress = maxMembers > 0 ? currentMembers / maxMembers : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Members ($currentMembers/$maxMembers)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // Navigate to members tab
                widget.onViewMembers?.call();
              }, 
              child: const Text('View All')
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Capacity Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: currentMembers >= maxMembers ? Colors.red : Colors.green,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
        if (members.isEmpty)
          const Text('No members yet')
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final profile = member['profile'] ?? {};
                final name = profile['full_name'] ?? 'Member';
                final status = member['status'] ?? 'active';
                final avatarUrl = profile['avatar_url'];

                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'M') : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: status == 'active' ? Colors.green : Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                status == 'active' ? Icons.check : Icons.access_time,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 60,
                        child: Text(
                          name, 
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
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
    final startDate = DateTime.parse(widget.pool!['start_date']);
    final totalRounds = widget.pool!['total_rounds'] as int;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contribution Schedule', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        // Show only next 3 cycles or recent ones
        ...List.generate(totalRounds > 3 ? 3 : totalRounds, (i) {
          final dueDate = startDate.add(Duration(days: i * 30));
          final isPast = dueDate.isBefore(now);
          
          // Check if user has paid for this cycle (simplified logic: count contributions)
          final hasPaid = _userTransactions.where((t) => t['type'] == 'contribution').length > i;
          
          String status;
          Color color;
          
          if (hasPaid) {
            status = 'Paid';
            color = Colors.green;
          } else if (isPast) {
            status = 'Overdue';
            color = Colors.red;
          } else {
            status = 'Upcoming';
            color = Colors.blue;
          }
          
          return _buildScheduleItem(
            context, 
            i + 1, 
            'Due: ${DateFormat('MMM d').format(dueDate)}', 
            status, 
            color
          );
        }),
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
        if (_recentWinners.isEmpty)
          const Text('No winners yet')
        else
          ..._recentWinners.map((winner) {
            final profile = winner['profiles'] ?? {};
            final name = profile['full_name'] ?? 'Unknown';
            final amount = winner['prize_amount'] ?? 0;
            final round = winner['round_number'] ?? 0;
            final date = winner['won_at'] != null 
                ? DateFormat('MMM d').format(DateTime.parse(winner['won_at']))
                : '';

            return _buildWinnerItem('Cycle $round', name, date, NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(amount));
          }),
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
class _MembersTab extends StatefulWidget {
  final String poolId;
  const _MembersTab({required this.poolId});

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final pool = await PoolService.getPoolDetails(widget.poolId);
      if (mounted) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(pool['members'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Members (${_members.length})', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _members.length,
          itemBuilder: (context, i) {
            final member = _members[i];
            final profile = member['profile'] ?? {};
            final name = profile['full_name'] ?? 'Member ${i + 1}';
            final status = member['status'] ?? 'active';
            
            return Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.primaries[i % Colors.primaries.length],
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'M', style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                Icon(
                  status == 'active' ? Icons.check_circle : Icons.access_time, 
                  size: 16, 
                  color: status == 'active' ? Colors.green : Colors.orange
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// Schedule Tab - Contribution calendar
class _ScheduleTab extends StatefulWidget {
  final String poolId;
  const _ScheduleTab({required this.poolId});

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  Map<String, dynamic>? _pool;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPool();
  }

  Future<void> _loadPool() async {
    try {
      final pool = await PoolService.getPoolDetails(widget.poolId);
      if (mounted) {
        setState(() {
          _pool = pool;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_pool == null) return const Center(child: Text('Error loading schedule'));

    final startDate = DateTime.parse(_pool!['start_date']);
    final totalRounds = _pool!['total_rounds'] as int;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Contribution Schedule', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...List.generate(totalRounds, (i) {
          final dueDate = startDate.add(Duration(days: i * 30));
          final isPast = dueDate.isBefore(DateTime.now());
          
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isPast ? Colors.green : Colors.grey.shade300,
                child: Text('${i + 1}', style: TextStyle(color: isPast ? Colors.white : Colors.black)),
              ),
              title: Text('Cycle ${i + 1}'),
              subtitle: Text('Due: ${DateFormat('MMM d, yyyy').format(dueDate)}'),
              trailing: Chip(
                label: Text(isPast ? 'Completed' : 'Upcoming'),
                backgroundColor: isPast ? Colors.green.shade50 : Colors.grey.shade200,
              ),
            ),
          );
        }),
      ],
    );
  }
}

// Winners Tab - Winner history list
class _WinnersTab extends StatefulWidget {
  final String poolId;
  const _WinnersTab({required this.poolId});

  @override
  State<_WinnersTab> createState() => _WinnersTabState();
}

class _WinnersTabState extends State<_WinnersTab> {
  List<Map<String, dynamic>> _winners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWinners();
  }

  Future<void> _loadWinners() async {
    try {
      final winners = await PoolService.getWinnerHistory(widget.poolId);
      if (mounted) {
        setState(() {
          _winners = winners;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Winner History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (_winners.isEmpty)
          const Center(child: Text('No winners yet'))
        else
          ..._winners.map((winner) {
            final profile = winner['profiles'] ?? {};
            final name = profile['full_name'] ?? 'Unknown Member';
            final amount = winner['prize_amount'] ?? 0;
            final round = winner['round_number'] ?? 0;
            final date = winner['won_at'] != null 
                ? DateFormat('MMM d, yyyy').format(DateTime.parse(winner['won_at']))
                : 'Unknown Date';

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.emoji_events, color: Colors.white),
                ),
                title: Text('Cycle $round Winner'),
                subtitle: Text('$name • ${NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(amount)}'),
                trailing: Text(
                  date,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ChatTab extends StatelessWidget {
  final String poolId;
  
  const _ChatTab({required this.poolId});

  @override
  Widget build(BuildContext context) {
    return PoolChatScreen(poolId: poolId, poolName: 'Pool Chat');
  }
}

class _DocsTab extends StatelessWidget {
  final String poolId;
  
  const _DocsTab({required this.poolId});

  @override
  Widget build(BuildContext context) {
    final isCreator = false; // TODO: Pass this properly or fetch in screen
    return PoolDocumentsScreen(poolId: poolId, isCreator: isCreator);
  }
}

class _StatsTab extends StatelessWidget {
  final String poolId;
  
  const _StatsTab({required this.poolId});

  @override
  Widget build(BuildContext context) {
    return PoolStatisticsScreen(poolId: poolId);
  }
}
