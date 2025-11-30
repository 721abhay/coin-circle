import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/services/pool_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _badges = [];
  List<Map<String, dynamic>> _reviews = [];
  Map<String, int> _poolStats = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      // Fetch profile
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      // Fetch badges
      final userBadges = await GamificationService.getUserBadges(widget.userId);
      final allBadges = await GamificationService.getBadges();
      
      List<Map<String, dynamic>> processedBadges = [];
      if (allBadges.isEmpty) {
        // Fallback badges
        processedBadges = [
          {'name': 'Early Adopter', 'icon': '🚀', 'unlocked': true},
          {'name': 'Reliable', 'icon': '⭐', 'unlocked': true},
          {'name': 'Winner', 'icon': '🏆', 'unlocked': false},
        ];
      } else {
        for (var badge in allBadges.take(3)) {
          final isUnlocked = userBadges.any((ub) => ub['badge_id'] == badge['id']);
          processedBadges.add({
            'name': badge['name'],
            'icon': badge['icon_url'] ?? '🏅',
            'unlocked': isUnlocked,
          });
        }
      }

      // Fetch reviews
      final reviews = await GamificationService.getReviews(widget.userId);

      // Fetch pool stats
      final pools = await PoolService.getUserPools();
      final totalPools = pools.length;
      final activePools = pools.where((p) => p['status'] == 'active').length;

      if (mounted) {
        setState(() {
          _profile = profile;
          _badges = processedBadges;
          _reviews = reviews;
          _poolStats = {
            'total': totalPools,
            'active': activePools,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = _profile?['full_name'] ?? 'User';
    final createdAt = _profile?['created_at'];
    final memberSince = createdAt != null 
        ? DateFormat('MMM yyyy').format(DateTime.parse(createdAt))
        : 'Recently';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _profile?['avatar_url'] != null
                  ? NetworkImage(_profile!['avatar_url'])
                  : null,
              child: _profile?['avatar_url'] == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Member since $memberSince', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _buildTrustScore(context),
            const SizedBox(height: 24),
            _buildStatsGrid(context),
            const SizedBox(height: 24),
            _buildBadgesSection(context),
            const SizedBox(height: 24),
            _buildReviewsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustScore(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user, color: Colors.green),
          const SizedBox(width: 8),
          Column(
            children: [
              Text('Trust Score', style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
              const Text('98/100', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Pools', '${_poolStats['total'] ?? 0}'),
        _buildStatItem('On-Time', '100%'),
        _buildStatItem('Friends', '45'), // TODO: Implement friends feature
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildBadgesSection(BuildContext context) {
    if (_badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Badges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _badges.map((badge) => _buildBadge(
            badge['icon'] ?? '🏅',
            badge['name'] ?? 'Badge',
            badge['unlocked'] ?? false,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(String icon, String label, bool unlocked) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.4,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: unlocked ? Colors.amber.shade100 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_reviews.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigate to full reviews list
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _ReviewsListPage(reviews: _reviews),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
          ],
        ),
        if (_reviews.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('No reviews yet', style: TextStyle(color: Colors.grey)),
              ),
            ),
          )
        else
          ..._reviews.take(1).map((review) {
            final reviewer = review['reviewer'] as Map<String, dynamic>?;
            final reviewerName = reviewer?['full_name'] ?? 'Anonymous';
            final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
            final comment = review['comment'] ?? '';

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'A'),
                ),
                title: Text(reviewerName),
                subtitle: Text(comment),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Block User', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Report Profile'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// Simple reviews list page
class _ReviewsListPage extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;

  const _ReviewsListPage({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Reviews')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          final reviewer = review['reviewer'] as Map<String, dynamic>?;
          final reviewerName = reviewer?['full_name'] ?? 'Anonymous';
          final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
          final comment = review['comment'] ?? '';
          final date = DateTime.parse(review['created_at']);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Text(reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'A'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reviewerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              DateFormat('MMM d, yyyy').format(date),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      RatingBarIndicator(
                        rating: rating,
                        itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 16.0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(comment),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
