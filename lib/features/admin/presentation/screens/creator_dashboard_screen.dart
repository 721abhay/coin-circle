import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/pool_service.dart';

class CreatorDashboardScreen extends StatefulWidget {
  final String? poolId; // Optional, if null, show list of pools? For now assume required or handle gracefully
  
  const CreatorDashboardScreen({super.key, this.poolId});

  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  Map<String, dynamic>? _pool;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoolData();
  }

  Future<void> _loadPoolData() async {
    if (widget.poolId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final pool = await PoolService.getPoolDetails(widget.poolId!);
      if (mounted) {
        setState(() {
          _pool = pool;
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If no poolId provided or pool not found, maybe show a list or error
    // For now, let's assume we are in the context of a specific pool if poolId is passed
    // If not, we might want to show a "Select Pool" screen, but let's stick to the specific pool dashboard for now.
    
    final poolName = _pool?['name'] ?? 'Pool Dashboard';
    final memberCount = _pool?['current_members'] ?? 0;
    final totalAmount = _pool?['total_amount'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(poolName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverviewCard(context, memberCount, totalAmount),
          const SizedBox(height: 24),
          const Text('Management Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            icon: Icons.people_outline,
            title: 'Member Management',
            subtitle: 'Approve requests, remove members',
            onTap: () => widget.poolId != null ? context.push('/member-management/${widget.poolId}') : null,
          ),
          _buildToolCard(
            context,
            icon: Icons.campaign_outlined,
            title: 'Announcements',
            subtitle: 'Send messages to all members',
            onTap: () => widget.poolId != null ? context.push('/announcements/${widget.poolId}') : null,
          ),
          _buildToolCard(
            context,
            icon: Icons.gavel_outlined,
            title: 'Moderation Tools',
            subtitle: 'Chat moderation & user bans',
            onTap: () => widget.poolId != null ? context.push('/moderation/${widget.poolId}') : null,
          ),
          _buildToolCard(
            context,
            icon: Icons.settings_outlined,
            title: 'Pool Settings',
            subtitle: 'Edit rules and configuration',
            onTap: () => widget.poolId != null ? context.push('/pool-settings/${widget.poolId}') : null,
          ),
          _buildToolCard(
            context,
            icon: Icons.attach_money,
            title: 'Financial Controls',
            subtitle: 'Monitor finances & adjustments',
            onTap: () => widget.poolId != null ? context.push('/financial-controls/${widget.poolId}') : null,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, int members, dynamic volume) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pool Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Active', 'Status'),
                _buildStatItem(context, '$members', 'Members'),
                _buildStatItem(context, NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN').format(volume), 'Volume'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildToolCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        enabled: onTap != null,
      ),
    );
  }
}
