import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// DEPRECATED: This screen is replaced by KYCVerificationScreen
/// Redirects to the new comprehensive KYC verification flow
class KYCSubmissionScreen extends StatelessWidget {
  const KYCSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Automatically redirect to new KYC screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go('/kyc-verification');
      }
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
