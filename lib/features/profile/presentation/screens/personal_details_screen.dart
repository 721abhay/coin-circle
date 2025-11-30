import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  // Data state
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  String _userName = 'User';
  String _memberSince = 'Recently';
  String _phoneNumber = 'Not provided';
  String _email = 'Not provided';
  String _address = 'Not provided';
  String _dateOfBirth = 'Not provided';
  String _panNumber = 'Not provided';
  String _aadhaarNumber = 'Not provided';
  String _occupation = 'Not provided';
  String _annualIncome = 'Not provided';
  bool _isPhoneVerified = false;
  bool _isEmailVerified = false;
  double _profileCompletion = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Fetch profile from database
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _profile = profile;
          _userName = profile['full_name'] ?? 'User';
          _email = user.email ?? 'Not provided';
          _phoneNumber = profile['phone'] ?? 'Not provided';
          _address = _buildFullAddress(profile);
          _dateOfBirth = _formatDate(profile['date_of_birth']);
          _panNumber = profile['pan_number'] ?? 'Not provided';
          _aadhaarNumber = profile['aadhaar_number'] ?? 'Not provided';
          _occupation = profile['occupation'] ?? 'Not provided';
          _annualIncome = profile['annual_income'] ?? 'Not provided';
          _isPhoneVerified = profile['phone_verified'] ?? false;
          _isEmailVerified = profile['email_verified'] ?? false;
          
          // Calculate member since
          if (profile['created_at'] != null) {
            final createdAt = DateTime.parse(profile['created_at']);
            _memberSince = DateFormat('MMM yyyy').format(createdAt);
          }
          
          // Calculate profile completion
          _profileCompletion = _calculateProfileCompletion(profile);
          
          _isLoading = false;
        });
        _controller.forward();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _buildFullAddress(Map<String, dynamic> profile) {
    final address = profile['address'];
    final city = profile['city'];
    final state = profile['state'];
    final postalCode = profile['postal_code'];
    
    if (address == null && city == null) return 'Not provided';
    
    List<String> parts = [];
    if (address != null) parts.add(address);
    if (city != null) parts.add(city);
    if (state != null) parts.add(state);
    if (postalCode != null) parts.add(postalCode);
    
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not provided';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('d MMMM yyyy').format(dateTime);
    } catch (e) {
      return 'Not provided';
    }
  }

  double _calculateProfileCompletion(Map<String, dynamic> profile) {
    int totalFields = 10;
    int filledFields = 0;
    
    if (profile['full_name'] != null && profile['full_name'].toString().isNotEmpty) filledFields++;
    if (profile['phone'] != null && profile['phone'].toString().isNotEmpty) filledFields++;
    if (profile['address'] != null && profile['address'].toString().isNotEmpty) filledFields++;
    if (profile['date_of_birth'] != null) filledFields++;
    if (profile['pan_number'] != null && profile['pan_number'].toString().isNotEmpty) filledFields++;
    if (profile['aadhaar_number'] != null && profile['aadhaar_number'].toString().isNotEmpty) filledFields++;
    if (profile['occupation'] != null && profile['occupation'].toString().isNotEmpty) filledFields++;
    if (profile['annual_income'] != null && profile['annual_income'].toString().isNotEmpty) filledFields++;
    if (profile['phone_verified'] == true) filledFields++;
    if (profile['email_verified'] == true) filledFields++;
    
    return filledFields / totalFields;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('$label copied successfully'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(title: const Text('Personal Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Premium App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'Personal Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
                    onPressed: () async {
                      final result = await context.push('/profile/edit-personal-details');
                      if (result == true && mounted) {
                        // Reload data after editing
                        setState(() => _isLoading = true);
                        await _loadProfileData();
                      }
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Profile Completion Card
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildProfileCompletionCard(),
                    ),

                    const SizedBox(height: 28),

                    // Contact Information
                    _buildSectionTitle('Contact Information'),
                    _buildContactSection(),

                    const SizedBox(height: 24),

                    // Identity Documents
                    _buildSectionTitle('Identity Documents'),
                    _buildIdentitySection(),

                    const SizedBox(height: 24),

                    // Financial Information
                    _buildSectionTitle('Financial Information'),
                    _buildFinancialSection(),

                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildSectionTitle('Quick Actions'),
                    _buildQuickActionsSection(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since $_memberSince',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Profile Completion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(_profileCompletion * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _profileCompletion,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.phone_android,
            iconColor: const Color(0xFF2196F3),
            label: 'Phone Number',
            value: _phoneNumber,
            isVerified: _isPhoneVerified,
          ),
          const Divider(height: 1, indent: 76),
          _buildInfoTile(
            icon: Icons.email,
            iconColor: const Color(0xFFE53935),
            label: 'Email Address',
            value: _email,
            isVerified: _isEmailVerified,
          ),
          const Divider(height: 1, indent: 76),
          _buildInfoTile(
            icon: Icons.location_on,
            iconColor: const Color(0xFF43A047),
            label: 'Address',
            value: _address,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.cake,
            iconColor: const Color(0xFF9C27B0),
            label: 'Date of Birth',
            value: _dateOfBirth,
          ),
          const Divider(height: 1, indent: 76),
          _buildInfoTile(
            icon: Icons.credit_card,
            iconColor: const Color(0xFFFF9800),
            label: 'PAN Number',
            value: _panNumber,
            isMasked: _panNumber != 'Not provided',
            maskedValue: _panNumber != 'Not provided' && _panNumber.length >= 5 
                ? '••••••${_panNumber.substring(_panNumber.length - 5)}' 
                : _panNumber,
            onCopy: _panNumber != 'Not provided' 
                ? () => _copyToClipboard(_panNumber, 'PAN Number') 
                : null,
          ),
          const Divider(height: 1, indent: 76),
          _buildInfoTile(
            icon: Icons.fingerprint,
            iconColor: const Color(0xFF3F51B5),
            label: 'Aadhaar Number',
            value: _aadhaarNumber,
            isMasked: _aadhaarNumber != 'Not provided',
            maskedValue: _aadhaarNumber != 'Not provided' && _aadhaarNumber.length >= 4
                ? '•••• •••• ${_aadhaarNumber.substring(_aadhaarNumber.length - 4)}'
                : _aadhaarNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.work_outline,
            iconColor: const Color(0xFF00897B),
            label: 'Occupation',
            value: _occupation,
          ),
          const Divider(height: 1, indent: 76),
          _buildInfoTile(
            icon: Icons.account_balance_wallet,
            iconColor: const Color(0xFFFFA726),
            label: 'Annual Income',
            value: _annualIncome,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.people_outline,
            iconColor: const Color(0xFF00ACC1),
            title: 'Nominee Details',
            subtitle: 'Manage your nominees',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nominee management - Connect database to enable'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 76),
          _buildActionTile(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF5E35B1),
            title: 'KYC Documents',
            subtitle: 'Upload verification documents',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('KYC documents - Connect database to enable'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isVerified = false,
    bool isMasked = false,
    String? maskedValue,
    VoidCallback? onCopy,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isMasked ? (maskedValue ?? value) : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                  maxLines: maxLines,
                ),
                if (isVerified) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 13, color: Colors.green.shade700),
                        const SizedBox(width: 5),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: Icon(Icons.copy, size: 20, color: iconColor),
              onPressed: onCopy,
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
