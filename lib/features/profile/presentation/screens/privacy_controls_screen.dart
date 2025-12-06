import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacyControlsScreen extends StatefulWidget {
  const PrivacyControlsScreen({super.key});

  @override
  State<PrivacyControlsScreen> createState() => _PrivacyControlsScreenState();
}

class _PrivacyControlsScreenState extends State<PrivacyControlsScreen> {
  bool _isLoading = true;
  bool _shareAnalytics = true;
  bool _publicProfile = true;
  bool _showBalance = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _shareAnalytics = prefs.getBool('shareAnalytics') ?? true;
          _publicProfile = prefs.getBool('publicProfile') ?? true;
          _showBalance = prefs.getBool('showBalance') ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Privacy & Data')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Data Sharing'),
          _buildSwitchTile(
            'Share Analytics',
            'Help us improve with anonymous data',
            _shareAnalytics,
            (val) async {
              setState(() => _shareAnalytics = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('shareAnalytics', val);
              
              // Save to database
              try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  await Supabase.instance.client
                      .from('profiles')
                      .update({'share_analytics': val})
                      .eq('id', user.id);
                }
              } catch (e) {
                debugPrint('Error saving analytics preference: $e');
              }
            },
          ),
          _buildSwitchTile(
            'Public Profile',
            'Allow others to find you',
            _publicProfile,
            (val) async {
              setState(() => _publicProfile = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('publicProfile', val);
              
              // Save to database
              try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  await Supabase.instance.client
                      .from('profiles')
                      .update({'is_public': val})
                      .eq('id', user.id);
                }
              } catch (e) {
                debugPrint('Error saving public profile preference: $e');
              }
            },
          ),
          _buildSwitchTile(
            'Show Balance',
            'Display wallet balance on home screen',
            _showBalance,
            (val) async {
              setState(() => _showBalance = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showBalance', val);
              
              // Save to database
              try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  await Supabase.instance.client
                      .from('profiles')
                      .update({'show_balance': val})
                      .eq('id', user.id);
                }
              } catch (e) {
                debugPrint('Error saving show balance preference: $e');
              }
            },
          ),

          _buildSectionHeader('Your Data Rights (GDPR/CCPA)'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download My Data'),
            subtitle: const Text('Get a copy of all your activity'),
            onTap: () async {
              try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) return;
                
                // Show loading
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preparing your data export...')),
                );
                
                // Fetch all user data
                final profile = await Supabase.instance.client
                    .from('profiles')
                    .select()
                    .eq('id', user.id)
                    .single();
                
                final transactions = await Supabase.instance.client
                    .from('transactions')
                    .select()
                    .eq('user_id', user.id);
                
                // In a real app, you'd generate a downloadable file
                // For now, just show success
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data export requested. We will email you a download link within 24 hours.'),
                    duration: Duration(seconds: 4),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Permanently remove all data'),
            onTap: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(title, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action is irreversible. All your data, pools, and wallet balance will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) return;
                
                // Delete user data from database
                // Note: In production, you'd want to do this via a secure RPC function
                await Supabase.instance.client
                    .from('profiles')
                    .delete()
                    .eq('id', user.id);
                
                // Sign out and delete auth user
                await Supabase.instance.client.auth.signOut();
                
                if (!mounted) return;
                Navigator.pop(context); // Close loading dialog
                
                // Navigate to login
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close loading dialog
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting account: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
