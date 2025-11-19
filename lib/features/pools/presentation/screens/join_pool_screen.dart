import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JoinPoolScreen extends StatefulWidget {
  const JoinPoolScreen({super.key});

  @override
  State<JoinPoolScreen> createState() => _JoinPoolScreenState();
}

class _JoinPoolScreenState extends State<JoinPoolScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Join a Pool'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Browse Pools'),
            Tab(text: 'Have a Code?'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BrowsePoolsTab(),
          _JoinByCodeTab(),
        ],
      ),
    );
  }
}

class _BrowsePoolsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search pools...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                  onPressed: () => _showFilterBottomSheet(context),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) {
              return _PoolListItem(
                name: 'Community Savings ${index + 1}',
                creator: 'John Doe',
                members: '${index + 2}/10',
                amount: (index + 1) * 100,
                duration: 10,
                rating: 4.5,
                onTap: () => _showJoinPreview(context),
              );
            },
          ),
        ),
      ],
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
            const Text('Contribution Amount'),
            RangeSlider(values: const RangeValues(100, 500), min: 50, max: 1000, onChanged: (values) {}),
            const SizedBox(height: 16),
            const Text('Duration (Months)'),
            Slider(value: 10, min: 3, max: 24, onChanged: (value) {}),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinPreview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _PoolPreviewSheet(scrollController: scrollController),
      ),
    );
  }
}

class _JoinByCodeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
          const SizedBox(height: 32),
          Text(
            'Enter Invitation Code',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the code shared by the pool creator',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'ABCD-1234',
              hintStyle: TextStyle(color: Colors.grey.shade300),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Join Pool'),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR')),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan QR Code'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolListItem extends StatelessWidget {
  final String name;
  final String creator;
  final String members;
  final int amount;
  final int duration;
  final double rating;
  final VoidCallback onTap;

  const _PoolListItem({
    required this.name,
    required this.creator,
    required this.members,
    required this.amount,
    required this.duration,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('by $creator', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(context, Icons.attach_money, '\$$amount', 'Monthly'),
                  _buildInfoItem(context, Icons.calendar_today, '$duration', 'Months'),
                  _buildInfoItem(context, Icons.people, members, 'Joined'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _PoolPreviewSheet extends StatelessWidget {
  final ScrollController scrollController;

  const _PoolPreviewSheet({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.groups, size: 30, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Community Savings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Created by John Doe • 4.5 ★'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Pool Details'),
          const SizedBox(height: 16),
          _buildDetailRow('Contribution', '\$100 / month'),
          _buildDetailRow('Duration', '10 months'),
          _buildDetailRow('Total Payout', '\$1,000'),
          _buildDetailRow('Start Date', 'Dec 1, 2025'),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Members (2/10)'),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    child: index < 2 ? const Icon(Icons.person) : Icon(Icons.person_outline, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Rules & Policies'),
          const SizedBox(height: 16),
          _buildRuleItem(Icons.check_circle_outline, 'Late payments incur a \$5 fee.'),
          _buildRuleItem(Icons.check_circle_outline, 'Winner selected by random draw.'),
          _buildRuleItem(Icons.check_circle_outline, 'Identity verification required.'),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showJoinConfirmation(context),
              child: const Text('Join Pool'),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Joining'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to join "Community Savings".'),
            const SizedBox(height: 16),
            _buildSummaryRow('Monthly Payment', '\$100'),
            _buildSummaryRow('Duration', '10 Months'),
            _buildSummaryRow('First Payment', 'Due Now'),
            const SizedBox(height: 24),
            const Text('By confirming, you agree to the pool rules and commit to timely payments.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.pop(); // Close dialog
              context.pop(); // Close sheet
              context.push('/payment', extra: {'poolId': 'new', 'amount': 100.0});
            },
            child: const Text('Confirm & Pay'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRuleItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
