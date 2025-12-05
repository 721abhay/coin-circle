import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Push Notification Service using Firebase Cloud Messaging
/// Handles both foreground and background notifications
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final _client = Supabase.instance.client;

  /// Initialize Firebase and request permissions
  static Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else {
        debugPrint('⚠️ User declined notification permission');
        return;
      }

      // Initialize local notifications for foreground display
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel
      const androidChannel = AndroidNotificationChannel(
        'coin_circle_notifications',
        'Win Pool Notifications',
        description: 'Notifications for pool updates, payments, and more',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Get FCM token and save to database
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('📱 FCM Token: $token');
        await _saveFCMToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveFCMToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

      // Check if app was opened from a terminated state notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessageTap(initialMessage);
      }

      debugPrint('✅ Push Notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing push notifications: $e');
    }
  }

  /// Save FCM token to Supabase for sending notifications
  static Future<void> _saveFCMToken(String token) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('profiles').upsert({
        'id': userId,
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ FCM token saved to database');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Foreground message: ${message.notification?.title}');

    // Show local notification
    const androidDetails = AndroidNotificationDetails(
      'coin_circle_notifications',
      'Win Pool Notifications',
      channelDescription: 'Notifications for pool updates, payments, and more',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Win Pool',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap (from background or terminated state)
  static void _handleBackgroundMessageTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');
    // TODO: Navigate to specific screen based on message.data
    // Example: if (message.data['pool_id'] != null) { navigate to pool }
  }

  /// Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Local notification tapped: ${response.payload}');
    // TODO: Navigate based on payload
  }

  /// Send a push notification to a specific user
  /// This should be called from your backend/cloud function for security
  /// For testing, you can call it from client (but not recommended for production)
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final profile = await _client
          .from('profiles')
          .select('fcm_token')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['fcm_token'] == null) {
        debugPrint('⚠️ User has no FCM token');
        return;
      }

      // In production, you would call your backend API here
      // which would use Firebase Admin SDK to send the notification
      // For now, we'll just log it
      debugPrint('📤 Would send notification to token: ${profile['fcm_token']}');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');
      debugPrint('   Data: $data');

      // TODO: Call your backend API endpoint
      // Example: await http.post('your-backend.com/send-notification', ...)
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// Subscribe to topic (for broadcast notifications)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📨 Background message: ${message.notification?.title}');
}
