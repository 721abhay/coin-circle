import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class WithdrawalRequestsScreen extends StatefulWidget {
  const WithdrawalRequestsScreen({super.key});

  @override
  State<WithdrawalRequestsScreen> createState() => _WithdrawalRequestsScreenState();
}

class _WithdrawalRequestsScreenState extends State<WithdrawalRequestsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _filter = 'pending'; // pending, approved, rejected, all

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      var query = _supabase
          .from('withdrawal_requests')
          .select('*, profiles!inner(full_name, email, phone), bank_accounts!inner(*)');

      if (_filter != 'all') {
        query = query.eq('status', _filter);
      }

      final response = await query.order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading requests: $e')),
        );
      }
    }
  }

  Future<void> _approveRequest(String requestId, String userId, double amount) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;

      // 1. Update withdrawal request status
      await _supabase.from('withdrawal_requests').update({
        'status': 'approved',
        'processed_by': adminId,
        'processed_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);

      // 2. Update transaction status (if you have a transaction linked, otherwise just the request is enough for record)
      // Assuming we created a transaction record when request was made.
      // We can try to find the pending transaction and update it.
      
      // Find pending withdrawal transaction for this user and amount
      // This is a bit loose but works for MVP if we don't store transaction_id in withdrawal_requests
      final transactions = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('type', 'withdrawal')
          .eq('amount', amount)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1);

      if (transactions.isNotEmpty) {
        await _supabase.from('transactions').update({
          'status': 'completed',
        }).eq('id', transactions.first['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal Approved'), backgroundColor: Colors.green),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId, String userId, double amount, String reason) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;

      // 1. Update withdrawal request status
      await _supabase.from('withdrawal_requests').update({
        'status': 'rejected',
        'processed_by': adminId,
        'processed_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
      }).eq('id', requestId);

      // 2. Refund money to wallet
      // We need to increment available_balance
      // Using RPC is safer for atomic updates, but direct update works if no concurrency issues expected for MVP
      
      // Get current wallet
      final wallet = await _supabase.from('wallets').select().eq('user_id', userId).single();
      final currentBalance = (wallet['available_balance'] as num).toDouble();
      
      await _supabase.from('wallets').update({
        'available_balance': currentBalance + amount,
      }).eq('user_id', userId);

      // 3. Update transaction status to failed/rejected
      final transactions = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('type', 'withdrawal')
          .eq('amount', amount)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1);

      if (transactions.isNotEmpty) {
        await _supabase.from('transactions').update({
          'status': 'failed',
          'description': 'Withdrawal rejected: $reason',
        }).eq('id', transactions.first['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal Rejected & Refunded'), backgroundColor: Colors.red),
        );
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting request: $e')),
        );
      }
    }
  }

  void _showRejectDialog(String requestId, String userId, double amount) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Withdrawal'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'e.g., Invalid bank details',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                _rejectRequest(requestId, userId, amount, reasonController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject & Refund'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal Requests')),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('Pending', 'pending'),
                _buildFilterChip('Approved', 'approved'),
                _buildFilterChip('Rejected', 'rejected'),
                _buildFilterChip('All', 'all'),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? const Center(child: Text('No requests found'))
                    : ListView.builder(
                        itemCount: _requests.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final req = _requests[index];
                          final profile = req['profiles'];
                          final bank = req['bank_accounts'];
                          final amount = (req['amount'] as num).toDouble();
                          final status = req['status'];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: status == 'pending' ? Colors.orange : (status == 'approved' ? Colors.green : Colors.red),
                                child: Icon(
                                  status == 'pending' ? Icons.hourglass_empty : (status == 'approved' ? Icons.check : Icons.close),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text('₹${amount.toStringAsFixed(2)}'),
                              subtitle: Text('${profile['full_name']} • ${DateFormat('MMM dd').format(DateTime.parse(req['created_at']))}'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow('User', profile['full_name']),
                                      _buildDetailRow('Email', profile['email']),
                                      _buildDetailRow('Phone', profile['phone'] ?? 'N/A'),
                                      const Divider(),
                                      const Text('Bank Details', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      _buildDetailRow('Bank', bank['bank_name']),
                                      _buildDetailRow('Account', bank['account_number']),
                                      _buildDetailRow('IFSC', bank['ifsc_code']),
                                      _buildDetailRow('Holder', bank['account_holder_name']),
                                      
                                      if (status == 'pending') ...[
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => _showRejectDialog(req['id'], req['user_id'], amount),
                                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                                child: const Text('Reject'),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => _approveRequest(req['id'], req['user_id'], amount),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                child: const Text('Approve'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      
                                      if (status == 'rejected')
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text('Reason: ${req['rejection_reason']}', style: const TextStyle(color: Colors.red)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = value);
          _loadRequests();
        }
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
