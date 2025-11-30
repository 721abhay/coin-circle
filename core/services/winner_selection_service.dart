import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class WinnerSelectionService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch eligible members (has_won = false) for a pool
  Future<List<Map<String, dynamic>>> fetchEligibleMembers(String poolId) async {
    try {
      final data = await _client
          .from('pool_members')
          .select('user_id, name, has_won, won_cycle, won_date, won_amount')
          .eq('pool_id', poolId)
          .eq('has_won', false)
          .order('name');
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Failed to fetch eligible members: $e');
      throw Exception('Failed to fetch eligible members: $e');
    }
  }

  // Fetch past winners (has_won = true)
  Future<List<Map<String, dynamic>>> fetchPastWinners(String poolId) async {
    try {
      final data = await _client
          .from('pool_members')
          .select('user_id, name, has_won, won_cycle, won_date, won_amount')
          .eq('pool_id', poolId)
          .eq('has_won', true)
          .order('won_cycle', ascending: false);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Failed to fetch past winners: $e');
      throw Exception('Failed to fetch past winners: $e');
    }
  }

  // Call RPC to select a random winner for a round
  Future<String> selectRandomWinner(String poolId, int roundNumber) async {
    try {
      final result = await _client.rpc('select_random_winner', params: {
        'p_pool_id': poolId,
        'p_round_number': roundNumber,
      });
      
      return result as String? ?? '';
    } catch (e) {
      debugPrint('Failed to select random winner: $e');
      throw Exception('Failed to select random winner: $e');
    }
  }
}

// Provider for the service
final winnerSelectionServiceProvider = Provider<WinnerSelectionService>((ref) => WinnerSelectionService());
