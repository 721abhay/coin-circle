import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsTab extends StatefulWidget {
  final String poolId;

  const StatisticsTab({super.key, required this.poolId});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await Supabase.instance.client.rpc('get_pool_statistics', params: {
        'p_pool_id': widget.poolId,
      });

      if (mounted) {
        setState(() {
          _stats = Map<String, dynamic>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null) {
      return const Center(child: Text('No statistics available'));
    }

    final completionPercentage = (_stats!['completion_percentage'] as num).toDouble();
    final onTimeRate = (_stats!['on_time_rate'] as num).toDouble();
    final totalCollected = (_stats!['total_collected'] as num).toDouble();
    final onTimePayments = (_stats!['on_time_payments'] as num).toInt();
    final latePayments = (_stats!['late_payments'] as num).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(completionPercentage, onTimeRate, totalCollected),
          const SizedBox(height: 24),
          Text(
            'Payment Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: onTimePayments.toDouble(),
                    title: '$onTimePayments',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: latePayments.toDouble(),
                    title: '$latePayments',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green, 'On-Time'),
              const SizedBox(width: 24),
              _buildLegendItem(Colors.orange, 'Late'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double completion, double onTimeRate, double collected) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildCard('Completion', '${completion.toStringAsFixed(1)}%', Icons.pie_chart, Colors.blue),
        _buildCard('On-Time Rate', '${onTimeRate.toStringAsFixed(1)}%', Icons.timer, Colors.green),
        _buildCard('Total Collected', 'â‚¹${collected.toStringAsFixed(0)}', Icons.attach_money, Colors.amber),
        _buildCard('Member Rating', '4.8/5', Icons.star, Colors.purple),
      ],
    );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
