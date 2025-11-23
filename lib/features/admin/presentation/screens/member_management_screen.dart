import 'package:flutter/material.dart';
import '../../../../core/services/pool_service.dart';

class MemberManagementScreen extends StatefulWidget {
  final String? poolId;
  
  const MemberManagementScreen({super.key, this.poolId});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  List<dynamic> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (widget.poolId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final pool = await PoolService.getPoolDetails(widget.poolId!);
      if (mounted) {
        setState(() {
          _members = pool['members'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Members'),
              Tab(text: 'Join Requests'),
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
    return const Center(child: Text('No pending requests'));
  }
}
