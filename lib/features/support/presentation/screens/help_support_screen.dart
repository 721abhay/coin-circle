import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSupportItem(
            context,
            icon: Icons.question_answer,
            title: 'FAQs',
            subtitle: 'Frequently asked questions',
            onTap: () {},
          ),
          _buildSupportItem(
            context,
            icon: Icons.chat,
            title: 'Chat with Support',
            subtitle: 'Get instant help',
            onTap: () => context.push('/submit-ticket'),
          ),
          _buildSupportItem(
            context,
            icon: Icons.email,
            title: 'Email Us',
            subtitle: 'support@winpool.com',
            onTap: () => context.push('/submit-ticket'),
          ),
          _buildSupportItem(
            context,
            icon: Icons.phone,
            title: 'Call Us',
            subtitle: '+91 1234567890',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
