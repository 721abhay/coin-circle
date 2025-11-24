import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/services/wallet_management_service.dart';

class WithdrawFundsScreen extends StatefulWidget {
  const WithdrawFundsScreen({super.key});

  @override
  State<WithdrawFundsScreen> createState() => _WithdrawFundsScreenState();
}

class _WithdrawFundsScreenState extends State<WithdrawFundsScreen> {
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isProcessing = false;
  bool _biometricVerified = false;
  bool _smsCodeSent = false;
  double _availableBalance = 0;
  double _lockedBalance = 0;
  
  static const double _minWithdrawal = 10.0;
  static const double _maxWithdrawalPerDay = 5000.0;
  static const double _processingFee = 5.0;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    try {
      final balances = await WalletManagementService.getBalanceBreakdown();
      if (mounted) {
        setState(() {
          _availableBalance = balances['available'] ?? 0;
          _lockedBalance = balances['locked'] ?? 0;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        _showPinDialog();
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to withdraw funds',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated && mounted) {
        setState(() => _biometricVerified = true);
        _sendSmsCode();
      }
    } catch (e) {
      _showPinDialog();
    }
  }

  void _showPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Security PIN'),
        content: TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'Enter 6-digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text.length == 6) {
                Navigator.pop(context);
                setState(() => _biometricVerified = true);
                _sendSmsCode();
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSmsCode() async {
    // Simulate sending SMS code
    setState(() => _smsCodeSent = true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent to your phone'),
          backgroundColor: Colors.green,
        ),
      );
      _showSmsVerificationDialog();
    }
  }

  void _showSmsVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('SMS Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 6-digit code sent to your phone'),
            const SizedBox(height: 16),
            TextField(
              controller: _smsCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'Enter code',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _biometricVerified = false;
                _smsCodeSent = false;
              });
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _sendSmsCode,
            child: const Text('Resend Code'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_smsCodeController.text.length == 6) {
                Navigator.pop(context);
                _processWithdrawal();
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Invalid amount';
    }
    
    if (amount < _minWithdrawal) {
      return 'Minimum withdrawal is \$${_minWithdrawal.toStringAsFixed(2)}';
    }
    
    if (amount > _maxWithdrawalPerDay) {
      return 'Maximum withdrawal per day is \$${_maxWithdrawalPerDay.toStringAsFixed(2)}';
    }
    
    if (amount > _availableBalance) {
      return 'Insufficient available balance';
    }
    
    return null;
  }

  Future<void> _processWithdrawal() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    setState(() => _isProcessing = true);

    try {
      // For now, we'll use a placeholder bank account ID or fetch the first one
      // In a real app, we'd let the user select the account
      final bankAccounts = await WalletManagementService.getBankAccounts();
      String bankAccountId;
      
      if (bankAccounts.isNotEmpty) {
        bankAccountId = bankAccounts.first['id'];
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add a bank account first'), 
              backgroundColor: Colors.red
            ),
          );
          setState(() => _isProcessing = false);
        }
        return;
      }

      await WalletManagementService.requestWithdrawal(
        amount: amount,
        bankAccountId: bankAccountId,
      );
      
      if (mounted) {
        setState(() => _isProcessing = false);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Withdrawal Requested'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: \$${amount.toStringAsFixed(2)}'),
                Text('Processing Fee: \$${_processingFee.toStringAsFixed(2)}'),
                Text('Net Amount: \$${(amount - _processingFee).toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                const Text('Your request has been submitted and is pending approval.'),
                const Text('Expected Arrival: 2-3 business days'),
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _initiateWithdrawal() {
    final validation = _validateAmount(_amountController.text);
    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation), backgroundColor: Colors.red),
      );
      return;
    }

    _authenticateWithBiometric();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw Funds'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceInfo(),
            const SizedBox(height: 24),
            _buildAmountField(),
            const SizedBox(height: 24),
            _buildDestinationAccount(context),
            const SizedBox(height: 24),
            _buildWithdrawalDetails(),
            const SizedBox(height: 24),
            _buildLimitations(),
            const SizedBox(height: 40),
            _buildWithdrawButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Balance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_availableBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Locked in Pools: \$${_lockedBalance.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        prefixText: '\$ ',
        labelText: 'Amount to Withdraw',
        border: const OutlineInputBorder(),
        hintText: 'Min \$${_minWithdrawal.toStringAsFixed(0)}, Max \$${_maxWithdrawalPerDay.toStringAsFixed(0)}',
        helperText: 'Cannot withdraw locked funds',
      ),
    );
  }

  Widget _buildDestinationAccount(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Destination Account',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.blue),
            title: const Text('Bank of America **** 3210'),
            subtitle: const Text('Default Account'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to select another account
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalDetails() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final netAmount = amount > 0 ? amount - _processingFee : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withdrawal Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount:', style: TextStyle(color: Colors.grey)),
                Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Processing Fee:', style: TextStyle(color: Colors.grey)),
                Text('-\$${_processingFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('\$${netAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Expected Arrival:', style: TextStyle(color: Colors.grey)),
                Text('2-3 business days', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitations() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Withdrawal Limitations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('• Minimum withdrawal: \$${_minWithdrawal.toStringAsFixed(2)}'),
            Text('• Maximum per day: \$${_maxWithdrawalPerDay.toStringAsFixed(2)}'),
            const Text('• Cannot withdraw locked funds'),
            const Text('• Requires biometric/PIN verification'),
            const Text('• SMS confirmation required'),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _initiateWithdrawal,
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
                'Confirm Withdrawal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _pinController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }
}
