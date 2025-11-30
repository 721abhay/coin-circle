import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling platform revenue (late fees and joining fees)
class PlatformRevenueService {
  static final _client = Supabase.instance.client;

  /// Calculate late fee based on days late
  /// Formula: 
  /// - 0-1 days: ₹0 (grace period)
  /// - 2-3 days: ₹50
  /// - 4-5 days: ₹70
  /// - 6-7 days: ₹90
  /// - +₹20 for every 2 additional days
  static double calculateLateFee(int daysLate) {
    if (daysLate <= 1) {
      return 0;
    }
    
    // Calculate periods (every 2 days)
    final periods = ((daysLate - 1) / 2).ceil();
    return 30 + (periods * 20);
  }

  /// Record a late fee payment to platform revenue
  static Future<void> recordLateFee({
    required String userId,
    required String poolId,
    required double amount,
    required int daysLate,
  }) async {
    await _client.from('platform_revenue').insert({
      'user_id': userId,
      'pool_id': poolId,
      'type': 'late_fee',
      'amount': amount,
      'description': 'Late fee for $daysLate days late',
    });
  }

  /// Record a joining fee payment to platform revenue
  static Future<void> recordJoiningFee({
    required String userId,
    required String poolId,
    required double amount,
  }) async {
    await _client.from('platform_revenue').insert({
      'user_id': userId,
      'pool_id': poolId,
      'type': 'joining_fee',
      'amount': amount,
      'description': 'Pool joining fee',
    });
  }

  /// Get total platform revenue
  static Future<Map<String, double>> getTotalRevenue() async {
    final response = await _client
        .from('platform_revenue')
        .select('type, amount');

    double totalLateFees = 0;
    double totalJoiningFees = 0;

    for (var record in response) {
      final amount = (record['amount'] as num).toDouble();
      if (record['type'] == 'late_fee') {
        totalLateFees += amount;
      } else if (record['type'] == 'joining_fee') {
        totalJoiningFees += amount;
      }
    }

    return {
      'late_fees': totalLateFees,
      'joining_fees': totalJoiningFees,
      'total': totalLateFees + totalJoiningFees,
    };
  }

  /// Get revenue for a specific pool
  static Future<Map<String, double>> getPoolRevenue(String poolId) async {
    final response = await _client
        .from('platform_revenue')
        .select('type, amount')
        .eq('pool_id', poolId);

    double totalLateFees = 0;
    double totalJoiningFees = 0;

    for (var record in response) {
      final amount = (record['amount'] as num).toDouble();
      if (record['type'] == 'late_fee') {
        totalLateFees += amount;
      } else if (record['type'] == 'joining_fee') {
        totalJoiningFees += amount;
      }
    }

    return {
      'late_fees': totalLateFees,
      'joining_fees': totalJoiningFees,
      'total': totalLateFees + totalJoiningFees,
    };
  }

  /// Get revenue breakdown by date range
  static Future<List<Map<String, dynamic>>> getRevenueByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client
        .from('platform_revenue')
        .select('*')
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String())
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get joining fee for a pool
  static Future<double> getPoolJoiningFee(String poolId) async {
    final response = await _client
        .from('pools')
        .select('joining_fee')
        .eq('id', poolId)
        .single();

    return (response['joining_fee'] as num?)?.toDouble() ?? 20.0;
  }
}
