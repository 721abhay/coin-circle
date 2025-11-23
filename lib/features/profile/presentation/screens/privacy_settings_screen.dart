import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isLoading = true;
  bool _showProfile = true;
  bool _showActivity = true;
  bool _emailNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('profiles')
          .select('privacy_settings')
          .eq('id', userId)
          .single();

      if (data['privacy_settings'] != null) {
        final settings = data['privacy_settings'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _showProfile = settings['show_profile'] ?? true;
            _showActivity = settings['show_activity'] ?? true;
            _emailNotifications = settings['email_notifications'] ?? true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    // Optimistic update
    setState(() {
      if (key == 'show_profile') _showProfile = value;
      if (key == 'show_activity') _showActivity = value;
      if (key == 'email_notifications') _emailNotifications = value;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final newSettings = {
        'show_profile': _showProfile,
        'show_activity': _showActivity,
        'email_notifications': _emailNotifications,
      };

      await Supabase.instance.client
          .from('profiles')
          .update({'privacy_settings': newSettings})
          .eq('id', userId);
          
    } catch (e) {
      // Revert on error (simplified, ideally would revert state)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating setting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Visibility'),
                SwitchListTile(
                  title: const Text('Public Profile'),
                  subtitle: const Text('Allow others to find and view your profile'),
                  value: _showProfile,
                  onChanged: (val) => _updateSetting('show_profile', val),
                  activeColor: Theme.of(context).primaryColor,
                ),
                SwitchListTile(
                  title: const Text('Activity Status'),
                  subtitle: const Text('Show when you are active in pools'),
                  value: _showActivity,
                  onChanged: (val) => _updateSetting('show_activity', val),
                  activeColor: Theme.of(context).primaryColor,
                ),
                const Divider(height: 32),
                _buildSectionHeader('Notifications'),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive updates via email'),
                  value: _emailNotifications,
                  onChanged: (val) => _updateSetting('email_notifications', val),
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
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
}
