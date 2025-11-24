import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/wallet_service.dart';
import '../../../../core/services/payment_service.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _amountController = TextEditingController();
  double _selectedAmount = 0;
  bool _isProcessing = false;

  final List<double> _quickAmounts = [100, 500, 1000, 2000, 5000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _processDeposit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Process Payment via Gateway (Simulated)
      final paymentResult = await PaymentService.processPayment(
        amount: amount,
        method: 'card', // In a real app, this would come from the selected method
        currency: 'INR',
      );

      if (paymentResult['success'] == true) {
        // 2. If successful, update wallet balance
        await WalletService.deposit(
          amount: amount,
          method: 'card',
          reference: paymentResult['transactionId'],
        );

        if (mounted) {
          setState(() => _isProcessing = false);
          
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Payment Successful'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  Text('Transaction ID: ${paymentResult['transactionId']}'),
                  const SizedBox(height: 8),
                  Text('Amount Added: ₹${amount.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Your wallet balance has been updated.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    context.pop(); // Close dialog
                    context.pop(); // Go back to wallet
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Money'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick Amount Selection
            Text(
              'Quick Select',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amount) {
                final isSelected = _selectedAmount == amount;
                return ChoiceChip(
                  label: Text('₹${amount.toStringAsFixed(0)}'),
                  selected: isSelected,
                  onSelected: (selected) => _selectQuickAmount(amount),
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Custom Amount Input
            Text(
              'Or Enter Custom Amount',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                hintText: 'Enter amount',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value);
                setState(() {
                  _selectedAmount = amount ?? 0;
                });
              },
            ),
            const SizedBox(height: 24),

            // Payment Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Amount', '₹${_selectedAmount.toStringAsFixed(2)}'),
                    _buildSummaryRow('Processing Fee', '₹0.00'),
                    const Divider(),
                    _buildSummaryRow(
                      'Total',
                      '₹${_selectedAmount.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method (Placeholder)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.credit_card),
                      title: const Text('Credit/Debit Card'),
                      subtitle: const Text('Visa, Mastercard, RuPay'),
                      trailing: Radio(value: true, groupValue: true, onChanged: null),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.account_balance),
                      title: const Text('Net Banking'),
                      subtitle: const Text('All major banks'),
                      trailing: Radio(value: false, groupValue: true, onChanged: null),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.wallet),
                      title: const Text('UPI'),
                      subtitle: const Text('Google Pay, PhonePe, Paytm'),
                      trailing: Radio(value: false, groupValue: true, onChanged: null),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Proceed Button
            ElevatedButton(
              onPressed: _isProcessing || _selectedAmount <= 0 ? null : _processDeposit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Proceed to Pay ₹${_selectedAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
