import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
    final isCreator = _pool?['creator_id'] == AuthService().currentUser?.id;
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
                        const PopupMenuItem(
                          value: 'winner_draw',
                          child: Row(
                            children: [
                              Icon(Icons.casino, size: 20),
                              SizedBox(width: 8),
                              Text('Draw Winner'),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuItem(value: 'edit', child: Text('Edit Pool')),
                      const PopupMenuItem(value: 'mute', child: Text('Mute Notifications')),
                      const PopupMenuItem(value: 'leave', child: Text('Leave Pool')),
                      const PopupMenuItem(value: 'report', child: Text('Report Issue')),
                    ];
                  },
                  onSelected: (value) {
                    if (value == 'manage') {
                      context.push('/creator-dashboard/${widget.poolId}');
                    } else if (value == 'members') {
                      context.push('/member-management/${widget.poolId}');
                    } else if (value == 'winner_draw') {
                      context.push('/winner-selection/${widget.poolId}');
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
            _DocsTab(poolId: widget.poolId, isCreator: isCreator),
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
  String? _membershipStatus;

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
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      final winners = await PoolService.getWinnerHistory(poolId);
      final transactions = await PoolService.getUserPoolTransactions(poolId);
      
      Map<String, dynamic>? membership;
      if (userId != null) {
        membership = await Supabase.instance.client
            .from('pool_members')
            .select('status')
            .eq('pool_id', poolId)
            .eq('user_id', userId)
            .maybeSingle();
      }

      if (mounted) {
        setState(() {
          _recentWinners = winners.take(2).toList();
          _userTransactions = transactions;
          _membershipStatus = membership?['status'];
        });
      }
    } catch (e) {
      debugPrint('Error loading overview data: $e');
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
    final status = widget.pool!['status'] ?? 'active';
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'active':
        color = Colors.green;
        text = 'Active';
        icon = Icons.check_circle;
        break;
      case 'completed':
        color = Colors.blue;
        text = 'Completed';
        icon = Icons.done_all;
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = 'Pending';
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pool Status', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeCard(BuildContext context) {
    final inviteCode = widget.pool!['invite_code'] ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invite Code', style: TextStyle(color: Colors.purple, fontSize: 12)),
              const SizedBox(height: 4),
              Text(inviteCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.5)),
            ],
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite code copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, color: Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    // 1. Handle Pending State
    if (_membershipStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request Pending', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Waiting for admin approval.', style: TextStyle(color: Colors.blueGrey)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. Handle Approved State (Need to Pay Joining Fee)
    if (_membershipStatus == 'approved') {
      final contributionAmount = (widget.pool!['contribution_amount'] as num).toDouble();
      final joiningFee = (widget.pool!['joining_fee'] as num?)?.toDouble() ?? 50.0;
      final total = contributionAmount + joiningFee;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green),
                SizedBox(width: 8),
                Text('Request Approved!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Please pay the joining fee + first contribution to activate your membership.', style: TextStyle(color: Colors.green.shade900)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Due:'),
                Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleJoinPayment(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Pay & Activate'),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Handle Active State (Regular Contributions)
    // Calculate real due date from pool schedule
    final startDate = DateTime.parse(widget.pool!['start_date']);
    final now = DateTime.now();
    final daysSinceStart = now.difference(startDate).inDays;
    final currentRound = ((daysSinceStart / 30).floor() + 1).clamp(1, widget.pool!['total_rounds'] as int);
    final nextDueDate = startDate.add(Duration(days: 30 * currentRound));
    final daysUntilDue = nextDueDate.difference(now).inDays;
    
    // Check if user has paid for current cycle
    final hasPaid = _userTransactions.where((t) => 
      t['type'] == 'contribution' && 
      t['created_at'] != null &&
      DateTime.parse(t['created_at']).isAfter(startDate.add(Duration(days: 30 * (currentRound - 1))))
    ).isNotEmpty;
    
    if (hasPaid) {
      // Don't show payment section if already paid
      return const SizedBox.shrink();
    }
    
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
              Text(
                daysUntilDue > 0 ? 'Due in $daysUntilDue days' : daysUntilDue == 0 ? 'Due today' : '${-daysUntilDue} days overdue',
                style: TextStyle(
                  color: daysUntilDue < 0 ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount Due:', style: TextStyle(color: Colors.grey)),
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

  Future<void> _handleJoinPayment() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await PoolService.completeJoinPayment(widget.pool!['id']);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the pool!')),
        );
        _loadData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
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
          final cycleStartDate = startDate.add(Duration(days: i * 30));
          final cycleEndDate = startDate.add(Duration(days: (i + 1) * 30));
          final isPast = cycleEndDate.isBefore(now);
          
          // Check if user has paid for THIS specific cycle by checking transaction dates
          final hasPaid = _userTransactions.where((t) {
            if (t['type'] != 'contribution') return false;
            if (t['created_at'] == null) return false;
            
            final txnDate = DateTime.parse(t['created_at']);
            // Payment is for this cycle if it's between cycle start and end
            return txnDate.isAfter(cycleStartDate.subtract(const Duration(days: 1))) && 
                   txnDate.isBefore(cycleEndDate.add(const Duration(days: 1)));
          }).isNotEmpty;
          
          String status;
          Color color;
          
          if (hasPaid) {
            status = 'Completed';
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
            'Due: ${DateFormat('MMM d, yyyy').format(cycleEndDate)}', 
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
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pool = await PoolService.getPoolDetails(widget.poolId);
      final transactions = await PoolService.getUserPoolTransactions(widget.poolId);
      if (mounted) {
        setState(() {
          _pool = pool;
          _transactions = transactions;
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
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Contribution Schedule', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...List.generate(totalRounds, (i) {
          final cycleStartDate = startDate.add(Duration(days: i * 30));
          final cycleEndDate = startDate.add(Duration(days: (i + 1) * 30));
          final isPast = cycleEndDate.isBefore(now);
          
          // Check if user has paid for THIS specific cycle
          final hasPaid = _transactions.where((t) {
            if (t['type'] != 'contribution') return false;
            if (t['created_at'] == null) return false;
            
            final txnDate = DateTime.parse(t['created_at']);
            return txnDate.isAfter(cycleStartDate.subtract(const Duration(days: 1))) && 
                   txnDate.isBefore(cycleEndDate.add(const Duration(days: 1)));
          }).isNotEmpty;
          
          String status;
          Color color;
          
          if (hasPaid) {
            status = 'Completed';
            color = Colors.green;
          } else if (isPast) {
            status = 'Overdue';
            color = Colors.red;
          } else {
            status = 'Upcoming';
            color = Colors.blue;
          }
          
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Text('${i + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ),
              title: Text('Cycle ${i + 1}'),
              subtitle: Text('Due: ${DateFormat('MMM d, yyyy').format(cycleEndDate)}'),
              trailing: Chip(
                label: Text(status),
                backgroundColor: color.withOpacity(0.1),
                labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
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
  final bool isCreator;
  
  const _DocsTab({required this.poolId, required this.isCreator});

  @override
  Widget build(BuildContext context) {
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
