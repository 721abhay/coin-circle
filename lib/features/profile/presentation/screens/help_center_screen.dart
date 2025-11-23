import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 24),
          const Text('Popular Topics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTopicTile(context, 'Getting Started', Icons.rocket_launch),
          _buildTopicTile(context, 'Payments & Wallet', Icons.account_balance_wallet),
          _buildTopicTile(context, 'Pool Management', Icons.groups),
          _buildTopicTile(context, 'Troubleshooting', Icons.build),
          const SizedBox(height: 24),
          const Text('Resources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildResourceTile(context, 'Video Tutorials', Icons.play_circle_outline),
          _buildResourceTile(context, 'FAQs', Icons.question_answer_outlined),
          _buildResourceTile(context, 'Glossary', Icons.menu_book),
          const SizedBox(height: 24),
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: ListTile(
              leading: Icon(Icons.support_agent, color: Theme.of(context).primaryColor),
              title: const Text('Need more help?'),
              subtitle: const Text('Contact our support team'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/support/contact'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search for help...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildTopicTile(BuildContext context, String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  Widget _buildResourceTile(BuildContext context, String title, IconData icon) {
    String route = '';
    if (title == 'Video Tutorials') {
      route = '/support/tutorials';
    } else if (title == 'FAQs') {
      route = '/support/faq';
    }
    
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: route.isNotEmpty ? () => context.push(route) : () {},
    );
  }
}
