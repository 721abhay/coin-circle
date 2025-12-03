import 'package:flutter/material.dart';
import '../../../../core/services/pool_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<Map<String, dynamic>> _pendingPayouts = [];
  bool _isLoadingPayouts = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPendingPayouts();
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
        // Don't show error here, might just be no data
      }
    }
  }

  Future<void> _loadPendingPayouts() async {
    if (widget.poolId == null) return;
    
    setState(() => _isLoadingPayouts = true);
    try {
      final response = await Supabase.instance.client
          .from('winner_history')
          .select('*, profiles!winner_history_user_id_fkey(full_name)')
          .eq('pool_id', widget.poolId!)
          .eq('payout_status', 'pending')
          .order('round_number');
      
      if (mounted) {
        setState(() {
          _pendingPayouts = List<Map<String, dynamic>>.from(response);
          _isLoadingPayouts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPayouts = false);
        debugPrint('Error loading payouts: $e');
      }
    }
  }

  Future<void> _approvePayout(String winnerHistoryId, String userId, double amount) async {
    try {
      final client = Supabase.instance.client;
      final adminId = client.auth.currentUser?.id;

      // 1. Update winner_history
      await client.from('winner_history').update({
        'payout_status': 'approved',
        'payout_approved_at': DateTime.now().toIso8601String(),
        'payout_approved_by': adminId,
      }).eq('id', winnerHistoryId);

      // 2. Move funds from locked to available
      // Get current wallet
      final wallet = await client.from('wallets').select().eq('user_id', userId).single();
      final currentLocked = (wallet['locked_balance'] as num).toDouble();
      final currentAvailable = (wallet['available_balance'] as num).toDouble();
      
      await client.from('wallets').update({
        'locked_balance': currentLocked - amount,
        'available_balance': currentAvailable + amount,
      }).eq('user_id', userId);

      // 3. Update transaction status
      // Find the pending winning transaction
      final transactions = await client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('pool_id', widget.poolId!)
          .eq('type', 'winning')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1);

      if (transactions.isNotEmpty) {
        await client.from('transactions').update({
          'status': 'completed',
        }).eq('id', transactions.first['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout Approved! Funds are now available for withdrawal.'), backgroundColor: Colors.green),
        );
        _loadPendingPayouts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving payout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Overview')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadData();
                await _loadPendingPayouts();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverviewCard(context),
                  const SizedBox(height: 24),
                  
                  const Text('Pending Payouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildPendingPayoutsList(),
                  
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Approving a payout moves the winning amount from "Locked" to "Available" balance in the winner\'s wallet.',
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPendingPayoutsList() {
    if (_isLoadingPayouts) return const Center(child: CircularProgressIndicator());
    
    if (_pendingPayouts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('No pending payouts', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _pendingPayouts.map((payout) {
        final amount = (payout['winning_amount'] as num).toDouble();
        final round = payout['round_number'];
        final winnerName = payout['profiles']['full_name'];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: const Icon(Icons.emoji_events, color: Colors.orange),
            ),
            title: Text('Round $round Winner'),
            subtitle: Text('$winnerName • ₹${amount.toStringAsFixed(2)}'),
            trailing: ElevatedButton(
              onPressed: () => _approvePayout(payout['id'], payout['user_id'], amount),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve'),
            ),
          ),
        );
      }).toList(),
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
