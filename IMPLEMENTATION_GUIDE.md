# 🚀 Backend Integration Implementation Guide

## Quick Start - Critical Fixes

### Step 1: Run Notifications Migration
```bash
cd "c:\Users\ABHAY\coin circle\coin_circle"
supabase db push
```

This will create:
- ✅ `notifications` table
- ✅ Real-time subscriptions
- ✅ Automatic triggers for pool events
- ✅ RLS policies

### Step 2: Update Home Screen (Remove Demo Data)

**File:** `lib/features/dashboard/presentation/screens/home_screen.dart`

Replace the notification count:
```dart
// OLD (Line ~152)
const Text('3', ...) // HARDCODED

// NEW
FutureBuilder<int>(
  future: NotificationService.getUnreadCount(),
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  },
)
```

### Step 3: Fix Pool Visibility

**File:** `lib/core/services/pool_service.dart`

Update `createPool()` to ensure pool_members entry:
```dart
static Future<String?> createPool({
  required String name,
  required double contributionAmount,
  required int maxMembers,
  required int totalRounds,
  required String frequency,
  required DateTime startDate,
  String? description,
}) async {
  try {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Create pool
    final poolResponse = await _client.rpc('create_pool', params: {
      'p_name': name,
      'p_description': description ?? '',
      'p_contribution_amount': contributionAmount,
      'p_max_members': maxMembers,
      'p_total_rounds': totalRounds,
      'p_frequency': frequency,
      'p_start_date': startDate.toIso8601String(),
    });

    final poolId = poolResponse as String;

    // CRITICAL: Ensure creator is added to pool_members
    await _client.from('pool_members').insert({
      'pool_id': poolId,
      'user_id': userId,
      'role': 'creator',
      'joined_at': DateTime.now().toIso8601String(),
    });

    print('✅ Pool created: $poolId');
    print('✅ Creator added to pool_members');

    return poolId;
  } catch (e) {
    print('❌ Error creating pool: $e');
    return null;
  }
}
```

### Step 4: Fix My Pools Screen (Real Data)

**File:** `lib/features/pools/presentation/screens/my_pools_screen.dart`

Update to use real data:
```dart
// Calculate real progress
double _calculateProgress(Map<String, dynamic> pool) {
  final contributionAmount = (pool['contribution_amount'] as num).toDouble();
  final currentRound = pool['current_round'] as int? ?? 1;
  final totalRounds = pool['total_rounds'] as int;
  
  return currentRound / totalRounds;
}

// Get real payment status
Future<String> _getPaymentStatus(String poolId, String userId) async {
  final transactions = await _client
      .from('transactions')
      .select()
      .eq('pool_id', poolId)
      .eq('user_id', userId)
      .eq('transaction_type', 'contribution')
      .order('created_at', ascending: false)
      .limit(1);
  
  if (transactions.isEmpty) return 'Pending';
  return 'Paid';
}

// Then use in build:
_ActivePoolCard(
  name: pool['name'],
  status: await _getPaymentStatus(pool['id'], userId), // REAL DATA
  nextDraw: DateFormat('MMM d').format(DateTime.parse(pool['next_draw_date'])), // FROM DB
  amount: '₹${pool['contribution_amount']}',
  members: pool['current_members'],
  progress: _calculateProgress(pool), // CALCULATED
  onTap: () => context.push('/pool-details/${pool['id']}'),
  onContribute: () => context.push('/payment', extra: {...}),
)
```

### Step 5: Connect Notifications Screen

**File:** `lib/features/profile/presentation/screens/notifications_screen.dart`

Replace with real data:
```dart
import '../../../../core/services/notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await NotificationService.markAllAsRead();
              setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService.subscribeToNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationTile(notif);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notif) {
    final isRead = notif['read'] as bool;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isRead ? Colors.grey : Colors.blue,
        child: Icon(_getIconForType(notif['type']), color: Colors.white),
      ),
      title: Text(
        notif['title'],
        style: TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(notif['message']),
      trailing: Text(_formatTime(notif['created_at'])),
      onTap: () async {
        if (!isRead) {
          await NotificationService.markAsRead(notif['id']);
        }
        // Navigate based on notification type
        _handleNotificationTap(notif);
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'payment_reminder':
        return Icons.payment;
      case 'draw_announcement':
        return Icons.celebration;
      case 'winner_announcement':
        return Icons.emoji_events;
      case 'pool_update':
        return Icons.update;
      case 'member_activity':
        return Icons.people;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _handleNotificationTap(Map<String, dynamic> notif) {
    final data = notif['data'] as Map<String, dynamic>?;
    if (data != null && data['pool_id'] != null) {
      context.push('/pool-details/${data['pool_id']}');
    }
  }
}
```

### Step 6: Fix Admin Dashboard Stats

**Create RPC Function:**
```sql
-- File: supabase/migrations/029_admin_stats.sql

CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS JSONB AS $$
DECLARE
  v_stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_users', (SELECT COUNT(*) FROM profiles),
    'active_users', (SELECT COUNT(DISTINCT user_id) FROM pool_members WHERE joined_at >= NOW() - INTERVAL '30 days'),
    'suspended_users', (SELECT COUNT(*) FROM profiles WHERE suspended = TRUE),
    'total_pools', (SELECT COUNT(*) FROM pools),
    'active_pools', (SELECT COUNT(*) FROM pools WHERE status = 'active'),
    'pending_pools', (SELECT COUNT(*) FROM pools WHERE status = 'pending'),
    'completed_pools', (SELECT COUNT(*) FROM pools WHERE status = 'completed'),
    'total_transactions', (SELECT COUNT(*) FROM transactions),
    'total_volume', (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE transaction_type = 'contribution'),
    'total_payouts', (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE transaction_type = 'payout'),
    'pending_kyc', (SELECT COUNT(*) FROM profiles WHERE kyc_verified = FALSE)
  ) INTO v_stats;
  
  RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_admin_stats TO authenticated;
```

**Update AdminService:**
```dart
// In lib/core/services/admin_service.dart

static Future<Map<String, dynamic>> getAdminStats() async {
  try {
    final response = await _client.rpc('get_admin_stats');
    return Map<String, dynamic>.from(response);
  } catch (e) {
    print('Error fetching admin stats: $e');
    return {};
  }
}
```

**Update Admin Dashboard:**
```dart
// In admin_dashboard_screen.dart

FutureBuilder<Map<String, dynamic>>(
  future: AdminService.getAdminStats(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }
    
    final stats = snapshot.data!;
    
    return Row(
      children: [
        _buildStatCard('Total Users', '${stats['total_users']}', '+12%', Icons.people, Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Active Pools', '${stats['active_pools']}', '+5%', Icons.pool, Colors.purple),
        // ... more cards
      ],
    );
  },
)
```

---

## Testing Checklist

### 1. Notifications
- [ ] Run migration: `supabase db push`
- [ ] Create a pool → Check if notification appears
- [ ] Join a pool → Check if all members get notified
- [ ] Make contribution → Check if notification sent
- [ ] Complete draw → Check winner notification
- [ ] Mark as read → Verify it works
- [ ] Real-time updates → Check stream works

### 2. Pool Visibility
- [ ] Create new pool
- [ ] Check if it appears in My Pools immediately
- [ ] Verify creator is in pool_members table
- [ ] Check pool details load correctly

### 3. Wallet
- [ ] Make contribution → Check balance decreases
- [ ] Win draw → Check balance increases
- [ ] View transaction history → Verify real data

### 4. Admin Dashboard
- [ ] View stats → Check real numbers
- [ ] Suspend user → Verify it works
- [ ] Force close pool → Check functionality
- [ ] View user list → Verify pagination

---

## Common Issues & Solutions

### Issue 1: Notifications not appearing
**Solution:**
1. Check if migration ran: `supabase db push`
2. Verify RLS policies allow user access
3. Check Realtime is enabled: `ALTER PUBLICATION supabase_realtime ADD TABLE notifications;`

### Issue 2: Pool not showing in My Pools
**Solution:**
1. Check pool_members table has entry
2. Verify getUserPools() query includes creator
3. Add logging to createPool() function

### Issue 3: Wallet balance not updating
**Solution:**
1. Check transaction is being inserted
2. Verify wallet update trigger exists
3. Test with manual transaction insert

---

## Deployment Steps

1. **Database Migrations**
   ```bash
   supabase db push
   ```

2. **Verify Tables**
   ```sql
   SELECT * FROM notifications LIMIT 1;
   SELECT * FROM pool_members WHERE role = 'creator';
   ```

3. **Test Notifications**
   ```sql
   SELECT create_notification(
     'user-id-here',
     'system_message',
     'Test',
     'This is a test notification'
   );
   ```

4. **Monitor Logs**
   ```bash
   supabase functions logs
   ```

---

## Next Steps

1. ✅ Run notifications migration
2. ✅ Update home screen notification count
3. ✅ Fix pool creation to add creator to pool_members
4. ✅ Update My Pools to show real data
5. ✅ Connect notifications screen to real data
6. ✅ Update admin dashboard with real stats
7. ✅ Test all flows end-to-end
8. ✅ Deploy to production

---

**Status:** Ready for Implementation  
**Estimated Time:** 2-3 hours  
**Priority:** HIGH
