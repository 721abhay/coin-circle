import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coin_circle/core/services/auth_service.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/profile_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ProfileService _profileService = ProfileService();
  String _verificationStatus = 'Loading...';
  String _linkedAccount = 'Loading...';
  String _profileVisibility = 'Private';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final status = await _profileService.getVerificationStatus();
      final provider = _profileService.getLinkedProvider();
      final profile = await _profileService.getProfile();
      
      String visibility = 'Private';
      if (profile != null) {
        // Check if column exists, otherwise check metadata
        if (profile.containsKey('profile_visibility')) {
          visibility = profile['profile_visibility'] ?? 'Private';
        } else {
          // Fallback to metadata
          final user = AuthService().currentUser;
          if (user != null && user.userMetadata != null) {
            visibility = user.userMetadata?['profile_visibility'] ?? 'Private';
          }
        }
      }

      if (mounted) {
        setState(() {
          _verificationStatus = status;
          _linkedAccount = provider;
          _profileVisibility = visibility;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _verificationStatus = 'Not Verified';
          _linkedAccount = 'Email';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfileVisibility(String visibility) async {
    setState(() => _profileVisibility = visibility);
    await _profileService.updateProfileVisibility(visibility);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile visibility set to $visibility')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('Account'),
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Personal Information',
            onTap: () => context.push('/profile-setup'),
          ),
          _buildListTile(
            icon: Icons.lock_outline,
            title: 'Password & Security',
            onTap: () => context.push('/settings/security'),
          ),
          _buildListTile(
            icon: Icons.verified_user_outlined,
            title: 'Verification Status',
            trailing: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : _verificationStatus == 'Verified'
                    ? const Chip(
                        label: Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10)),
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )
                    : const Text('Not Verified', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () => context.push('/settings/kyc'),
          ),
          _buildListTile(
            icon: Icons.link,
            title: 'Linked Accounts',
            trailing: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_linkedAccount, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              // Show linked accounts details
            },
          ),
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Personal Details',
            subtitle: 'Contact, PAN, Income details',
            onTap: () => context.push('/profile/personal-details'),
          ),
          _buildListTile(
            icon: Icons.account_balance,
            title: 'Bank Accounts',
            subtitle: 'Manage your bank accounts',
            onTap: () => context.push('/profile/bank-accounts'),
          ),

          _buildSectionHeader('App Settings'),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            value: settings.darkMode,
            onChanged: (val) async {
              await settingsNotifier.toggleDarkMode(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? 'Dark mode enabled' : 'Dark mode disabled')),
              );
            },
          ),

          _buildSwitchTile(
            icon: Icons.data_saver_on,
            title: 'Data Saver',
            subtitle: 'Reduce data usage',
            value: settings.dataSaver,
            onChanged: (val) async {
              await settingsNotifier.toggleDataSaver(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? 'Data saver enabled' : 'Data saver disabled')),
              );
            },
          ),

          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            value: settings.pushNotifications,
            onChanged: (val) async {
              await settingsNotifier.togglePushNotifications(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? 'Push notifications enabled' : 'Push notifications disabled')),
              );
            },
          ),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Email Updates',
            value: settings.emailNotifications,
            onChanged: (val) async {
              await settingsNotifier.toggleEmailNotifications(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? 'Email notifications enabled' : 'Email notifications disabled')),
              );
            },
          ),

          _buildSectionHeader('Privacy & Security'),
          // Biometric Login removed as requested
          
          _buildListTile(
            icon: Icons.visibility_outlined,
            title: 'Profile Visibility',
            trailing: Text(_profileVisibility, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () => _showVisibilityDialog(),
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => context.push('/settings/privacy'),
          ),
          _buildSwitchTile(
            icon: Icons.online_prediction,
            title: 'Show Online Status',
            value: settings.showOnlineStatus,
            onChanged: (val) async {
              await settingsNotifier.toggleShowOnlineStatus(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? 'Online status visible' : 'Online status hidden')),
              );
            },
          ),
          _buildListTile(
            icon: Icons.group_add_outlined,
            title: 'Who Can Invite Me',
            trailing: const Text('Friends Only', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite permissions coming soon')),
              );
            },
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
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      activeThumbColor: Theme.of(context).primaryColor,
    );
  }



  void _showVisibilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Visibility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Public'),
              subtitle: const Text('Everyone can see your profile'),
              value: 'Public',
              groupValue: _profileVisibility,
              onChanged: (val) {
                _updateProfileVisibility(val!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Friends Only'),
              subtitle: const Text('Only friends can see your profile'),
              value: 'Friends Only',
              groupValue: _profileVisibility,
              onChanged: (val) {
                _updateProfileVisibility(val!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Private'),
              subtitle: const Text('Only you can see your profile'),
              value: 'Private',
              groupValue: _profileVisibility,
              onChanged: (val) {
                _updateProfileVisibility(val!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
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
              SecurityService.setSessionVerified(false);
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
