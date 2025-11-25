import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/security_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final pinEnabled = await SecurityService.isPinEnabled();
      final biometricAvailable = await SecurityService.isBiometricAvailable();
      
      // Load biometric preference
      final prefs = await SharedPreferences.getInstance();
      final biometricPref = prefs.getBool('biometric_login_enabled') ?? false;
      
      if (mounted) {
        setState(() {
          _pinEnabled = pinEnabled;
          _biometricEnabled = biometricAvailable && biometricPref;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      // Navigate to PIN setup
      final result = await context.push('/setup-pin');
      if (result == true) {
        setState(() => _pinEnabled = true);
      }
    } else {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable Transaction PIN?'),
          content: const Text('This will remove PIN protection from your transactions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Disable'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // TODO: Implement PIN removal
        setState(() => _pinEnabled = false);
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Check if biometric is available
      final available = await SecurityService.isBiometricAvailable();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication is not available on this device'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Authenticate to enable
      final authenticated = await SecurityService.authenticateWithBiometric(
        reason: 'Enable biometric authentication for login',
      );
      
      if (authenticated) {
        // Save preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_login_enabled', true);
        
        setState(() => _biometricEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric login enabled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Disable biometric
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_login_enabled', false);
      
      setState(() => _biometricEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric login disabled'),
          ),
        );
      }
    }
  }

  Future<void> _toggle2FA(bool value) async {
    if (value) {
      // Show 2FA setup dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable 2FA'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Two-factor authentication adds an extra layer of security.'),
              SizedBox(height: 16),
              Text('Choose your preferred method:'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _twoFactorEnabled = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('2FA enabled via SMS')),
                );
              },
              child: const Text('SMS'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _twoFactorEnabled = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('2FA enabled via Email')),
                );
              },
              child: const Text('Email'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _twoFactorEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Authentication'),
          _buildSwitchTile(
            'Two-Factor Authentication',
            'Secure your account with SMS/Email OTP',
            _twoFactorEnabled,
            _toggle2FA,
          ),
          _buildSwitchTile(
            'Biometric Login',
            'Use Fingerprint or Face ID',
            _biometricEnabled,
            _toggleBiometric,
          ),

          _buildSectionHeader('Transaction Security'),
          _buildSwitchTile(
            'Transaction PIN',
            'Require PIN for all payments',
            _pinEnabled,
            _togglePin,
          ),
          if (_pinEnabled)
            ListTile(
              title: const Text('Change PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/setup-pin'),
            ),

          _buildSectionHeader('Security Info'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Daily Deposit Limit', '₹50,000'),
                  const Divider(),
                  _buildInfoRow('Daily Withdrawal Limit', '₹50,000'),
                  const Divider(),
                  _buildInfoRow('Daily Contribution Limit', '₹1,00,000'),
                  const Divider(),
                  _buildInfoRow('Velocity Check', '3 transactions / 5 min'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Security Events'),
                  content: const Text('View your recent security activity and login history.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('View Security History'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
