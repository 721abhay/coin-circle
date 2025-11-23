import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/dispute_service.dart';

class AdminDisputesTab extends StatefulWidget {
  const AdminDisputesTab({super.key});

  @override
  State<AdminDisputesTab> createState() => _AdminDisputesTabState();
}

class _AdminDisputesTabState extends State<AdminDisputesTab> {
  late Future<List<Map<String, dynamic>>> _disputesFuture;

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  void _loadDisputes() {
    setState(() {
      _disputesFuture = DisputeService.getAllDisputes();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'under_review':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Future<void> _updateStatus(String disputeId, String newStatus) async {
    final notesController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as ${_formatStatus(newStatus)}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a resolution note (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Enter notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DisputeService.resolveDispute(
          disputeId: disputeId,
          status: newStatus,
          resolutionNotes: notesController.text,
        );
        _loadDisputes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dispute updated successfully')),
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
  }

  String _formatStatus(String status) {
    return status.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _disputesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final disputes = snapshot.data ?? [];

        if (disputes.isEmpty) {
          return const Center(child: Text('No disputes found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: disputes.length,
          itemBuilder: (context, index) {
            final dispute = disputes[index];
            final creator = dispute['creator'] ?? {};
            final date = DateTime.parse(dispute['created_at']);
            final status = dispute['status'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(status).withOpacity(0.1),
                  child: Icon(Icons.report_problem, color: _getStatusColor(status)),
                ),
                title: Text(
                  _formatStatus(dispute['category']),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'By ${creator['full_name'] ?? 'Unknown'} • ${DateFormat('MMM d').format(date)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(dispute['description']),
                        const SizedBox(height: 16),
                        if (dispute['resolution_notes'] != null) ...[
                          const Text('Resolution Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(dispute['resolution_notes'], style: const TextStyle(fontStyle: FontStyle.italic)),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status != 'under_review' && status != 'resolved' && status != 'dismissed')
                              TextButton(
                                onPressed: () => _updateStatus(dispute['id'], 'under_review'),
                                child: const Text('Mark Under Review'),
                              ),
                            if (status != 'resolved')
                              ElevatedButton(
                                onPressed: () => _updateStatus(dispute['id'], 'resolved'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Resolve'),
                              ),
                            if (status != 'dismissed')
                              TextButton(
                                onPressed: () => _updateStatus(dispute['id'], 'dismissed'),
                                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                                child: const Text('Dismiss'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
