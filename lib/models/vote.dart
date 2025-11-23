class Vote {
  final String memberName;
  final String reason;
  final int approvedCount;
  final int totalMembers;
  final String timeLeft;
  final bool isUrgent;
  final int roundNumber;

  Vote({
    required this.memberName,
    required this.reason,
    required this.approvedCount,
    required this.totalMembers,
    required this.timeLeft,
    required this.isUrgent,
    required this.roundNumber,
  });

  factory Vote.fromMap(Map<String, dynamic> map) {
    return Vote(
      memberName: map['member_name'] ?? '',
      reason: map['reason'] ?? '',
      approvedCount: map['approved_count'] ?? 0,
      totalMembers: map['total_members'] ?? 0,
      timeLeft: map['time_left'] ?? '',
      isUrgent: map['is_urgent'] ?? false,
      roundNumber: map['round_number'] ?? 0,
    );
  }
}
