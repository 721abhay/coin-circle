import 'package:flutter/material.dart';
import '../../../../core/services/legal_service.dart';

class LegalAgreementDialog extends StatefulWidget {
  final String poolId;
  final String poolName;
  final double contributionAmount;
  final int totalRounds;
  final String paymentSchedule;
  final VoidCallback onSigned;

  const LegalAgreementDialog({
    super.key,
    required this.poolId,
    required this.poolName,
    required this.contributionAmount,
    required this.totalRounds,
    required this.paymentSchedule,
    required this.onSigned,
  });

  @override
  State<LegalAgreementDialog> createState() => _LegalAgreementDialogState();
}

class _LegalAgreementDialogState extends State<LegalAgreementDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isAgreed = false;
  bool _isSigning = false;
  late String _agreementText;

  @override
  void initState() {
    super.initState();
    _agreementText = LegalService.generatePoolAgreementText(
      poolName: widget.poolName,
      contributionAmount: widget.contributionAmount,
      totalRounds: widget.totalRounds,
      paymentSchedule: widget.paymentSchedule,
    );

    _scrollController.addListener(() {
      if (!_hasScrolledToBottom &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 50) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _signAndJoin() async {
    setState(() => _isSigning = true);

    try {
      // 1. Sign Agreement
      await LegalService.signAgreement(
        poolId: widget.poolId,
        agreementType: 'pool_participation',
        agreementText: _agreementText,
        version: '1.0',
        deviceInfo: 'Mobile App', // In a real app, get actual device info
      );

      if (mounted) {
        widget.onSigned();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing agreement: $e')),
        );
        setState(() => _isSigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Legal Agreement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Text(
                    _agreementText,
                    style: const TextStyle(
                      fontFamily: 'Courier', // Monospace for legal text feel
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                if (!_hasScrolledToBottom)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Please scroll to the bottom to agree',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Checkbox(
                      value: _isAgreed,
                      onChanged: _hasScrolledToBottom
                          ? (value) => setState(() => _isAgreed = value ?? false)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        'I have read and agree to the terms and conditions.',
                        style: TextStyle(
                          color: _hasScrolledToBottom ? Colors.black : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_isAgreed && !_isSigning) ? _signAndJoin : null,
                    icon: _isSigning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.edit_document),
                    label: Text(_isSigning ? 'Signing...' : 'Sign & Join Pool'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
