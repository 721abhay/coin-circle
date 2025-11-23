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
  String _filter = 'pending'; // pending, solved, dismissed

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      // Try to fetch from 'tickets' table
      final response = await Supabase.instance.client
          .from('tickets')
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
      // Fallback to mock data if table doesn't exist
      if (mounted) {
        setState(() {
          _tickets = _getMockTickets();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getMockTickets() {
    if (_filter != 'pending') return [];
    return [
      {
        'id': '1',
        'subject': 'Payment Failed',
        'description': 'I tried to pay for the pool but it failed twice.',
        'status': 'pending',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'profiles': {'full_name': 'Rahul Kumar', 'email': 'rahul@example.com'}
      },
      {
        'id': '2',
        'subject': 'App Crash',
        'description': 'App crashes when I open the profile screen.',
        'status': 'pending',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'profiles': {'full_name': 'Priya Singh', 'email': 'priya@example.com'}
      },
    ];
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
        _buildFilterChip('Pending', 'pending'),
        const SizedBox(width: 12),
        _buildFilterChip('Solved', 'solved'),
        const SizedBox(width: 12),
        _buildFilterChip('Dismissed', 'dismissed'),
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
                onPressed: () {},
                child: const Text('Dismiss'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
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
}
