import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyControlsScreen extends StatefulWidget {
  const PrivacyControlsScreen({super.key});

  @override
  State<PrivacyControlsScreen> createState() => _PrivacyControlsScreenState();
}

class _PrivacyControlsScreenState extends State<PrivacyControlsScreen> {
  bool _shareAnalytics = true;
  bool _publicProfile = true;
  bool _showBalance = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shareAnalytics = prefs.getBool('shareAnalytics') ?? true;
      _publicProfile = prefs.getBool('publicProfile') ?? true;
      _showBalance   = prefs.getBool('showBalance') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      },
          ),

          _buildSectionHeader('Your Data Rights (GDPR/CCPA)'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download My Data'),
            subtitle: const Text('Get a copy of all your activity'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data export requested. We will email you shortly.')));
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion scheduled.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
