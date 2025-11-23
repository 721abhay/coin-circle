import 'package:flutter/material.dart';

class ModerationDashboardScreen extends StatelessWidget {
  final String? poolId;
  const ModerationDashboardScreen({super.key, this.poolId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moderation Tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Chat Moderation'),
          _buildActionTile(
            context,
            'Mute Members',
            'Restrict chat access',
            Icons.mic_off,
            () {},
          ),
          _buildActionTile(
            context,
            'Delete Messages',
            'Remove inappropriate content',
            Icons.delete_outline,
            () {},
          ),
          _buildActionTile(
            context,
            'Pin Message',
            'Highlight important info',
            Icons.push_pin_outlined,
            () {},
          ),

          const SizedBox(height: 24),
          _buildSection('User Actions'),
          _buildActionTile(
            context,
            'Ban User',
            'Remove and block from pool',
            Icons.block,
            () {},
          ),
          _buildActionTile(
            context,
            'Report to Support',
            'Escalate serious issues',
            Icons.report_problem_outlined,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.red),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
