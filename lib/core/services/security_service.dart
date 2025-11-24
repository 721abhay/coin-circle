import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:geolocator/geolocator.dart';

class SecurityService {
  static final _client = Supabase.instance.client;
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Transaction PIN Management
  static Future<void> setTransactionPin(String pin) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Hash the PIN before storing
    final hashedPin = _hashPin(pin);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('transaction_pin_$userId', hashedPin);
    
    // Also store in database for cross-device sync
    await _client.from('user_security_settings').upsert({
      'user_id': userId,
      'pin_hash': hashedPin,
      'pin_enabled': true,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<bool> verifyTransactionPin(String pin) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString('transaction_pin_$userId');
    
    if (storedHash == null) {
      // Try to fetch from database
      final response = await _client
          .from('user_security_settings')
          .select('pin_hash')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) return false;
      
      // Cache it locally
      await prefs.setString('transaction_pin_$userId', response['pin_hash']);
      return _hashPin(pin) == response['pin_hash'];
    }

    return _hashPin(pin) == storedHash;
  }

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<bool> isPinEnabled() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('transaction_pin_$userId') != null;
  }

  // Biometric Authentication
  static Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticateWithBiometric({String reason = 'Authenticate to proceed'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  // 2FA for Withdrawals
  static Future<String> sendWithdrawalOTP() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Generate 6-digit OTP
    final otp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    
    // Store OTP with expiry (5 minutes)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('withdrawal_otp_$userId', otp);
    await prefs.setInt('withdrawal_otp_expiry_$userId', 
        DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch);

    // In production, send via SMS/Email
    // For now, return it for testing
    print('Withdrawal OTP: $otp');
    return otp;
  }

  static Future<bool> verifyWithdrawalOTP(String otp) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final prefs = await SharedPreferences.getInstance();
    final storedOtp = prefs.getString('withdrawal_otp_$userId');
    final expiry = prefs.getInt('withdrawal_otp_expiry_$userId');

    if (storedOtp == null || expiry == null) return false;
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      // OTP expired
      await prefs.remove('withdrawal_otp_$userId');
      await prefs.remove('withdrawal_otp_expiry_$userId');
      return false;
    }

    final isValid = storedOtp == otp;
    if (isValid) {
      // Clear OTP after successful verification
      await prefs.remove('withdrawal_otp_$userId');
      await prefs.remove('withdrawal_otp_expiry_$userId');
    }

    return isValid;
  }

  // Transaction Limits & Velocity Checks
  static Future<bool> checkTransactionLimit(double amount, String type) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Daily limits
    const dailyDepositLimit = 50000.0; // ₹50,000
    const dailyWithdrawalLimit = 50000.0;
    const dailyContributionLimit = 100000.0;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    // Get today's transactions
    final transactions = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', userId)
        .eq('transaction_type', type)
        .gte('created_at', startOfDay.toIso8601String());

    final totalToday = transactions.fold<double>(
      0.0,
      (sum, t) => sum + ((t['amount'] as num).abs()),
    );

    double limit;
    switch (type) {
      case 'deposit':
        limit = dailyDepositLimit;
        break;
      case 'withdrawal':
        limit = dailyWithdrawalLimit;
        break;
      case 'contribution':
        limit = dailyContributionLimit;
        break;
      default:
        limit = 100000.0;
    }

    return (totalToday + amount) <= limit;
  }

  static Future<bool> checkVelocity() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Check for rapid transactions (more than 3 in last 5 minutes)
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

    final recentTransactions = await _client
        .from('transactions')
        .select('id')
        .eq('user_id', userId)
        .gte('created_at', fiveMinutesAgo.toIso8601String());

    return recentTransactions.length < 3;
  }

  // Suspicious Activity Monitoring
  static Future<void> logSecurityEvent(String eventType, Map<String, dynamic> metadata) async {
    final userId = _client.auth.currentUser?.id;
    
    await _client.from('security_events').insert({
      'user_id': userId,
      'event_type': eventType,
      'metadata': metadata,
      'ip_address': metadata['ip_address'],
      'device_info': metadata['device_info'],
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<bool> detectSuspiciousActivity() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    // Check for multiple failed PIN attempts
    final prefs = await SharedPreferences.getInstance();
    final failedAttempts = prefs.getInt('failed_pin_attempts_$userId') ?? 0;
    
    if (failedAttempts >= 3) {
      await logSecurityEvent('account_locked', {
        'reason': 'Multiple failed PIN attempts',
        'failed_attempts': failedAttempts,
      });
      return true;
    }

    return false;
  }

  static Future<void> incrementFailedPinAttempts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('failed_pin_attempts_$userId') ?? 0;
    await prefs.setInt('failed_pin_attempts_$userId', current + 1);
  }

  static Future<void> resetFailedPinAttempts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('failed_pin_attempts_$userId', 0);
  }

  // Device Fingerprinting
  static Future<String> getDeviceFingerprint() async {
    // In production, use device_info_plus package for more details
    final prefs = await SharedPreferences.getInstance();
    var fingerprint = prefs.getString('device_fingerprint');
    
    if (fingerprint == null) {
      // Generate unique fingerprint
      fingerprint = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_fingerprint', fingerprint);
    }

    return fingerprint;
  }

  // Session Management
  static Future<void> validateSession() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt('last_activity_$userId');
    
    if (lastActivity != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      const sessionTimeout = 30 * 60 * 1000; // 30 minutes
      
      if (now - lastActivity > sessionTimeout) {
        await _client.auth.signOut();
        throw Exception('Session expired');
      }
    }

    await prefs.setInt('last_activity_$userId', DateTime.now().millisecondsSinceEpoch);
  }

  // ============ ADVANCED SECURITY FEATURES ============

  // Rate Limiting (100 requests per minute per user)
  static Future<bool> checkRateLimit(String endpoint) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final result = await _client.rpc('check_rate_limit', params: {
        'p_user_id': userId,
        'p_endpoint': endpoint,
        'p_max_requests': 100,
      });
      
      return result as bool;
    } catch (e) {
      print('Rate limit check error: $e');
      // Fail open - allow request if check fails
      return true;
    }
  }

  // Geo-location Tracking
  static Future<void> trackLocation(String actionType, {Map<String, dynamic>? metadata}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Store location
      await _client.from('user_locations').insert({
        'user_id': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'action_type': actionType,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      print('Location tracking error: $e');
      // Don't fail the operation if location tracking fails
    }
  }

  // TDS Calculation and Deduction
  static Future<Map<String, dynamic>> calculateTDS({
    required double winningAmount,
    required String transactionId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final result = await _client.rpc('calculate_and_deduct_tds', params: {
        'p_user_id': userId,
        'p_winning_amount': winningAmount,
        'p_transaction_id': transactionId,
      });

      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      print('TDS calculation error: $e');
      rethrow;
    }
  }

  // Multiple Account Detection
  static Future<List<Map<String, dynamic>>> detectMultipleAccounts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final result = await _client.rpc('detect_multiple_accounts', params: {
        'p_user_id': userId,
      });

      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      print('Multiple account detection error: $e');
      return [];
    }
  }

  // IP Whitelist Check (for admin operations)
  static Future<bool> isIPWhitelisted(String ipAddress) async {
    try {
      final result = await _client
          .from('admin_ip_whitelist')
          .select('id')
          .eq('ip_address', ipAddress)
          .eq('is_active', true)
          .maybeSingle();

      return result != null;
    } catch (e) {
      print('IP whitelist check error: $e');
      return false;
    }
  }

  // Get TDS Records for User
  static Future<List<Map<String, dynamic>>> getTDSRecords({String? financialYear}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      var query = _client
          .from('tds_records')
          .select()
          .eq('user_id', userId);

      if (financialYear != null) {
        query = query.eq('financial_year', financialYear);
      }

      final result = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error fetching TDS records: $e');
      return [];
    }
  }

  // Get User Location History
  static Future<List<Map<String, dynamic>>> getLocationHistory({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final result = await _client
          .from('user_locations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error fetching location history: $e');
      return [];
    }
  }

  // Check for Suspicious Geo-location
  static Future<bool> checkSuspiciousLocation() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // Get last two locations
      final locations = await _client
          .from('user_locations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(2);

      if (locations.length < 2) return false;

      final loc1 = locations[0];
      final loc2 = locations[1];

      // Calculate distance between locations
      final distance = Geolocator.distanceBetween(
        loc2['latitude'],
        loc2['longitude'],
        loc1['latitude'],
        loc1['longitude'],
      );

      // Calculate time difference
      final time1 = DateTime.parse(loc1['created_at']);
      final time2 = DateTime.parse(loc2['created_at']);
      final timeDiff = time1.difference(time2).inMinutes;

      // If traveled > 100km in < 30 minutes, flag as suspicious
      if (distance > 100000 && timeDiff < 30) {
        await logSecurityEvent('suspicious_location', {
          'distance_meters': distance,
          'time_diff_minutes': timeDiff,
          'location1': {'lat': loc1['latitude'], 'lng': loc1['longitude']},
          'location2': {'lat': loc2['latitude'], 'lng': loc2['longitude']},
        });
        return true;
      }

      return false;
    } catch (e) {
      print('Suspicious location check error: $e');
      return false;
    }
  }
}
