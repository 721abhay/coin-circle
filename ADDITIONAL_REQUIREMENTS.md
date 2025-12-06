# Additional Requirements - Implementation Plan

## Summary of New Requirements

Based on the latest feedback, here are the additional changes needed:

---

## 1. ✅ Joining Fee Cap at ₹100

### Current Issue:
- Joining fee keeps increasing with contribution amount

### Required Change:
- **Maximum joining fee: ₹100** (even for ₹20,000+ pools)

### Implementation:

**Fee Structure:**
```
< ₹1,000    = ₹50
₹1,000-2,999 = ₹60
₹3,000-4,999 = ₹70
₹5,000-9,999 = ₹80
₹10,000+     = ₹100 (CAPPED)
```

**Files to Update:**
1. `create_pool_screen.dart` - Update `_calculateJoiningFee()` function
2. Database migration created: `20251130_joining_fee_function.sql`

---

## 2. ✅ Remove "Allow Early Closure" Option

### Current State:
- Toggle exists in Additional Settings step

### Required Change:
- **Remove completely** from pool creation

**Files to Update:**
1. `create_pool_provider.dart` - Remove `allowEarlyClosure` field
2. `create_pool_screen.dart` - Remove from Additional Settings step UI

---

## 3. 🔧 Enable Chat Functionality

### Current State:
- Just a toggle, not functional

### Required Change:
- **Make chat actually work** for pool members

**Implementation Needed:**
1. Chat is already implemented in `pool_chat_screen.dart`
2. Just need to ensure toggle enables/disables access
3. When `enableChat = true`, members can access chat tab
4. When `enableChat = false`, chat tab is hidden

**Files to Update:**
1. `pool_details_screen.dart` - Conditionally show/hide Chat tab based on pool settings

---

## 4. 🔧 ID Verification Functionality

### Current State:
- Just a toggle, not functional

### Required Change:
- **Make ID verification actually work**

**Implementation Needed:**
1. When `requireIdVerification = true`:
   - Check if user has completed KYC
   - Block pool joining if KYC not complete
   - Show message: "ID verification required to join this pool"

2. KYC check already exists in `WalletService`
3. Need to add check in `joinPool()` method

**Files to Update:**
1. `pool_service.dart` - Add KYC check in `joinPool()` method
2. Show appropriate error message if KYC not complete

---

## 5. 🔧 Payment Day Logic for Different Frequencies

### Current Issue:
- Payment day selector shows for all frequencies
- Should only apply to Monthly pools

### Required Change:

**Monthly Pools:**
- Show payment day selector (1-28)
- Payment due on selected day each month

**Weekly Pools:**
- Hide payment day selector
- Payment due every 7 days from start date
- Example: If pool starts Monday, payment due every Monday

**Bi-weekly Pools:**
- Hide payment day selector  
- Payment due every 14 days from start date
- Example: If pool starts on 1st, payment due on 1st, 15th, 29th...

**Implementation:**
1. Conditionally show/hide payment day selector based on frequency
2. Update database function to calculate due date based on frequency
3. For weekly/bi-weekly, use start_date + (n * interval)
4. For monthly, use payment_day setting

**Files to Update:**
1. `create_pool_screen.dart` - Conditionally show payment day selector
2. `20251130_auto_late_fees.sql` - Update payment calculation logic

---

## Implementation Priority

### High Priority (Do First):
1. ✅ Cap joining fee at ₹100
2. ✅ Remove "Allow Early Closure"
3. 🔧 Fix payment day logic for weekly/bi-weekly

### Medium Priority:
4. 🔧 Enable chat functionality
5. 🔧 Enable ID verification

---

## Detailed Implementation Steps

### Step 1: Update Joining Fee Calculation

```dart
// In create_pool_screen.dart
static double _calculateJoiningFee(double contributionAmount) {
  if (contributionAmount < 1000) {
    return 50.0;
  } else if (contributionAmount < 3000) {
    return 60.0;
  } else if (contributionAmount < 5000) {
    return 70.0;
  } else if (contributionAmount < 10000) {
    return 80.0;
  } else {
    return 100.0; // CAPPED AT ₹100
  }
}
```

### Step 2: Remove Allow Early Closure

**In `create_pool_provider.dart`:**
- Remove `allowEarlyClosure` field from `CreatePoolState`
- Remove from `copyWith()` method
- Remove `updateEarlyClosure()` method

**In `create_pool_screen.dart`:**
- Remove the SwitchListTile for "Allow Early Closure"

### Step 3: Payment Day Logic

**In `create_pool_screen.dart` - Pool Rules Step:**
```dart
// Only show payment day for Monthly pools
if (state.frequency == 'Monthly') {
  DropdownButtonFormField<int>(
    value: state.paymentDay,
    decoration: const InputDecoration(
      labelText: 'Payment Day',
      helperText: 'Day of month for monthly payments',
    ),
    items: List.generate(28, (i) => i + 1)
        .map((day) => DropdownMenuItem(
              value: day,
              child: Text('Day $day'),
            ))
        .toList(),
    onChanged: (value) {
      if (value != null) {
        ref.read(createPoolProvider.notifier).updatePaymentDay(value);
      }
    },
  );
} else {
  // For Weekly/Bi-weekly, show info text
  Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      state.frequency == 'Weekly' 
        ? 'Payments due every 7 days from pool start date'
        : 'Payments due every 14 days from pool start date',
      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
    ),
  );
}
```

**In database migration:**
```sql
-- Update get_payment_status_with_late_fee to handle different frequencies
CREATE OR REPLACE FUNCTION get_payment_status_with_late_fee(
  p_pool_id UUID,
  p_user_id UUID,
  p_payment_day INTEGER DEFAULT 1,
  p_frequency TEXT DEFAULT 'monthly'
)
RETURNS TABLE (...) AS $$
DECLARE
  v_payment_due_date DATE;
  v_interval_days INTEGER;
BEGIN
  -- Calculate due date based on frequency
  IF p_frequency = 'weekly' THEN
    v_interval_days := 7;
    v_payment_due_date := v_pool.start_date + (v_interval_days * current_period);
  ELSIF p_frequency = 'bi-weekly' THEN
    v_interval_days := 14;
    v_payment_due_date := v_pool.start_date + (v_interval_days * current_period);
  ELSE -- monthly
    v_payment_due_date := DATE_TRUNC('month', CURRENT_DATE) + (p_payment_day - 1);
  END IF;
  
  -- Rest of logic...
END;
$$ LANGUAGE plpgsql;
```

### Step 4: Enable Chat Functionality

**In `pool_details_screen.dart`:**
```dart
// In TabBar - conditionally show Chat tab
bottom: TabBar(
  controller: _tabController,
  tabs: [
    Tab(text: 'Overview'),
    Tab(text: 'Members'),
    Tab(text: 'Schedule'),
    Tab(text: 'Winners'),
    if (_pool?['enable_chat'] == true) Tab(text: 'Chat'), // Conditional
    Tab(text: 'Docs'),
    Tab(text: 'Stats'),
  ],
),

// In TabBarView - conditionally show Chat screen
body: TabBarView(
  controller: _tabController,
  children: [
    _OverviewTab(...),
    _MembersTab(...),
    _ScheduleTab(...),
    _WinnersTab(...),
    if (_pool?['enable_chat'] == true) _ChatTab(...), // Conditional
    _DocsTab(...),
    _StatsTab(...),
  ],
),
```

### Step 5: Enable ID Verification

**In `pool_service.dart` - `joinPool()` method:**
```dart
static Future<void> joinPool(String poolId, String inviteCode) async {
  final user = _client.auth.currentUser;
  if (user == null) throw const AuthException('User not logged in');

  // Get pool details to check if ID verification is required
  final pool = await getPoolDetails(poolId);
  
  if (pool['require_id_verification'] == true) {
    // Check if user has completed KYC
    final profile = await _client
        .from('profiles')
        .select('kyc_verified')
        .eq('id', user.id)
        .single();
    
    if (profile['kyc_verified'] != true) {
      throw Exception('ID verification required to join this pool. Please complete KYC first.');
    }
  }

  // Rest of join logic...
}
```

---

## Testing Checklist

### Joining Fee:
- [ ] Pool with ₹500 contribution = ₹50 joining fee
- [ ] Pool with ₹2000 contribution = ₹60 joining fee
- [ ] Pool with ₹5000 contribution = ₹80 joining fee
- [ ] Pool with ₹20,000 contribution = ₹100 joining fee (CAPPED)
- [ ] Pool with ₹100,000 contribution = ₹100 joining fee (CAPPED)

### Allow Early Closure:
- [ ] Option not visible in pool creation
- [ ] Field removed from database

### Chat:
- [ ] When enabled, chat tab appears
- [ ] When disabled, chat tab hidden
- [ ] Chat messages work when enabled

### ID Verification:
- [ ] User without KYC cannot join pools requiring verification
- [ ] Error message shows: "ID verification required"
- [ ] User with KYC can join successfully

### Payment Day:
- [ ] Monthly pools show payment day selector
- [ ] Weekly pools show "every 7 days" message
- [ ] Bi-weekly pools show "every 14 days" message
- [ ] Payment calculations work correctly for each frequency

---

## Files That Need Changes

1. ✅ `create_pool_provider.dart` - Remove allowEarlyClosure
2. ✅ `create_pool_screen.dart` - Update joining fee calc, remove early closure, conditional payment day
3. 🔧 `pool_details_screen.dart` - Conditional chat tab
4. 🔧 `pool_service.dart` - Add KYC check in joinPool
5. 🔧 `20251130_auto_late_fees.sql` - Update payment calculation for frequencies

---

## Summary

**Completed:**
- ✅ Joining fee function with ₹100 cap created
- ✅ Files restored from corruption

**Next Steps:**
1. Update joining fee calculation in create_pool_screen.dart
2. Remove allowEarlyClosure from provider and UI
3. Add conditional payment day display
4. Enable chat functionality
5. Add ID verification check
6. Update database functions for frequency-based payments

All changes maintain backward compatibility and follow the platform's revenue model!
