import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/pool_service.dart';

class MyPoolsScreen extends StatefulWidget {
  const MyPoolsScreen({super.key});

  @override
  State<MyPoolsScreen> createState() => _MyPoolsScreenState();
}

class _MyPoolsScreenState extends State<MyPoolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filter state
  Set<String> _selectedPaymentStatuses = {};
  Set<String> _selectedRoles = {};
  
  // Sort state
  String _sortBy = 'name'; // 'name', 'amount', 'next_payment', 'next_draw'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pools'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PoolList(
            status: 'Active',
            paymentStatusFilter: _selectedPaymentStatuses,
            roleFilter: _selectedRoles,
            sortBy: _sortBy,
          ),
          _PoolList(
            status: 'Pending',
            paymentStatusFilter: _selectedPaymentStatuses,
            roleFilter: _selectedRoles,
            sortBy: _sortBy,
          ),
          _PoolList(
            status: 'Completed',
            paymentStatusFilter: _selectedPaymentStatuses,
            roleFilter: _selectedRoles,
            sortBy: _sortBy,
          ),
        ],
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Sort by Next Payment'),
            trailing: _sortBy == 'next_payment' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _sortBy = 'next_payment');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Sort by Next Draw'),
            trailing: _sortBy == 'next_draw' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _sortBy = 'next_draw');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Sort by Name'),
            trailing: _sortBy == 'name' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _sortBy = 'name');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Sort by Amount'),
            trailing: _sortBy == 'amount' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _sortBy = 'amount');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    // Local state for the dialog
    Set<String> tempPaymentStatuses = Set.from(_selectedPaymentStatuses);
    Set<String> tempRoles = Set.from(_selectedRoles);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Pools', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('Payment Status'),
              Wrap(
                spacing: 8,
                children: ['Paid', 'Pending', 'Overdue'].map((status) {
                  return FilterChip(
                    label: Text(status),
                    selected: tempPaymentStatuses.contains(status),
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          tempPaymentStatuses.add(status);
                        } else {
                          tempPaymentStatuses.remove(status);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Role'),
              Wrap(
                spacing: 8,
                children: ['Creator', 'Member'].map((role) {
                  return FilterChip(
                    label: Text(role),
                    selected: tempRoles.contains(role),
                    onSelected: (selected) {
                      setModalState(() {
                        if (selected) {
                          tempRoles.add(role);
                        } else {
                          tempRoles.remove(role);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          tempPaymentStatuses.clear();
                          tempRoles.clear();
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedPaymentStatuses = tempPaymentStatuses;
                          _selectedRoles = tempRoles;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoolList extends StatefulWidget {
  final String status;
  final Set<String> paymentStatusFilter;
  final Set<String> roleFilter;
  final String sortBy;

  const _PoolList({
    required this.status,
    required this.paymentStatusFilter,
    required this.roleFilter,
    required this.sortBy,
  });

  @override
  State<_PoolList> createState() => _PoolListState();
}

class _PoolListState extends State<_PoolList> {
  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPools();
  }

  @override
  void didUpdateWidget(_PoolList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when filters or sort changes
    if (oldWidget.paymentStatusFilter != widget.paymentStatusFilter ||
        oldWidget.roleFilter != widget.roleFilter ||
        oldWidget.sortBy != widget.sortBy) {
      _loadPools();
    }
  }

  Future<void> _loadPools() async {
    setState(() => _isLoading = true);
    try {
      final pools = await PoolService.getUserPools();
      
      if (mounted) {
        setState(() {
          // Filter by tab status
          var filteredPools = pools.where((pool) {
            final membershipStatus = (pool['membership_status'] ?? 'active').toString().toLowerCase();
            final targetTab = widget.status.toLowerCase();
            
            if (targetTab == 'pending') {
              return membershipStatus == 'pending' || membershipStatus == 'approved';
            } else if (targetTab == 'active') {
              return membershipStatus == 'active';
            } else if (targetTab == 'completed') {
              return membershipStatus == 'completed' || pool['status'] == 'completed';
            }
            return false;
          }).toList();

          // Apply role filter
          if (widget.roleFilter.isNotEmpty) {
            filteredPools = filteredPools.where((pool) {
              final role = pool['role'] ?? 'member';
              if (widget.roleFilter.contains('Creator') && role == 'admin') return true;
              if (widget.roleFilter.contains('Member') && role == 'member') return true;
              return false;
            }).toList();
          }

          // Apply payment status filter (for active pools)
          if (widget.paymentStatusFilter.isNotEmpty && widget.status == 'Active') {
            filteredPools = filteredPools.where((pool) {
              // This would require payment data - for now, just return all
              // In a real implementation, you'd check payment status from transactions
              return true;
            }).toList();
          }

          // Apply sorting
          filteredPools.sort((a, b) {
            switch (widget.sortBy) {
              case 'name':
                return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
              case 'amount':
                final amountA = (a['contribution_amount'] as num?)?.toInt() ?? 0;
                final amountB = (b['contribution_amount'] as num?)?.toInt() ?? 0;
                return amountB.compareTo(amountA); // Descending
              case 'next_payment':
              case 'next_draw':
                // Sort by start_date as a proxy
                final dateA = a['start_date'] != null ? DateTime.parse(a['start_date']) : DateTime.now();
                final dateB = b['start_date'] != null ? DateTime.parse(b['start_date']) : DateTime.now();
                return dateA.compareTo(dateB);
              default:
                return 0;
            }
          });

          _pools = filteredPools;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pools: $e')),
        );
      }
    }
  }

  double _calculateProgress(Map<String, dynamic> pool) {
    final currentRound = pool['current_round'] as int? ?? 1;
    final totalRounds = pool['total_rounds'] as int? ?? 1;
    return currentRound / totalRounds;
  }

  Future<void> _handleJoinPayment(Map<String, dynamic> pool) async {
    final poolId = pool['id'];
    final poolName = pool['name'];
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Joining'),
        content: Text('Your request to join "$poolName" has been approved.\n\nProceed to pay the joining fee and first contribution?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pay & Join')),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await PoolService.completeJoinPayment(poolId);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the pool!')),
        );
        _loadPools(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pools.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPools,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.status} pools found',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPools,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pools.length,
        itemBuilder: (context, index) {
          final pool = _pools[index];
          final membershipStatus = pool['membership_status'] ?? 'active';
          final contributionAmount = (pool['contribution_amount'] as num?)?.toInt() ?? 0;
          final maxMembers = (pool['max_members'] as num?)?.toInt() ?? 1;
          
          // If approved, show special status
          String displayStatus = membershipStatus == 'approved' ? 'Approved - Pay Now' : 
                               (membershipStatus == 'pending' ? 'Request Pending' : 'Active');
          
          return _ActivePoolCard(
            name: pool['name'] ?? 'Unnamed Pool',
            status: displayStatus,
            nextDraw: pool['start_date'] != null 
                ? DateFormat('MMM d').format(DateTime.parse(pool['start_date']).add(const Duration(days: 30)))
                : 'TBD',
            totalPoolAmount: contributionAmount * maxMembers,
            contributionAmount: contributionAmount,
            cycle: '${pool['current_round'] ?? 1} of ${pool['total_rounds'] ?? 12}',
            progress: _calculateProgress(pool),
            onTap: () => context.push('/pool-details/${pool['id']}'),
            onPay: membershipStatus == 'approved' 
                ? () => _handleJoinPayment(pool)
                : (membershipStatus == 'active' ? () => context.push('/payment', extra: {'poolId': pool['id'], 'amount': contributionAmount.toDouble()}) : null),
            isApproved: membershipStatus == 'approved',
          );
        },
      ),
    );
  }
}

class _ActivePoolCard extends StatelessWidget {
  final String name;
  final String status;
  final String nextDraw;
  final int totalPoolAmount;
  final int contributionAmount;
  final String cycle;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback? onPay;
  final bool isApproved;

  const _ActivePoolCard({
    required this.name,
    required this.status,
    required this.nextDraw,
    required this.totalPoolAmount,
    required this.contributionAmount,
    required this.cycle,
    required this.progress,
    required this.onTap,
    this.onPay,
    this.isApproved = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isApproved ? Colors.green : (status == 'Paid' ? Colors.green : (status == 'Pending' || status == 'Request Pending' ? Colors.orange : Colors.red));
    final statusIcon = isApproved ? Icons.check_circle_outline : (status == 'Paid' ? Icons.check_circle : (status == 'Pending' || status == 'Request Pending' ? Icons.access_time : Icons.warning));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(Icons.groups, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Cycle $cycle', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: statusColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(Icons.calendar_today, 'Next Draw', nextDraw),
                  _buildInfoItem(Icons.attach_money, 'Total Pool', '₹$totalPoolAmount'),
                  _buildInfoItem(Icons.pie_chart, 'Contribution', '₹$contributionAmount'),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: Theme.of(context).primaryColor,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (onPay != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onPay,
                        style: isApproved ? ElevatedButton.styleFrom(backgroundColor: Colors.green) : null,
                        child: Text(isApproved ? 'Pay Joining Fee' : 'Pay Now'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
