import 'package:flutter/material.dart';

class FinancialControlsScreen extends StatelessWidget {
  final String? poolId;
  const FinancialControlsScreen({super.key, this.poolId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Controls')),
      body: ListView(
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
            () {},
          ),
          _buildActionTile(
            context,
            'Manual Payment',
            'Record an offline payment',
            Icons.payments_outlined,
            () {},
          ),
          _buildActionTile(
            context,
            'Adjust Balance',
            'Credit/Debit member wallet',
            Icons.account_balance_wallet_outlined,
            () {},
          ),
          _buildActionTile(
            context,
            'Process Refund',
            'Return funds to source',
            Icons.replay,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Financial Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatRow('Total Collected', '₹1,20,000'),
            const Divider(),
            _buildStatRow('Outstanding', '₹5,000', color: Colors.red),
            const Divider(),
            _buildStatRow('Late Fees', '₹250'),
            const Divider(),
            _buildStatRow('Next Payout', '₹25,000'),
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
