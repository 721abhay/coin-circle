/// Input validation utilities following the Single Responsibility Principle.
///
/// Each validator method has a single, well-defined purpose and returns
/// either null (valid) or an error message (invalid).
class InputValidator {
  // ==================== AMOUNT VALIDATION ====================
  
  /// Validates monetary amount input.
  ///
  /// Rules:
  /// - Must not be empty
  /// - Must be a valid number
  /// - Must be greater than 0
  /// - Must not exceed maximum limit
  /// - Must have at most 2 decimal places
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateAmount(
    String? value, {
    double minAmount = 1.0,
    double maxAmount = 1000000.0,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value.trim());
    
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    if (amount < minAmount) {
      return 'Amount must be at least ₹${minAmount.toStringAsFixed(2)}';
    }
    
    if (amount > maxAmount) {
      return 'Amount cannot exceed ₹${maxAmount.toStringAsFixed(0)}';
    }
    
    // Check decimal places
    final parts = value.split('.');
    if (parts.length > 1 && parts[1].length > 2) {
      return 'Amount can have at most 2 decimal places';
    }
    
    return null;
  }
  
  // ==================== TRANSACTION REFERENCE VALIDATION ====================
  
  /// Validates UPI/Bank transaction reference (UTR).
  ///
  /// Rules:
  /// - Must not be empty
  /// - Must be at least 6 characters
  /// - Must contain only alphanumeric characters
  /// - No special characters except hyphen and underscore
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateTransactionReference(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Transaction reference is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 6) {
      return 'Transaction reference must be at least 6 characters';
    }
    
    if (trimmed.length > 50) {
      return 'Transaction reference is too long';
    }
    
    // Allow alphanumeric, hyphen, and underscore
    final validPattern = RegExp(r'^[a-zA-Z0-9\-_]+$');
    if (!validPattern.hasMatch(trimmed)) {
      return 'Transaction reference can only contain letters, numbers, hyphens, and underscores';
    }
    
    return null;
  }
  
  // ==================== EMAIL VALIDATION ====================
  
  /// Validates email address.
  ///
  /// Uses a comprehensive regex pattern that covers most valid email formats.
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final trimmed = value.trim();
    
    // Comprehensive email regex
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailPattern.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // ==================== PHONE NUMBER VALIDATION ====================
  
  /// Validates Indian phone number.
  ///
  /// Rules:
  /// - Must be 10 digits
  /// - Must start with 6, 7, 8, or 9
  /// - Can optionally include +91 or 91 prefix
  ///
  /// Returns null if valid, error message otherwise.
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Check for +91 or 91 prefix
    String phoneNumber = digitsOnly;
    if (phoneNumber.startsWith('91') && phoneNumber.length == 12) {
      phoneNumber = phoneNumber.substring(2);
    }
    
    if (phoneNumber.length != 10) {
      return 'Phone number must be 10 digits';
    }
    
    // Must start with 6, 7, 8, or 9
    if (!phoneNumber.startsWith(RegExp(r'[6-9]'))) {
      return 'Phone number must start with 6, 7, 8, or 9';
    }
    
    return null;
  }
  
  // ==================== PASSWORD VALIDATION ====================
  
  /// Validates password strength.
  ///
  /// Rules:
  /// - Minimum 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one digit
  /// - At least one special character
  ///
  /// Returns null if valid, error message otherwise.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one digit';
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
  
  /// Validates password confirmation.
  static String? validatePasswordConfirmation(
    String? value,
    String? password,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // ==================== PIN VALIDATION ====================
  
  /// Validates 4-digit PIN.
  ///
  /// Rules:
  /// - Must be exactly 4 digits
  /// - Cannot be sequential (1234, 4321)
  /// - Cannot be all same digits (1111)
  ///
  /// Returns null if valid, error message otherwise.
  static String? validatePIN(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    
    if (value.length != 4) {
      return 'PIN must be exactly 4 digits';
    }
    
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'PIN must contain only digits';
    }
    
    // Check for all same digits
    if (value == value[0] * 4) {
      return 'PIN cannot be all same digits';
    }
    
    // Check for sequential digits
    final sequential = ['0123', '1234', '2345', '3456', '4567', '5678', '6789'];
    final reverseSequential = sequential.map((s) => s.split('').reversed.join()).toList();
    
    if (sequential.contains(value) || reverseSequential.contains(value)) {
      return 'PIN cannot be sequential digits';
    }
    
    return null;
  }
  
  // ==================== NAME VALIDATION ====================
  
  /// Validates person's name.
  ///
  /// Rules:
  /// - Must not be empty
  /// - Must be at least 2 characters
  /// - Can only contain letters, spaces, hyphens, and apostrophes
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    if (trimmed.length > 50) {
      return '$fieldName is too long';
    }
    
    // Allow letters, spaces, hyphens, and apostrophes
    final namePattern = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!namePattern.hasMatch(trimmed)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }
  
  // ==================== BANK ACCOUNT VALIDATION ====================
  
  /// Validates Indian bank account number.
  ///
  /// Rules:
  /// - Must be between 9 and 18 digits
  /// - Can only contain digits
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateBankAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account number is required';
    }
    
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length < 9 || digitsOnly.length > 18) {
      return 'Account number must be between 9 and 18 digits';
    }
    
    return null;
  }
  
  /// Validates Indian IFSC code.
  ///
  /// Rules:
  /// - Must be exactly 11 characters
  /// - First 4 characters: bank code (letters)
  /// - 5th character: always 0
  /// - Last 6 characters: branch code (alphanumeric)
  ///
  /// Returns null if valid, error message otherwise.
  static String? validateIFSC(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IFSC code is required';
    }
    
    final trimmed = value.trim().toUpperCase();
    
    if (trimmed.length != 11) {
      return 'IFSC code must be exactly 11 characters';
    }
    
    // Pattern: 4 letters + 0 + 6 alphanumeric
    final ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    if (!ifscPattern.hasMatch(trimmed)) {
      return 'Invalid IFSC code format';
    }
    
    return null;
  }
  
  // ==================== POOL VALIDATION ====================
  
  /// Validates pool name.
  static String? validatePoolName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pool name is required';
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < 3) {
      return 'Pool name must be at least 3 characters';
    }
    
    if (trimmed.length > 50) {
      return 'Pool name is too long (max 50 characters)';
    }
    
    return null;
  }
  
  /// Validates pool description.
  static String? validatePoolDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Description is optional
    }
    
    if (value.trim().length > 500) {
      return 'Description is too long (max 500 characters)';
    }
    
    return null;
  }
  
  /// Validates number of pool members.
  static String? validateMemberCount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Number of members is required';
    }
    
    final count = int.tryParse(value.trim());
    
    if (count == null) {
      return 'Please enter a valid number';
    }
    
    if (count < 2) {
      return 'Pool must have at least 2 members';
    }
    
    if (count > 100) {
      return 'Pool cannot have more than 100 members';
    }
    
    return null;
  }
  
  /// Validates invite code.
  static String? validateInviteCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Invite code is required';
    }
    
    final trimmed = value.trim().toUpperCase();
    
    if (trimmed.length != 6) {
      return 'Invite code must be exactly 6 characters';
    }
    
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(trimmed)) {
      return 'Invalid invite code format';
    }
    
    return null;
  }
  
  // ==================== GENERAL VALIDATION ====================
  
  /// Validates that a field is not empty.
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  /// Validates minimum length.
  static String? validateMinLength(
    String? value,
    int minLength, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }
  
  /// Validates maximum length.
  static String? validateMaxLength(
    String? value,
    int maxLength, {
    String fieldName = 'This field',
  }) {
    if (value != null && value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    
    return null;
  }
  
  /// Sanitizes input by removing potentially dangerous characters.
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[<>]'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[;]'), ''); // Remove SQL injection attempts
  }
}
