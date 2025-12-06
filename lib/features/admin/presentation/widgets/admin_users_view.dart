import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersView extends ConsumerStatefulWidget {
  const AdminUsersView({super.key});

  @override
  ConsumerState<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends ConsumerState<AdminUsersView> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildUsersTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search users...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        columns: const [
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Joined')),
          DataColumn(label: Text('KYC')),
          DataColumn(label: Text('Actions')),
        ],
        rows: _users.map((user) {
          final name = user['full_name'] ?? 'Unknown';
          final email = user['email'] ?? 'N/A';
          final status = user['is_suspended'] == true ? 'Suspended' : 'Active';
          final kycStatus = user['kyc_verified'] == true ? 'Verified' : 'Pending';
          final createdAt = user['created_at'] != null 
              ? DateTime.parse(user['created_at']).toString().substring(0, 10)
              : 'Unknown';

          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: user['avatar_url'] != null 
                          ? NetworkImage(user['avatar_url'])
                          : null,
                      child: user['avatar_url'] == null 
                          ? Text(name[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'Active' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status, 
                    style: TextStyle(
                      color: status == 'Active' ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(Text(createdAt)),
              DataCell(
                Row(
                  children: [
                    Icon(
                      kycStatus == 'Verified' ? Icons.check_circle : Icons.pending,
                      size: 16,
                      color: kycStatus == 'Verified' ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(kycStatus),
                  ],
                ),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined),
                      onPressed: () => _viewUserDetails(user),
                      tooltip: 'View Details',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editUser(user),
                      tooltip: 'Edit User',
                    ),
                    IconButton(
                      icon: Icon(
                        user['is_suspended'] == true ? Icons.check_circle_outline : Icons.block_outlined,
                        color: user['is_suspended'] == true ? Colors.green : Colors.red,
                      ),
                      onPressed: () => _toggleSuspendUser(user),
                      tooltip: user['is_suspended'] == true ? 'Unsuspend User' : 'Suspend User',
                    ),
                  ],
                ),
              ),
            ],
          );
          }).toList(),
        ),
      ),
    );
  }

  void _viewUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['full_name'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user['email'] ?? 'N/A'),
              _buildDetailRow('Phone', user['phone_number'] ?? 'N/A'),
              _buildDetailRow('User ID', user['id'] ?? 'N/A'),
              _buildDetailRow('Status', user['is_suspended'] == true ? 'Suspended' : 'Active'),
              _buildDetailRow('KYC', user['kyc_verified'] == true ? 'Verified' : 'Pending'),
              _buildDetailRow('Admin', user['is_admin'] == true ? 'Yes' : 'No'),
              _buildDetailRow('Joined', user['created_at'] != null 
                  ? DateTime.parse(user['created_at']).toString().substring(0, 16)
                  : 'Unknown'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _editUser(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['full_name']);
    final phoneController = TextEditingController(text: user['phone_number']);
    bool isAdmin = user['is_admin'] == true;
    bool kycVerified = user['kyc_verified'] == true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Admin'),
                  value: isAdmin,
                  onChanged: (val) => setState(() => isAdmin = val),
                ),
                SwitchListTile(
                  title: const Text('KYC Verified'),
                  value: kycVerified,
                  onChanged: (val) => setState(() => kycVerified = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client
                      .from('profiles')
                      .update({
                        'full_name': nameController.text,
                        'phone_number': phoneController.text,
                        'is_admin': isAdmin,
                        'kyc_verified': kycVerified,
                      })
                      .eq('id', user['id']);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    _loadUsers(); // Reload users
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User updated successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSuspendUser(Map<String, dynamic> user) {
    final isSuspended = user['is_suspended'] == true;
    final action = isSuspended ? 'Unsuspend' : 'Suspend';
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action User?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to $action ${user['full_name']}?'),
            if (!isSuspended) ...[
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (required)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate reason for suspension
              if (!isSuspended && reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason'), backgroundColor: Colors.red),
                );
                return;
              }

              try {
                final reason = isSuspended ? 'Account unsuspended by admin' : reasonController.text.trim();
                
                // Use RPC function
                await Supabase.instance.client.rpc('suspend_user_admin', params: {
                  'p_reason': reason,
                  'p_user_id': user['id'],
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  _loadUsers(); // Reload users
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User ${isSuspended ? 'unsuspended' : 'suspended'} and notified'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error suspending user: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuspended ? Colors.green : Colors.red,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}
