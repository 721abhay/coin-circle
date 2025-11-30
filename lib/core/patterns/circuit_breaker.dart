import 'package:flutter/foundation.dart';
/// Circuit Breaker Pattern implementation for fault tolerance.
///
/// The Circuit Breaker prevents cascading failures by stopping requests
/// to a failing service and allowing it time to recover.
///
/// States:
/// - CLOSED: Normal operation, requests pass through
/// - OPEN: Service is failing, requests are blocked
/// - HALF_OPEN: Testing if service has recovered
///
/// Example usage:
/// ```dart
/// final breaker = CircuitBreaker(
///   failureThreshold: 5,
///   timeout: Duration(seconds: 60),
/// );
///
/// try {
///   final result = await breaker.execute(() => apiService.fetchData());
/// } on CircuitBreakerOpenException {
///   // Handle service unavailable
/// }
/// ```
enum CircuitState {
  /// Normal operation - requests pass through
  closed,
  
  /// Service is failing - requests are blocked
  open,
  
  /// Testing if service has recovered
  halfOpen,
}

class CircuitBreaker {
  /// Current state of the circuit breaker
  CircuitState _state = CircuitState.closed;
  
  /// Number of consecutive failures
  int _failureCount = 0;
  
  /// Number of consecutive successes in half-open state
  int _successCount = 0;
  
  /// Timestamp of the last failure
  DateTime? _lastFailureTime;
  
  /// Timestamp when the circuit was opened
  DateTime? _openedAt;
  
  /// Number of failures before opening the circuit
  final int _failureThreshold;
  
  /// Duration to wait before attempting to close the circuit
  final Duration _timeout;
  
  /// Number of successful requests needed to close from half-open
  final int _successThreshold;
  
  /// Optional callback when circuit opens
  final void Function()? _onOpen;
  
  /// Optional callback when circuit closes
  final void Function()? _onClose;
  
  /// Optional callback when circuit enters half-open state
  final void Function()? _onHalfOpen;
  
  CircuitBreaker({
    required int failureThreshold,
    required Duration timeout,
    int successThreshold = 2,
    void Function()? onOpen,
    void Function()? onClose,
    void Function()? onHalfOpen,
  })  : assert(failureThreshold > 0, 'failureThreshold must be greater than 0'),
        assert(successThreshold > 0, 'successThreshold must be greater than 0'),
        _failureThreshold = failureThreshold,
        _timeout = timeout,
        _successThreshold = successThreshold,
        _onOpen = onOpen,
        _onClose = onClose,
        _onHalfOpen = onHalfOpen;
  
  /// Executes an operation through the circuit breaker.
  ///
  /// Throws [CircuitBreakerOpenException] if the circuit is open.
  Future<T> execute<T>(Future<T> Function() operation) async {
    // Check if we should attempt to reset from open to half-open
    if (_state == CircuitState.open && _shouldAttemptReset()) {
      _transitionToHalfOpen();
    }
    
    // Block requests if circuit is open
    if (_state == CircuitState.open) {
      throw CircuitBreakerOpenException('Circuit breaker is open');
    }
    
    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure(error);
      rethrow;
    }
  }
  
  /// Executes an operation with a fallback if the circuit is open.
  Future<T> executeWithFallback<T>({
    required Future<T> Function() operation,
    required T Function() fallback,
  }) async {
    try {
      return await execute(operation);
    } on CircuitBreakerOpenException {
      return fallback();
    }
  }
  
  /// Checks if enough time has passed to attempt reset.
  bool _shouldAttemptReset() {
    if (_openedAt == null) return false;
    return DateTime.now().difference(_openedAt!) > _timeout;
  }
  
  /// Handles successful operation execution.
  void _onSuccess() {
    if (_state == CircuitState.halfOpen) {
      _successCount++;
      
      // If we've had enough successes, close the circuit
      if (_successCount >= _successThreshold) {
        _transitionToClosed();
      }
    } else if (_state == CircuitState.closed) {
      // Reset failure count on success
      _failureCount = 0;
    }
  }
  
  /// Handles failed operation execution.
  void _onFailure(dynamic error) {
    _lastFailureTime = DateTime.now();
    
    if (_state == CircuitState.halfOpen) {
      // Any failure in half-open state reopens the circuit
      _transitionToOpen();
    } else if (_state == CircuitState.closed) {
      _failureCount++;
      
      // Open circuit if threshold is reached
      if (_failureCount >= _failureThreshold) {
        _transitionToOpen();
      }
    }
  }
  
  /// Transitions the circuit to OPEN state.
  void _transitionToOpen() {
    _state = CircuitState.open;
    _openedAt = DateTime.now();
    _successCount = 0;
    _onOpen?.call();
  }
  
  /// Transitions the circuit to HALF_OPEN state.
  void _transitionToHalfOpen() {
    _state = CircuitState.halfOpen;
    _successCount = 0;
    _failureCount = 0;
    _onHalfOpen?.call();
  }
  
  /// Transitions the circuit to CLOSED state.
  void _transitionToClosed() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _openedAt = null;
    _onClose?.call();
  }
  
  /// Manually resets the circuit breaker to closed state.
  void reset() {
    _transitionToClosed();
  }
  
  /// Gets the current state of the circuit breaker.
  CircuitState get state => _state;
  
  /// Gets the current failure count.
  int get failureCount => _failureCount;
  
  /// Gets the current success count (in half-open state).
  int get successCount => _successCount;
  
  /// Checks if the circuit is currently open.
  bool get isOpen => _state == CircuitState.open;
  
  /// Checks if the circuit is currently closed.
  bool get isClosed => _state == CircuitState.closed;
  
  /// Checks if the circuit is currently half-open.
  bool get isHalfOpen => _state == CircuitState.halfOpen;
  
  /// Gets statistics about the circuit breaker.
  Map<String, dynamic> get stats => {
        'state': _state.toString(),
        'failureCount': _failureCount,
        'successCount': _successCount,
        'lastFailureTime': _lastFailureTime?.toIso8601String(),
        'openedAt': _openedAt?.toIso8601String(),
      };
}

/// Exception thrown when circuit breaker is open.
class CircuitBreakerOpenException implements Exception {
  final String message;
  
  CircuitBreakerOpenException(this.message);
  
  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// Circuit Breaker Manager for managing multiple circuit breakers.
///
/// This allows you to have separate circuit breakers for different services.
class CircuitBreakerManager {
  final Map<String, CircuitBreaker> _breakers = {};
  
  /// Gets or creates a circuit breaker for the specified service.
  CircuitBreaker getBreaker(
    String serviceName, {
    int failureThreshold = 5,
    Duration timeout = const Duration(seconds: 60),
    int successThreshold = 2,
  }) {
    return _breakers.putIfAbsent(
      serviceName,
      () => CircuitBreaker(
        failureThreshold: failureThreshold,
        timeout: timeout,
        successThreshold: successThreshold,
        onOpen: () => _onBreakerOpen(serviceName),
        onClose: () => _onBreakerClose(serviceName),
        onHalfOpen: () => _onBreakerHalfOpen(serviceName),
      ),
    );
  }
  
  /// Executes an operation through the circuit breaker for the specified service.
  Future<T> execute<T>(
    String serviceName,
    Future<T> Function() operation,
  ) async {
    final breaker = getBreaker(serviceName);
    return breaker.execute(operation);
  }
  
  /// Resets the circuit breaker for the specified service.
  void resetBreaker(String serviceName) {
    _breakers[serviceName]?.reset();
  }
  
  /// Resets all circuit breakers.
  void resetAll() {
    for (final breaker in _breakers.values) {
      breaker.reset();
    }
  }
  
  /// Gets statistics for all circuit breakers.
  Map<String, Map<String, dynamic>> get allStats {
    return Map.fromEntries(
      _breakers.entries.map((e) => MapEntry(e.key, e.value.stats)),
    );
  }
  
  void _onBreakerOpen(String serviceName) {
    debugPrint('⚠️ Circuit breaker OPENED for service: $serviceName');
  }
  
  void _onBreakerClose(String serviceName) {
    debugPrint('✅ Circuit breaker CLOSED for service: $serviceName');
  }
  
  void _onBreakerHalfOpen(String serviceName) {
    debugPrint('🔄 Circuit breaker HALF-OPEN for service: $serviceName');
  }
}
