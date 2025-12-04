import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/legal_service.dart';

class AdminLegalTab extends StatefulWidget {
  const AdminLegalTab({super.key});

  @override
  State<AdminLegalTab> createState() => _AdminLegalTabState();
}

class _AdminLegalTabState extends State<AdminLegalTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _escalations = [];
  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _actions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load all data in parallel
      final results = await Future.wait([
        LegalService.getEnforcementEscalations(),
        LegalService.getLegalNotices(), 
        LegalService.getLegalActions(), 
      ]);

      if (mounted) {
        setState(() {
          _escalations = results[0];
          _notices = results[1]; 
          _actions = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading legal data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Escalations'),
              Tab(text: 'Notices'),
              Tab(text: 'Actions'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEscalationsTab(),
                    _buildNoticesTab(),
                    _buildActionsTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEscalationsTab() {
    if (_escalations.isEmpty) {
      return const Center(child: Text('No active escalations'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _escalations.length,
      itemBuilder: (context, index) {
        final item = _escalations[index];
        final levelInfo = LegalService.getEscalationInfo(item['escalation_level']);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(levelInfo['color']).withOpacity(0.2),
              child: Text(levelInfo['icon']),
            ),
            title: Text('User ID: ${item['user_id']}'), // Should fetch name
            subtitle: Text('${levelInfo['name']} - ${item['days_overdue']} days overdue'),
            trailing: Text('₹${item['amount_overdue']}'),
          ),
        );
      },
    );
  }

  Widget _buildNoticesTab() {
    if (_notices.isEmpty) {
      return const Center(child: Text('No notices issued'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notices.length,
      itemBuilder: (context, index) {
        final item = _notices[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.description),
            title: Text(item['notice_type']),
            subtitle: Text('Issued: ${DateFormat('MMM d').format(DateTime.parse(item['issued_at']))}'),
            trailing: Chip(label: Text(item['status'])),
          ),
        );
      },
    );
  }

  Widget _buildActionsTab() {
    if (_actions.isEmpty) {
      return const Center(child: Text('No legal actions taken'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _actions.length,
      itemBuilder: (context, index) {
        final item = _actions[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.gavel),
            title: Text(item['action_type']),
            subtitle: Text('Status: ${item['action_status']}'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
