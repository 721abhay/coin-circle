import 'package:flutter/material.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification Submitted!')));
            Navigator.pop(context);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          Step(
            title: const Text('Personal Details'),
            content: Column(
              children: [
                const TextField(decoration: InputDecoration(labelText: 'Full Name (as per ID)')),
                const SizedBox(height: 16),
                const TextField(decoration: InputDecoration(labelText: 'Date of Birth')),
                const SizedBox(height: 16),
                const TextField(decoration: InputDecoration(labelText: 'Address')),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Document Upload'),
            content: Column(
              children: [
                _buildUploadButton('Government ID (Front)'),
                const SizedBox(height: 16),
                _buildUploadButton('Government ID (Back)'),
                const SizedBox(height: 16),
                const Text('Accepted: Passport, Driver\'s License, National ID', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Selfie Verification'),
            content: Column(
              children: [
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text('Take a clear selfie to match your ID', textAlign: TextAlign.center),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.blue),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
