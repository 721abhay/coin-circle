import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gamification_service.dart';

class BadgeListScreen extends StatefulWidget {
  const BadgeListScreen({super.key});

  @override
  State<BadgeListScreen> createState() => _BadgeListScreenState();
}

class _BadgeListScreenState extends State<BadgeListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final allBadges = await GamificationService.getBadges();
        final userBadges = await GamificationService.getUserBadges(userId);
        
        final List<Map<String, dynamic>> processedBadges = [];
        
        // If no badges in DB yet, use default ones for display
        if (allBadges.isEmpty) {
          processedBadges.addAll([
            {'name': 'Early Adopter', 'icon': '🚀', 'desc': 'Joined in the first month', 'unlocked': true},
            {'name': 'First Pool', 'icon': '🏊', 'desc': 'Joined your first pool', 'unlocked': true},
            {'name': 'Reliable', 'icon': '⭐', 'desc': 'Paid on time for 3 cycles', 'unlocked': true},
            {'name': 'Winner', 'icon': '🏆', 'desc': 'Won a pool pot', 'unlocked': false},
            {'name': 'Socialite', 'icon': '🤝', 'desc': 'Referred 5 friends', 'unlocked': false},
            {'name': 'Big Saver', 'icon': '💰', 'desc': 'Contributed over ₹50,000', 'unlocked': false},
          ]);
        } else {
          for (var badge in allBadges) {
            final isUnlocked = userBadges.any((ub) => ub['badge_id'] == badge['id']);
            processedBadges.add({
              'name': badge['name'],
              'icon': badge['icon_url'] ?? '🏅', // Default icon if null
              'desc': badge['description'],
              'unlocked': isUnlocked,
            });
          }
        }

        setState(() {
          _badges = processedBadges;
        });
      }
    } catch (e) {
      print('Error loading badges: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Badges')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Badges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBadges,
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _badges.length,
        itemBuilder: (context, index) {
          final badge = _badges[index];
          final isUnlocked = badge['unlocked'] as bool;

          return Opacity(
            opacity: isUnlocked ? 1.0 : 0.5,
            child: Column(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.amber.shade100 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: isUnlocked ? Border.all(color: Colors.amber, width: 2) : null,
                  ),
                  child: Center(
                    child: Text(
                      badge['icon'] as String,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  badge['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isUnlocked)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.lock, size: 12, color: Colors.grey),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing badges...')));
        },
        icon: const Icon(Icons.share),
        label: const Text('Share Achievements'),
      ),
    );
  }
}
