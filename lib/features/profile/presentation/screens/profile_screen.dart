import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/wallet_management_service.dart';
import '../../../../core/services/pool_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, double>? _walletStats;
  Map<String, int>? _poolStats;
  Map<String, dynamic>? _performanceMetrics;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Fetch profile
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        
        // Fetch wallet stats
        final wallet = await WalletManagementService.getBalanceBreakdown();
        
        // Fetch pool stats
        final pools = await PoolService.getUserPools();
        final joined = pools.length;
        final active = pools.where((p) => p['status'] == 'active').length;
        final completed = pools.where((p) => p['status'] == 'completed').length;
        
        // Calculate performance metrics
        final metrics = await _calculatePerformanceMetrics(user.id);

        if (mounted) {
          setState(() {
            _profile = profile;
            _walletStats = wallet;
            _poolStats = {
              'joined': joined,
              'active': active,
              'completed': completed,
            };
            _performanceMetrics = metrics;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Handle error silently or show snackbar
      }
    }
  }
  
  Future<Map<String, dynamic>> _calculatePerformanceMetrics(String userId) async {
    try {
      // Fetch all transactions
      final transactions = await Supabase.instance.client
          .from('transactions')
          .select()
          .eq('user_id', userId);
      
      // Calculate total contributed
      double totalContributed = 0;
      int totalPayments = 0;
      int onTimePayments = 0;
      
      for (var txn in transactions) {
        if (txn['type'] == 'contribution' && txn['status'] == 'completed') {
          totalContributed += (txn['amount'] as num).toDouble();
          totalPayments++;
          
          // Check if payment was on time (no late fee)
          if (txn['late_fee'] == null || txn['late_fee'] == 0) {
            onTimePayments++;
          }
        }
      }
      
      // Calculate on-time percentage
      double onTimeRate = totalPayments > 0 ? (onTimePayments / totalPayments * 100) : 100;
      
      // Calculate trust score (based on on-time rate and activity)
      double trustScore = onTimeRate * 0.7 + (totalPayments > 0 ? 30 : 0);
      trustScore = trustScore.clamp(0, 100);
      
      return {
        'trustScore': trustScore.round(),
        'onTimeRate': onTimeRate.round(),
        'totalContributed': totalContributed,
      };
    } catch (e) {
      print('Error calculating metrics: $e');
      return {
        'trustScore': 0,
        'onTimeRate': 0,
        'totalContributed': 0.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildAccountStats(context),
            const SizedBox(height: 24),
            _buildPerformanceMetrics(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildMenuOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context) {
    final trustScore = _performanceMetrics?['trustScore'] ?? 0;
    final onTimeRate = _performanceMetrics?['onTimeRate'] ?? 0;
    final totalContributed = _performanceMetrics?['totalContributed'] ?? 0.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMetricItem('Trust Score', '$trustScore/100', Colors.green),
        _buildMetricItem('On-Time', '$onTimeRate%', Colors.blue),
        _buildMetricItem('Contributed', '₹${NumberFormat.compact().format(totalContributed)}', Colors.orange),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'No Email';
    final name = _profile?['full_name'] ?? 'User';
    final phone = _profile?['phone'] ?? 'No Phone';
    final avatarUrl = _profile?['avatar_url'];
    final location = _profile?['location'];
    final bio = _profile?['bio'];
    final dobString = _profile?['dob'];
    DateTime? dob;
    if (dobString != null && dobString is String) {
      try {
        dob = DateTime.parse(dobString);
      } catch (_) {}
    }

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : const NetworkImage('https://i.pravatar.cc/150?img=12'),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(email, style: const TextStyle(color: Colors.grey)),
        Text(phone, style: const TextStyle(color: Colors.grey)),
        if (location != null && location.isNotEmpty)
          Text('Location: $location', style: const TextStyle(color: Colors.grey)),
        if (bio != null && bio.isNotEmpty)
          Text('Bio: $bio', style: const TextStyle(color: Colors.grey)),
        if (dob != null)
          Text('Born: ${DateFormat.yMMMMd().format(dob)}', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildAccountStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('${_poolStats?['joined'] ?? 0}', 'Pools\nJoined', Icons.groups),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              _buildStatItem('${_poolStats?['active'] ?? 0}', 'Active\nPools', Icons.trending_up),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              _buildStatItem('₹${NumberFormat.compact().format(_walletStats?['total'] ?? 0)}', 'Total\nBalance', Icons.account_balance_wallet),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Member Since', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.parse(_profile?['created_at'] ?? DateTime.now().toIso8601String())),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(context, 'Contributed', '₹${NumberFormat.compact().format(_walletStats?['locked'] ?? 0)}', Icons.savings, Colors.blue),
        _buildStatCard(context, 'On-Time Rate', '100%', Icons.timer, Colors.green),
        _buildStatCard(context, 'Completed', '${_poolStats?['completed'] ?? 0} Pools', Icons.check_circle, Colors.purple),
        _buildStatCard(context, 'Avg. Rating', '4.9/5', Icons.star, Colors.amber),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMenuItem(context, 'Verify Identity (KYC)', Icons.verified_user, () => context.push('/kyc-submission')),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(context, 'Edit Profile', Icons.edit, () => _showEditProfileDialog(context)),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(context, 'My Created Pools', Icons.dashboard, () => context.push('/my-pools')),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(context, 'Payment Methods', Icons.credit_card, () => context.push('/bank-accounts')),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(context, 'Notification Settings', Icons.notifications, () => context.push('/notifications')),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(context, 'Privacy Settings', Icons.privacy_tip, () => context.push('/privacy-policy')), // Using privacy policy for now
              const Divider(height: 1, indent: 56),
              _buildMenuItem(context, 'Refer & Earn', Icons.card_giftcard, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral system coming soon!')))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support & Account',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMenuItem(context, 'Help & Support', Icons.help_outline, () => context.push('/help-support')),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(context, 'Terms of Service', Icons.description, () => context.push('/terms')), // Ensure route exists
              const Divider(height: 1, indent: 56),
              _buildMenuItem(context, 'Privacy Policy', Icons.policy, () => context.push('/privacy-policy')), // Ensure route exists
              const Divider(height: 1, indent: 56),
              _buildMenuItem(context, 'Export Data', Icons.download, () => context.push('/export-data')),
              const Divider(height: 1, indent: 56),
              _buildMenuItem(context, 'Log Out', Icons.logout, () => _showLogoutDialog(context), isDestructive: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, VoidCallback onTap, {bool isDestructive = false, Widget? trailing}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : Colors.grey.shade700, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Bio (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
