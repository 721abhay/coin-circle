import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/reputation_service.dart';

class ReputationLeaderboardScreen extends ConsumerStatefulWidget {
  const ReputationLeaderboardScreen({super.key});

  @override
  ConsumerState<ReputationLeaderboardScreen> createState() => _ReputationLeaderboardScreenState();
}

class _ReputationLeaderboardScreenState extends ConsumerState<ReputationLeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final data = await ReputationService.getLeaderboard(limit: 100);
      if (mounted) {
        setState(() {
          _leaderboard = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leaderboard: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Reputation Leaderboard'),
        backgroundColor: const Color(0xFFF9F9F9),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLeaderboard,
              child: _buildLeaderboard(),
            ),
    );
  }

  Widget _buildLeaderboard() {
    if (_leaderboard.isEmpty) {
      return const Center(
        child: Text('No users found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final user = _leaderboard[index];
        final rank = index + 1;
        final isTopThree = rank <= 3;

        return GestureDetector(
          onTap: () {
            context.push('/profile/${user['id']}');
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isTopThree
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getRankColor(rank).withOpacity(0.1),
                        _getRankColor(rank).withOpacity(0.05),
                      ],
                    )
                  : null,
              color: isTopThree ? null : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTopThree ? _getRankColor(rank) : Colors.grey.shade200,
                width: isTopThree ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isTopThree ? _getRankColor(rank) : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isTopThree
                        ? Text(
                            _getRankIcon(rank),
                            style: const TextStyle(fontSize: 20),
                          )
                        : Text(
                            rank.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    user['full_name']?[0] ?? '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isTopThree ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user['pools_completed'] ?? 0} pools',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(user['on_time_payment_percentage'] as num?)?.toStringAsFixed(0) ?? 0}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Reputation Score
                Column(
                  children: [
                    Text(
                      user['reputation_score']?.toString() ?? '0',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isTopThree ? _getRankColor(rank) : Colors.black87,
                      ),
                    ),
                    Text(
                      'Score',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }

  String _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return rank.toString();
    }
  }
}
