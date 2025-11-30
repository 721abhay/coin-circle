import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityService {
  static final _supabase = Supabase.instance.client;

  /// Fetch all forum posts
  static Future<List<Map<String, dynamic>>> getForumPosts() async {
    try {
      final response = await _supabase
          .from('forum_posts')
          .select('*, profiles(full_name, avatar_url)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching forum posts: $e');
      return [];
    }
  }

  /// Create a new forum post
  static Future<void> createPost(String title, String content) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    
    await _supabase.from('forum_posts').insert({
      'user_id': user.id,
      'title': title,
      'content': content,
      'likes_count': 0,
      'comments_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
