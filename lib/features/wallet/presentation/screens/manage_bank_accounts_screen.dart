import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/wallet_management_service.dart';

class ManageBankAccountsScreen extends StatefulWidget {
  const ManageBankAccountsScreen({super.key});

  @override
  State<ManageBankAccountsScreen> createState() => _ManageBankAccountsScreenState();
}

class _ManageBankAccountsScreenState extends State<ManageBankAccountsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _bankAccounts = [];

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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading accounts: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setPrimaryAccount(String accountId) async {
    try {
      await WalletManagementService.setPrimaryBankAccount(accountId);
      _loadBankAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primary account updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteAccount(String accountId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank Account'),
        content: const Text('Are you sure you want to delete this bank account?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await WalletManagementService.deleteBankAccount(accountId);
      _loadBankAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddAccountDialog() {
    final formKey = GlobalKey<FormState>();
    final holderNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final bankNameController = TextEditingController();
    final ifscController = TextEditingController();
    String accountType = 'savings';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bank Account'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: holderNameController,
                  decoration: const InputDecoration(labelText: 'Account Holder Name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v!)) {
                      return 'Only letters and spaces allowed';
                    }
                    if (v.length < 3) return 'Name must be at least 3 characters';
                    return null;
                  },
                ),
                TextFormField(
                  controller: accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    hintText: '9-18 digits',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    if (!RegExp(r'^[0-9]+$').hasMatch(v!)) {
                      return 'Only numbers allowed';
                    }
                    if (v.length < 9 || v.length > 18) {
                      return 'Account number must be 9-18 digits';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: bankNameController,
                  decoration: const InputDecoration(labelText: 'Bank Name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v!)) {
                      return 'Only letters and spaces allowed';
                    }
                    if (v.length < 3) return 'Bank name must be at least 3 characters';
                    return null;
                  },
                ),
                TextFormField(
                  controller: ifscController,
                  decoration: const InputDecoration(
                    labelText: 'IFSC Code',
                    hintText: 'e.g., SBIN0001234',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 11,
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    final ifsc = v!.toUpperCase();
                    if (ifsc.length != 11) return 'IFSC code must be 11 characters';
                    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
                      return 'Invalid IFSC format (e.g., SBIN0001234)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: accountType,
                  decoration: const InputDecoration(labelText: 'Account Type'),
                  items: const [
                    DropdownMenuItem(value: 'savings', child: Text('Savings')),
                    DropdownMenuItem(value: 'checking', child: Text('Checking')),
                  ],
                  onChanged: (value) => accountType = value ?? 'savings',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;

              try {
                await WalletManagementService.addBankAccount(
                  accountHolderName: holderNameController.text,
                  accountNumber: accountNumberController.text,
                  bankName: bankNameController.text,
                  ifscCode: ifscController.text,
                  accountType: accountType,
                  isPrimary: _bankAccounts.isEmpty,
                );
                if (context.mounted) {
                  context.pop();
                  _loadBankAccounts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bank account added')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bank Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAccountDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bankAccounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No bank accounts added'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddAccountDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Bank Account'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bankAccounts.length,
                  itemBuilder: (context, index) {
                    final account = _bankAccounts[index];
                    final isPrimary = account['is_primary'] == true;
                    final isVerified = account['is_verified'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(Icons.account_balance, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(account['bank_name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${account['account_holder_name']}'),
                            Text(() {
                              final accountNum = account['account_number'].toString();
                              if (accountNum.length >= 4) {
                                return '****${accountNum.substring(accountNum.length - 4)}';
                              } else {
                                return accountNum; // Show full number if less than 4 digits
                              }
                            }()),
                            Row(
                              children: [
                                if (isPrimary)
                                  const Chip(
                                    label: Text('Primary', style: TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (isPrimary) const SizedBox(width: 4),
                                if (isVerified)
                                  const Chip(
                                    label: Text('Verified', style: TextStyle(fontSize: 10)),
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            if (!isPrimary)
                              const PopupMenuItem(
                                value: 'primary',
                                child: Text('Set as Primary'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'primary') {
                              _setPrimaryAccount(account['id']);
                            } else if (value == 'delete') {
                              _deleteAccount(account['id']);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _bankAccounts.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddAccountDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
