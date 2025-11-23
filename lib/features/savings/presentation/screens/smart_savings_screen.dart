import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Smart Savings Recommendations Screen
/// Provides AI-powered savings suggestions based on user behavior
class SmartSavingsScreen extends ConsumerStatefulWidget {
  const SmartSavingsScreen({super.key});

  @override
  ConsumerState<SmartSavingsScreen> createState() => _SmartSavingsScreenState();
}

class _SmartSavingsScreenState extends ConsumerState<SmartSavingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    
    // Simulate AI recommendations
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _recommendations = [
        {
          'title': 'Emergency Fund Builder',
          'description': 'Build a 6-month emergency fund with automated savings',
          'targetAmount': 50000.0,
          'monthlyContribution': 5000.0,
          'duration': 10,
          'icon': Icons.security,
          'color': Colors.blue,
          'priority': 'High',
        },
        {
          'title': 'Vacation Savings',
          'description': 'Save for your dream vacation in 12 months',
          'targetAmount': 30000.0,
          'monthlyContribution': 2500.0,
          'duration': 12,
          'icon': Icons.flight,
          'color': Colors.orange,
          'priority': 'Medium',
        },
        {
          'title': 'Investment Starter',
          'description': 'Start investing with a diversified portfolio',
          'targetAmount': 100000.0,
          'monthlyContribution': 8000.0,
          'duration': 12,
          'icon': Icons.trending_up,
          'color': Colors.green,
          'priority': 'High',
        },
        {
          'title': 'Education Fund',
          'description': 'Save for higher education or skill development',
          'targetAmount': 75000.0,
          'monthlyContribution': 6000.0,
          'duration': 12,
          'icon': Icons.school,
          'color': Colors.purple,
          'priority': 'Medium',
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Savings'),
        backgroundColor: const Color(0xFF6C63FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecommendations,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSavingsScore(),
                  const SizedBox(height: 24),
                  const Text(
                    'Recommended for You',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._recommendations.map((rec) => _buildRecommendationCard(rec)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI-Powered Savings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Personalized recommendations based on your spending patterns and financial goals',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsScore() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Savings Score',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '78',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('/100', style: TextStyle(fontSize: 20, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Good! Keep it up',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: 0.78,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                ),
                const Center(
                  child: Icon(Icons.trending_up, size: 40, color: Color(0xFF6C63FF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showRecommendationDetails(rec),
        borderRadius: BorderRadius.circular(16),
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
                      color: (rec['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(rec['icon'] as IconData, color: rec['color'] as Color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec['title'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: rec['priority'] == 'High' ? Colors.red.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${rec['priority']} Priority',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: rec['priority'] == 'High' ? Colors.red : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                rec['description'],
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip('Target', '₹${rec['targetAmount'].toStringAsFixed(0)}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip('Monthly', '₹${rec['monthlyContribution'].toStringAsFixed(0)}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip('Duration', '${rec['duration']} months'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startSavingsPlan(rec),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rec['color'] as Color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start This Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showRecommendationDetails(Map<String, dynamic> rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Icon(rec['icon'] as IconData, size: 64, color: rec['color'] as Color),
            const SizedBox(height: 16),
            Text(
              rec['title'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              rec['description'],
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Target Amount', '₹${rec['targetAmount'].toStringAsFixed(0)}'),
            _buildDetailRow('Monthly Contribution', '₹${rec['monthlyContribution'].toStringAsFixed(0)}'),
            _buildDetailRow('Duration', '${rec['duration']} months'),
            _buildDetailRow('Priority', rec['priority']),
            const SizedBox(height: 24),
            const Text(
              'Benefits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBenefitItem('Automated savings with no manual effort'),
            _buildBenefitItem('Track progress with detailed analytics'),
            _buildBenefitItem('Flexible adjustments anytime'),
            _buildBenefitItem('Community support and motivation'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startSavingsPlan(rec);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: rec['color'] as Color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start This Plan', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _startSavingsPlan(Map<String, dynamic> rec) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Savings Plan'),
        content: Text('Would you like to create a pool for "${rec['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Creating pool for ${rec['title']}...'),
                  backgroundColor: Colors.green,
                ),
              );
              // TODO: Navigate to pool creation with pre-filled data
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: rec['color'] as Color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Pool'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Color(0xFF6C63FF)),
            SizedBox(width: 12),
            Text('About Smart Savings'),
          ],
        ),
        content: const Text(
          'Our AI analyzes your spending patterns, income, and financial goals to provide personalized savings recommendations. '
          'These suggestions are designed to help you achieve your financial objectives faster and more efficiently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
