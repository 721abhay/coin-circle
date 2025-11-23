
import 'package:coin_circle/features/wallet/presentation/screens/add_money_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/withdraw_funds_screen.dart';
import 'package:flutter/material.dart';

class WalletDashboardScreen extends StatelessWidget {
  const WalletDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Section
            _buildBalanceCard(context),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context),
            const SizedBox(height: 32),

            // Transaction History
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Balance',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '₹1,250.75',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBalanceDetail('Locked', '₹500.00'),
                _buildBalanceDetail('Winnings', '₹2,300.00'),
                _buildBalanceDetail('Pending', '₹150.00'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceDetail(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Money'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMoneyScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('Withdraw'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WithdrawFundsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    // Dummy data for now
    final transactions = [
      {'icon': Icons.arrow_downward, 'color': Colors.green, 'title': 'Deposit from Bank', 'amount': '+ ₹1,000.00', 'date': 'June 28, 2024'},
      {'icon': Icons.shopping_cart, 'color': Colors.red, 'title': 'Contribution to 'Weekend Pool'', 'amount': '- ₹250.00', 'date': 'June 27, 2024'},
      {'icon': Icons.card_giftcard, 'color': Colors.green, 'title': 'Winnings from 'Monthly Saver'', 'amount': '+ ₹1,500.00', 'date': 'June 25, 2024'},
      {'icon': Icons.arrow_upward, 'color': Colors.red, 'title': 'Withdrawal to Bank', 'amount': '- ₹500.00', 'date': 'June 24, 2024'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return ListTile(
          leading: Icon(tx['icon'] as IconData, color: tx['color'] as Color),
          title: Text(tx['title'] as String),
          subtitle: Text(tx['date'] as String),
          trailing: Text(
            tx['amount'] as String,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tx['color'] as Color,
            ),
          ),
          onTap: () {
            // TODO: Show transaction details
          },
        );
      },
    );
  }
}
