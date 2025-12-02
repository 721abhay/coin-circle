import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/pool_service.dart';

class AdminPoolsView extends ConsumerStatefulWidget {
  const AdminPoolsView({super.key});

  @override
  ConsumerState<AdminPoolsView> createState() => _AdminPoolsViewState();
}

class _AdminPoolsViewState extends ConsumerState<AdminPoolsView> {
  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPools();
  }

  Future<void> _loadPools() async {
    try {
      // Fetch pools created by the admin (official pools)
      final pools = await PoolService.getUserPools(); 
      
      if (mounted) {
        setState(() {
          _pools = pools;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePool(String poolId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pool?'),
        content: const Text('This action cannot be undone. All data associated with this pool will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PoolService.deletePool(poolId);
        
        setState(() {
          _pools.removeWhere((p) => p['id'] == poolId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pool deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting pool: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showEditPoolDialog(Map<String, dynamic> pool) {
    final nameController = TextEditingController(text: pool['name']);
    final descriptionController = TextEditingController(text: pool['description']);
    String status = pool['status'] ?? 'pending';
    String privacy = pool['privacy'] ?? 'public';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Pool'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Pool Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['pending', 'active', 'completed', 'paused']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => status = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: privacy,
                  decoration: const InputDecoration(labelText: 'Privacy'),
                  items: ['public', 'private']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => privacy = val!),
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
                  await PoolService.updatePool(pool['id'], {
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'status': status,
                    'privacy': privacy,
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    _loadPools(); // Refresh list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pool updated successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating pool: $e'), backgroundColor: Colors.red),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pools.isEmpty 
                    ? const Center(child: Text('No pools found. Create one!'))
                    : _buildPoolsGrid(),
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
          'Pool Management',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          onPressed: () => context.push('/create-pool'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create'), // Shortened text to prevent overflow
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E2C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildPoolsGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Adjusted aspect ratio for better fit
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _pools.length,
      itemBuilder: (context, index) {
        final pool = _pools[index];
        return _buildPoolCard(pool);
      },
    );
  }

  Widget _buildPoolCard(Map<String, dynamic> pool) {
    final status = pool['status'] ?? 'pending';
    final isPrivate = pool['privacy'] == 'private';
    final poolId = pool['id'];

    Color statusColor;
    switch (status.toString().toLowerCase()) {
      case 'active': statusColor = Colors.green; break;
      case 'completed': statusColor = Colors.blue; break;
      default: statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toString().toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditPoolDialog(pool);
                      break;
                    case 'pause':
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pool paused')));
                      break;
                    case 'delete':
                      _deletePool(poolId);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Pool')),
                  const PopupMenuItem(value: 'pause', child: Text('Pause Pool')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Pool', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pool['name'] ?? 'Unnamed Pool',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'ID: ${poolId.toString().substring(0, 6)}...',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          const Spacer(),
          _buildPoolStat('Amount', '₹${pool['contribution_amount']}'),
          const SizedBox(height: 4),
          _buildPoolStat('Members', '${pool['current_members']}/${pool['max_members']}'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/pool-details/$poolId'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: Color(0xFF1E1E2C)),
              ),
              child: const Text('Manage', style: TextStyle(color: Color(0xFF1E1E2C), fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
