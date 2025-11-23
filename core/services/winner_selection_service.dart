import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member.dart'; // define Member model

class WinnerSelectionService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch eligible members (has_won = false) for a pool
  Future<List<Member>> fetchEligibleMembers(String poolId) async {
    final response = await _client
        .from('pool_members')
        .select('user_id, name, has_won, won_cycle, won_date, won_amount')
        .eq('pool_id', poolId)
        .eq('has_won', false)
        .order('name')
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Member(
          id: e['user_id'],
          name: e['name'] ?? 'Unknown',
          hasWon: e['has_won'] ?? false,
          wonCycle: e['won_cycle'],
          wonDate: e['won_date'],
          wonAmount: e['won_amount']?.toDouble(),
        ))
        .toList();
  }

  // Fetch past winners (has_won = true)
  Future<List<Member>> fetchPastWinners(String poolId) async {
    final response = await _client
        .from('pool_members')
        .select('user_id, name, has_won, won_cycle, won_date, won_amount')
        .eq('pool_id', poolId)
        .eq('has_won', true)
        .order('won_cycle', ascending: false)
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.data as List<dynamic>;
    return data.map((e) => Member(
          id: e['user_id'],
          name: e['name'] ?? 'Unknown',
          hasWon: e['has_won'] ?? true,
          wonCycle: e['won_cycle'],
          wonDate: e['won_date'],
          wonAmount: e['won_amount']?.toDouble(),
        ))
        .toList();
  }

  // Call RPC to select a random winner for a round
  Future<String> selectRandomWinner(String poolId, int roundNumber) async {
    final response = await _client
        .rpc('select_random_winner', params: {
          'p_pool_id': poolId,
          'p_round_number': roundNumber,
        })
        .execute();
    if (response.error != null) {
      throw response.error!;
    }
    return response.data as String; // returns winner UUID
  }
}

// Provider for the service
final winnerSelectionServiceProvider = Provider<WinnerSelectionService>((ref) => WinnerSelectionService());
