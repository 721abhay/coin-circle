import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/admin_service.dart';

class AdminSettingsView extends ConsumerStatefulWidget {
  const AdminSettingsView({super.key});

  @override
  ConsumerState<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends ConsumerState<AdminSettingsView> {
  bool _isLoading = true;
  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  bool _allowWithdrawals = true;
  String _appVersion = 'v1.0.0';
  String _lastBackup = 'Never';
  List<Map<String, dynamic>> _announcements = [];
  
  final _announcementController = TextEditingController();
  String _selectedPriority = 'Info';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      // Load all settings
      final maintenanceData = await AdminService.getSystemSetting('maintenance_mode');
      final registrationsData = await AdminService.getSystemSetting('allow_registrations');
      final withdrawalsData = await AdminService.getSystemSetting('allow_withdrawals');
      final versionData = await AdminService.getSystemSetting('app_version');
      final announcements = await AdminService.getAnnouncements(limit: 5);

      if (mounted) {
        setState(() {
          _maintenanceMode = maintenanceData['enabled'] ?? false;
          _allowNewRegistrations = registrationsData['enabled'] ?? true;
          _allowWithdrawals = withdrawalsData['enabled'] ?? true;
          _appVersion = versionData['current'] ?? 'v1.0.0';
          _announcements = announcements;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    try {
      await AdminService.updateSystemSetting(key, {'enabled': value});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setting updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sendAnnouncement() async {
    if (_announcementController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    try {
      await AdminService.createAnnouncement(
        _announcementController.text.trim(),
        _selectedPriority,
      );
      
      _announcementController.clear();
      await _loadSettings(); // Reload to show new announcement
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _triggerBackup() async {
    try {
      final result = await AdminService.triggerDatabaseBackup();
      if (mounted) {
        setState(() {
          _lastBackup = 'Just now';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Backup completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      await AdminService.clearSystemCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'General Controls',
            [
              _buildSwitchTile(
                'Maintenance Mode',
                'Lock the app for all users except admins',
                _maintenanceMode,
                (val) async {
                  setState(() => _maintenanceMode = val);
                  await _updateSetting('maintenance_mode', val);
                },
                isDestructive: true,
              ),
              _buildSwitchTile(
                'Allow New Registrations',
                'Enable or disable new user signups',
                _allowNewRegistrations,
                (val) async {
                  setState(() => _allowNewRegistrations = val);
                  await _updateSetting('allow_registrations', val);
                },
              ),
              _buildSwitchTile(
                'Allow Withdrawals',
                'Global switch to pause all withdrawals',
                _allowWithdrawals,
                (val) async {
                  setState(() => _allowWithdrawals = val);
                  await _updateSetting('allow_withdrawals', val);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'App Configuration',
            [
              _buildActionTile(
                'Update App Version',
                'Current: $_appVersion',
                Icons.system_update,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('App version management - Contact DevOps')),
                  );
                },
              ),
              _buildActionTile(
                'Clear System Cache',
                'Free up server resources',
                Icons.cleaning_services,
                _clearCache,
              ),
              _buildActionTile(
                'Database Backup',
                'Last backup: $_lastBackup',
                Icons.backup,
                _triggerBackup,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAnnouncementsPanel(),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Future<void> Function(bool) onChanged, {bool isDestructive = false}) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(color: isDestructive && value ? Colors.red : Colors.black87, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (val) async {
        await onChanged(val);
      },
      activeThumbColor: isDestructive ? Colors.red : Colors.green,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black87),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildAnnouncementsPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Global Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _announcementController,
            decoration: InputDecoration(
              hintText: 'Type announcement...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: _selectedPriority,
                items: const [
                  DropdownMenuItem(value: 'Info', child: Text('Info')),
                  DropdownMenuItem(value: 'Warning', child: Text('Warning')),
                  DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                  DropdownMenuItem(value: 'Success', child: Text('Success')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedPriority = v);
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _sendAnnouncement,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  backgroundColor: const Color(0xFF1E1E2C),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent History', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_announcements.isEmpty)
            const Text('No announcements yet', style: TextStyle(color: Colors.grey))
          else
            ..._announcements.map((announcement) {
              final timeAgo = _formatTimeAgo(announcement['created_at']);
              return _buildAnnouncementItem(
                announcement['message'] ?? '',
                announcement['priority'] ?? 'Info',
                timeAgo,
              );
            }),
        ],
      ),
    );
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildAnnouncementItem(String text, String type, String time) {
    Color color = Colors.blue;
    if (type == 'Warning') color = Colors.orange;
    if (type == 'Critical') color = Colors.red;
    if (type == 'Success') color = Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('$type • $time', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
