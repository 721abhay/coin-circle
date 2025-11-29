import 'package:coin_circle/features/wallet/presentation/screens/add_money_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/withdraw_funds_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/wallet_service.dart';

class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _walletData;
  List<Map<String, dynamic>> _transactions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final wallet = await WalletService.getWallet();
      final transactions = await WalletService.getTransactions(limit: 5);
      
      if (mounted) {
        setState(() {
          _walletData = wallet;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final available = (_walletData?['available_balance'] as num?)?.toDouble() ?? 0.0;
    final locked = (_walletData?['locked_balance'] as num?)?.toDouble() ?? 0.0;
    final winnings = (_walletData?['total_winnings'] as num?)?.toDouble() ?? 0.0;
    
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

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
            Text(
              currencyFormatter.format(available),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBalanceDetail('Locked', currencyFormatter.format(locked)),
                _buildBalanceDetail('Winnings', currencyFormatter.format(winnings)),
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
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMoneyScreen()),
              );
              _loadData(); // Refresh on return
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
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WithdrawFundsScreen()),
              );
              _loadData(); // Refresh on return
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
    if (_transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No transactions yet'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final type = tx['transaction_type'] as String;
        final amount = (tx['amount'] as num).toDouble();
        final date = DateTime.parse(tx['created_at']);
        final status = tx['status'] as String;
        
        IconData icon;
        Color color;
        String title;
        String amountPrefix;

        switch (type) {
          case 'deposit':
            icon = Icons.arrow_downward;
            color = Colors.green;
            title = 'Deposit';
            amountPrefix = '+';
            break;
          case 'withdrawal':
            icon = Icons.arrow_upward;
            color = Colors.red;
            title = 'Withdrawal';
            amountPrefix = '-';
            break;
          case 'contribution':
            icon = Icons.shopping_cart;
            color = Colors.orange;
            title = 'Pool Contribution';
            amountPrefix = '-';
            break;
          case 'winning':
            icon = Icons.card_giftcard;
            color = Colors.purple;
            title = 'Winnings';
            amountPrefix = '+';
            break;
          default:
            icon = Icons.receipt;
            color = Colors.grey;
            title = 'Transaction';
            amountPrefix = '';
        }

        final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
        final dateFormatter = DateFormat('MMM dd, yyyy HH:mm');

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(tx['description'] ?? title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateFormatter.format(date)),
              if (status != 'completed')
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == 'pending' ? Colors.orange.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: status == 'pending' ? Colors.orange.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          trailing: Text(
            '$amountPrefix ${currencyFormatter.format(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
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
