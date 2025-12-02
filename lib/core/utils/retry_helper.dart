import 'dart:async';

/// Utility class for retrying failed operations with exponential backoff.
///
/// This implements the Retry Pattern for handling transient failures,
/// particularly useful for network operations and database queries.
///
/// Example usage:
/// ```dart
/// final result = await RetryHelper.retry(
///   operation: () => apiService.fetchData(),
///   maxAttempts: 3,
///   retryIf: (error) => error is NetworkException,
/// );
/// ```
class RetryHelper {
  /// Retries an operation with exponential backoff.
  ///
  /// Parameters:
  /// - [operation]: The async operation to retry
  /// - [maxAttempts]: Maximum number of retry attempts (default: 3)
  /// - [initialDelay]: Initial delay before first retry (default: 1 second)
  /// - [maxDelay]: Maximum delay between retries (default: 30 seconds)
  /// - [retryIf]: Optional predicate to determine if error should trigger retry
  /// - [onRetry]: Optional callback called before each retry attempt
  ///
  /// Returns: The result of the successful operation
  ///
  /// Throws: The last error if all retry attempts fail
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    bool Function(dynamic error)? retryIf,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    assert(maxAttempts > 0, 'maxAttempts must be greater than 0');
    
    int attempt = 0;
    dynamic lastError;
    
    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        attempt++;
        
        // Check if we should retry this error
        if (retryIf != null && !retryIf(error)) {
          rethrow;
        }
        
        // If this was the last attempt, rethrow the error
        if (attempt >= maxAttempts) {
          rethrow;
        }
        
        // Calculate delay with exponential backoff
        final delay = _calculateDelay(
          attempt: attempt,
          initialDelay: initialDelay,
          maxDelay: maxDelay,
        );
        
        // Call retry callback if provided
        if (onRetry != null) {
          onRetry(attempt, error);
        }
        
        // Wait before retrying
        await Future.delayed(delay);
      }
    }
    
    // This should never be reached, but just in case
    throw lastError ?? Exception('Retry failed with unknown error');
  }
  
  /// Retries an operation with custom delay strategy.
  ///
  /// This allows for more control over the retry delay calculation.
  static Future<T> retryWithDelays<T>({
    required Future<T> Function() operation,
    required List<Duration> delays,
    bool Function(dynamic error)? retryIf,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    assert(delays.isNotEmpty, 'delays list cannot be empty');
    
    int attempt = 0;
    
    while (true) {
      try {
        return await operation();
      } catch (error) {
        // Check if we should retry this error
        if (retryIf != null && !retryIf(error)) {
          rethrow;
        }
        
        // If we've exhausted all delays, rethrow the error
        if (attempt >= delays.length) {
          rethrow;
        }
        
        // Call retry callback if provided
        if (onRetry != null) {
          onRetry(attempt + 1, error);
        }
        
        // Wait before retrying
        await Future.delayed(delays[attempt]);
        attempt++;
      }
    }
  }
  
  /// Calculates the delay for the next retry attempt using exponential backoff.
  ///
  /// The delay is calculated as: initialDelay * (2 ^ (attempt - 1))
  /// with a maximum cap of [maxDelay].
  static Duration _calculateDelay({
    required int attempt,
    required Duration initialDelay,
    required Duration maxDelay,
  }) {
    // Calculate exponential backoff: initialDelay * 2^(attempt-1)
    final multiplier = 1 << (attempt - 1); // 2^(attempt-1)
    final calculatedDelay = initialDelay * multiplier;
    
    // Cap at maxDelay
    if (calculatedDelay > maxDelay) {
      return maxDelay;
    }
    
    return calculatedDelay;
  }
  
  /// Retries an operation with jitter to avoid thundering herd problem.
  ///
  /// Jitter adds randomness to the delay to prevent all clients
  /// from retrying at the same time.
  static Future<T> retryWithJitter<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    double jitterFactor = 0.3, // 30% jitter
    bool Function(dynamic error)? retryIf,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    assert(maxAttempts > 0, 'maxAttempts must be greater than 0');
    assert(jitterFactor >= 0 && jitterFactor <= 1, 'jitterFactor must be between 0 and 1');
    
    int attempt = 0;
    
    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        // Check if we should retry this error
        if (retryIf != null && !retryIf(error)) {
          rethrow;
        }
        
        // If this was the last attempt, rethrow the error
        if (attempt >= maxAttempts) {
          rethrow;
        }
        
        // Calculate delay with exponential backoff
        final baseDelay = _calculateDelay(
          attempt: attempt,
          initialDelay: initialDelay,
          maxDelay: maxDelay,
        );
        
        // Add jitter
        final jitter = baseDelay * jitterFactor * (0.5 + (DateTime.now().millisecond % 1000) / 2000);
        final delay = baseDelay + jitter;
        
        // Call retry callback if provided
        if (onRetry != null) {
          onRetry(attempt, error);
        }
        
        // Wait before retrying
        await Future.delayed(delay);
      }
    }
    
    throw Exception('Retry failed with unknown error');
  }
}

/// Extension methods for Future to add retry capabilities.
extension RetryExtension<T> on Future<T> Function() {
  /// Retries this future with the specified parameters.
  ///
  /// Example:
  /// ```dart
  /// final result = await (() => apiService.fetchData()).withRetry(
  ///   maxAttempts: 3,
  /// );
  /// ```
  Future<T> withRetry({
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    bool Function(dynamic error)? retryIf,
    void Function(int attempt, dynamic error)? onRetry,
  }) {
    return RetryHelper.retry(
      operation: this,
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
      maxDelay: maxDelay,
      retryIf: retryIf,
      onRetry: onRetry,
    );
  }
}
