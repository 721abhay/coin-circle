import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/services/wallet_service.dart';
import '../../../../core/services/pool_service.dart';

class PaymentScreen extends StatefulWidget {
  final String poolId;
  final double amount;

  const PaymentScreen({super.key, required this.poolId, required this.amount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0;
  bool _autoPayEnabled = false;
  bool _isProcessing = false;
  Map<String, dynamic>? _pool;
  int _currentRound = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoolDetails();
  }

  Future<void> _loadPoolDetails() async {
    try {
      final pool = await PoolService.getPoolDetails(widget.poolId);
      if (mounted) {
        setState(() {
          _pool = pool;
          _calculateCurrentRound();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pool details: $e')),
        );
      }
    }
  }

  void _calculateCurrentRound() {
    if (_pool == null) return;
    final startDate = DateTime.parse(_pool!['start_date']);
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;
    // Simple monthly calculation (30 days approx)
    _currentRound = (difference / 30).floor() + 1;
    if (_currentRound < 1) _currentRound = 1;
    // Clamp to total rounds if available
    if (_pool!['total_rounds'] != null) {
      if (_currentRound > _pool!['total_rounds']) {
        _currentRound = _pool!['total_rounds'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double processingFee = widget.amount * 0.01; // 1% fee
    final double totalAmount = widget.amount + processingFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Make Payment')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPoolHeader(context),
                    const SizedBox(height: 24),
                    _buildAmountCard(context),
                    const SizedBox(height: 32),
                    Text(
                      'Select Payment Method',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentMethod(0, 'Wallet Balance', 'Available: ₹2,450.00', Icons.account_balance_wallet),
                    _buildPaymentMethod(1, 'Bank Account', 'Chase **** 1234', Icons.account_balance),
                    _buildPaymentMethod(2, 'Credit Card', 'Visa **** 5678', Icons.credit_card),
                    const SizedBox(height: 24),
                    _buildAutoPayToggle(),
                    const SizedBox(height: 24),
                    _buildPaymentBreakdown(widget.amount, processingFee, totalAmount),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _showConfirmationDialog(context, totalAmount),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Pay ₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.groups, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_pool?['name'] ?? 'Pool Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Cycle $_currentRound of ${_pool?['total_rounds'] ?? 10}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Amount Due',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${widget.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Due in 2 days',
              style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(int index, String title, String subtitle, IconData icon) {
    final isSelected = _selectedMethod == index;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Colors.grey.shade700),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoPayToggle() {
    return SwitchListTile(
      value: _autoPayEnabled,
      onChanged: (value) => setState(() => _autoPayEnabled = value),
      title: const Text('Enable Auto-Pay', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('Automatically pay 3 days before due date'),
      secondary: const Icon(Icons.autorenew),
      contentPadding: EdgeInsets.zero,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildPaymentBreakdown(double amount, double fee, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildBreakdownRow('Contribution', amount),
          const SizedBox(height: 8),
          _buildBreakdownRow('Processing Fee', fee),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
          _buildBreakdownRow('Total', total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double value, {bool isTotal = false}) {
    return Row(
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
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context, double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Are you sure you want to pay ₹${total.toStringAsFixed(2)}?'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.pop();
              _processPayment();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);
    
    try {
      // Only support wallet balance for now as per requirement
      if (_selectedMethod != 0) {
        throw Exception('Only Wallet Balance payment is currently supported');
      }

      await WalletService.contributeToPool(
        poolId: widget.poolId,
        amount: widget.amount,
        round: _currentRound,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(
          amount: widget.amount,
          transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final double amount;
  final String transactionId;

  const PaymentSuccessScreen({super.key, required this.amount, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ZoomIn(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 64, color: Colors.green),
                ),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                child: Text(
                  'Payment Successful!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'You have successfully contributed ₹${amount.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const SizedBox(height: 48),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildReceiptRow('Transaction ID', transactionId),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Payment Method', 'Wallet Balance'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Share Receipt'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
