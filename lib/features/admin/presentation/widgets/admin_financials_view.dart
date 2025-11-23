import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: _buildBalanceCard('System Wallet', '₹1,24,500', Colors.blue),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  child: _buildBalanceCard('Fees Collected', '₹12,450', Colors.green),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  child: _buildBalanceCard('Pending Withdrawals', '₹5,000', Colors.orange),
                ),
              ],
            ),
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
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 10, // Placeholder
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index % 2 == 0 ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(
                        index % 2 == 0 ? Icons.arrow_downward : Icons.arrow_upward,
                        color: index % 2 == 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text('Transaction #${1000 + index}'),
                    subtitle: Text('User: John Doe • ${DateTime.now().subtract(Duration(minutes: index * 15)).toString().substring(0, 16)}'),
                    trailing: Text(
                      '₹${(index + 1) * 500}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: index % 2 == 0 ? Colors.green : Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
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
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('+12% this week', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
