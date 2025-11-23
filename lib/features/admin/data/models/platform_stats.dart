class PlatformStats {
  final int totalUsers;
  final int activeUsers;
  final int suspendedUsers;
  final int totalPools;
  final int activePools;
  final int pendingPools;
  final int completedPools;
  final int totalTransactions;
  final double totalTransactionVolume;
  final double totalPayouts;
  final double averagePoolSize;
  final double averageContribution;

  PlatformStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.suspendedUsers,
    required this.totalPools,
    required this.activePools,
    required this.pendingPools,
    required this.completedPools,
    required this.totalTransactions,
    required this.totalTransactionVolume,
    required this.totalPayouts,
    required this.averagePoolSize,
    required this.averageContribution,
  });

  factory PlatformStats.fromMap(Map<String, dynamic> map) {
    return PlatformStats(
      totalUsers: (map['total_users'] as num?)?.toInt() ?? 0,
      activeUsers: (map['active_users'] as num?)?.toInt() ?? 0,
      suspendedUsers: (map['suspended_users'] as num?)?.toInt() ?? 0,
      totalPools: (map['total_pools'] as num?)?.toInt() ?? 0,
      activePools: (map['active_pools'] as num?)?.toInt() ?? 0,
      pendingPools: (map['pending_pools'] as num?)?.toInt() ?? 0,
      completedPools: (map['completed_pools'] as num?)?.toInt() ?? 0,
      totalTransactions: (map['total_transactions'] as num?)?.toInt() ?? 0,
      totalTransactionVolume: (map['total_transaction_volume'] as num?)?.toDouble() ?? 0.0,
      totalPayouts: (map['total_payouts'] as num?)?.toDouble() ?? 0.0,
      averagePoolSize: (map['average_pool_size'] as num?)?.toDouble() ?? 0.0,
      averageContribution: (map['average_contribution'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_users': totalUsers,
      'active_users': activeUsers,
      'suspended_users': suspendedUsers,
      'total_pools': totalPools,
      'active_pools': activePools,
      'pending_pools': pendingPools,
      'completed_pools': completedPools,
      'total_transactions': totalTransactions,
      'total_transaction_volume': totalTransactionVolume,
      'total_payouts': totalPayouts,
      'average_pool_size': averagePoolSize,
      'average_contribution': averageContribution,
    };
  }

  double get userGrowthRate {
    if (totalUsers == 0) return 0.0;
    return (activeUsers / totalUsers) * 100;
  }

  double get poolCompletionRate {
    if (totalPools == 0) return 0.0;
    return (completedPools / totalPools) * 100;
  }
}
