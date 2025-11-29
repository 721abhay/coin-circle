import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/services/bank_service.dart';

class AddBankAccountScreen extends StatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final BankService _bankService = BankService();
  
  final _accountHolderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  
  String _accountType = 'savings';
  bool _setPrimary = false;
  bool _isLoading = false;
  bool _ifscVerified = false;

  @override
  void dispose() {
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _ifscCodeController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    super.dispose();
  }

  Future<void> _verifyIFSC() async {
    final ifsc = _ifscCodeController.text.trim().toUpperCase();
    if (ifsc.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IFSC code must be 11 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final details = await _bankService.getBankDetailsFromIFSC(ifsc);
      setState(() {
        _bankNameController.text = details['bank_name'] ?? '';
        _branchNameController.text = details['branch_name'] ?? '';
        _ifscVerified = true;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IFSC verified successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying IFSC: $e')),
        );
      }
    }
  }

  Future<void> _addBankAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (_accountNumberController.text != _confirmAccountNumberController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account numbers do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _bankService.addBankAccount(
        accountHolderName: _accountHolderNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscCodeController.text.trim().toUpperCase(),
        bankName: _bankNameController.text.trim(),
        branchName: _branchNameController.text.trim(),
        accountType: _accountType,
        setPrimary: _setPrimary,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank account added successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding bank account: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bank Account'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account Holder Name
            TextFormField(
              controller: _accountHolderNameController,
              decoration: const InputDecoration(
                labelText: 'Account Holder Name',
                hintText: 'Enter name as per bank records',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter account holder name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Account Number
            TextFormField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                hintText: 'Enter your account number',
                prefixIcon: Icon(Icons.account_balance),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter account number';
                }
                if (value.length < 9 || value.length > 18) {
                  return 'Invalid account number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Account Number
            TextFormField(
              controller: _confirmAccountNumberController,
              decoration: const InputDecoration(
                labelText: 'Confirm Account Number',
                hintText: 'Re-enter your account number',
                prefixIcon: Icon(Icons.account_balance),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please confirm account number';
                }
                if (value != _accountNumberController.text) {
                  return 'Account numbers do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // IFSC Code
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ifscCodeController,
                    decoration: InputDecoration(
                      labelText: 'IFSC Code',
                      hintText: 'Enter 11-digit IFSC code',
                      prefixIcon: const Icon(Icons.code),
                      suffixIcon: _ifscVerified
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 11,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter IFSC code';
                      }
                      if (value.length != 11) {
                        return 'IFSC code must be 11 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyIFSC,
                  child: const Text('Verify'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bank Name (auto-filled)
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                hintText: 'Will be auto-filled after IFSC verification',
                prefixIcon: Icon(Icons.business),
              ),
              readOnly: _ifscVerified,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter bank name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Branch Name (auto-filled)
            TextFormField(
              controller: _branchNameController,
              decoration: const InputDecoration(
                labelText: 'Branch Name',
                hintText: 'Will be auto-filled after IFSC verification',
                prefixIcon: Icon(Icons.location_on),
              ),
              readOnly: _ifscVerified,
            ),
            const SizedBox(height: 16),

            // Account Type
            DropdownButtonFormField<String>(
              value: _accountType,
              decoration: const InputDecoration(
                labelText: 'Account Type',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              items: const [
                DropdownMenuItem(value: 'savings', child: Text('Savings')),
                DropdownMenuItem(value: 'current', child: Text('Current')),
              ],
              onChanged: (value) {
                setState(() => _accountType = value ?? 'savings');
              },
            ),
            const SizedBox(height: 16),

            // Set as Primary
            SwitchListTile(
              title: const Text('Set as Primary Account'),
              subtitle: const Text('Use this account for all transactions'),
              value: _setPrimary,
              onChanged: (value) {
                setState(() => _setPrimary = value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your bank account will be verified before you can receive payouts',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Add Button
            ElevatedButton(
              onPressed: _isLoading ? null : _addBankAccount,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ADD BANK ACCOUNT'),
            ),
          ],
        ),
      ),
    );
  }
}
