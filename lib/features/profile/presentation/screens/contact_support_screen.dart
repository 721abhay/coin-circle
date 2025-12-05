import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('How can we help you?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Choose a method to contact us', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _buildContactOption(
            context,
            'Live Chat',
            'Chat with an agent now',
            'Wait time: < 5 mins',
            Icons.chat,
            Colors.green,
            () {},
          ),
          _buildContactOption(
            context,
            'Email Support',
            'Send us a detailed message',
            'Response: < 24 hrs',
            Icons.email,
            Colors.blue,
            () {},
          ),
          _buildContactOption(
            context,
            'Phone Support',
            'Call our support line',
            'Business hours only',
            Icons.phone,
            Colors.orange,
            () {},
          ),
          _buildContactOption(
            context,
            'Submit a Ticket',
            'Report a problem or request help',
            'Track status in app',
            Icons.confirmation_number,
            Colors.purple,
            () => context.push('/support/report-problem'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(BuildContext context, String title, String subtitle, String status, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
