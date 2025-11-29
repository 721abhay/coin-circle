import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/wallet_management_service.dart';

class AdminFinancialsView extends ConsumerStatefulWidget {
  const AdminFinancialsView({super.key});

  @override
  ConsumerState<AdminFinancialsView> createState() => _AdminFinancialsViewState();
}

class _AdminFinancialsViewState extends ConsumerState<AdminFinancialsView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Control',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, dynamic>>(
            future: AdminService.getPlatformStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final stats = snapshot.data!;
              final totalVolume = stats['total_volume'] ?? 0.0;
              final formatter = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: _buildBalanceCard(
                        'Total Volume', 
                        formatter.format(totalVolume), 
                        Colors.blue
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 200,
                      child: _buildBalanceCard(
                        'Active Pools', 
                        '${stats['active_pools'] ?? 0}', 
                        Colors.green
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 200,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: AdminService.getAllWithdrawalRequests(),
                        builder: (context, withdrawalSnapshot) {
                          final pendingCount = withdrawalSnapshot.data
                              ?.where((w) => w['status'] == 'pending')
                              .length ?? 0;
                          return _buildBalanceCard(
                            'Pending Withdrawals', 
                            '$pendingCount', 
                            Colors.orange
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Global Transaction Log',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchRecentTransactions(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final transactions = snapshot.data!;
                  if (transactions.isEmpty) {
                    return const Center(child: Text('No transactions yet'));
                  }
                  
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final txn = transactions[index];
                      final isCredit = txn['transaction_type'] == 'deposit' || 
                                      txn['transaction_type'] == 'contribution';
                      final amount = (txn['amount'] as num?)?.toDouble() ?? 0.0;
                      final userName = txn['user']?['full_name'] ?? 'Unknown';
                      final createdAt = txn['created_at'] != null
                          ? DateTime.parse(txn['created_at'])
                          : DateTime.now();
                      final formatter = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                          child: Icon(
                            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isCredit ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text('${txn['transaction_type']?.toString().toUpperCase() ?? 'TRANSACTION'} #${txn['id'].toString().substring(0, 8)}'),
                        subtitle: Text('User: $userName • ${DateFormat('MMM d, HH:mm').format(createdAt)}'),
                        trailing: Text(
                          formatter.format(amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCredit ? Colors.green : Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRecentTransactions() async {
    try {
      final response = await WalletManagementService.client
          .from('transactions')
          .select('*, user:profiles(full_name)')
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(20);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  Widget _buildBalanceCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
