import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notification Service
/// Handles all notification-related operations
class NotificationService {
  static final _client = Supabase.instance.client;

  /// Get all notifications for current user
  static Future<List<Map<String, dynamic>>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _client
          .from('notifications')
          .select();
      
      // Apply filters BEFORE ordering
      query = query.eq('user_id', userId);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }
      
      // Order and limit come last
      var orderedQuery = query.order('created_at', ascending: false);

      if (limit > 0) {
        orderedQuery = orderedQuery.limit(limit);
      }

      final response = await orderedQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('notifications')
          .count(CountOption.exact)
          .eq('user_id', userId)
          .eq('is_read', false);

      return response;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('notifications')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      rethrow;
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Create a notification (for testing or manual creation)
  static Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'metadata': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time notifications
  static Stream<List<Map<String, dynamic>>> subscribeToNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  /// Get notifications by type
  static Future<List<Map<String, dynamic>>> getNotificationsByType(
      String type) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('type', type)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notifications by type: $e');
      return [];
    }
  }

  /// Delete all read notifications
  static Future<void> deleteAllRead() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .eq('is_read', true);
    } catch (e) {
      debugPrint('Error deleting read notifications: $e');
      rethrow;
    }
  }

  /// Get notification preferences for current user
  static Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return _getDefaultPreferences();
      }

      final response = await _client
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return _getDefaultPreferences();
      }

      return {
        'payment_reminders': response['payment_reminders'] ?? true,
        'draw_announcements': response['draw_announcements'] ?? true,
        'pool_updates': response['pool_updates'] ?? true,
        'member_activities': response['member_activities'] ?? true,
        'system_messages': response['system_messages'] ?? true,
      };
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return _getDefaultPreferences();
    }
  }

  /// Update notification preferences for current user
  static Future<void> updateNotificationPreferences(
      Map<String, bool> preferences) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _client.from('notification_preferences').upsert({
        'user_id': userId,
        'payment_reminders': preferences['payment_reminders'] ?? true,
        'draw_announcements': preferences['draw_announcements'] ?? true,
        'pool_updates': preferences['pool_updates'] ?? true,
        'member_activities': preferences['member_activities'] ?? true,
        'system_messages': preferences['system_messages'] ?? true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      rethrow;
    }
  }

  /// Get default notification preferences
  static Map<String, bool> _getDefaultPreferences() {
    return {
      'payment_reminders': true,
      'draw_announcements': true,
      'pool_updates': true,
      'member_activities': true,
      'system_messages': true,
    };
  }
}
