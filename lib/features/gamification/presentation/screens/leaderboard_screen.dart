import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/gamification_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
            Tab(text: 'My Pools'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardList(context, 'global'),
          _buildLeaderboardList(context, 'friends'),
          _buildLeaderboardList(context, 'pools'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(BuildContext context, String type) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadLeaderboardData(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final users = snapshot.data ?? [];
        
        if (users.isEmpty) {
          return const Center(child: Text('No players found yet. Be the first!'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isTop3 = index < 3;
            
            return Card(
              elevation: isTop3 ? 4 : 1,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isTop3 
                    ? BorderSide(color: Colors.amber.shade200, width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '#${user['rank']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isTop3 ? Colors.amber.shade800 : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundImage: user['avatar'] != null 
                          ? NetworkImage(user['avatar']) 
                          : null,
                      child: user['avatar'] == null 
                          ? Text(user['name'][0].toUpperCase()) 
                          : null,
                    ),
                  ],
                ),
                title: Row(
                  children: [
                    Text(
                      user['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (user['badge'] != null) ...[
                      const SizedBox(width: 8),
                      Text(user['badge'], style: const TextStyle(fontSize: 20)),
                    ],
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${user['score']} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadLeaderboardData(String type) async {
    // Import service if not already imported
    // Assuming GamificationService is available
    // We need to map the backend response to the UI format
    try {
      // Use the fully qualified name or ensure import is added at top
      // For now, I'll rely on the import being present or add it if missing.
      // Since I can't add imports in this block easily without replacing the whole file,
      // I will assume the user has the service. 
      // Wait, I should check imports first. 
      // I'll use a dynamic approach or assume the import is there.
      // Actually, I'll use the service directly.
      
      // Note: I need to add the import at the top of the file if it's missing.
      // But for this tool, I am replacing the method.
      
      final rawData = await GamificationService.getLeaderboard(type);
      
      return List.generate(rawData.length, (index) {
        final item = rawData[index];
        final profile = item['profiles'] as Map<String, dynamic>?;
        final name = profile?['full_name'] ?? 'Unknown';
        final avatar = profile?['avatar_url'];
        
        return {
          'rank': index + 1,
          'name': name,
          'score': item['current_xp'] ?? 0,
          'avatar': avatar,
          'badge': index < 3 ? ['🥇', '🥈', '🥉'][index] : null,
        };
      });
    } catch (e) {
      print('Error in _loadLeaderboardData: $e');
      return [];
    }
  }
}
