import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/pool_service.dart';

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
        title: const Text('Join a Pool'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'Browse'),
            Tab(text: 'Map View'),
            Tab(text: 'Have Code?'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DiscoverTab(),
          _BrowsePoolsTab(),
          _MapViewTab(),
          _JoinByCodeTab(),
        ],
      ),
    );
  }
}

class _DiscoverTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(context, 'Trending Now'),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) => _buildTrendingCard(context, index),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Recommended for You'),
        _buildRecommendedCard(context, 'High Savers Club', '₹5,000/month', '98% Match'),
        _buildRecommendedCard(context, 'Vacation Fund', '₹2,000/month', '95% Match'),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Categories'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCategoryChip(context, 'Travel', Icons.flight),
            _buildCategoryChip(context, 'Gadgets', Icons.devices),
            _buildCategoryChip(context, 'Emergency', Icons.medical_services),
            _buildCategoryChip(context, 'Education', Icons.school),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTrendingCard(BuildContext context, int index) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(child: Icon(Icons.trending_up, size: 32, color: Colors.primaries[index % Colors.primaries.length])),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pool #${index + 100}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${(index + 1) * 1000}/mo', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    Text(' 4.${9 - index}', style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCard(BuildContext context, String title, String amount, String match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(title[0])),
        title: Text(title),
        subtitle: Text(amount),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(match, style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: Colors.grey.shade100,
    );
  }
}

class _MapViewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Map View', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Find pools near you (Coming Soon)', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
          ),
        ],
      ),
    );
  }
}

class _BrowsePoolsTab extends StatefulWidget {
  @override
  State<_BrowsePoolsTab> createState() => _BrowsePoolsTabState();
}

class _BrowsePoolsTabState extends State<_BrowsePoolsTab> {
  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPools();
  }

  Future<void> _loadPools() async {
    try {
      final pools = await PoolService.getPublicPools();
      if (mounted) {
        setState(() {
          _pools = pools;
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
                  onChanged: (value) {
                    // TODO: Implement search
                  },
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pools.isEmpty
                  ? const Center(child: Text('No pools found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _pools.length,
                      itemBuilder: (context, index) {
                        final pool = _pools[index];
                        return _PoolListItem(
                          name: pool['name'],
                          creator: 'Admin', // Creator name not always available in simple join query
                          members: '${pool['current_members']}/${pool['max_members']}',
                          amount: (pool['contribution_amount'] as num).toInt(),
                          duration: pool['total_rounds'],
                          rating: 4.5, // Placeholder
                          onTap: () => _showJoinPreview(context, pool),
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

  void _showJoinPreview(BuildContext context, Map<String, dynamic> pool) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _PoolPreviewSheet(scrollController: scrollController, pool: pool),
      ),
    );
  }
}



class _JoinByCodeTab extends StatefulWidget {
  @override
  State<_JoinByCodeTab> createState() => _JoinByCodeTabState();
}

class _JoinByCodeTabState extends State<_JoinByCodeTab> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _findAndJoinPool() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-character code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pool = await PoolService.findPoolByCode(code);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (pool == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pool not found with this code')),
          );
          return;
        }

        // Show preview
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => _PoolPreviewSheet(scrollController: scrollController, pool: pool),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

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
            'Enter the 6-character code shared by the pool creator',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'ABCD12',
              hintStyle: TextStyle(color: Colors.grey.shade300),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _findAndJoinPool,
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Find Pool'),
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
                  _buildInfoItem(context, Icons.attach_money, '₹$amount', 'Monthly'),
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
  final Map<String, dynamic> pool;

  const _PoolPreviewSheet({required this.scrollController, required this.pool});

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
                    Text(pool['name'], style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Created by Admin • 4.5 ★'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Pool Details'),
          const SizedBox(height: 16),
          _buildDetailRow('Contribution', '₹${pool['contribution_amount']} / ${pool['frequency']}'),
          _buildDetailRow('Duration', '${pool['total_rounds']} cycles'),
          _buildDetailRow('Total Payout', '₹${(pool['contribution_amount'] as num) * (pool['total_rounds'] as int)}'),
          _buildDetailRow('Start Date', DateFormat('MMM d, yyyy').format(DateTime.parse(pool['start_date']))),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Members (${pool['current_members']}/${pool['max_members']})'),
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
          _buildRuleItem(Icons.check_circle_outline, 'Late payments incur a ₹ fee.'),
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
            Text('You are about to join "${pool['name']}".'),
            const SizedBox(height: 16),
            _buildSummaryRow('Monthly Payment', '₹${pool['contribution_amount']}'),
            _buildSummaryRow('Duration', '${pool['total_rounds']} Cycles'),
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
              _joinPool(context);
            },
            child: const Text('Confirm & Pay'),
          ),
        ],
      ),
    );
  }

  void _joinPool(BuildContext context) async {
    try {
      // For public pools in discovery, we use the invite code from the pool object
      // If it's missing (legacy data), we might need to handle it, but for now assume it's there
      final inviteCode = pool['invite_code'] ?? '';
      
      await PoolService.joinPool(pool['id'], inviteCode);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent! Waiting for admin approval.')),
        );
        context.go('/pool-details/${pool['id']}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining pool: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
