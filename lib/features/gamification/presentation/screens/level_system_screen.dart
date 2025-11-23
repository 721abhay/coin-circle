import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gamification_service.dart';

class LevelSystemScreen extends StatefulWidget {
  const LevelSystemScreen({super.key});

  @override
  State<LevelSystemScreen> createState() => _LevelSystemScreenState();
}

class _LevelSystemScreenState extends State<LevelSystemScreen> {
  bool _isLoading = true;
  int _currentLevel = 1;
  int _currentXP = 0;
  int _xpForNextLevel = 500; // Default for level 1
  
  final List<Map<String, dynamic>> _levels = [
    {'level': 1, 'name': 'Newcomer', 'xp': 0, 'benefits': ['Basic features', 'Join up to 3 pools']},
    {'level': 2, 'name': 'Member', 'xp': 500, 'benefits': ['Join up to 5 pools', '5% fee discount']},
    {'level': 3, 'name': 'Regular', 'xp': 1500, 'benefits': ['Join up to 8 pools', '10% fee discount', 'Priority support']},
    {'level': 4, 'name': 'Trusted', 'xp': 3000, 'benefits': ['Join up to 12 pools', '15% fee discount', 'Create private pools']},
    {'level': 5, 'name': 'Veteran', 'xp': 5000, 'benefits': ['Join up to 15 pools', '20% fee discount', 'Verified badge']},
    {'level': 6, 'name': 'Expert', 'xp': 8000, 'benefits': ['Unlimited pools', '25% fee discount', 'Custom pool templates']},
    {'level': 7, 'name': 'Master', 'xp': 12000, 'benefits': ['All Expert benefits', '30% fee discount', 'Featured creator']},
    {'level': 8, 'name': 'Legend', 'xp': 18000, 'benefits': ['All Master benefits', '35% fee discount', 'Exclusive events']},
    {'level': 9, 'name': 'Champion', 'xp': 25000, 'benefits': ['All Legend benefits', '40% fee discount', 'Personal account manager']},
    {'level': 10, 'name': 'Elite', 'xp': 35000, 'benefits': ['Maximum benefits', '50% fee discount', 'VIP status']},
  ];

  final List<Map<String, dynamic>> _xpActivities = [
    {'activity': 'Make a payment', 'xp': 50},
    {'activity': 'Make payment early', 'xp': 75},
    {'activity': 'Complete a pool cycle', 'xp': 200},
    {'activity': 'Invite a friend', 'xp': 100},
    {'activity': 'Friend joins and makes first payment', 'xp': 250},
    {'activity': 'Create a pool', 'xp': 150},
    {'activity': 'Pool fills up', 'xp': 300},
    {'activity': 'Complete a challenge', 'xp': '100-500'},
    {'activity': 'Maintain payment streak (per week)', 'xp': 100},
    {'activity': 'Write a review', 'xp': 50},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await GamificationService.ensureGamificationProfile();
        final profile = await GamificationService.getGamificationProfile(userId);
        
        if (profile != null) {
          setState(() {
            _currentLevel = profile['current_level'] ?? 1;
            _currentXP = profile['current_xp'] ?? 0;
            
            // Calculate XP for next level
            if (_currentLevel < _levels.length) {
              _xpForNextLevel = _levels[_currentLevel]['xp'];
            } else {
              _xpForNextLevel = _currentXP; // Max level reached
            }
          });
        }
      }
    } catch (e) {
      print('Error loading level data: $e');
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
        appBar: AppBar(title: const Text('Level System')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final progressToNext = _currentLevel < _levels.length 
        ? (_currentXP - _levels[_currentLevel - 1]['xp']) / (_xpForNextLevel - _levels[_currentLevel - 1]['xp'])
        : 1.0;
    
    // Ensure progress is between 0 and 1
    final safeProgress = progressToNext.clamp(0.0, 1.0);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCurrentLevelCard(safeProgress),
          const SizedBox(height: 24),
          _buildXPActivities(),
          const SizedBox(height: 24),
          _buildAllLevels(),
        ],
      ),
    );
  }

  Widget _buildCurrentLevelCard(double progress) {
    final currentLevelData = _levels[_currentLevel - 1];
    final nextLevelData = _currentLevel < _levels.length ? _levels[_currentLevel] : null;
    
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Level',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      'Level $_currentLevel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentLevelData['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, size: 48, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'XP Progress',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      '$_currentXP / $_xpForNextLevel XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                if (nextLevelData != null)
                  Text(
                    '${_xpForNextLevel - _currentXP} XP to ${nextLevelData['name']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earn XP',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: _xpActivities.map((activity) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.add, color: Colors.blue.shade700),
                ),
                title: Text(activity['activity']),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${activity['xp']} XP',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAllLevels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Levels',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._levels.map((level) => _LevelCard(
          level: level['level'],
          name: level['name'],
          xp: level['xp'],
          benefits: List<String>.from(level['benefits']),
          isUnlocked: level['level'] <= _currentLevel,
          isCurrent: level['level'] == _currentLevel,
        )),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final String name;
  final int xp;
  final List<String> benefits;
  final bool isUnlocked;
  final bool isCurrent;

  const _LevelCard({
    required this.level,
    required this.name,
    required this.xp,
    required this.benefits,
    required this.isUnlocked,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCurrent 
          ? Colors.blue.shade50 
          : isUnlocked 
              ? Colors.green.shade50 
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.blue : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '$xp XP required',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isUnlocked ? Icons.check_circle : Icons.lock,
                  color: isUnlocked ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Benefits:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: isUnlocked ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnlocked ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
