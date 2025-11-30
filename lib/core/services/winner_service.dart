import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_service.dart';

class WinnerService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Get the current user's ID
  static String? get _userId => _client.auth.currentUser?.id;

  /// Get winner history for a pool
  static Future<List<Map<String, dynamic>>> getWinnerHistory(String poolId) async {
    try {
      final response = await _client
          .from('winner_history')
          .select('*, profiles(full_name, avatar_url)')
          .eq('pool_id', poolId)
          .order('round_number', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching winner history: $e');
      rethrow;
    }
  }

  /// Place a bid for a pool round
  static Future<void> placeBid({
    required String poolId,
    required int round,
    required double amount,
  }) async {
    if (_userId == null) throw Exception('User not logged in');

    try {
      await _client.from('bids').insert({
        'pool_id': poolId,
        'user_id': _userId,
        'round_number': round,
        'bid_amount': amount,
        'status': 'active',
      });
    } catch (e) {
      debugPrint('Error placing bid: $e');
      rethrow;
    }
  }

  /// Get active bids for a pool round
  static Future<List<Map<String, dynamic>>> getBids(String poolId, int round) async {
    try {
      final response = await _client
          .from('bids')
          .select('*, profiles(full_name)')
          .eq('pool_id', poolId)
          .eq('round_number', round)
          .eq('status', 'active')
          .order('bid_amount', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching bids: $e');
      rethrow;
    }
  }

  /// Trigger random winner selection (Admin/System function - exposed for testing/demo)
  static Future<void> selectRandomWinner(String poolId, int round) async {
    try {
      await _client.rpc('select_random_winner', params: {
        'p_pool_id': poolId,
        'p_round_number': round,
      });

      // Send chat notification
      try {
        // Fetch the winner to get their name and amount
        final winner = await _client
            .from('winner_history')
            .select('*, profiles(full_name)')
            .eq('pool_id', poolId)
            .eq('round_number', round)
            .single();

        final winnerName = winner['profiles']['full_name'] ?? 'A member';
        final amount = (winner['amount_won'] as num).toDouble();

        await ChatService.sendWinnerAnnouncement(
          poolId: poolId,
          winnerName: winnerName,
          amount: amount,
        );
      } catch (e) {
        debugPrint('Failed to send winner announcement: $e');
      }
    } catch (e) {
      debugPrint('Error selecting random winner: $e');
      rethrow;
    }
  }
  
  /// Trigger bid winner selection (Admin/System function - exposed for testing/demo)
  static Future<void> selectBidWinner(String poolId, int round) async {
    try {
      await _client.rpc('select_bid_winner', params: {
        'p_pool_id': poolId,
        'p_round_number': round,
      });

      // Send chat notification
      try {
        // Fetch the winner to get their name and amount
        final winner = await _client
            .from('winner_history')
            .select('*, profiles(full_name)')
            .eq('pool_id', poolId)
            .eq('round_number', round)
            .single();

        final winnerName = winner['profiles']['full_name'] ?? 'A member';
        final amount = (winner['amount_won'] as num).toDouble();

        await ChatService.sendWinnerAnnouncement(
          poolId: poolId,
          winnerName: winnerName,
          amount: amount,
        );
      } catch (e) {
        debugPrint('Failed to send winner announcement: $e');
      }
    } catch (e) {
      debugPrint('Error selecting bid winner: $e');
      rethrow;
    }
  }
}
