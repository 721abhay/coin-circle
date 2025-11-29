class PersonalDetails {
  final String userId;
  final String? phoneNumber;
  final bool phoneVerified;
  final String? email;
  final bool emailVerified;
  final String? address;
  final DateTime? dateOfBirth;
  final String? panNumber;
  final String? aadhaarNumber;
  final String? annualIncome;
  final String? occupation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PersonalDetails({
    required this.userId,
    this.phoneNumber,
    this.phoneVerified = false,
    this.email,
    this.emailVerified = false,
    this.address,
    this.dateOfBirth,
    this.panNumber,
    this.aadhaarNumber,
    this.annualIncome,
    this.occupation,
    this.createdAt,
    this.updatedAt,
  });

  // Get masked PAN (show only last 4 digits)
  String? get maskedPan {
    if (panNumber == null || panNumber!.length < 4) return panNumber;
    return '******${panNumber!.substring(panNumber!.length - 4)}';
  }

  // Get masked Aadhaar (show only last 4 digits)
  String? get maskedAadhaar {
    if (aadhaarNumber == null || aadhaarNumber!.length < 4) return aadhaarNumber;
    return '********${aadhaarNumber!.substring(aadhaarNumber!.length - 4)}';
  }

  factory PersonalDetails.fromJson(Map<String, dynamic> json) {
    return PersonalDetails(
      userId: json['user_id'] as String? ?? json['id'] as String,
      phoneNumber: json['phone_number'] as String?,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      email: json['email'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      address: json['address'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      panNumber: json['pan_number'] as String?,
      aadhaarNumber: json['aadhaar_number'] as String?,
      annualIncome: json['annual_income'] as String?,
      occupation: json['occupation'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'phone_number': phoneNumber,
      'phone_verified': phoneVerified,
      'email': email,
      'email_verified': emailVerified,
      'address': address,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'pan_number': panNumber,
      'aadhaar_number': aadhaarNumber,
      'annual_income': annualIncome,
      'occupation': occupation,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PersonalDetails copyWith({
    String? userId,
    String? phoneNumber,
    bool? phoneVerified,
    String? email,
    bool? emailVerified,
    String? address,
    DateTime? dateOfBirth,
    String? panNumber,
    String? aadhaarNumber,
    String? annualIncome,
    String? occupation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalDetails(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      panNumber: panNumber ?? this.panNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      annualIncome: annualIncome ?? this.annualIncome,
      occupation: occupation ?? this.occupation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
