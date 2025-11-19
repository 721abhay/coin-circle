import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

enum NotificationCategory { all, payments, draws, poolUpdates, memberActivity, system }

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  bool isRead;
  final NotificationCategory category;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    this.isRead = false,
    required this.category,
  });
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;
  
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: 'Payment Due Tomorrow',
      message: 'Your contribution of \$500 for Office Savings Circle is due tomorrow.',
      time: '2h ago',
      icon: Icons.payment,
      color: Colors.orange,
      category: NotificationCategory.payments,
    ),
    NotificationItem(
      title: 'Draw Happening Soon',
      message: 'Winner selection for Family Vacation Fund starts in 24 hours!',
      time: '5h ago',
      icon: Icons.casino,
      color: Colors.purple,
      category: NotificationCategory.draws,
    ),
    NotificationItem(
      title: 'New Member Joined',
      message: 'Sarah Connor joined your Office Savings Circle pool.',
      time: '1d ago',
      icon: Icons.person_add,
      color: Colors.blue,
      isRead: true,
      category: NotificationCategory.memberActivity,
    ),
    NotificationItem(
      title: 'Payment Received',
      message: 'Your payment of \$500 has been successfully processed.',
      time: '2d ago',
      icon: Icons.check_circle,
      color: Colors.green,
      isRead: true,
      category: NotificationCategory.payments,
    ),
    NotificationItem(
      title: 'Pool is Full',
      message: 'Office Savings Circle has reached maximum capacity (10/10 members).',
      time: '3d ago',
      icon: Icons.groups,
      color: Colors.teal,
      isRead: true,
      category: NotificationCategory.poolUpdates,
    ),
    NotificationItem(
      title: 'Vote Requested',
      message: 'Michael Brown requested early payout. Your vote is needed.',
      time: '3d ago',
      icon: Icons.how_to_vote,
      color: Colors.indigo,
      category: NotificationCategory.poolUpdates,
    ),
    NotificationItem(
      title: 'Account Verified',
      message: 'Your account has been successfully verified!',
      time: '5d ago',
      icon: Icons.verified_user,
      color: Colors.green,
      isRead: true,
      category: NotificationCategory.system,
    ),
  ];

  List<NotificationItem> get _filteredNotifications {
    if (_selectedCategory == NotificationCategory.all) {
      return _notifications;
    }
    return _notifications.where((n) => n.category == _selectedCategory).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in _notifications) {
                    notification.isRead = true;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              },
              child: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showNotificationSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredNotifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_filteredNotifications[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('All', NotificationCategory.all, Icons.notifications),
          _buildCategoryChip('Payments', NotificationCategory.payments, Icons.payment),
          _buildCategoryChip('Draws', NotificationCategory.draws, Icons.casino),
          _buildCategoryChip('Pool Updates', NotificationCategory.poolUpdates, Icons.update),
          _buildCategoryChip('Members', NotificationCategory.memberActivity, Icons.people),
          _buildCategoryChip('System', NotificationCategory.system, Icons.settings),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, NotificationCategory category, IconData icon) {
    final isSelected = _selectedCategory == category;
    final count = category == NotificationCategory.all
        ? _notifications.length
        : _notifications.where((n) => n.category == category).length;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black87),
            const SizedBox(width: 6),
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, int index) {
    return Dismissible(
      key: Key('notification_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _notifications.remove(notification);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: Card(
        elevation: notification.isRead ? 0 : 2,
        color: notification.isRead ? Colors.grey.shade50 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: notification.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(notification.icon, color: notification.color),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                notification.time,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            setState(() {
              notification.isRead = true;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Notification Preferences',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildPreferenceSection('Payment Notifications', [
                _buildPreferenceSwitch('Payment reminders', true),
                _buildPreferenceSwitch('Payment confirmations', true),
                _buildPreferenceSwitch('Auto-pay notifications', true),
              ]),
              const SizedBox(height: 16),
              _buildPreferenceSection('Pool Activity', [
                _buildPreferenceSwitch('Member joins/leaves', true),
                _buildPreferenceSwitch('Pool updates', true),
                _buildPreferenceSwitch('Cycle completions', false),
              ]),
              const SizedBox(height: 16),
              _buildPreferenceSection('Winner Announcements', [
                _buildPreferenceSwitch('Draw reminders', true),
                _buildPreferenceSwitch('Winner announcements', true),
                _buildPreferenceSwitch('Payout updates', true),
              ]),
              const SizedBox(height: 16),
              _buildPreferenceSection('Voting & Approval', [
                _buildPreferenceSwitch('New vote requests', true),
                _buildPreferenceSwitch('Vote reminders', true),
                _buildPreferenceSwitch('Vote results', true),
              ]),
              const SizedBox(height: 24),
              Text(
                'Delivery Methods',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPreferenceSwitch('Push notifications', true),
              _buildPreferenceSwitch('Email notifications', true),
              _buildPreferenceSwitch('SMS (critical only)', false),
              const SizedBox(height: 24),
              Text(
                'Quiet Hours',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPreferenceSwitch('Enable quiet hours', false),
              const SizedBox(height: 8),
              const Text('10:00 PM - 8:00 AM', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildPreferenceSwitch(String title, bool value) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (newValue) {},
      contentPadding: EdgeInsets.zero,
    );
  }
}