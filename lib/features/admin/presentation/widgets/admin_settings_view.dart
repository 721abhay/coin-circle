import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminSettingsView extends ConsumerStatefulWidget {
  const AdminSettingsView({super.key});

  @override
  ConsumerState<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends ConsumerState<AdminSettingsView> {
  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  bool _allowWithdrawals = true;

  @override
  Widget build(BuildContext context) {
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
                (val) => setState(() => _maintenanceMode = val),
                isDestructive: true,
              ),
              _buildSwitchTile(
                'Allow New Registrations',
                'Enable or disable new user signups',
                _allowNewRegistrations,
                (val) => setState(() => _allowNewRegistrations = val),
              ),
              _buildSwitchTile(
                'Allow Withdrawals',
                'Global switch to pause all withdrawals',
                _allowWithdrawals,
                (val) => setState(() => _allowWithdrawals = val),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'App Configuration',
            [
              _buildActionTile('Update App Version', 'Current: v1.0.0', Icons.system_update),
              _buildActionTile('Clear System Cache', 'Free up server resources', Icons.cleaning_services),
              _buildActionTile('Database Backup', 'Last backup: 2 hours ago', Icons.backup),
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

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, {bool isDestructive = false}) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(color: isDestructive && value ? Colors.red : Colors.black87, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeThumbColor: isDestructive ? Colors.red : Colors.green,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon) {
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
      onTap: () {},
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
                initialValue: 'Info',
                items: const [
                  DropdownMenuItem(value: 'Info', child: Text('Info')),
                  DropdownMenuItem(value: 'Warning', child: Text('Warning')),
                  DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                ],
                onChanged: (v) {},
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
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
          _buildAnnouncementItem('Maintenance scheduled for tonight', 'Info', '2h ago'),
          _buildAnnouncementItem('New features added!', 'Success', '1d ago'),
        ],
      ),
    );
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
