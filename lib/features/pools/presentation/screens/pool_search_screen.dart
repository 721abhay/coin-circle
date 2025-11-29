import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/pool_service.dart';

class PoolSearchScreen extends StatefulWidget {
  const PoolSearchScreen({super.key});

  @override
  State<PoolSearchScreen> createState() => _PoolSearchScreenState();
}

class _PoolSearchScreenState extends State<PoolSearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedCategory = 'All';
  RangeValues _contributionRange = const RangeValues(100, 5000);
  int _selectedDuration = 0; // 0 = All
  String _sortBy = 'Popular';
  
  List<Map<String, dynamic>> _allPools = [];
  bool _isLoading = true;

  final List<String> _categories = ['All', 'Family', 'Friends', 'Colleagues', 'Community'];
  final List<String> _sortOptions = ['Popular', 'Newest', 'Ending Soon', 'Lowest Amount', 'Highest Amount'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPools();
  }

  Future<void> _loadPools() async {
    setState(() => _isLoading = true);
    try {
      final pools = await PoolService.getPublicPools();
      if (mounted) {
        setState(() {
          _allPools = pools;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading pools: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pools: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredPools {
    var filtered = _allPools;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((pool) =>
        pool['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (pool['description'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Category filter (if category field exists in pool data)
    if (_selectedCategory != 'All' && filtered.isNotEmpty) {
      filtered = filtered.where((pool) => 
        (pool['category'] ?? 'Community') == _selectedCategory
      ).toList();
    }

    // Contribution range filter
    filtered = filtered.where((pool) {
      final amount = (pool['contribution_amount'] as num?)?.toDouble() ?? 0;
      return amount >= _contributionRange.start && amount <= _contributionRange.end;
    }).toList();

    // Duration filter
    if (_selectedDuration > 0) {
      filtered = filtered.where((pool) => 
        (pool['total_rounds'] as int?) == _selectedDuration
      ).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Newest':
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        break;
      case 'Ending Soon':
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a['start_date'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['start_date'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
        break;
      case 'Lowest Amount':
        filtered.sort((a, b) {
          final amtA = (a['contribution_amount'] as num?)?.toDouble() ?? 0;
          final amtB = (b['contribution_amount'] as num?)?.toDouble() ?? 0;
          return amtA.compareTo(amtB);
        });
        break;
      case 'Highest Amount':
        filtered.sort((a, b) {
          final amtA = (a['contribution_amount'] as num?)?.toDouble() ?? 0;
          final amtB = (b['contribution_amount'] as num?)?.toDouble() ?? 0;
          return amtB.compareTo(amtA);
        });
        break;
      default: // Popular
        filtered.sort((a, b) {
          final membersA = (a['current_members'] as num?)?.toInt() ?? 0;
          final membersB = (b['current_members'] as num?)?.toInt() ?? 0;
          return membersB.compareTo(membersA);
        });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Pools'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Recommended'),
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBrowseTab(),
                      _buildRecommendedTab(),
                      _buildTrendingTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search pools by name, category...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Category',
                    onTap: () => _showCategoryFilter(),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Amount',
                    onTap: () => _showAmountFilter(),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Duration',
                    onTap: () => _showDurationFilter(),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => _sortOptions.map((option) {
              return PopupMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onTap}) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(Icons.filter_list, size: 18),
    );
  }

  Widget _buildBrowseTab() {
    if (_filteredPools.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPools,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No pools found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters or pull to refresh',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPools,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredPools.length,
        itemBuilder: (context, index) {
          return _PoolCard(pool: _filteredPools[index]);
        },
      ),
    );
  }

  Widget _buildRecommendedTab() {
    // Show pools with high member count as "recommended"
    final recommended = _filteredPools.where((p) {
      final members = (p['current_members'] as num?)?.toInt() ?? 0;
      final maxMembers = (p['max_members'] as num?)?.toInt() ?? 1;
      return members >= (maxMembers * 0.5); // At least 50% full
    }).take(5).toList();

    if (recommended.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.recommend, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No recommended pools yet', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPools,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recommended.length,
        itemBuilder: (context, index) {
          return _PoolCard(pool: recommended[index], isRecommended: true);
        },
      ),
    );
  }

  Widget _buildTrendingTab() {
    // Show pools with most members as "trending"
    final trending = List<Map<String, dynamic>>.from(_filteredPools)
      ..sort((a, b) {
        final membersA = (a['current_members'] as num?)?.toInt() ?? 0;
        final membersB = (b['current_members'] as num?)?.toInt() ?? 0;
        return membersB.compareTo(membersA);
      });
    
    final topTrending = trending.take(5).toList();

    if (topTrending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No trending pools yet', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPools,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: topTrending.length,
        itemBuilder: (context, index) {
          return _PoolCard(pool: topTrending[index], isTrending: true);
        },
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._categories.map((category) {
              return RadioListTile<String>(
                title: Text(category),
                value: category,
                groupValue: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAmountFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contribution Amount Range',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              RangeSlider(
                values: _contributionRange,
                min: 0,
                max: 10000,
                divisions: 100,
                labels: RangeLabels(
                  '₹${_contributionRange.start.round()}',
                  '₹${_contributionRange.end.round()}',
                ),
                onChanged: (values) {
                  setModalState(() {
                    _contributionRange = values;
                  });
                },
              ),
              Text(
                '₹${_contributionRange.start.round()} - ₹${_contributionRange.end.round()}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDurationFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pool Duration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<int>(
              title: const Text('All Durations'),
              value: 0,
              groupValue: _selectedDuration,
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text('6 months'),
              value: 6,
              groupValue: _selectedDuration,
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text('12 months'),
              value: 12,
              groupValue: _selectedDuration,
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<int>(
              title: const Text('18 months'),
              value: 18,
              groupValue: _selectedDuration,
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PoolCard extends StatelessWidget {
  final Map<String, dynamic> pool;
  final bool isRecommended;
  final bool isTrending;

  const _PoolCard({
    required this.pool,
    this.isRecommended = false,
    this.isTrending = false,
  });

  @override
  Widget build(BuildContext context) {
    final creatorName = pool['creator']?['full_name'] ?? 'Unknown';
    final contributionAmount = (pool['contribution_amount'] as num?)?.toDouble() ?? 0;
    final frequency = pool['frequency'] ?? 'monthly';
    final duration = (pool['total_rounds'] as int?) ?? 12;
    final currentMembers = (pool['current_members'] as num?)?.toInt() ?? 0;
    final maxMembers = (pool['max_members'] as num?)?.toInt() ?? 1;
    final startDate = DateTime.tryParse(pool['start_date'] ?? '') ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          context.push('/pool-details/${pool['id']}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pool['name'] ?? 'Unnamed Pool',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Recommended',
                        style: TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                    ),
                  if (isTrending)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Trending',
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pool['description'] ?? 'No description',
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    creatorName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.account_balance_wallet,
                      label: '₹${contributionAmount.toStringAsFixed(0)} / $frequency',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.calendar_today,
                      label: '$duration months',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: currentMembers / maxMembers,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$currentMembers/$maxMembers members',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Starts ${DateFormat('MMM d').format(startDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
