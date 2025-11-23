import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coin_circle/core/services/auth_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _darkMode = false;
  bool _biometricEnabled = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('Account'),
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () => context.push('/profile-setup'), // Re-use profile setup for editing
          ),
          _buildListTile(
            icon: Icons.lock_outline,
            title: 'Password & Security',
            onTap: () => context.push('/settings/security'),
          ),
          _buildListTile(
            icon: Icons.verified_user_outlined,
            title: 'Verification Status',
            trailing: const Chip(
              label: Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10)),
              backgroundColor: Colors.green,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            onTap: () => context.push('/settings/kyc'),
          ),
          _buildListTile(
            icon: Icons.link,
            title: 'Linked Accounts',
            trailing: const Text('Google', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),

          _buildSectionHeader('App Settings'),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            value: _darkMode,
            onChanged: (val) => setState(() => _darkMode = val),
          ),
          _buildListTile(
            icon: Icons.language_outlined,
            title: 'Language',
            trailing: const Text('English', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.currency_exchange,
            title: 'Currency',
            trailing: const Text('INR (₹)', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.format_size,
            title: 'Font Size',
            trailing: const Text('Medium', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
          _buildSwitchTile(
            icon: Icons.data_saver_on,
            title: 'Data Saver',
            value: false,
            onChanged: (val) {},
          ),

          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            value: _pushNotifications,
            onChanged: (val) => setState(() => _pushNotifications = val),
          ),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Email Updates',
            value: _emailNotifications,
            onChanged: (val) => setState(() => _emailNotifications = val),
          ),

          _buildSectionHeader('Privacy & Security'),
          _buildSwitchTile(
            icon: Icons.fingerprint,
            title: 'Biometric Login',
            value: _biometricEnabled,
            onChanged: (val) => setState(() => _biometricEnabled = val),
          ),
          _buildListTile(
            icon: Icons.visibility_outlined,
            title: 'Profile Visibility',
            trailing: const Text('Public', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => context.push('/settings/privacy'),
          ),
          _buildSwitchTile(
            icon: Icons.online_prediction,
            title: 'Show Online Status',
            value: true,
            onChanged: (val) {},
          ),
          _buildListTile(
            icon: Icons.group_add_outlined,
            title: 'Who Can Invite Me',
            trailing: const Text('Everyone', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => context.push('/support/terms'),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Support & Help'),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () => context.push('/help'),
          ),
          _buildListTile(
            icon: Icons.report_problem_outlined,
            title: 'Report a Problem',
            onTap: () => context.push('/submit-ticket'),
          ),
          _buildListTile(
            icon: Icons.question_answer_outlined,
            title: 'FAQs',
            onTap: () => context.push('/support/faq'),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Account'),
          _buildListTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Account Management',
            onTap: () => context.push('/settings/account-management'),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      activeColor: Theme.of(context).primaryColor,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
