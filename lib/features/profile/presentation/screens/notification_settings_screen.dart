import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _paymentReminders = true;
  bool _drawAnnouncements = true;
  bool _poolUpdates = true;
  bool _memberActivities = true;
  bool _systemMessages = true;
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await NotificationService.getNotificationPreferences();
      if (mounted) {
        setState(() {
          _paymentReminders = prefs['payment_reminders'] ?? true;
          _drawAnnouncements = prefs['draw_announcements'] ?? true;
          _poolUpdates = prefs['pool_updates'] ?? true;
          _memberActivities = prefs['member_activities'] ?? true;
          _systemMessages = prefs['system_messages'] ?? true;
          _quietHoursEnabled = prefs['quiet_hours_enabled'] ?? false;
          
          if (prefs['quiet_hours_start'] != null) {
            final parts = prefs['quiet_hours_start'].toString().split(':');
            _quietHoursStart = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          if (prefs['quiet_hours_end'] != null) {
            final parts = prefs['quiet_hours_end'].toString().split(':');
            _quietHoursEnd = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      await NotificationService.updateNotificationPreferences({
        'payment_reminders': _paymentReminders,
        'draw_announcements': _drawAnnouncements,
        'pool_updates': _poolUpdates,
        'member_activities': _memberActivities,
        'system_messages': _systemMessages,
        'quiet_hours_enabled': _quietHoursEnabled,
        'quiet_hours_start': '${_quietHoursStart.hour.toString().padLeft(2, '0')}:${_quietHoursStart.minute.toString().padLeft(2, '0')}:00',
        'quiet_hours_end': '${_quietHoursEnd.hour.toString().padLeft(2, '0')}:${_quietHoursEnd.minute.toString().padLeft(2, '0')}:00',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietHoursStart : _quietHoursEnd,
    );

    if (time != null) {
      setState(() {
        if (isStart) {
          _quietHoursStart = time;
        } else {
          _quietHoursEnd = time;
        }
      });
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
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          TextButton(
            onPressed: _savePreferences,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Notification Categories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildToggleTile(
            'Payment Reminders',
            'Get notified about upcoming payments',
            Icons.payment,
            _paymentReminders,
            (value) => setState(() => _paymentReminders = value),
          ),
          _buildToggleTile(
            'Draw Announcements',
            'Notifications about winner selections',
            Icons.casino,
            _drawAnnouncements,
            (value) => setState(() => _drawAnnouncements = value),
          ),
          _buildToggleTile(
            'Pool Updates',
            'Changes to your pools',
            Icons.groups,
            _poolUpdates,
            (value) => setState(() => _poolUpdates = value),
          ),
          _buildToggleTile(
            'Member Activities',
            'When members join or leave',
            Icons.person_add,
            _memberActivities,
            (value) => setState(() => _memberActivities = value),
          ),
          _buildToggleTile(
            'System Messages',
            'Important system announcements',
            Icons.info,
            _systemMessages,
            (value) => setState(() => _systemMessages = value),
          ),
          const SizedBox(height: 24),
          Text(
            'Quiet Hours',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Enable Quiet Hours'),
            subtitle: const Text('Mute notifications during specific hours'),
            value: _quietHoursEnabled,
            onChanged: (value) => setState(() => _quietHoursEnabled = value),
          ),
          if (_quietHoursEnabled) ...[
            ListTile(
              leading: const Icon(Icons.bedtime),
              title: const Text('Start Time'),
              trailing: Text(
                _quietHoursStart.format(context),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onTap: () => _pickTime(true),
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny),
              title: const Text('End Time'),
              trailing: Text(
                _quietHoursEnd.format(context),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onTap: () => _pickTime(false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
