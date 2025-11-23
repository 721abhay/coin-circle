import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/services/wallet_management_service.dart';

class PayoutScreen extends StatefulWidget {
  final double amount;

  const PayoutScreen({super.key, this.amount = 2500.00});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  int _currentStep = 0;
  int _selectedMethod = 0;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _bankAccounts = [];
  String? _selectedBankAccountId;
  bool _isLoading = true;

  // Bank Details Controllers
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingNumberController = TextEditingController(); // IFSC for India

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
  }

  Future<void> _loadBankAccounts() async {
    try {
      final accounts = await WalletManagementService.getBankAccounts();
      if (mounted) {
        setState(() {
          _bankAccounts = accounts;
          if (_bankAccounts.isNotEmpty) {
            _selectedBankAccountId = _bankAccounts.first['id'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Don't show error snackbar here to avoid clutter, just log or silent fail
        print('Error loading bank accounts: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw Funds')),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _handleStepContinue,
        onStepCancel: _handleStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : details.onStepContinue,
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_currentStep == 3 ? 'Confirm Payout' : 'Continue'),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Amount'),
            content: _buildAmountStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Method'),
            content: _buildMethodStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Details'),
            content: _buildDetailsStep(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text('Confirm'),
            content: _buildConfirmStep(),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.editing,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountStep() {
    final double processingFee = 5.00;
    final double netAmount = widget.amount - processingFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payout Breakdown',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Pool Contribution', widget.amount),
              const SizedBox(height: 8),
              _buildSummaryRow('Processing Fee', -processingFee, isDeduction: true),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
              _buildSummaryRow('Net Payout', netAmount, isTotal: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Expected Payout Date',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(DateFormat('MMMM dd, yyyy').format(DateTime.now().add(const Duration(days: 2)))),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodStep() {
    return Column(
      children: [
        _buildMethodOption(0, 'Bank Transfer (ACH)', '1-3 business days', Icons.account_balance),
        _buildMethodOption(1, 'Mailed Check', '5-7 business days', Icons.mail_outline),
        _buildMethodOption(2, 'Digital Wallet', 'Instant', Icons.account_balance_wallet),
      ],
    );
  }

  Widget _buildMethodOption(int index, String title, String subtitle, IconData icon) {
    final isSelected = _selectedMethod == index;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = index),
        borderRadius: BorderRadius.circular(12),
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
              if (isSelected) Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    if (_selectedMethod != 0) {
      return const Center(child: Text('Only Bank Transfer is currently supported.'));
    }
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_bankAccounts.isNotEmpty) ...[
          Text(
            'Select Bank Account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBankAccountId,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _bankAccounts.map((account) {
              return DropdownMenuItem<String>(
                value: account['id'],
                child: Text('${account['bank_name']} - ${account['account_number'].toString().substring(account['account_number'].toString().length - 4)}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBankAccountId = value;
              });
            },
          ),
          const SizedBox(height: 24),
          const Text('OR Enter New Account Details', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
        ],
        
        TextField(
          controller: _bankNameController,
          decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _accountHolderController,
          decoration: const InputDecoration(labelText: 'Account Holder Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _accountNumberController,
          decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _routingNumberController,
          decoration: const InputDecoration(labelText: 'IFSC Code', border: OutlineInputBorder()),
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Payout Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Amount', '₹${(widget.amount - 5.00).toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        _buildDetailRow('Method', _getMethodName(_selectedMethod)),
        const SizedBox(height: 12),
        _buildDetailRow('Expected Date', DateFormat('MMM dd, yyyy').format(DateTime.now().add(const Duration(days: 2)))),
        if (_selectedMethod == 0) ...[
          const SizedBox(height: 12),
          _buildDetailRow('Bank', _bankNameController.text),
          const SizedBox(height: 12),
          _buildDetailRow('Account', '****${_accountNumberController.text.length > 4 ? _accountNumberController.text.substring(_accountNumberController.text.length - 4) : _accountNumberController.text}'),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'By confirming, you agree to the terms of service and payout processing times.',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMethodName(int index) {
    switch (index) {
      case 0:
        return 'Bank Transfer (ACH)';
      case 1:
        return 'Mailed Check';
      case 2:
        return 'Digital Wallet';
      default:
        return 'Unknown';
    }
  }

  Widget _buildSummaryRow(String label, double value, {bool isDeduction = false, bool isTotal = false}) {
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
          '${isDeduction ? '-' : ''}₹${value.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isDeduction ? Colors.red : (isTotal ? Theme.of(context).primaryColor : null),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _handleStepContinue() {
    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
    } else {
      _processPayout();
    }
  }

  void _handleStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      context.pop();
    }
  }

  void _processPayout() async {
    setState(() => _isProcessing = true);
    
    try {
      if (_selectedMethod != 0) {
        throw Exception('Only Bank Transfer is currently supported');
      }

      String bankAccountId;

      // If manual details entered, create new account first
      if (_bankNameController.text.isNotEmpty && _accountNumberController.text.isNotEmpty) {
        bankAccountId = await WalletManagementService.addBankAccount(
          accountHolderName: _accountHolderController.text,
          accountNumber: _accountNumberController.text,
          bankName: _bankNameController.text,
          ifscCode: _routingNumberController.text,
          accountType: 'savings', // Default
        );
      } else if (_selectedBankAccountId != null) {
        bankAccountId = _selectedBankAccountId!;
      } else {
        throw Exception('Please select or enter bank account details');
      }

      await WalletManagementService.requestWithdrawal(
        amount: widget.amount,
        bankAccountId: bankAccountId,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PayoutSuccessScreen(
              amount: widget.amount - 5.00,
              method: _getMethodName(_selectedMethod),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payout failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class PayoutSuccessScreen extends StatelessWidget {
  final double amount;
  final String method;

  const PayoutSuccessScreen({super.key, required this.amount, required this.method});

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
                  'Payout Initiated!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Your withdrawal of ₹${amount.toStringAsFixed(2)} via $method is being processed.',
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
                      _buildReceiptRow('Transaction ID', 'PAY-${DateTime.now().millisecondsSinceEpoch}'),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())),
                      const SizedBox(height: 12),
                      _buildReceiptRow('Status', 'Processing'),
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
                        child: const Text('Download Receipt'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/wallet'),
                        child: const Text('Back to Wallet'),
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
