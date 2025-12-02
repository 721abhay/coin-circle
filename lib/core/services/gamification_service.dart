import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationService {
  static final _supabase = Supabase.instance.client;

  // Get user's gamification profile (XP, Level, Streaks)
  static Future<Map<String, dynamic>?> getGamificationProfile(String userId) async {
    try {
      final response = await _supabase
          .from('gamification_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('Error fetching gamification profile: $e');
      return null;
    }
  }

  // Get all available badges
  static Future<List<Map<String, dynamic>>> getBadges() async {
    try {
      final response = await _supabase
          .from('badges')
          .select()
          .order('xp_reward', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      return [];
    }
  }

  // Get badges earned by a specific user
  static Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final response = await _supabase
          .from('user_badges')
          .select('*, badges(*)')
          .eq('user_id', userId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user badges: $e');
      return [];
    }
  }

  // Get all active challenges
  static Future<List<Map<String, dynamic>>> getActiveChallenges() async {
    try {
      final response = await _supabase
          .from('challenges')
          .select()
          .eq('is_active', true)
          .gt('end_date', DateTime.now().toIso8601String());
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching active challenges: $e');
      return [];
    }
  }

  // Get user's progress on challenges
  static Future<List<Map<String, dynamic>>> getUserChallenges(String userId) async {
    try {
      final response = await _supabase
          .from('user_challenges')
          .select('*, challenges(*)')
          .eq('user_id', userId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user challenges: $e');
      return [];
    }
  }

  // Join a challenge
  static Future<void> joinChallenge(String challengeId) async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      await _supabase.from('user_challenges').insert({
        'user_id': userId,
        'challenge_id': challengeId,
        'current_progress': 0,
        'is_completed': false,
      });
    } catch (e) {
      debugPrint('Error joining challenge: $e');
      rethrow;
    }
  }

  // Get streak logs for calendar view
  static Future<List<Map<String, dynamic>>> getStreakLogs(String userId) async {
    try {
      final response = await _supabase
          .from('streak_logs')
          .select()
          .eq('user_id', userId)
          .order('activity_date', ascending: false)
          .limit(365); // Get last year's data
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching streak logs: $e');
      return [];
    }
  }

  // Get leaderboard data
  static Future<List<Map<String, dynamic>>> getLeaderboard(String type) async {
    try {
      // For now, we'll return global leaderboard for all types as friend/pool logic 
      // requires more complex joins that might not be ready.
      // We join with profiles to get name and avatar.
      final response = await _supabase
          .from('gamification_profiles')
          .select('current_xp, current_level, profiles(full_name, avatar_url)')
          .order('current_xp', ascending: false)
          .limit(50);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  // Get reviews for a user
  static Future<List<Map<String, dynamic>>> getReviews(String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, reviewer:reviewer_id(full_name, avatar_url)') // Join with profiles to get reviewer details
          .eq('reviewee_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  // Initialize gamification profile if it doesn't exist
  static Future<void> ensureGamificationProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final exists = await getGamificationProfile(userId);
      if (exists == null) {
        await _supabase.from('gamification_profiles').insert({
          'user_id': userId,
          'current_xp': 0,
          'current_level': 1,
        });
      }
    } catch (e) {
      debugPrint('Error ensuring gamification profile: $e');
    }
  }
}
