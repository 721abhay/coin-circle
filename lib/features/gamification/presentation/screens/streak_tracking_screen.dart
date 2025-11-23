import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/services/wallet_management_service.dart';

class StreakTrackingScreen extends StatefulWidget {
  const StreakTrackingScreen({super.key});

  @override
  State<StreakTrackingScreen> createState() => _StreakTrackingScreenState();
}

class _StreakTrackingScreenState extends State<StreakTrackingScreen> {
  bool _isLoading = true;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalPayments = 0;
  
  List<Map<String, dynamic>> _streakMilestones = [
    {'days': 7, 'reward': '50 Points', 'achieved': false},
    {'days': 30, 'reward': '200 Points + Bronze Badge', 'achieved': false},
    {'days': 60, 'reward': '500 Points + Silver Badge', 'achieved': false},
    {'days': 90, 'reward': '1000 Points + Gold Badge', 'achieved': false},
    {'days': 180, 'reward': '2500 Points + Platinum Badge', 'achieved': false},
    {'days': 365, 'reward': '5000 Points + Diamond Badge', 'achieved': false},
  ];

  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _streakLogs = [];

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
        final logs = await GamificationService.getStreakLogs(userId);
        
        if (profile != null) {
          setState(() {
            _currentStreak = profile['current_streak'] ?? 0;
            _longestStreak = profile['longest_streak'] ?? 0;
            _totalPayments = profile['total_points'] ?? 0; // Using points as proxy for now
          });
        }

        final transactions = await WalletManagementService.getTransactions();
        
        if (mounted) {
          setState(() {
            _streakLogs = logs;
            
            // Map transactions to recent activity format
            // Filter for contributions (payments to pools)
            final contributions = transactions
                .where((t) => t['transaction_type'] == 'contribution')
                .take(5);
                
            _recentActivity = contributions.map((t) {
              final poolName = t['pool'] != null ? t['pool']['name'] : 'Unknown Pool';
              return {
                'date': t['created_at'],
                'type': 'Payment',
                'pool': poolName,
                'amount': t['amount'],
              };
            }).toList();
            
            // Update milestones
            for (var milestone in _streakMilestones) {
              milestone['achieved'] = _currentStreak >= (milestone['days'] as int);
            }
          });
        }
      }
    } catch (e) {
      print('Error loading streak data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
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
        appBar: AppBar(title: const Text('Payment Streaks')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Streaks'),
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
          _buildCurrentStreakCard(),
          const SizedBox(height: 16),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildCalendarView(),
          const SizedBox(height: 24),
          _buildMilestonesSection(),
          const SizedBox(height: 24),
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildCurrentStreakCard() {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.local_fire_department, size: 64, color: Colors.white),
            const SizedBox(height: 12),
            const Text(
              'Current Streak',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_currentStreak Days',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep it up! ${_getNextMilestone() - _currentStreak} days until next reward',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events,
            label: 'Longest Streak',
            value: '$_longestStreak days',
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.payment,
            label: 'Total Payments',
            value: '$_totalPayments',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: DateTime.now().day, // Show up to today
              itemBuilder: (context, index) {
                final day = index + 1;
                final now = DateTime.now();
                final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, day));
                
                final hasPayment = _streakLogs.any((log) => 
                  log['activity_date'].toString().startsWith(dateStr) && 
                  log['activity_type'] == 'payment'
                );
                
                return Container(
                  decoration: BoxDecoration(
                    color: hasPayment ? Colors.green.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasPayment ? Colors.green : Colors.grey.shade300,
                      width: hasPayment ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: hasPayment ? FontWeight.bold : FontWeight.normal,
                        color: hasPayment ? Colors.green.shade900 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.green.shade100, label: 'Payment Made'),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.grey.shade100, label: 'No Payment'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Streak Milestones',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._streakMilestones.map((milestone) => _MilestoneCard(
          days: milestone['days'],
          reward: milestone['reward'],
          achieved: milestone['achieved'],
          current: _currentStreak,
        )),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: _recentActivity.map((activity) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.check, color: Colors.green.shade700),
                ),
                title: Text(activity['pool']),
                subtitle: Text(
                  DateFormat('MMM d, yyyy').format(DateTime.parse(activity['date'])),
                ),
                trailing: Text(
                  '₹${activity['amount']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  int _getNextMilestone() {
    for (var milestone in _streakMilestones) {
      if (!milestone['achieved']) {
        return milestone['days'] as int;
      }
    }
    return 365;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final int days;
  final String reward;
  final bool achieved;
  final int current;

  const _MilestoneCard({
    required this.days,
    required this.reward,
    required this.achieved,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / days * 100).clamp(0, 100);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: achieved ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: achieved ? Colors.green : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achieved ? Icons.check : Icons.lock,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$days Day Streak',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        reward,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (achieved)
                  Icon(Icons.emoji_events, color: Colors.amber.shade700)
                else
                  Text(
                    '${days - current} days',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            if (!achieved) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 75 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${progress.toStringAsFixed(0)}% Complete',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
