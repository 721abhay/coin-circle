import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

class WinnerSelectionScreen extends StatefulWidget {
  const WinnerSelectionScreen({super.key});

  @override
  State<WinnerSelectionScreen> createState() => _WinnerSelectionScreenState();
}

enum DrawState { preDraw, liveDraw, completed }

class Member {
  final String name;
  final bool hasWon;
  final int? wonCycle;
  final String? wonDate;
  final double? wonAmount;

  Member({
    required this.name,
    this.hasWon = false,
    this.wonCycle,
    this.wonDate,
    this.wonAmount,
  });
}

class _WinnerSelectionScreenState extends State<WinnerSelectionScreen> {
  // Theme colors from the design
  final Color _primaryColor = const Color(0xFFF97A53);
  final Color _lightPrimaryColor = const Color(0xFFFFF2EF);
  final Color _scaffoldBgColor = const Color(0xFFF9F9F9);

  DrawState _currentState = DrawState.preDraw;
  int _countdown = 3;
  String _currentName = "Waiting...";
  String _winnerName = "";
  Timer? _timer;

  final List<Member> _allMembers = [
    Member(name: 'Alice Johnson', hasWon: true, wonCycle: 1, wonDate: 'Oct 15', wonAmount: 2500),
    Member(name: 'Bob Smith', hasWon: true, wonCycle: 2, wonDate: 'Nov 15', wonAmount: 2500),
    Member(name: 'Charlie Brown'),
    Member(name: 'Diana Prince'),
    Member(name: 'Evan Wright'),
    Member(name: 'Fiona Green'),
    Member(name: 'George King'),
    Member(name: 'Hannah White'),
    Member(name: 'Ian Moore'),
    Member(name: 'Julia Davis'),
  ];

  List<Member> get _eligibleMembers => _allMembers.where((m) => !m.hasWon).toList();
  List<Member> get _pastWinners => _allMembers.where((m) => m.hasWon).toList();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startDraw() {
    setState(() {
      _currentState = DrawState.liveDraw;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _currentName = _eligibleMembers[Random().nextInt(_eligibleMembers.length)].name;
      });
    });

    Future.delayed(const Duration(seconds: 3), () {
      _timer?.cancel();
      setState(() {
        _winnerName = _eligibleMembers[Random().nextInt(_eligibleMembers.length)].name;
        _currentState = DrawState.completed;
      });
    });
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
      body: _buildBody(),
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
                    member.name[0],
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
                        'Won Cycle ${member.wonCycle} • ${member.wonDate}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : null,
                trailing: member.hasWon
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${member.wonAmount?.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                        ],
                      )
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
            _currentName.split(' ').first[0],
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
              'You won \$2,500!',
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
