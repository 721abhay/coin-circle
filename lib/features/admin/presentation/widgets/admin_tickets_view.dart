import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminTicketsView extends ConsumerStatefulWidget {
  const AdminTicketsView({super.key});

  @override
  ConsumerState<AdminTicketsView> createState() => _AdminTicketsViewState();
}

class _AdminTicketsViewState extends ConsumerState<AdminTicketsView> {
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;
  String _filter = 'open'; // open, resolved, closed

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      // Fetch from 'support_tickets' table
      final response = await Supabase.instance.client
          .from('support_tickets')
          .select('*, profiles(full_name, email)')
          .eq('status', _filter)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _tickets = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading tickets: $e');
      if (mounted) {
        setState(() {
          _tickets = [];
          _isLoading = false;
        });
      }
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
          _buildFilterTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTicketsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Support Tickets',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadTickets,
          tooltip: 'Refresh Tickets',
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Row(
      children: [
        _buildFilterChip('Open', 'open'),
        const SizedBox(width: 12),
        _buildFilterChip('Resolved', 'resolved'),
        const SizedBox(width: 12),
        _buildFilterChip('Closed', 'closed'),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = value);
          _loadTickets();
        }
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF1E1E2C).withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1E1E2C) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTicketsList() {
    if (_tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No $_filter tickets',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _tickets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final profile = ticket['profiles'] ?? {};
    final name = profile['full_name'] ?? 'Unknown User';
    final email = profile['email'] ?? 'No Email';
    final date = DateTime.parse(ticket['created_at']);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text(name[0].toUpperCase(), style: TextStyle(color: Colors.blue.shade800)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeago.format(date),
                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ticket['subject'] ?? 'No Subject',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            ticket['description'] ?? 'No Description',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _dismissTicket(ticket['id']),
                child: const Text('Dismiss'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _markSolved(ticket['id']),
                icon: const Icon(Icons.check),
                label: const Text('Mark Solved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _dismissTicket(String ticketId) async {
    try {
      // Get ticket details first to get user_id
      final ticket = await Supabase.instance.client
          .from('support_tickets')
          .select('user_id, subject')
          .eq('id', ticketId)
          .single();
      
      // Update ticket status
      await Supabase.instance.client
          .from('support_tickets')
          .update({'status': 'closed'})
          .eq('id', ticketId);
      
      // Send notification to user
      await Supabase.instance.client
          .from('notifications')
          .insert({
            'user_id': ticket['user_id'],
            'title': 'Support Ticket Closed',
            'message': 'Your support ticket "${ticket['subject']}" has been closed by admin.',
            'type': 'system',
            'created_at': DateTime.now().toIso8601String(),
          });
      
      await _loadTickets(); // Reload tickets
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket dismissed and user notified')),
        );
      }
    } catch (e) {
      debugPrint('Error dismissing ticket: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markSolved(String ticketId) async {
    try {
      // Get ticket details first to get user_id
      final ticket = await Supabase.instance.client
          .from('support_tickets')
          .select('user_id, subject')
          .eq('id', ticketId)
          .single();
      
      // Update ticket status
      await Supabase.instance.client
          .from('support_tickets')
          .update({
            'status': 'resolved',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId);
      
      // Send notification to user
      await Supabase.instance.client
          .from('notifications')
          .insert({
            'user_id': ticket['user_id'],
            'title': 'Support Ticket Resolved',
            'message': 'Your support ticket "${ticket['subject']}" has been resolved. Thank you for your patience!',
            'type': 'system',
            'created_at': DateTime.now().toIso8601String(),
          });
      
      await _loadTickets(); // Reload tickets
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket marked as solved and user notified'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking ticket as solved: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
