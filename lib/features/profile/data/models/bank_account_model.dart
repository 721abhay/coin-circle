class BankAccount {
  final String id;
  final String userId;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final String? branchName;
  final String accountType; // 'savings' or 'current'
  final bool isPrimary;
  final bool isVerified;
  final String? verificationMethod;
  final DateTime? verificationDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  BankAccount({
    required this.id,
    required this.userId,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    this.branchName,
    required this.accountType,
    required this.isPrimary,
    required this.isVerified,
    this.verificationMethod,
    this.verificationDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get masked account number (show last 4 digits)
  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '••••••••$lastFour';
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountHolderName: json['account_holder_name'] as String,
      accountNumber: json['account_number'] as String,
      ifscCode: json['ifsc_code'] as String,
      bankName: json['bank_name'] as String,
      branchName: json['branch_name'] as String?,
      accountType: json['account_type'] as String? ?? 'savings',
      isPrimary: json['is_primary'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      verificationMethod: json['verification_method'] as String?,
      verificationDate: json['verification_date'] != null
          ? DateTime.parse(json['verification_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'bank_name': bankName,
      'branch_name': branchName,
      'account_type': accountType,
      'is_primary': isPrimary,
      'is_verified': isVerified,
      'verification_method': verificationMethod,
      'verification_date': verificationDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BankAccount copyWith({
    String? id,
    String? userId,
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? bankName,
    String? branchName,
    String? accountType,
    bool? isPrimary,
    bool? isVerified,
    String? verificationMethod,
    DateTime? verificationDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
      accountType: accountType ?? this.accountType,
      isPrimary: isPrimary ?? this.isPrimary,
      isVerified: isVerified ?? this.isVerified,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      verificationDate: verificationDate ?? this.verificationDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
