import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1: Profile Picture
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  // Step 2: Phone Number
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate; // Store the actual date
  String _selectedCountryCode = '+91'; // Default India

  // Step 3: Notification Preferences
  bool _paymentReminders = true;
  bool _poolUpdates = true;
  bool _winnerAnnouncements = true;
  bool _memberActivities = false;

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF6C63FF)),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF6C63FF)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadProfilePicture() async {
    if (_profileImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Upload to Supabase Storage
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await _profileImage!.readAsBytes();

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(fileName, bytes);

      // Get public URL
      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Update profile
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);

    } catch (e) {
      _showError('Failed to upload image: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _savePhoneNumber() async {
    final phone = _phoneController.text.trim();
    
    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await Supabase.instance.client
          .from('profiles')
          .update({
            'phone': '$_selectedCountryCode$phone',
            'bio': _bioController.text.trim(),
            'location': _locationController.text.trim(),
            'date_of_birth': _selectedDate != null 
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!) 
                : null, // Database format: YYYY-MM-DD
          })
          .eq('id', userId);

    } catch (e) {
      _showError('Failed to save phone number: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await Supabase.instance.client
          .from('profiles')
          .update({
            'privacy_settings': {
              'payment_reminders': _paymentReminders,
              'pool_updates': _poolUpdates,
              'winner_announcements': _winnerAnnouncements,
              'member_activities': _memberActivities,
            },
          })
          .eq('id', userId);

    } catch (e) {
      _showError('Failed to save preferences: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _nextStep() async {
    if (_currentStep < _totalSteps - 1) {
      // Save current step data
      if (_currentStep == 0 && _profileImage != null) {
        await _uploadProfilePicture();
      } else if (_currentStep == 1) {
        await _savePhoneNumber();
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      // Final step - save and complete
      await _savePreferences();
      
      if (mounted) {
        context.go('/home');
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  void _skip() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: List.generate(_totalSteps, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? const Color(0xFF6C63FF)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildProfilePictureStep(),
                  _buildPhoneNumberStep(),
                  _buildNotificationPreferencesStep(),
                ],
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploadingImage ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isUploadingImage
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _currentStep < _totalSteps - 1 ? 'Next' : 'Complete',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Add Profile Picture',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Help others recognize you',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 48),
            
            // Profile Picture Preview
            GestureDetector(
              onTap: _showImageSourceOptions,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  image: _profileImage != null
                      ? DecorationImage(
                          image: FileImage(_profileImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profileImage == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 50,
                        color: Color(0xFF6C63FF),
                      )
                    : null,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              _profileImage == null ? 'Tap to add photo' : 'Tap to change photo',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNumberStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Add Phone Number',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stay connected with your savings circle',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 48),
            
            Row(
              children: [
                // Country Code Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCountryCode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: '+1', child: Text('+1')),
                      DropdownMenuItem(value: '+44', child: Text('+44')),
                      DropdownMenuItem(value: '+91', child: Text('+91')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCountryCode = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Phone Number Input
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF6C63FF),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio (Optional)',
                hintText: 'Tell us about yourself',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (Optional)',
                hintText: 'City, Country',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dobController,
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                hintText: 'DD/MM/YYYY',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _dobController.text = DateFormat('dd/MM/yyyy').format(date); // Display format
                  });
                }
              },
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPreferencesStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Notification Preferences',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose what updates you want to receive',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            _buildPreferenceToggle(
              'Payment Reminders',
              'Get notified before payments are due',
              _paymentReminders,
              (value) => setState(() => _paymentReminders = value),
            ),
            _buildPreferenceToggle(
              'Pool Updates',
              'New members, cycles, and important changes',
              _poolUpdates,
              (value) => setState(() => _poolUpdates = value),
            ),
            _buildPreferenceToggle(
              'Winner Announcements',
              'Be the first to know who won the draw',
              _winnerAnnouncements,
              (value) => setState(() => _winnerAnnouncements = value),
            ),
            _buildPreferenceToggle(
              'Member Activities',
              'Contributions, joins, and other activities',
              _memberActivities,
              (value) => setState(() => _memberActivities = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF6C63FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
