import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const referralCode = 'ALEX123'; // Mock code

    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Image.network(
              'https://cdn-icons-png.flaticon.com/512/3893/3893069.png',
              height: 200,
            ),
            const SizedBox(height: 32),
            Text(
              'Invite Friends, Earn Rewards',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Share your code with friends. When they join their first pool, you both get ₹50 bonus credit!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Referral Code', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        referralCode,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement share
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Code'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Referrals (3)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _buildReferralItem(context, 'Sarah Mike', 'Joined Oct 24', '+ ₹50'),
            _buildReferralItem(context, 'John Doe', 'Joined Oct 20', '+ ₹50'),
            _buildReferralItem(context, 'Emily Blunt', 'Joined Oct 15', '+ ₹50'),

            const SizedBox(height: 32),
            const Text(
              'Top Referrers 🏆',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildLeaderboardItem(context, 1, 'Mike Ross', '15 Referrals'),
            _buildLeaderboardItem(context, 2, 'Rachel Zane', '12 Referrals'),
            _buildLeaderboardItem(context, 3, 'Harvey Specter', '10 Referrals'),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralItem(BuildContext context, String name, String date, String reward) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Text(name[0]),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(date),
      trailing: Text(
        reward,
        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildLeaderboardItem(BuildContext context, int rank, String name, String count) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: rank == 1 ? Colors.amber.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rank == 1 ? Colors.amber : Colors.grey.shade300,
          foregroundColor: rank == 1 ? Colors.white : Colors.black,
          child: Text('#$rank'),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(count, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
