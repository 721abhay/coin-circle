import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
            onTap: () => context.push('/faq'),
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
            subtitle: 'winpoolqsypport@gmail.com',
            onTap: () => _launchEmail(context),
          ),
          _buildSupportItem(
            context,
            icon: Icons.phone,
            title: 'Call Us',
            subtitle: '+91 1234567890',
            onTap: () => _launchPhone(context),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'winpoolqsypport@gmail.com',
      query: 'subject=Support Request from Win Pool App',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email app. Please email us at winpoolqsypport@gmail.com'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening email app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '+911234567890',
    );

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open phone app. Please call +91 1234567890'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening phone app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
