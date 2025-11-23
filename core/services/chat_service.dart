import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  ChatMessage({required this.id, required this.userId, required this.content, required this.createdAt});
}

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ChatMessage>> fetchMessages(String poolId) async {
    final response = await _client
        .from('pool_messages')
        .select()
        .eq('pool_id', poolId)
        .order('created_at', ascending: true)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => ChatMessage(
      id: e['id'],
      userId: e['user_id'],
      content: e['content'] ?? '',
      createdAt: DateTime.parse(e['created_at']),
    )).toList();
  }

  Future<void> sendMessage(String poolId, String userId, String content) async {
    final response = await _client.from('pool_messages').insert({
      'pool_id': poolId,
      'user_id': userId,
      'content': content,
    }).execute();
    if (response.error != null) {
      throw response.error!;
    }
  }
}

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());
