import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await NotificationService.markAllAsRead();
              setState(() {}); // Refresh UI
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService.subscribeToNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Dismissible(
                key: Key(notif['id']),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  await NotificationService.deleteNotification(notif['id']);
                },
                child: _buildNotificationTile(notif),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notif) {
    final isRead = notif['read'] as bool;
    final type = notif['type'] as String;
    
    return Container(
      color: isRead ? null : Colors.blue.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForType(type).withOpacity(0.1),
          child: Icon(_getIconForType(type), color: _getColorForType(type)),
        ),
        title: Text(
          notif['title'],
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notif['message']),
            const SizedBox(height: 4),
            Text(
              _formatTime(notif['created_at']),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        onTap: () async {
          if (!isRead) {
            await NotificationService.markAsRead(notif['id']);
            setState(() {}); // Refresh to update unread status locally if stream doesn't immediately
          }
          _handleNotificationTap(notif);
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'payment_reminder':
        return Icons.payment;
      case 'draw_announcement':
        return Icons.celebration;
      case 'winner_announcement':
        return Icons.emoji_events;
      case 'pool_update':
        return Icons.update;
      case 'member_activity':
        return Icons.people;
      case 'contribution_received':
        return Icons.attach_money;
      case 'pool_joined':
        return Icons.group_add;
      case 'pool_created':
        return Icons.add_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'payment_reminder':
        return Colors.orange;
      case 'winner_announcement':
        return Colors.amber;
      case 'contribution_received':
        return Colors.green;
      case 'pool_joined':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  String _formatTime(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  void _handleNotificationTap(Map<String, dynamic> notif) {
    final data = notif['data'] as Map<String, dynamic>?;
    if (data != null && data['pool_id'] != null) {
      context.push('/pool-details/${data['pool_id']}');
    }
  }
}