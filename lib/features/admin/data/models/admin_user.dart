class AdminUser {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final bool suspended;
  final String? suspensionReason;
  final bool isAdmin;
  final int poolsJoined;
  final int poolsCreated;
  final double walletBalance;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.suspended,
    this.suspensionReason,
    required this.isAdmin,
    required this.poolsJoined,
    required this.poolsCreated,
    required this.walletBalance,
    required this.createdAt,
  });

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phone_number'] as String?,
      suspended: map['suspended'] as bool? ?? false,
      suspensionReason: map['suspension_reason'] as String?,
      isAdmin: map['is_admin'] as bool? ?? false,
      poolsJoined: (map['pools_joined'] as num?)?.toInt() ?? 0,
      poolsCreated: (map['pools_created'] as num?)?.toInt() ?? 0,
      walletBalance: (map['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'suspended': suspended,
      'suspension_reason': suspensionReason,
      'is_admin': isAdmin,
      'pools_joined': poolsJoined,
      'pools_created': poolsCreated,
      'wallet_balance': walletBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get statusText => suspended ? 'Suspended' : 'Active';
}
