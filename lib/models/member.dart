class Member {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String email;
  final bool isEligible;

  Member({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.email,
    this.isEligible = true,
  });

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] ?? '',
      fullName: map['full_name'] ?? '',
      avatarUrl: map['avatar_url'],
      email: map['email'] ?? '',
      isEligible: map['is_eligible'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'email': email,
      'is_eligible': isEligible,
    };
  }
}
