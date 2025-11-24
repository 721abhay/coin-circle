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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: $value')));
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
          Text('No pending requests'),
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
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null,
                      child: profile['avatar_url'] == null ? Text(name[0]) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(email, style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleRequest(request['user_id'], false),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleRequest(request['user_id'], true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('Approve'),
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
}
