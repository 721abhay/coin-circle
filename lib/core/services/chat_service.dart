import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coin_circle/features/pools/data/models/chat_message.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;

  /// Get real-time stream of messages for a pool
  static Stream<List<ChatMessage>> getPoolMessages(String poolId) {
    return _supabase
        .from('pool_messages')
        .stream(primaryKey: ['id'])
        .eq('pool_id', poolId)
        .order('created_at', ascending: true)
        .map((data) {
          return data.map((message) => ChatMessage.fromMap(message)).toList();
        });
  }

  /// Send a user message to the pool chat
  static Future<void> sendMessage({
    required String poolId,
    required String content,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('pool_messages').insert({
        'pool_id': poolId,
        'user_id': userId,
        'message_type': 'user_message',
        'content': content,
        'metadata': {},
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send a file attachment
  static Future<void> sendAttachment({
    required String poolId,
    required String fileUrl,
    required String fileName,
    required String fileType,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('pool_messages').insert({
        'pool_id': poolId,
        'user_id': userId,
        'message_type': 'attachment',
        'content': 'Sent an attachment: $fileName',
        'metadata': {
          'file_url': fileUrl,
          'file_name': fileName,
          'file_type': fileType,
        },
      });
    } catch (e) {
      throw Exception('Failed to send attachment: $e');
    }
  }

  /// Send a system message (automated notifications)
  static Future<void> sendSystemMessage({
    required String poolId,
    required String content,
    required String messageType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.rpc('create_system_message', params: {
        'p_pool_id': poolId,
        'p_message_type': messageType,
        'p_content': content,
        'p_metadata': metadata ?? {},
      });
    } catch (e) {
      throw Exception('Failed to send system message: $e');
    }
  }

  /// Pin or unpin a message (admin only)
  static Future<void> toggleMessagePin({
    required String messageId,
    required bool isPinned,
  }) async {
    try {
      await _supabase.rpc('toggle_message_pin', params: {
        'p_message_id': messageId,
        'p_is_pinned': isPinned,
      });
    } catch (e) {
      throw Exception('Failed to toggle pin: $e');
    }
  }

  /// Delete a message (own messages or admin)
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('pool_messages').delete().eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get pinned messages for a pool
  static Future<List<ChatMessage>> getPinnedMessages(String poolId) async {
    try {
      final response = await _supabase
          .from('pool_messages')
          .select('*, profiles(full_name, avatar_url)')
          .eq('pool_id', poolId)
          .eq('is_pinned', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((message) => ChatMessage.fromMap(message))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pinned messages: $e');
    }
  }

  /// Helper: Send payment confirmation message
  static Future<void> sendPaymentConfirmation({
    required String poolId,
    required String userName,
    required double amount,
  }) async {
    await sendSystemMessage(
      poolId: poolId,
      content: '$userName made a contribution of ₹$amount',
      messageType: 'system_notification',
      metadata: {
        'type': 'payment',
        'amount': amount,
      },
    );
  }

  /// Helper: Send winner announcement message
  static Future<void> sendWinnerAnnouncement({
    required String poolId,
    required String winnerName,
    required double amount,
  }) async {
    await sendSystemMessage(
      poolId: poolId,
      content: '🎉 Congratulations $winnerName! You won ₹$amount!',
      messageType: 'winner_announcement',
      metadata: {
        'type': 'winner',
        'amount': amount,
      },
    );
  }

  /// Helper: Send member joined message
  static Future<void> sendMemberJoinedMessage({
    required String poolId,
    required String memberName,
  }) async {
    await sendSystemMessage(
      poolId: poolId,
      content: '$memberName joined the pool',
      messageType: 'member_joined',
      metadata: {
        'type': 'member_joined',
      },
    );
  }
}
