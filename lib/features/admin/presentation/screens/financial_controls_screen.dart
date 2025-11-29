import 'package:flutter/material.dart';
import '../../../../core/services/pool_service.dart';

class FinancialControlsScreen extends StatefulWidget {
  final String? poolId;
  const FinancialControlsScreen({super.key, this.poolId});

  @override
  State<FinancialControlsScreen> createState() => _FinancialControlsScreenState();
}

class _FinancialControlsScreenState extends State<FinancialControlsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'total_collected': 0.0,
    'late_fees': 0.0,
    'target_per_round': 0.0,
    'payout_amount': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.poolId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final stats = await PoolService.getPoolFinancialStats(widget.poolId!);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading financial stats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Controls')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverviewCard(context),
                const SizedBox(height: 24),
                const Text('Adjustments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildActionTile(
                  context,
                  'Waive Late Fees',
                  'Remove fees for specific members',
                  Icons.money_off,
                  () => _showNotImplemented(context),
                ),
                _buildActionTile(
                  context,
                  'Manual Payment',
                  'Record an offline payment',
                  Icons.payments_outlined,
                  () => _showNotImplemented(context),
                ),
                _buildActionTile(
                  context,
                  'Adjust Balance',
                  'Credit/Debit member wallet',
                  Icons.account_balance_wallet_outlined,
                  () => _showNotImplemented(context),
                ),
                _buildActionTile(
                  context,
                  'Process Refund',
                  'Return funds to source',
                  Icons.replay,
                  () => _showNotImplemented(context),
                ),
              ],
            ),
    );
  }

  void _showNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon!')),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final totalCollected = (_stats['total_collected'] as num).toDouble();
    final lateFees = (_stats['late_fees'] as num).toDouble();
    final targetPerRound = (_stats['target_per_round'] as num).toDouble();
    final payoutAmount = (_stats['payout_amount'] as num).toDouble();
    
    // Outstanding is roughly Target - Collected (for current round, but we only have total collected).
    // Let's just show "Target Per Round" instead of "Outstanding" to be accurate with available data.
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Financial Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatRow('Total Collected', '₹${totalCollected.toStringAsFixed(2)}'),
            const Divider(),
            _buildStatRow('Target Per Round', '₹${targetPerRound.toStringAsFixed(2)}', color: Colors.blue),
            const Divider(),
            _buildStatRow('Late Fees Collected', '₹${lateFees.toStringAsFixed(2)}'),
            const Divider(),
            _buildStatRow('Total Pool Value', '₹${payoutAmount.toStringAsFixed(2)}', color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
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
      ),
    );
  }
}
