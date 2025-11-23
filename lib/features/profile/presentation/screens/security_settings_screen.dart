import 'package:flutter/material.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = true;
  bool _pinEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Authentication'),
          _buildSwitchTile(
            'Two-Factor Authentication',
            'Secure your account with SMS/Email OTP',
            _twoFactorEnabled,
            (val) => setState(() => _twoFactorEnabled = val),
          ),
          _buildSwitchTile(
            'Biometric Login',
            'Use Fingerprint or Face ID',
            _biometricEnabled,
            (val) => setState(() => _biometricEnabled = val),
          ),

          _buildSectionHeader('Transaction Security'),
          _buildSwitchTile(
            'Transaction PIN',
            'Require PIN for all payments',
            _pinEnabled,
            (val) => setState(() => _pinEnabled = val),
          ),
          ListTile(
            title: const Text('Change PIN'),
            enabled: _pinEnabled,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter current PIN')));
            },
          ),

          _buildSectionHeader('Device Management'),
          _buildDeviceTile('iPhone 14 Pro', 'Current Device', true),
          _buildDeviceTile('Chrome Browser', 'Last active: 2 days ago', false),
          
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.security_update_warning),
            label: const Text('Log Out All Devices'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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

  Widget _buildDeviceTile(String name, String status, bool isCurrent) {
    return ListTile(
      leading: Icon(Icons.smartphone, color: isCurrent ? Colors.green : Colors.grey),
      title: Text(name),
      subtitle: Text(status),
      trailing: isCurrent 
          ? const Chip(label: Text('Active', style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.green)
          : IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {}),
      contentPadding: EdgeInsets.zero,
    );
  }
}
