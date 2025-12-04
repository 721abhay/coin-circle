import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  
  // Controllers
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  
  // Image files
  File? _aadhaarPhoto;
  File? _panPhoto;
  File? _selfieWithId;
  File? _addressProof;
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _kycStatus;
  
  @override
  void initState() {
    super.initState();
    _loadKYCStatus();
  }
  
  Future<void> _loadKYCStatus() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final response = await _supabase
          .from('kyc_documents')
          .select('verification_status')
          .eq('user_id', userId)
          .limit(1);
      
      if (mounted) {
        setState(() {
          if (response != null && response.isNotEmpty) {
            _kycStatus = response[0]['verification_status'];
          } else {
            _kycStatus = null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading KYC status: $e');
      if (mounted) {
        setState(() {
          _kycStatus = null;
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        switch (type) {
          case 'aadhaar':
            _aadhaarPhoto = File(pickedFile.path);
            break;
          case 'pan':
            _panPhoto = File(pickedFile.path);
            break;
          case 'selfie':
            _selfieWithId = File(pickedFile.path);
            break;
          case 'address':
            _addressProof = File(pickedFile.path);
            break;
        }
      });
    }
  }
  
  Future<String?> _uploadImage(File file, String type) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final fileName = '${userId}_${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage
          .from('kyc-documents')
          .upload(fileName, file);
      
      final url = _supabase.storage
          .from('kyc-documents')
          .getPublicUrl(fileName);
      
      return url;
    } catch (e) {
      debugPrint('Error uploading $type: $e');
      return null;
    }
  }
  
  Future<void> _submitKYC() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check required images
    if (_aadhaarPhoto == null || _panPhoto == null || _selfieWithId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents')),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');
      
      // Upload images
      final aadhaarUrl = await _uploadImage(_aadhaarPhoto!, 'aadhaar');
      final panUrl = await _uploadImage(_panPhoto!, 'pan');
      final selfieUrl = await _uploadImage(_selfieWithId!, 'selfie');
      String? addressUrl;
      if (_addressProof != null) {
        addressUrl = await _uploadImage(_addressProof!, 'address');
      }
      
      // Insert KYC documents
      await _supabase.from('kyc_documents').upsert({
        'user_id': userId,
        'aadhaar_number': _aadhaarController.text,
        'aadhaar_photo_url': aadhaarUrl,
        'pan_number': _panController.text.toUpperCase(),
        'pan_photo_url': panUrl,
        'bank_account_number': _bankAccountController.text,
        'bank_ifsc_code': _ifscController.text.toUpperCase(),
        'selfie_with_id_url': selfieUrl,
        'address_proof_url': addressUrl,
        'verification_status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      });
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _kycStatus = 'pending';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC submitted successfully! Verification usually takes 24-48 hours.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting KYC: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Show status if already submitted
    if (_kycStatus == 'pending') {
      return Scaffold(
        appBar: AppBar(title: const Text('KYC Verification')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 80, color: Colors.orange.shade300),
                const SizedBox(height: 24),
                const Text(
                  'KYC Verification Pending',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your documents are being verified by our team. This usually takes 24-48 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadKYCStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Status'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_kycStatus == 'approved') {
      return Scaffold(
        appBar: AppBar(title: const Text('KYC Verification')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, size: 80, color: Colors.green.shade400),
                const SizedBox(height: 24),
                const Text(
                  'KYC Verified!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account is fully verified. You can now create and join pools.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Show KYC form
    return Scaffold(
      appBar: AppBar(title: const Text('Complete KYC Verification')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Warning Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'KYC verification is mandatory to create or join pools. All information must be accurate.',
                      style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Aadhaar Section
            _buildSectionHeader('Aadhaar Card (Mandatory)', Icons.badge),
            TextFormField(
              controller: _aadhaarController,
              decoration: const InputDecoration(
                labelText: 'Aadhaar Number',
                hintText: 'XXXX XXXX XXXX',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 12,
              validator: (value) {
                if (value == null || value.length != 12) {
                  return 'Please enter valid 12-digit Aadhaar number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildPhotoUpload('Aadhaar Photo', _aadhaarPhoto, () => _pickImage('aadhaar')),
            const SizedBox(height: 24),
            
            // PAN Section
            _buildSectionHeader('PAN Card (Mandatory)', Icons.credit_card),
            TextFormField(
              controller: _panController,
              decoration: const InputDecoration(
                labelText: 'PAN Number',
                hintText: 'ABCDE1234F',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 10,
              validator: (value) {
                if (value == null || value.length != 10) {
                  return 'Please enter valid 10-character PAN';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildPhotoUpload('PAN Photo', _panPhoto, () => _pickImage('pan')),
            const SizedBox(height: 24),
            
            // Bank Account Section
            _buildSectionHeader('Bank Account (Mandatory)', Icons.account_balance),
            TextFormField(
              controller: _bankAccountController,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter bank account number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ifscController,
              decoration: const InputDecoration(
                labelText: 'IFSC Code',
                hintText: 'SBIN0001234',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 11,
              validator: (value) {
                if (value == null || value.length != 11) {
                  return 'Please enter valid 11-character IFSC code';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Selfie Section
            _buildSectionHeader('Selfie with ID (Mandatory)', Icons.photo_camera),
            _buildPhotoUpload('Selfie with Aadhaar', _selfieWithId, () => _pickImage('selfie')),
            const SizedBox(height: 24),
            
            // Address Proof (Optional)
            _buildSectionHeader('Address Proof (Optional)', Icons.home),
            _buildPhotoUpload('Address Proof', _addressProof, () => _pickImage('address'), optional: true),
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitKYC,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit for Verification', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildPhotoUpload(String label, File? image, VoidCallback onTap, {bool optional = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: image != null ? Colors.green : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: image != null ? Colors.green.shade50 : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(image, fit: BoxFit.cover),
                    )
                  : Icon(Icons.add_a_photo, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label + (optional ? ' (Optional)' : ''),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    image != null ? 'Photo uploaded' : 'Tap to take photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: image != null ? Colors.green : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              image != null ? Icons.check_circle : Icons.camera_alt,
              color: image != null ? Colors.green : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _aadhaarController.dispose();
    _panController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }
}
