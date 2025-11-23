import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/platform_stats.dart';

class AnalyticsTab extends StatelessWidget {
  final PlatformStats stats;

  const AnalyticsTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Pool Distribution'),
          const SizedBox(height: 16),
          _buildPoolStatusChart(context),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'User Status'),
          const SizedBox(height: 16),
          _buildUserStatusChart(context),
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'Financial Overview'),
          const SizedBox(height: 16),
          _buildFinancialSummary(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildPoolStatusChart(BuildContext context) {
    final total = stats.totalPools;
    if (total == 0) return const Center(child: Text('No pool data available'));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    if (stats.activePools > 0)
                      PieChartSectionData(
                        color: Colors.green,
                        value: stats.activePools.toDouble(),
                        title: '${((stats.activePools / total) * 100).toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (stats.pendingPools > 0)
                      PieChartSectionData(
                        color: Colors.orange,
                        value: stats.pendingPools.toDouble(),
                        title: '${((stats.pendingPools / total) * 100).toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (stats.completedPools > 0)
                      PieChartSectionData(
                        color: Colors.blue,
                        value: stats.completedPools.toDouble(),
                        title: '${((stats.completedPools / total) * 100).toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (stats.totalPools - stats.activePools - stats.pendingPools - stats.completedPools > 0)
                      PieChartSectionData(
                        color: Colors.red,
                        value: (stats.totalPools - stats.activePools - stats.pendingPools - stats.completedPools).toDouble(),
                        title: '${(((stats.totalPools - stats.activePools - stats.pendingPools - stats.completedPools) / total) * 100).toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Active', Colors.green, stats.activePools),
                _buildLegendItem('Pending', Colors.orange, stats.pendingPools),
                _buildLegendItem('Completed', Colors.blue, stats.completedPools),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatusChart(BuildContext context) {
    final total = stats.totalUsers;
    if (total == 0) return const Center(child: Text('No user data available'));

    final active = stats.activeUsers;
    final suspended = stats.suspendedUsers;
    final inactive = total - active - suspended;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 150,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 30,
                    sections: [
                      PieChartSectionData(
                        color: Colors.green,
                        value: active.toDouble(),
                        title: '',
                        radius: 40,
                      ),
                      PieChartSectionData(
                        color: Colors.red,
                        value: suspended.toDouble(),
                        title: '',
                        radius: 40,
                      ),
                      PieChartSectionData(
                        color: Colors.grey,
                        value: inactive.toDouble(),
                        title: '',
                        radius: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem('Active', Colors.green, active),
                  const SizedBox(height: 8),
                  _buildLegendItem('Suspended', Colors.red, suspended),
                  const SizedBox(height: 8),
                  _buildLegendItem('Inactive', Colors.grey, inactive),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFinancialRow(
              context,
              'Total Transaction Volume',
              '₹${stats.totalTransactionVolume.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.green,
            ),
            const Divider(),
            _buildFinancialRow(
              context,
              'Total Payouts',
              '₹${stats.totalPayouts.toStringAsFixed(2)}',
              Icons.payments,
              Colors.blue,
            ),
            const Divider(),
            _buildFinancialRow(
              context,
              'Avg. Contribution',
              '₹${stats.averageContribution.toStringAsFixed(2)}',
              Icons.trending_up,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(BuildContext context, String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($value)',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
