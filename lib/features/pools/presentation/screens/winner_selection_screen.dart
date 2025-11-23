import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/winner_service.dart';

class WinnerSelectionScreen extends ConsumerStatefulWidget {
  final String poolId;

  const WinnerSelectionScreen({
    super.key,
    required this.poolId,
  });

  @override
  ConsumerState<WinnerSelectionScreen> createState() => _WinnerSelectionScreenState();
}

enum DrawState { preDraw, liveDraw, completed }

class Member {
  final String id;
  final String name;
  final bool hasWon;
  final int? wonCycle;
  final String? wonDate;
  final double? wonAmount;

  Member({
    required this.id,
    required this.name,
    this.hasWon = false,
    this.wonCycle,
    this.wonDate,
    this.wonAmount,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final name = profile != null 
        ? '${profile['first_name']} ${profile['last_name']}'
        : 'Unknown Member';
    
    return Member(
      id: json['user_id'],
      name: name,
      hasWon: json['has_won'] ?? false,
      // These fields would need to be joined from winner_history if we want full details
      // For now, we'll just use the has_won flag from pool_members
    );
  }
}

class _WinnerSelectionScreenState extends ConsumerState<WinnerSelectionScreen> {
  // Theme colors from the design
  final Color _primaryColor = const Color(0xFFF97A53);
  final Color _lightPrimaryColor = const Color(0xFFFFF2EF);
  final Color _scaffoldBgColor = const Color(0xFFF9F9F9);

  DrawState _currentState = DrawState.preDraw;
  String _currentName = "Waiting...";
  String _winnerName = "";
  double _winningAmount = 0;
  Timer? _timer;
  List<Member> _allMembers = [];
  bool _isLoading = true;

  List<Member> get _eligibleMembers => _allMembers.where((m) => !m.hasWon).toList();
  List<Member> get _pastWinners => _allMembers.where((m) => m.hasWon).toList();

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('pool_members')
          .select('*, profiles(first_name, last_name)')
          .eq('pool_id', widget.poolId);

      if (mounted) {
        setState(() {
          _allMembers = (response as List)
              .map((data) => Member.fromJson(data))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching members: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startDraw() async {
    setState(() {
      _currentState = DrawState.liveDraw;
    });

    // Start the animation loop
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_eligibleMembers.isNotEmpty) {
        setState(() {
          _currentName = _eligibleMembers[Random().nextInt(_eligibleMembers.length)].name;
        });
      }
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Get the next round number by checking winner history count + 1
      final historyResponse = await supabase
          .from('winner_history')
          .select('*')
          .eq('pool_id', widget.poolId);
      final nextRound = (historyResponse as List).length + 1;

      // Use WinnerService to select winner
      await WinnerService.selectRandomWinner(widget.poolId, nextRound);

      // Fetch the winner's details from winner_history
      final winnerData = await supabase
          .from('winner_history')
          .select('*, profiles(first_name, last_name)')
          .eq('pool_id', widget.poolId)
          .eq('round_number', nextRound)
          .single();

      final winnerProfile = winnerData['profiles'];
      final winnerName = '${winnerProfile['first_name']} ${winnerProfile['last_name']}';
      final winningAmount = (winnerData['amount_won'] as num).toDouble();
      
      // Stop animation and show result
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _winnerName = winnerName;
          _winningAmount = winningAmount;
          _currentState = DrawState.completed;
        });
      }
    } catch (e) {
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _currentState = DrawState.preDraw;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting winner: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      appBar: AppBar(
        title: const Text('Winner Selection'),
        backgroundColor: _scaffoldBgColor,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case DrawState.preDraw:
        return _buildPreDraw();
      case DrawState.liveDraw:
        return _buildLiveDraw();
      case DrawState.completed:
        return _buildCompleted();
    }
  }

  Widget _buildPreDraw() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(Icons.casino, size: 80, color: _primaryColor),
          const SizedBox(height: 32),
          Text(
            'Ready for the Draw?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _lightPrimaryColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryColor.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: _primaryColor),
                const SizedBox(width: 12),
                Text(
                  '${_eligibleMembers.length} eligible members',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Eligible for This Draw',
            _eligibleMembers,
            _primaryColor,
            isEligible: true,
          ),
          const SizedBox(height: 24),
          if (_pastWinners.isNotEmpty)
            _buildSection(
              'Past Winners (Excluded)',
              _pastWinners,
              Colors.grey,
              isEligible: false,
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _eligibleMembers.isEmpty ? null : _startDraw,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Live Draw', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Member> members, Color color, {required bool isEligible}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(isEligible ? 0.1 : 0.05),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0] : '?',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  member.name,
                  style: TextStyle(
                    color: isEligible ? Colors.black87 : Colors.grey,
                    fontWeight: isEligible ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                subtitle: member.hasWon
                    ? Text(
                        'Won previously',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : null,
                trailing: member.hasWon
                    ? const Icon(Icons.emoji_events, color: Colors.amber, size: 20)
                    : Icon(Icons.check_circle_outline, color: color, size: 20),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveDraw() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Selecting Winner...', style: TextStyle(fontSize: 24, color: Colors.grey)),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _lightPrimaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: _primaryColor, width: 4),
          ),
          child: Text(
            _currentName.isNotEmpty ? _currentName.split(' ').first[0] : '?',
            style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: _primaryColor),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _currentName,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCompleted() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ZoomIn(
            child: Icon(Icons.emoji_events, size: 100, color: _primaryColor),
          ),
          const SizedBox(height: 32),
          FadeInUp(
            child: const Text(
              'Congratulations!',
              style: TextStyle(fontSize: 24, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              _winnerName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Text(
              'You won ₹${_winningAmount.toStringAsFixed(0)}!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lightPrimaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: _primaryColor),
                  const SizedBox(height: 8),
                  Text(
                    '$_winnerName is now marked as a winner and will be excluded from future draws.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _primaryColor.withOpacity(0.9), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeInUp(
            delay: const Duration(milliseconds: 800),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Return to Pool', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            delay: const Duration(milliseconds: 1000),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share),
              label: const Text('Share Announcement'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: _primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
