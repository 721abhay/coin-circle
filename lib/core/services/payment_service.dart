import 'dart:math';

class PaymentService {
  /// Simulates processing a payment with a gateway like Stripe or Razorpay
  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String method, // 'card', 'upi', 'netbanking'
    required String currency,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate random success/failure (90% success rate for demo)
    final random = Random();
    final isSuccess = random.nextDouble() < 0.9;

    if (isSuccess) {
      return {
        'success': true,
        'transactionId': 'TXN-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1000)}',
        'message': 'Payment processed successfully',
      };
    } else {
      throw Exception('Payment failed: Gateway rejected the transaction');
    }
  }

  /// Validate card details (Mock)
  static bool validateCard(String number, String expiry, String cvv) {
    return number.length >= 16 && expiry.isNotEmpty && cvv.length == 3;
  }

  /// Validate UPI ID (Mock)
  static bool validateUpi(String upiId) {
    return upiId.contains('@');
  }
}
