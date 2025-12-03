import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ReputationService {
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Get user's reputation profile
  static Future<Map<String, dynamic>> getReputationProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('''
            id,
            full_name,
            avatar_url,
            reputation_score,
            on_time_payment_percentage,
            total_payments_made,
            on_time_payments,
            late_payments,
            missed_payments,
            pools_completed,
            pools_defaulted,
            is_defaulter,
            is_banned,
            defaulted_at
          ''')
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error fetching reputation profile: $e');
      rethrow;
    }
  }

  /// Get user's badges
  static Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final response = await _client
          .from('user_badges')
          .select('*, badge:badges(*)')
          .eq('user_id', userId)
          .order('earned_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user badges: $e');
      return [];
    }
  }

  /// Get user's reviews
  static Future<Map<String, dynamic>> getUserReviews(String userId) async {
    try {
      final response = await _client
          .from('user_reviews')
          .select('*, reviewer:reviewer_id(full_name, avatar_url)')
          .eq('reviewee_id', userId)
          .order('created_at', ascending: false);

      final reviews = List<Map<String, dynamic>>.from(response);
      
      // Calculate average rating
      double avgRating = 0;
      if (reviews.isNotEmpty) {
        final sum = reviews.fold<int>(0, (sum, review) => sum + (review['rating'] as int));
        avgRating = sum / reviews.length;
      }

      return {
        'reviews': reviews,
        'average_rating': avgRating,
        'total_reviews': reviews.length,
      };
    } catch (e) {
      debugPrint('Error fetching user reviews: $e');
      return {
        'reviews': [],
        'average_rating': 0.0,
        'total_reviews': 0,
      };
    }
  }

  /// Submit a review for a user
  static Future<void> submitReview({
    required String revieweeId,
    required String poolId,
    required int rating,
    String? comment,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _client.from('user_reviews').insert({
        'reviewer_id': user.id,
        'reviewee_id': revieweeId,
        'pool_id': poolId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      debugPrint('Error submitting review: $e');
      rethrow;
    }
  }

  /// Get reputation history
  static Future<List<Map<String, dynamic>>> getReputationHistory(String userId) async {
    try {
      final response = await _client
          .from('reputation_history')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching reputation history: $e');
      return [];
    }
  }

  /// Update reputation (called by backend triggers mostly)
  static Future<void> updateReputation({
    required String userId,
    required int changeAmount,
    required String reason,
    String? poolId,
    String? transactionId,
  }) async {
    try {
      await _client.rpc('update_reputation', params: {
        'p_user_id': userId,
        'p_change_amount': changeAmount,
        'p_reason': reason,
        'p_pool_id': poolId,
        'p_transaction_id': transactionId,
      });
    } catch (e) {
      debugPrint('Error updating reputation: $e');
      rethrow;
    }
  }

  /// Mark user as defaulter
  static Future<void> markAsDefaulter({
    required String userId,
    required String poolId,
    required int roundNumber,
    required double amountOwed,
    required String reason,
  }) async {
    try {
      await _client.rpc('mark_as_defaulter', params: {
        'p_user_id': userId,
        'p_pool_id': poolId,
        'p_round_number': roundNumber,
        'p_amount_owed': amountOwed,
        'p_reason': reason,
      });
    } catch (e) {
      debugPrint('Error marking as defaulter: $e');
      rethrow;
    }
  }

  /// Add user to blacklist
  static Future<void> addToBlacklist({
    required String userId,
    required String reason,
    bool permanent = true,
  }) async {
    try {
      await _client.rpc('add_to_blacklist', params: {
        'p_user_id': userId,
        'p_reason': reason,
        'p_permanent': permanent,
      });
    } catch (e) {
      debugPrint('Error adding to blacklist: $e');
      rethrow;
    }
  }

  /// Check if phone/email is blacklisted
  static Future<bool> isBlacklisted({
    String? phone,
    String? email,
  }) async {
    try {
      final result = await _client.rpc('is_blacklisted', params: {
        'p_phone': phone,
        'p_email': email,
      });
      return result as bool;
    } catch (e) {
      debugPrint('Error checking blacklist: $e');
      return false;
    }
  }

  /// Get leaderboard (top users by reputation)
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, avatar_url, reputation_score, pools_completed, on_time_payment_percentage')
          .eq('is_banned', false)
          .eq('is_defaulter', false)
          .order('reputation_score', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Get all badges
  static Future<List<Map<String, dynamic>>> getAllBadges() async {
    try {
      final response = await _client
          .from('badges')
          .select('*')
          .order('requirement_value', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      return [];
    }
  }

  /// Get reputation tier info
  static Map<String, dynamic> getReputationTier(int score) {
    if (score >= 90) {
      return {
        'tier': 'Elite',
        'color': 0xFFF59E0B,
        'icon': '⭐',
        'benefits': [
          'Join premium pools',
          'Lowest fees (1.5%)',
          'Early withdrawal rights',
          'Create larger pools',
          'Priority support',
        ],
      };
    } else if (score >= 70) {
      return {
        'tier': 'Trusted',
        'color': 0xFF10B981,
        'icon': '✅',
        'benefits': [
          'Join most pools',
          'Standard fees (2%)',
          'Create pools',
          'Good standing',
        ],
      };
    } else if (score >= 50) {
      return {
        'tier': 'Member',
        'color': 0xFF3B82F6,
        'icon': '👤',
        'benefits': [
          'Join basic pools',
          'Standard fees (2.5%)',
          'Limited pool creation',
        ],
      };
    } else if (score >= 30) {
      return {
        'tier': 'Probation',
        'color': 0xFFF59E0B,
        'icon': '⚠️',
        'benefits': [
          'Limited pool access',
          'Higher fees (3%)',
          'Cannot create pools',
        ],
      };
    } else {
      return {
        'tier': 'At Risk',
        'color': 0xFFEF4444,
        'icon': '🚫',
        'benefits': [
          'Very limited access',
          'Highest fees (4%)',
          'Cannot create pools',
          'Risk of ban',
        ],
      };
    }
  }

  /// Calculate fee based on reputation
  static double calculateFeePercentage(int reputationScore) {
    if (reputationScore >= 90) return 1.5; // Elite
    if (reputationScore >= 70) return 2.0; // Trusted
    if (reputationScore >= 50) return 2.5; // Member
    if (reputationScore >= 30) return 3.0; // Probation
    return 4.0; // At Risk
  }

  /// Check if user can join pool based on reputation
  static bool canJoinPool(int reputationScore, String poolType) {
    if (poolType == 'premium') {
      return reputationScore >= 90; // Only Elite
    } else if (poolType == 'standard') {
      return reputationScore >= 50; // Member and above
    } else {
      return reputationScore >= 30; // Basic pools
    }
  }

  /// Check if user can create pool based on reputation
  static bool canCreatePool(int reputationScore) {
    return reputationScore >= 50; // Member tier and above
  }

  /// Get default events for a pool
  static Future<List<Map<String, dynamic>>> getDefaultEvents(String poolId) async {
    try {
      final response = await _client
          .from('default_events')
          .select('*, user:user_id(full_name, avatar_url)')
          .eq('pool_id', poolId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching default events: $e');
      return [];
    }
  }

  /// Get user's complete social profile
  static Future<Map<String, dynamic>> getSocialProfile(String userId) async {
    try {
      final profile = await getReputationProfile(userId);
      final badges = await getUserBadges(userId);
      final reviewsData = await getUserReviews(userId);
      final tier = getReputationTier(profile['reputation_score'] as int);

      return {
        ...profile,
        'badges': badges,
        'reviews': reviewsData['reviews'],
        'average_rating': reviewsData['average_rating'],
        'total_reviews': reviewsData['total_reviews'],
        'tier': tier,
      };
    } catch (e) {
      debugPrint('Error fetching social profile: $e');
      rethrow;
    }
  }
}
