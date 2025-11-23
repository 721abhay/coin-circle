import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    // Mock data
    final List<Map<String, dynamic>> users = List.generate(10, (index) => {
      'rank': index + 1,
      'name': 'User ${index + 1}',
      'score': 1000 - (index * 50),
      'avatar': 'https://i.pravatar.cc/150?img=${index + 1}',
      'badge': index < 3 ? ['🥇', '🥈', '🥉'][index] : null,
    });

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
                  backgroundImage: NetworkImage(user['avatar']),
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
  }
}
