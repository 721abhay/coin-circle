import 'package:flutter/material.dart';
import '../../../../core/services/pool_service.dart';

class MemberManagementScreen extends StatefulWidget {
  final String? poolId;
  
  const MemberManagementScreen({super.key, this.poolId});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  List<dynamic> _requests = [];
  List<dynamic> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.poolId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final pool = await PoolService.getPoolDetails(widget.poolId!);
      final requests = await PoolService.getJoinRequests(widget.poolId!);
      
      if (mounted) {
        setState(() {
          _members = pool['members'] ?? [];
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRequest(String userId, bool approve) async {
    try {
      await PoolService.respondToJoinRequest(widget.poolId!, userId, approve);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Member approved' : 'Request rejected'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
        _loadData(); // Refresh lists
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Member Management'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Active Members'),
              Tab(text: 'Join Requests (${_requests.length})'),
            ],
          ),
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildActiveMembersList(context),
                  _buildJoinRequestsList(context),
                ],
              ),
      ),
    );
  }

  Widget _buildActiveMembersList(BuildContext context) {
    if (_members.isEmpty) {
      return const Center(child: Text('No active members'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final profile = member['profile'] ?? {};
        final name = profile['full_name'] ?? 'Unknown User';
        
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null,
              child: profile['avatar_url'] == null ? Text(name[0]) : null,
            ),
            title: Text(name),
            subtitle: Text('Status: ${member['status'] ?? 'Active'}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'remind', child: Text('Send Reminder')),
                const PopupMenuItem(value: 'warning', child: Text('Issue Warning')),
                const PopupMenuItem(value: 'remove', child: Text('Remove Member', style: TextStyle(color: Colors.red))),
              ],
              onSelected: (value) {
                if (value == 'remove') {
                  _showRemoveMemberDialog(member);
                } else if (value == 'remind') {
                  _sendPaymentReminder(member);
                } else if (value == 'warning') {
                  _issueWarning(member);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildJoinRequestsList(BuildContext context) {
    if (_requests.isEmpty) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_disabled, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No pending requests', style: TextStyle(fontSize: 16, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Join requests will appear here', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        final profile = request['profile'] ?? {};
        final name = profile['full_name'] ?? 'Unknown User';
        final email = profile['email'] ?? 'No email';
        final phone = profile['phone'] ?? 'No phone';
        final joinDate = request['join_date'] != null 
            ? DateTime.parse(request['join_date'])
            : DateTime.now();
        final daysAgo = DateTime.now().difference(joinDate).inDays;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: profile['avatar_url'] != null 
                          ? NetworkImage(profile['avatar_url']) 
                          : null,
                      backgroundColor: Colors.blue.shade100,
                      child: profile['avatar_url'] == null 
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                daysAgo == 0 ? 'Today' : '$daysAgo day${daysAgo > 1 ? 's' : ''} ago',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Text(
                        'PENDING',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // User Details
                _buildDetailRow(Icons.email, 'Email', email),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.phone, 'Phone', phone),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleRequest(request['user_id'], false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showApprovalConfirmation(context, request),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showApprovalConfirmation(BuildContext context, dynamic request) {
    final profile = request['profile'] ?? {};
    final name = profile['full_name'] ?? 'Unknown User';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to approve $name to join this pool?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'They will be added as an active member and can start contributing.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleRequest(request['user_id'], true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(dynamic member) {
    final profile = member['profile'] ?? {};
    final name = profile['full_name'] ?? 'Unknown User';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to remove $name from this pool?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The member will lose access to the pool.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await PoolService.removeMember(widget.poolId!, member['user_id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Member removed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadData(); // Refresh the list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error removing member: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove Member'),
          ),
        ],
      ),
    );
  }

  void _sendPaymentReminder(dynamic member) {
    final profile = member['profile'] ?? {};
    final name = profile['full_name'] ?? 'Unknown User';
    
    // TODO: Implement actual notification/email sending
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment reminder sent to $name'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _issueWarning(dynamic member) {
    final profile = member['profile'] ?? {};
    final name = profile['full_name'] ?? 'Unknown User';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Issue a warning to $name?'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Warning Message',
                border: OutlineInputBorder(),
                hintText: 'Enter warning message...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement actual warning system
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Warning issued to $name'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Issue Warning'),
          ),
        ],
      ),
    );
  }
}
