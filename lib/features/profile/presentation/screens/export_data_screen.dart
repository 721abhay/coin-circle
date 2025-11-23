import 'package:flutter/material.dart';

class ExportDataScreen extends StatelessWidget {
  const ExportDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Download your data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can download a copy of your data in JSON or CSV format.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildExportOption(
              context,
              title: 'Transaction History',
              description: 'All your deposits, withdrawals, and contributions',
              icon: Icons.receipt_long,
            ),
            const SizedBox(height: 16),
            _buildExportOption(
              context,
              title: 'Pool Activity',
              description: 'History of pools you participated in',
              icon: Icons.groups,
            ),
            const SizedBox(height: 16),
            _buildExportOption(
              context,
              title: 'Account Data',
              description: 'Your profile information and settings',
              icon: Icons.person,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(icon, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exporting $title...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
