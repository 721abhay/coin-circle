import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PoolDetailsScreen extends StatefulWidget {
  final String poolId;

  const PoolDetailsScreen({super.key, required this.poolId});

  @override
  State<PoolDetailsScreen> createState() => _PoolDetailsScreenState();
}

class _PoolDetailsScreenState extends State<PoolDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Increased to 5
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
                title: const Text('Office Savings Circle', style: TextStyle(color: Colors.white)),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://picsum.photos/seed/pool/800/400',
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
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Pool')),
                    const PopupMenuItem(value: 'mute', child: Text('Mute Notifications')),
                    const PopupMenuItem(value: 'leave', child: Text('Leave Pool')),
                    const PopupMenuItem(value: 'report', child: Text('Report Issue')),
                    const PopupMenuItem(value: 'demo_draw', child: Text('Simulate Draw (Demo)')),
                    const PopupMenuItem(value: 'demo_vote', child: Text('View Vote Request (Demo)')),
                  ],
                  onSelected: (value) {
                    if (value == 'demo_draw') {
                      context.push('/winner-selection');
                    } else if (value == 'demo_vote') {
                      context.push('/voting');
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
                  Tab(text: 'Rules'), // New Tab
                  Tab(text: 'Chat'),
                  Tab(text: 'Files'),
                  Tab(text: 'Stats'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(poolId: widget.poolId),
            _RulesTab(), // New Tab View
            _ChatTab(),
            _FilesTab(),
            _StatsTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String poolId;

  const _OverviewTab({required this.poolId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(context),
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
                  const Text('\$2,500', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Cycle 3 of 10', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem('Next Draw', '2 Days'),
              _buildStatusItem('Your Contribution', '\$1,500'),
              _buildStatusItem('Time Left', '3M 15D'), // Updated format
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
                  color: Colors.white,
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount Due:', style: TextStyle(color: Colors.grey)),
              Text('\$500.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/payment', extra: {'poolId': poolId, 'amount': 500.0}),
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
            Text('Members (8/10)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), // Updated Capacity
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cycle $cycle', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
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
        _buildWinnerItem('Cycle 2', 'Sarah Smith', 'Nov 15', '\$2,500'),
        _buildWinnerItem('Cycle 1', 'Mike Johnson', 'Oct 15', '\$2,500'),
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
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRuleSection(
          context,
          'Time Limits',
          Icons.timer,
          [
            _buildRuleRow('Duration', '10 Cycles (10 Months)'),
            _buildRuleRow('Frequency', 'Monthly'),
            _buildRuleRow('End Date', 'July 15, 2026'),
            _buildRuleRow('Extension', 'Requires 100% Vote'),
          ],
        ),
        const SizedBox(height: 16),
        _buildRuleSection(
          context,
          'Contributions',
          Icons.attach_money,
          [
            _buildRuleRow('Fixed Amount', '\$500.00 per cycle'),
            _buildRuleRow('Late Fee', '\$5.00 after 3 days'),
            _buildRuleRow('Prorated', 'Not allowed for mid-cycle'),
          ],
        ),
        const SizedBox(height: 16),
        _buildRuleSection(
          context,
          'Membership',
          Icons.group,
          [
            _buildRuleRow('Max Members', '10 Members'),
            _buildRuleRow('Start Condition', 'When full (10/10)'),
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

class _ChatTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 10,
            itemBuilder: (context, index) {
              final isMe = index % 2 == 0;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isMe ? const Radius.circular(0) : null,
                      bottomLeft: !isMe ? const Radius.circular(0) : null,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        const Text('John Doe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'Hey everyone! Just made my payment for this month.',
                        style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '10:30 AM',
                        style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () {}),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFileItem(Icons.description, 'Pool Rules.pdf', '2.5 MB'),
        _buildFileItem(Icons.article, 'Member Agreement.docx', '1.2 MB'),
        _buildFileItem(Icons.receipt, 'Cycle 1 Receipt.pdf', '500 KB'),
        _buildFileItem(Icons.receipt, 'Cycle 2 Receipt.pdf', '500 KB'),
      ],
    );
  }

  Widget _buildFileItem(IconData icon, String name, String size) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(size),
        trailing: IconButton(icon: const Icon(Icons.download), onPressed: () {}),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard(context, 'On-time Payment Rate', '95%', Colors.green),
          const SizedBox(height: 16),
          _buildStatCard(context, 'Pool Completion', '30%', Colors.blue),
          const SizedBox(height: 24),
          const Text('Contribution Trends', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('C${value.toInt() + 1}');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  5,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(toY: (index + 1) * 1000.0, color: Theme.of(context).primaryColor, width: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

