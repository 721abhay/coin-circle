import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GoalBasedPoolScreen extends StatefulWidget {
  final String poolId;
  
  const GoalBasedPoolScreen({super.key, required this.poolId});

  @override
  State<GoalBasedPoolScreen> createState() => _GoalBasedPoolScreenState();
}

class _GoalBasedPoolScreenState extends State<GoalBasedPoolScreen> {
  final _goalNameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  
  String _goalType = 'Vacation';
  final DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  double _currentAmount = 0;
  double _targetAmount = 50000;
  
  final List<String> _goalTypes = [
    'Vacation',
    'Emergency Fund',
    'Education',
    'Home Purchase',
    'Wedding',
    'Business',
    'Vehicle',
    'Other',
  ];

  final List<Map<String, dynamic>> _milestones = [
    {'percentage': 25, 'name': '25% Milestone', 'reached': true, 'date': '2024-03-15'},
    {'percentage': 50, 'name': '50% Milestone', 'reached': true, 'date': '2024-06-20'},
    {'percentage': 75, 'name': '75% Milestone', 'reached': false, 'date': null},
    {'percentage': 100, 'name': 'Goal Achieved!', 'reached': false, 'date': null},
  ];

  @override
  void initState() {
    super.initState();
    _currentAmount = 25000; // Mock current amount
    _targetAmount = 50000;
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  double get _progressPercentage => (_currentAmount / _targetAmount * 100).clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal-Based Pool'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditGoalDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalHeader(),
            const SizedBox(height: 24),
            _buildProgressCard(),
            const SizedBox(height: 24),
            _buildMilestones(),
            const SizedBox(height: 24),
            _buildContributionStats(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getGoalIcon(_goalType),
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dream Vacation 2025',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _goalType,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(_targetDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Days Remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${_targetDate.difference(DateTime.now()).inDays}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '₹${NumberFormat('#,##,###').format(_currentAmount)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '₹${NumberFormat('#,##,###').format(_targetAmount)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progressPercentage / 100,
                minHeight: 20,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progressPercentage >= 75
                      ? Colors.green
                      : _progressPercentage >= 50
                          ? Colors.orange
                          : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_progressPercentage.toStringAsFixed(1)}% Complete',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Remaining: ₹${NumberFormat('#,##,###').format(_targetAmount - _currentAmount)}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Milestones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._milestones.map((milestone) => _MilestoneCard(
          percentage: milestone['percentage'],
          name: milestone['name'],
          reached: milestone['reached'],
          date: milestone['date'],
        )),
      ],
    );
  }

  Widget _buildContributionStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contribution Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _StatRow(
              icon: Icons.people,
              label: 'Total Members',
              value: '8',
            ),
            _StatRow(
              icon: Icons.account_balance_wallet,
              label: 'Average per Member',
              value: '₹${NumberFormat('#,###').format(_currentAmount / 8)}',
            ),
            _StatRow(
              icon: Icons.calendar_today,
              label: 'Contributions Made',
              value: '24 / 96',
            ),
            _StatRow(
              icon: Icons.speed,
              label: 'Monthly Rate',
              value: '₹${NumberFormat('#,###').format(_currentAmount / 6)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to contribute
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Make Contribution'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Share goal
            },
            icon: const Icon(Icons.share),
            label: const Text('Share Goal Progress'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _goalNameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _goalType,
                decoration: const InputDecoration(
                  labelText: 'Goal Type',
                  border: OutlineInputBorder(),
                ),
                items: _goalTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _goalType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon(String type) {
    switch (type) {
      case 'Vacation':
        return Icons.beach_access;
      case 'Emergency Fund':
        return Icons.health_and_safety;
      case 'Education':
        return Icons.school;
      case 'Home Purchase':
        return Icons.home;
      case 'Wedding':
        return Icons.favorite;
      case 'Business':
        return Icons.business_center;
      case 'Vehicle':
        return Icons.directions_car;
      default:
        return Icons.flag;
    }
  }
}

class _MilestoneCard extends StatelessWidget {
  final int percentage;
  final String name;
  final bool reached;
  final String? date;

  const _MilestoneCard({
    required this.percentage,
    required this.name,
    required this.reached,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: reached ? Colors.green.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: reached ? Colors.green : Colors.grey.shade300,
          child: Icon(
            reached ? Icons.check : Icons.flag,
            color: reached ? Colors.white : Colors.grey.shade600,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: reached ? Colors.green.shade900 : null,
          ),
        ),
        subtitle: Text(
          reached && date != null
              ? 'Reached on ${DateFormat('MMM d, yyyy').format(DateTime.parse(date!))}'
              : '$percentage% of target',
        ),
        trailing: reached
            ? Icon(Icons.celebration, color: Colors.green.shade700)
            : null,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
