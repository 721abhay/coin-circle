import 'package:flutter/material.dart';
import '../../../../core/services/wallet_management_service.dart';
import 'package:intl/intl.dart';

class AdminWithdrawalsTab extends StatefulWidget {
  const AdminWithdrawalsTab({super.key});

  @override
  State<AdminWithdrawalsTab> createState() => _AdminWithdrawalsTabState();
}

class _AdminWithdrawalsTabState extends State<AdminWithdrawalsTab> {
  List<Map<String, dynamic>> _withdrawals = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    setState(() => _isLoading = true);
    try {
      final withdrawals = await WalletManagementService.getAllWithdrawalRequests();
      if (mounted) {
        setState(() {
          _withdrawals = withdrawals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading withdrawals: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredWithdrawals {
    if (_selectedStatus == 'all') {
      return _withdrawals;
    }
    return _withdrawals.where((w) => w['status'] == _selectedStatus).toList();
  }

  Future<void> _processWithdrawal(String withdrawalId, String action) async {
    final notes = await _showNotesDialog(action);
    if (notes == null) return;

    try {
      if (action == 'Approve') {
        await WalletManagementService.approveWithdrawal(withdrawalId, notes);
      } else {
        await WalletManagementService.rejectWithdrawal(withdrawalId, notes);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Withdrawal ${action.toLowerCase()}d successfully')),
        );
        _loadWithdrawals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _showNotesDialog(String action) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Withdrawal'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Admin Notes ${action == 'Reject' ? '(Required)' : '(Optional)'}',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (action == 'Reject' && controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notes required for rejection')),
                );
                return;
              }
              Navigator.pop(context, controller.text);
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Processing', 'processing'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),
        ),

        // Withdrawals List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredWithdrawals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No ${_selectedStatus == 'all' ? '' : _selectedStatus} withdrawals',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWithdrawals,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredWithdrawals.length,
                        itemBuilder: (context, index) {
                          final withdrawal = _filteredWithdrawals[index];
                          return _buildWithdrawalCard(withdrawal);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedStatus = value);
      },
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal) {
    final status = withdrawal['status'] as String;
    final amount = (withdrawal['amount'] as num).toDouble();
    final createdAt = DateTime.parse(withdrawal['created_at']);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          currencyFormat.format(amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${withdrawal['user_id']}'),
            Text('Requested: ${DateFormat.yMMMd().add_jm().format(createdAt)}'),
          ],
        ),
        trailing: Chip(
          label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10)),
          backgroundColor: statusColor.withOpacity(0.1),
          labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Bank Account ID', withdrawal['bank_account_id']),
                _buildDetailRow('Processing Fee', currencyFormat.format(withdrawal['processing_fee'] ?? 0)),
                if (withdrawal['admin_notes'] != null)
                  _buildDetailRow('Admin Notes', withdrawal['admin_notes']),
                if (withdrawal['processed_at'] != null)
                  _buildDetailRow(
                    'Processed At',
                    DateFormat.yMMMd().add_jm().format(DateTime.parse(withdrawal['processed_at'])),
                  ),
                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _processWithdrawal(withdrawal['id'], 'Approve'),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _processWithdrawal(withdrawal['id'], 'Reject'),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.toString()),
          ),
        ],
      ),
    );
  }
}
