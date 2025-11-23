import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/admin_service.dart';

class PoolOversightTab extends StatefulWidget {
  const PoolOversightTab({super.key});

  @override
  State<PoolOversightTab> createState() => _PoolOversightTabState();
}

class _PoolOversightTabState extends State<PoolOversightTab> {
  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  String? _selectedStatus;

  final List<String> _statusOptions = ['active', 'pending', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _loadPools();
  }

  Future<void> _loadPools({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
        _pools.clear();
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final poolsData = await AdminService.getAllPools(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          _pools.addAll(poolsData);
          _isLoading = false;
          if (poolsData.length < _pageSize) {
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

  Future<void> _forceClosePool(String poolId, String poolName) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Close Pool'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to force close "$poolName"?'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. All members will be notified.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for closing',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Force Close'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.forceClosePool(
          poolId: poolId,
          reason: reasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pool closed successfully')),
          );
          _loadPools(refresh: true);
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Filter by Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedStatus == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedStatus = null);
                          _loadPools(refresh: true);
                        }
                      },
                    ),
                    ..._statusOptions.map((status) => ChoiceChip(
                          label: Text(status[0].toUpperCase() + status.substring(1)),
                          selected: _selectedStatus == status,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedStatus = status);
                              _loadPools(refresh: true);
                            }
                          },
                          selectedColor: _getStatusColor(status).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _selectedStatus == status ? _getStatusColor(status) : null,
                            fontWeight: _selectedStatus == status ? FontWeight.bold : null,
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Pool List
        Expanded(
          child: _isLoading && _pools.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadPools(refresh: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _pools.isEmpty
                      ? const Center(child: Text('No pools found'))
                      : RefreshIndicator(
                          onRefresh: () => _loadPools(refresh: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _pools.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _pools.length) {
                                _loadPools();
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final pool = _pools[index];
                              final status = pool['status'] as String;
                              final statusColor = _getStatusColor(status);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
                                ),
                                child: InkWell(
                                  onTap: () => context.push('/pool-details/${pool['id']}'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                pool['name'] ?? 'Unnamed Pool',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: statusColor.withOpacity(0.5)),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Created by: ${pool['creator_name'] ?? 'Unknown'}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            _buildInfoChip(
                                              Icons.attach_money,
                                              '₹${pool['contribution_amount']}',
                                              'Contribution',
                                            ),
                                            const SizedBox(width: 12),
                                            _buildInfoChip(
                                              Icons.people,
                                              '${pool['current_members']}/${pool['max_members']}',
                                              'Members',
                                            ),
                                            const SizedBox(width: 12),
                                            _buildInfoChip(
                                              Icons.calendar_today,
                                              pool['start_date'] != null 
                                                  ? DateFormat.yMMMd().format(DateTime.parse(pool['start_date']))
                                                  : 'Not started',
                                              'Start Date',
                                            ),
                                          ],
                                        ),
                                        if (status != 'cancelled' && status != 'completed') ...[
                                          const Divider(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => context.push('/pool-details/${pool['id']}'),
                                                icon: const Icon(Icons.visibility, size: 16),
                                                label: const Text('View Details'),
                                              ),
                                              const SizedBox(width: 8),
                                              TextButton.icon(
                                                onPressed: () => _forceClosePool(pool['id'], pool['name']),
                                                icon: const Icon(Icons.block, size: 16),
                                                label: const Text('Force Close'),
                                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
