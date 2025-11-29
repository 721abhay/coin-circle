import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/wallet_service.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  double _selectedAmount = 0;
  bool _isProcessing = false;

  final List<double> _quickAmounts = [100, 500, 1000, 2000, 5000];
  
  // ⚠️ IMPORTANT: UPDATE THESE WITH YOUR REAL BANK DETAILS BEFORE LAUNCH! ⚠️
  // Admin Bank Details - Users will transfer money to these accounts
  // TODO: Replace with your actual UPI ID, Bank Name, Account Number, and IFSC Code
  final String _adminUpiId = 'admin@coincircle';  // ← UPDATE THIS
  final String _adminBankName = 'HDFC Bank';      // ← UPDATE THIS
  final String _adminAccountNo = '50100123456789'; // ← UPDATE THIS
  final String _adminIfsc = 'HDFC0001234';        // ← UPDATE THIS

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _submitDepositRequest() async {
    final amount = double.tryParse(_amountController.text);
    final reference = _referenceController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
      );
      return;
    }

    if (reference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the Transaction Reference ID'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await WalletService.requestDeposit(
        amount: amount,
        transactionReference: reference,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Request Submitted'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                const Text('Your deposit request has been submitted successfully.'),
                const SizedBox(height: 8),
                const Text(
                  'The amount will be credited to your wallet once the admin verifies your transaction (usually within 1-2 hours).',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
    );
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
            // Step 1: Enter Amount
            Text(
              'Step 1: Enter Amount',
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
            const SizedBox(height: 32),

            // Step 2: Make Payment
            Text(
              'Step 2: Transfer Money',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Send money to the following account:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildCopyRow('UPI ID', _adminUpiId),
                  const Divider(),
                  _buildCopyRow('Bank Name', _adminBankName),
                  const SizedBox(height: 8),
                  _buildCopyRow('Account No', _adminAccountNo),
                  const SizedBox(height: 8),
                  _buildCopyRow('IFSC Code', _adminIfsc),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Step 3: Enter Reference
            Text(
              'Step 3: Submit Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Transaction Reference ID / UTR',
                hintText: 'e.g. 123456789012',
                border: OutlineInputBorder(),
                helperText: 'Enter the reference number from your payment app',
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isProcessing || _selectedAmount <= 0 ? null : _submitDepositRequest,
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
                  : const Text(
                      'Submit Request',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () => _copyToClipboard(value),
          color: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}
