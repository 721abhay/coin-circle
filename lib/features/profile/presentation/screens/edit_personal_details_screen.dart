import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/services/personal_details_service.dart';

class EditPersonalDetailsScreen extends StatefulWidget {
  const EditPersonalDetailsScreen({super.key});

  @override
  State<EditPersonalDetailsScreen> createState() => _EditPersonalDetailsScreenState();
}

class _EditPersonalDetailsScreenState extends State<EditPersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _panController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _occupationController = TextEditingController();
  final _annualIncomeController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  String? _initialPhone;
  final _personalDetailsService = PersonalDetailsService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _panController.dispose();
    _aadhaarController.dispose();
    _occupationController.dispose();
    _annualIncomeController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _fullNameController.text = profile['full_name'] ?? '';
          _phoneController.text = profile['phone_number'] ?? '';
          _initialPhone = profile['phone_number'];
          _addressController.text = profile['address'] ?? '';
          _cityController.text = profile['city'] ?? '';
          _stateController.text = profile['state'] ?? '';
          _postalCodeController.text = profile['postal_code'] ?? '';
          _panController.text = profile['pan_number'] ?? '';
          _aadhaarController.text = profile['aadhaar_number'] ?? '';
          _occupationController.text = profile['occupation'] ?? '';
          _annualIncomeController.text = profile['annual_income'] ?? '';
          _emergencyNameController.text = profile['emergency_contact_name'] ?? '';
          _emergencyPhoneController.text = profile['emergency_contact_phone'] ?? '';
          
          if (profile['date_of_birth'] != null) {
            _selectedDateOfBirth = DateTime.parse(profile['date_of_birth']);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if phone number changed
    final newPhone = _phoneController.text.trim();
    if (newPhone.isNotEmpty && newPhone != _initialPhone) {
      final verified = await _handlePhoneVerification(newPhone);
      if (!verified) return;
    }

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final fullName = _fullNameController.text.trim();
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await Supabase.instance.client.from('profiles').update({
        'full_name': fullName,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'date_of_birth': _selectedDateOfBirth?.toIso8601String(),
        'pan_number': _panController.text.trim().toUpperCase(),
        'aadhaar_number': _aadhaarController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'annual_income': _annualIncomeController.text.trim(),
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate data was saved
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _handlePhoneVerification(String newPhone) async {
    try {
      setState(() => _isSaving = true);
      
      // Send OTP
      await _personalDetailsService.sendPhoneVerificationOTP(newPhone);
      
      if (!mounted) return false;
      setState(() => _isSaving = false);

      // Show OTP Dialog
      final otp = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _OtpVerificationDialog(phone: newPhone),
      );

      if (otp == null) return false; // Cancelled

      setState(() => _isSaving = true);
      
      // Verify OTP
      await _personalDetailsService.verifyPhoneOTP(newPhone, otp);
      
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'), 
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDateOfBirth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Personal Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Personal Details'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information
            _buildSectionHeader('Basic Information'),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'John Doe',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Contact Information
            _buildSectionHeader('Contact Information'),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+91 9876543210',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address
            _buildSectionHeader('Address'),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: '123 Main Street, Apt 4B',
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'Mumbai',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      hintText: 'Maharashtra',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'Postal Code',
                hintText: '400001',
                prefixIcon: Icon(Icons.pin_drop),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 16),

            // Personal Details
            _buildSectionHeader('Personal Details'),
            ListTile(
              leading: const Icon(Icons.cake),
              title: const Text('Date of Birth'),
              subtitle: Text(
                _selectedDateOfBirth != null
                    ? DateFormat('d MMMM yyyy').format(_selectedDateOfBirth!)
                    : 'Not set',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDateOfBirth,
            ),
            const SizedBox(height: 16),

            // Identity Documents
            _buildSectionHeader('Identity Documents'),
            TextFormField(
              controller: _panController,
              decoration: const InputDecoration(
                labelText: 'PAN Number',
                hintText: 'ABCDE1234F',
                prefixIcon: Icon(Icons.credit_card),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 10,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(value)) {
                    return 'Invalid PAN format';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aadhaarController,
              decoration: const InputDecoration(
                labelText: 'Aadhaar Number',
                hintText: '123456789012',
                prefixIcon: Icon(Icons.fingerprint),
              ),
              keyboardType: TextInputType.number,
              maxLength: 12,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (value.length != 12) {
                    return 'Aadhaar must be 12 digits';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Financial Information
            _buildSectionHeader('Financial Information'),
            TextFormField(
              controller: _occupationController,
              decoration: const InputDecoration(
                labelText: 'Occupation',
                hintText: 'Software Engineer',
                prefixIcon: Icon(Icons.work),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _annualIncomeController,
              decoration: const InputDecoration(
                labelText: 'Annual Income',
                hintText: '₹10,00,000 - ₹15,00,000',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Contact
            _buildSectionHeader('Emergency Contact'),
            TextFormField(
              controller: _emergencyNameController,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Name',
                hintText: 'John Doe',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: const InputDecoration(
                labelText: 'Emergency Contact Phone',
                hintText: '+91 9876543211',
                prefixIcon: Icon(Icons.phone_in_talk),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

class _OtpVerificationDialog extends StatefulWidget {
  final String phone;

  const _OtpVerificationDialog({required this.phone});

  @override
  State<_OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<_OtpVerificationDialog> {
  final _otpController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      setState(() {
        _isValid = _otpController.text.trim().length == 6;
      });
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Phone Number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Enter the 6-digit OTP sent to ${widget.phone}'),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(_otpController.text.trim())
              : null,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}
