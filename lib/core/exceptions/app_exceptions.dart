/// Base exception class for all application-specific exceptions.
///
/// This follows the Single Responsibility Principle by providing
/// a consistent error handling interface across the application.
abstract class AppException implements Exception {
  /// Human-readable error message
  final String message;
  
  /// Optional error code for categorization
  final String? code;
  
  /// Original error that caused this exception (for debugging)
  final dynamic originalError;
  
  /// Stack trace at the point of exception creation
  final StackTrace? stackTrace;
  
  AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer('${runtimeType}: $message');
    if (code != null) buffer.write(' (code: $code)');
    if (originalError != null) buffer.write('\nCaused by: $originalError');
    return buffer.toString();
  }
}

/// Exception thrown when wallet operations fail
class WalletException extends AppException {
  WalletException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when wallet is not found
class WalletNotFoundException extends WalletException {
  WalletNotFoundException(String userId)
      : super('Wallet not found for user: $userId', code: 'WALLET_NOT_FOUND');
}

/// Exception thrown when wallet has insufficient balance
class InsufficientBalanceException extends WalletException {
  final double required;
  final double available;
  
  InsufficientBalanceException({
    required this.required,
    required this.available,
  }) : super(
          'Insufficient balance. Required: ₹$required, Available: ₹$available',
          code: 'INSUFFICIENT_BALANCE',
        );
}

/// Exception thrown when pool operations fail
class PoolException extends AppException {
  PoolException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when pool is not found
class PoolNotFoundException extends PoolException {
  PoolNotFoundException(String poolId)
      : super('Pool not found: $poolId', code: 'POOL_NOT_FOUND');
}

/// Exception thrown when pool is full
class PoolFullException extends PoolException {
  PoolFullException(String poolName)
      : super('Pool "$poolName" is full', code: 'POOL_FULL');
}

/// Exception thrown when user is already a member of a pool
class AlreadyPoolMemberException extends PoolException {
  AlreadyPoolMemberException(String poolName)
      : super('You are already a member of "$poolName"', code: 'ALREADY_MEMBER');
}

/// Exception thrown when network operations fail
class NetworkException extends AppException {
  NetworkException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when network is unavailable
class NoInternetException extends NetworkException {
  NoInternetException()
      : super(
          'No internet connection. Please check your network.',
          code: 'NO_INTERNET',
        );
}

/// Exception thrown when request times out
class TimeoutException extends NetworkException {
  TimeoutException()
      : super(
          'Request timed out. Please try again.',
          code: 'TIMEOUT',
        );
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  AuthException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when user is not authenticated
class UnauthorizedException extends AuthException {
  UnauthorizedException()
      : super(
          'You must be logged in to perform this action',
          code: 'UNAUTHORIZED',
        );
}

/// Exception thrown when user lacks required permissions
class ForbiddenException extends AuthException {
  ForbiddenException(String action)
      : super(
          'You do not have permission to $action',
          code: 'FORBIDDEN',
        );
}

/// Exception thrown when admin operations fail
class AdminException extends AppException {
  AdminException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  final Map<String, String> errors;
  
  ValidationException(this.errors)
      : super(
          'Validation failed: ${errors.values.join(', ')}',
          code: 'VALIDATION_ERROR',
        );
}

/// Exception thrown when rate limit is exceeded
class RateLimitException extends AppException {
  final DateTime? retryAfter;
  
  RateLimitException({
    String message = 'Too many requests. Please try again later.',
    this.retryAfter,
  }) : super(message, code: 'RATE_LIMIT_EXCEEDED');
}

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException extends AppException {
  CircuitBreakerOpenException(String service)
      : super(
          'Service "$service" is temporarily unavailable',
          code: 'CIRCUIT_BREAKER_OPEN',
        );
}

/// Exception thrown when payment operations fail
class PaymentException extends AppException {
  PaymentException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when payment is declined
class PaymentDeclinedException extends PaymentException {
  PaymentDeclinedException(String reason)
      : super('Payment declined: $reason', code: 'PAYMENT_DECLINED');
}

/// Exception thrown when transaction reference is invalid
class InvalidTransactionReferenceException extends PaymentException {
  InvalidTransactionReferenceException()
      : super(
          'Invalid transaction reference. Please check and try again.',
          code: 'INVALID_TRANSACTION_REF',
        );
}

/// Exception thrown when database operations fail
class DatabaseException extends AppException {
  DatabaseException(
    String message, {
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Exception thrown when a required record is not found
class RecordNotFoundException extends DatabaseException {
  RecordNotFoundException(String recordType, String identifier)
      : super(
          '$recordType not found: $identifier',
          code: 'RECORD_NOT_FOUND',
        );
}

/// Exception thrown when a duplicate record is detected
class DuplicateRecordException extends DatabaseException {
  DuplicateRecordException(String recordType)
      : super(
          'A $recordType with this information already exists',
          code: 'DUPLICATE_RECORD',
        );
}
