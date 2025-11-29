import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      // In a real admin app, we'd fetch ALL pools, not just user's
      // For now, using getUserPools as a placeholder or we'd need a new service method
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
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Create Official Pool'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E2C),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPoolsGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _pools.length,
      itemBuilder: (context, index) {
        final pool = _pools[index];
        return _buildPoolCard(pool);
      },
    );
  }

  Widget _buildPoolCard(Map<String, dynamic> pool) {
    final status = pool['status'] ?? 'Unknown';
    final isPrivate = pool['privacy'] == 'private';

    return Container(
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPrivate ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPrivate ? 'PRIVATE' : 'PUBLIC',
                  style: TextStyle(
                    color: isPrivate ? Colors.purple : Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Pool')),
                  const PopupMenuItem(value: 'pause', child: Text('Pause Pool')),
                  const PopupMenuItem(value: 'close', child: Text('Force Close', style: TextStyle(color: Colors.red))),
                ],
                child: const Icon(Icons.more_vert, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pool['name'] ?? 'Unnamed Pool',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${pool['id'].toString().substring(0, 8)}...',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPoolStat('Amount', '₹${pool['contribution_amount']}'),
              _buildPoolStat('Members', '${pool['current_members']}/${pool['max_members']}'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Manage Pool'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
