import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/admin_service.dart';
import '../../data/models/admin_user.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  final TextEditingController _searchController = TextEditingController();
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
        _users.clear();
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final usersData = await AdminService.getAllUsers(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );

      final newUsers = usersData.map((data) => AdminUser.fromMap(data)).toList();

      if (mounted) {
        setState(() {
          _users.addAll(newUsers);
          _isLoading = false;
          if (newUsers.length < _pageSize) {
            _hasMore = false;
          } else {
            _currentPage++;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _toggleUserSuspension(AdminUser user) async {
    final isSuspending = !user.suspended;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSuspending ? 'Suspend User' : 'Unsuspend User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to ${isSuspending ? 'suspend' : 'unsuspend'} ${user.fullName}?'),
            if (isSuspending) ...[
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for suspension',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isSuspending && reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuspending ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isSuspending ? 'Suspend' : 'Unsuspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (isSuspending) {
          await AdminService.suspendUser(user.id, reasonController.text.trim());
        } else {
          await AdminService.unsuspendUser(user.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User ${isSuspending ? 'suspended' : 'unsuspended'} successfully')),
          );
          _loadUsers(refresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showUserDetails(AdminUser user) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final details = await AdminService.getUserDetails(user.id);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(user.fullName),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Email', user.email),
                  _buildDetailRow('Phone', user.phoneNumber ?? 'N/A'),
                  _buildDetailRow('Joined', DateFormat.yMMMd().format(user.createdAt)),
                  const Divider(),
                  _buildDetailRow('Status', user.suspended ? 'Suspended' : 'Active', 
                    color: user.suspended ? Colors.red : Colors.green),
                  if (user.suspended)
                    _buildDetailRow('Reason', user.suspensionReason ?? 'N/A'),
                  const Divider(),
                  _buildDetailRow('Wallet Balance', '₹${user.walletBalance.toStringAsFixed(2)}'),
                  if (details != null) ...[
                    _buildDetailRow('Pools Joined', details['pools_joined']?.toString() ?? '0'),
                    _buildDetailRow('Pools Created', details['pools_created']?.toString() ?? '0'),
                    _buildDetailRow('Total Transactions', details['total_transactions']?.toString() ?? '0'),
                    _buildDetailRow('Total Contributed', '₹${((details['total_contributed'] as num?) ?? 0).toStringAsFixed(2)}'),
                    _buildDetailRow('Total Won', '₹${((details['total_won'] as num?) ?? 0).toStringAsFixed(2)}'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading details: $e')),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadUsers(refresh: true);
                      },
                    ),
                  ),
                  onSubmitted: (_) => _loadUsers(refresh: true),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _loadUsers(refresh: true),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadUsers(refresh: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _users.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _users.length) {
                              _loadUsers();
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final user = _users[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: user.suspended
                                    ? BorderSide(color: Colors.red.shade200, width: 1)
                                    : BorderSide.none,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: user.suspended 
                                      ? Colors.red.shade100 
                                      : Theme.of(context).primaryColor.withOpacity(0.1),
                                  child: Text(
                                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: user.suspended 
                                          ? Colors.red 
                                          : Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (user.isAdmin)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'ADMIN',
                                          style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    if (user.suspended)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'SUSPENDED',
                                          style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.email),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.account_balance_wallet, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text('₹${user.walletBalance.toStringAsFixed(2)}'),
                                        const SizedBox(width: 12),
                                        Icon(Icons.groups, size: 14, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text('${user.poolsJoined} pools'),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'details') {
                                      _showUserDetails(user);
                                    } else if (value == 'suspend') {
                                      _toggleUserSuspension(user);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'details',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility, size: 20),
                                          SizedBox(width: 8),
                                          Text('View Details'),
                                        ],
                                      ),
                                    ),
                                    if (!user.isAdmin)
                                      PopupMenuItem(
                                        value: 'suspend',
                                        child: Row(
                                          children: [
                                            Icon(
                                              user.suspended ? Icons.restore : Icons.block,
                                              size: 20,
                                              color: user.suspended ? Colors.green : Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              user.suspended ? 'Unsuspend User' : 'Suspend User',
                                              style: TextStyle(
                                                color: user.suspended ? Colors.green : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () => _showUserDetails(user),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
