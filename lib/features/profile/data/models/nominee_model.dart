class Nominee {
  final String id;
  final String userId;
  final String name;
  final String relationship;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final String? email;
  final int allocationPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Nominee({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    this.dateOfBirth,
    this.phoneNumber,
    this.email,
    this.allocationPercentage = 100,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Nominee.fromJson(Map<String, dynamic> json) {
    return Nominee(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      allocationPercentage: json['allocation_percentage'] as int? ?? 100,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'relationship': relationship,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'phone_number': phoneNumber,
      'email': email,
      'allocation_percentage': allocationPercentage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Nominee copyWith({
    String? id,
    String? userId,
    String? name,
    String? relationship,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? email,
    int? allocationPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Nominee(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      allocationPercentage: allocationPercentage ?? this.allocationPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
