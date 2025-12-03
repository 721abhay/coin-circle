import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class VotingService {
  static final SupabaseClient _client = SupabaseConfig.client;

  /// Start a voting period for a round
  static Future<String> startVotingPeriod({
    required String poolId,
    required int roundNumber,
    int durationHours = 48,
  }) async {
    try {
      final response = await _client.rpc('start_voting_period', params: {
        'p_pool_id': poolId,
        'p_round_number': roundNumber,
        'p_duration_hours': durationHours,
      });
      return response as String;
    } catch (e) {
      debugPrint('Error starting voting period: $e');
      rethrow;
    }
  }

  /// Close a voting period
  static Future<void> closeVotingPeriod({
    required String poolId,
    required int roundNumber,
  }) async {
    try {
      await _client.rpc('close_voting_period', params: {
        'p_pool_id': poolId,
        'p_round_number': roundNumber,
      });
    } catch (e) {
      debugPrint('Error closing voting period: $e');
      rethrow;
    }
  }

  /// Cast or update a vote
  static Future<void> castVote({
    required String poolId,
    required int roundNumber,
    required String candidateId,
  }) async {
    try {
      await _client.rpc('cast_vote', params: {
        'p_pool_id': poolId,
        'p_round_number': roundNumber,
        'p_candidate_id': candidateId,
      });
    } catch (e) {
      debugPrint('Error casting vote: $e');
      rethrow;
    }
  }

  /// Get current voting period status
  static Future<Map<String, dynamic>?> getVotingPeriod({
    required String poolId,
    required int roundNumber,
  }) async {
    try {
      final response = await _client
          .from('voting_periods')
          .select()
          .eq('pool_id', poolId)
          .eq('round_number', roundNumber)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching voting period: $e');
      return null;
    }
  }

  /// Get user's vote for a round
  static Future<Map<String, dynamic>?> getUserVote({
    required String poolId,
    required int roundNumber,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('votes')
          .select('*, candidate:candidate_id(full_name, avatar_url)')
          .eq('pool_id', poolId)
          .eq('round_number', roundNumber)
          .eq('voter_id', user.id)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching user vote: $e');
      return null;
    }
  }

  /// Get vote counts for a round
  static Future<List<Map<String, dynamic>>> getVoteCounts({
    required String poolId,
    required int roundNumber,
  }) async {
    try {
      final response = await _client.rpc('get_vote_counts', params: {
        'p_pool_id': poolId,
        'p_round_number': roundNumber,
      });
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching vote counts: $e');
      return [];
    }
  }

  /// Get all votes for a round (for admins)
  static Future<List<Map<String, dynamic>>> getAllVotes({
    required String poolId,
    required int roundNumber,
  }) async {
    try {
      final response = await _client
          .from('votes')
          .select('*, voter:voter_id(full_name), candidate:candidate_id(full_name)')
          .eq('pool_id', poolId)
          .eq('round_number', roundNumber)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching all votes: $e');
      return [];
    }
  }

  /// Check if voting is currently open
  static Future<bool> isVotingOpen({
    required String poolId,
    required int roundNumber,
  }) async {
    final period = await getVotingPeriod(
      poolId: poolId,
      roundNumber: roundNumber,
    );

    if (period == null) return false;

    final status = period['status'] as String?;
    if (status != 'open') return false;

    final endsAt = period['ends_at'] as String?;
    if (endsAt != null) {
      final endTime = DateTime.parse(endsAt);
      if (DateTime.now().isAfter(endTime)) return false;
    }

    return true;
  }

  /// Get voting statistics
  static Future<Map<String, dynamic>> getVotingStats({
    required String poolId,
    required int roundNumber,
  }) async {
    try {
      // Get total eligible voters
      final membersResponse = await _client
          .from('pool_members')
          .select('id')
          .eq('pool_id', poolId)
          .eq('status', 'active');
      final totalVoters = (membersResponse as List).length;

      // Get total votes cast
      final votesResponse = await _client
          .from('votes')
          .select('id')
          .eq('pool_id', poolId)
          .eq('round_number', roundNumber);
      final votesCast = (votesResponse as List).length;

      // Get voting period
      final period = await getVotingPeriod(
        poolId: poolId,
        roundNumber: roundNumber,
      );

      return {
        'total_voters': totalVoters,
        'votes_cast': votesCast,
        'votes_remaining': totalVoters - votesCast,
        'participation_rate': totalVoters > 0 ? (votesCast / totalVoters * 100) : 0,
        'status': period?['status'] ?? 'not_started',
        'ends_at': period?['ends_at'],
      };
    } catch (e) {
      debugPrint('Error fetching voting stats: $e');
      return {
        'total_voters': 0,
        'votes_cast': 0,
        'votes_remaining': 0,
        'participation_rate': 0,
        'status': 'error',
      };
    }
  }
}
