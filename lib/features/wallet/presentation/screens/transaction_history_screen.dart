import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/wallet_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _filter = 'All';
  String? _selectedPool;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await WalletService.getTransactions(
        limit: 50,
        type: _filter == 'All' ? null : _filter.toLowerCase(),
      );
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    
    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
        _isLoading = true;
      });
      _loadTransactions();
    }
  }

  void _clearDateRange() {
    setState(() {
      _dateRange = null;
      _isLoading = true;
    });
    _loadTransactions();
  }

  void _downloadReceipt(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Transaction ID: ${transaction['id']}'),
              const SizedBox(height: 8),
              Text('Date: ${DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(transaction['created_at']))}'),
              const SizedBox(height: 8),
              Text('Type: ${transaction['transaction_type'].toString().toUpperCase()}'),
              const SizedBox(height: 8),
              Text('Amount: \$${(transaction['amount'] as num).abs().toStringAsFixed(2)}'),
              if (transaction['pool_name'] != null) ...[
                const SizedBox(height: 8),
                Text('Pool: ${transaction['pool_name']}'),
              ],
              const SizedBox(height: 8),
              Text('Status: ${transaction['status'] ?? 'Completed'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt downloaded')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    var filtered = _transactions;
    
    // Filter by date range
    if (_dateRange != null) {
      filtered = filtered.where((t) {
        final date = DateTime.parse(t['created_at']);
        return date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    // Filter by pool
    if (_selectedPool != null && _selectedPool != 'All Pools') {
      filtered = filtered.where((t) => t['pool_name'] == _selectedPool).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Filter by date',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filter = value;
                _isLoading = true;
              });
              _loadTransactions();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Transactions')),
              const PopupMenuItem(value: 'deposit', child: Text('Deposits')),
              const PopupMenuItem(value: 'withdrawal', child: Text('Withdrawals')),
              const PopupMenuItem(value: 'contribution', child: Text('Contributions')),
              const PopupMenuItem(value: 'winning', child: Text('Winnings')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_dateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_dateRange!.end)}',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _clearDateRange,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          _buildPoolFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _filteredTransactions[index];
                          final type = transaction['transaction_type'];
                          final isPositive = type == 'deposit' || type == 'winning';
                          final amount = (transaction['amount'] as num).abs();
                          final date = DateTime.parse(transaction['created_at']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                                child: Icon(
                                  isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isPositive ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(transaction['description'] ?? type.toString().toUpperCase()),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DateFormat('MMM d, yyyy • h:mm a').format(date)),
                                  if (transaction['pool_name'] != null)
                                    Text(
                                      'Pool: ${transaction['pool_name']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  Text(
                                    'Status: ${transaction['status'] ?? 'Completed'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isPositive ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPositive ? Colors.green : Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.receipt, size: 18),
                                    onPressed: () => _downloadReceipt(transaction),
                                    tooltip: 'View Receipt',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              isThreeLine: transaction['pool_name'] != null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolFilter() {
    // Get unique pool names from transactions
    final poolNames = _transactions
        .where((t) => t['pool_name'] != null)
        .map((t) => t['pool_name'] as String)
        .toSet()
        .toList();
    
    if (poolNames.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Pool: ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('All Pools'),
              selected: _selectedPool == null || _selectedPool == 'All Pools',
              onSelected: (selected) {
                setState(() {
                  _selectedPool = selected ? 'All Pools' : null;
                });
              },
            ),
            const SizedBox(width: 8),
            ...poolNames.map((pool) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(pool),
                selected: _selectedPool == pool,
                onSelected: (selected) {
                  setState(() {
                    _selectedPool = selected ? pool : null;
                  });
                },
              ),
            )),
          ],
        ),
      ),
    );
  }
}
