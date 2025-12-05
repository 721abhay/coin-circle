# 🚀 Immediate Action Plan - Win Pool App

**Date**: December 4, 2025  
**Priority**: HIGH  
**Timeline**: 1-2 Weeks

---

## 📋 QUICK FIXES (Can Complete Today)

### 1. **Enable Chat Conditional Display** ⚡
**Time**: 15 minutes  
**File**: `lib/features/pools/presentation/screens/pool_details_screen.dart`

**Changes Needed**:
```dart
// In TabBar - make Chat tab conditional
bottom: TabBar(
  controller: _tabController,
  tabs: [
    Tab(text: 'Overview'),
    Tab(text: 'Members'),
    Tab(text: 'Schedule'),
    Tab(text: 'Winners'),
    if (_pool?['enable_chat'] == true) Tab(text: 'Chat'), // ← ADD THIS
    Tab(text: 'Docs'),
    Tab(text: 'Stats'),
  ],
),

// In TabBarView - make Chat screen conditional
body: TabBarView(
  controller: _tabController,
  children: [
    _OverviewTab(...),
    _MembersTab(...),
    _ScheduleTab(...),
    _WinnersTab(...),
    if (_pool?['enable_chat'] == true) _ChatTab(...), // ← ADD THIS
    _DocsTab(...),
    _StatsTab(...),
  ],
),
```

---

### 2. **Add ID Verification Check** ⚡
**Time**: 20 minutes  
**File**: `lib/core/services/pool_service.dart`

**Changes Needed**:
```dart
// In joinPool() method, add this check after getting pool details:
static Future<void> joinPool(String poolId, String inviteCode) async {
  final user = _client.auth.currentUser;
  if (user == null) throw const AuthException('User not logged in');

  // Get pool details
  final pool = await getPoolDetails(poolId);
  
  // ← ADD THIS BLOCK
  if (pool['require_id_verification'] == true) {
    final profile = await _client
        .from('profiles')
        .select('kyc_verified')
        .eq('id', user.id)
        .single();
    
    if (profile['kyc_verified'] != true) {
      throw Exception('ID verification required to join this pool. Please complete KYC first.');
    }
  }
  // ← END OF NEW BLOCK

  // Rest of join logic...
}
```

---

### 3. **Fix Payment Day Logic** ⚡
**Time**: 30 minutes  
**File**: `lib/features/pools/presentation/screens/create_pool_screen.dart`

**Changes Needed**:
```dart
// In Pool Rules step, replace payment day selector with:
if (state.frequency == 'Monthly') {
  // Show payment day selector (existing code)
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
  ),
} else {
  // Show info text for Weekly/Bi-weekly
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            state.frequency == 'Weekly' 
              ? 'Payments due every 7 days from pool start date'
              : 'Payments due every 14 days from pool start date',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
          ),
        ),
      ],
    ),
  ),
}
```

---

## 🔧 BACKEND CONNECTIONS (This Week)

### 4. **Connect Feedback to Backend** 📝
**Time**: 1 hour  
**Files**: 
- Create: `supabase/migrations/create_feedback_table.sql`
- Update: `lib/features/profile/presentation/screens/feedback_screen.dart`

**Step 1: Create Database Table**
```sql
-- supabase/migrations/create_feedback_table.sql
CREATE TABLE IF NOT EXISTS feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  category TEXT NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved'))
);

-- Enable RLS
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Users can only see their own feedback
CREATE POLICY "Users can view own feedback"
  ON feedback FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own feedback
CREATE POLICY "Users can insert own feedback"
  ON feedback FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create index
CREATE INDEX idx_feedback_user ON feedback(user_id);
CREATE INDEX idx_feedback_status ON feedback(status);
```

**Step 2: Update Feedback Screen**
```dart
// In _FeedbackScreenState, update submit button:
ElevatedButton(
  onPressed: () async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      await Supabase.instance.client.from('feedback').insert({
        'user_id': user.id,
        'rating': _rating,
        'category': _selectedCategory,
        'message': _feedbackController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    }
  },
  child: const Text('Submit Feedback'),
),
```

---

### 5. **Save Currency Settings** 💱
**Time**: 45 minutes  
**File**: `lib/features/profile/presentation/screens/currency_settings_screen.dart`

**Step 1: Add to profiles table** (if not exists)
```sql
-- Add currency settings column to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS currency_settings JSONB DEFAULT '{
  "primary_currency": "INR",
  "auto_convert": true,
  "show_multiple": false
}'::jsonb;
```

**Step 2: Update Currency Settings Screen**
```dart
// Add at top of _CurrencySettingsScreenState:
bool _isSaving = false;

// Add save method:
Future<void> _saveSettings() async {
  setState(() => _isSaving = true);
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await Supabase.instance.client.from('profiles').update({
      'currency_settings': {
        'primary_currency': _primaryCurrency,
        'auto_convert': _autoConvert,
        'show_multiple': _showMultipleCurrencies,
      }
    }).eq('id', user.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!'), backgroundColor: Colors.green),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

// Add floating action button in Scaffold:
floatingActionButton: FloatingActionButton.extended(
  onPressed: _isSaving ? null : _saveSettings,
  icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
  label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
),
```

---

## 🔌 CRITICAL INTEGRATIONS (Next Week)

### 6. **Payment Gateway Integration** 💳
**Time**: 4-6 hours  
**Priority**: CRITICAL

**Steps**:
1. Choose payment gateway (Razorpay recommended for India)
2. Sign up and get API keys
3. Add Razorpay package: `razorpay_flutter: ^1.3.6`
4. Update `payment_service.dart` with real integration
5. Test with small amounts (₹1, ₹10)
6. Configure webhooks for payment status

**Resources**:
- Razorpay Docs: https://razorpay.com/docs/
- Flutter Plugin: https://pub.dev/packages/razorpay_flutter

---

### 7. **Push Notifications Setup** 🔔
**Time**: 3-4 hours  
**Priority**: HIGH

**Steps**:
1. Create Firebase project
2. Add Android app to Firebase
3. Download `google-services.json` → `android/app/`
4. Add iOS app to Firebase (if needed)
5. Download `GoogleService-Info.plist` → `ios/Runner/`
6. Update `android/build.gradle` and `android/app/build.gradle`
7. Test notifications

**Resources**:
- Firebase Console: https://console.firebase.google.com/
- Flutter Firebase Messaging: https://firebase.flutter.dev/docs/messaging/overview

---

### 8. **OTP Verification** 📱
**Time**: 3-4 hours  
**Priority**: HIGH

**Steps**:
1. Choose SMS provider (MSG91/Twilio)
2. Sign up and get API credentials
3. Create OTP service in backend
4. Update `personal_details_service.dart`
5. Add OTP input screen
6. Test OTP flow

**Resources**:
- MSG91: https://msg91.com/
- Twilio: https://www.twilio.com/

---

### 9. **Document Upload to Supabase Storage** 📄
**Time**: 2-3 hours  
**Priority**: MEDIUM

**Steps**:
1. Enable Supabase Storage in dashboard
2. Create storage bucket for documents
3. Set up storage policies
4. Update `report_problem_screen.dart`
5. Test file upload and retrieval

**Code Example**:
```dart
// Upload file to Supabase Storage
Future<String> uploadDocument(File file, String fileName) async {
  final bytes = await file.readAsBytes();
  final fileExt = fileName.split('.').last;
  final filePath = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
  
  await Supabase.instance.client.storage
      .from('documents')
      .uploadBinary(filePath, bytes);
  
  final url = Supabase.instance.client.storage
      .from('documents')
      .getPublicUrl(filePath);
  
  return url;
}
```

---

## 📊 TESTING CHECKLIST

After completing above tasks, test:

- [ ] Chat tab appears/disappears based on pool settings
- [ ] ID verification blocks non-KYC users from joining pools
- [ ] Payment day selector only shows for Monthly pools
- [ ] Feedback saves to database successfully
- [ ] Currency settings persist after app restart
- [ ] Payment gateway processes real transactions
- [ ] Push notifications received on device
- [ ] OTP verification works for phone numbers
- [ ] Documents upload to Supabase Storage

---

## 🎯 SUCCESS METRICS

**By End of Week 1**:
- ✅ All quick fixes completed
- ✅ Feedback and currency settings connected to backend
- ✅ All features tested and working

**By End of Week 2**:
- ✅ Payment gateway integrated and tested
- ✅ Push notifications configured
- ✅ OTP verification working
- ✅ Document upload functional

---

## 📝 NOTES

- Keep the app name "Win Pool" consistent across all new code
- Test each feature thoroughly before moving to next
- Document any issues encountered
- Update FEATURE_AUDIT_REPORT.md as features are completed

---

**Created**: December 4, 2025  
**Last Updated**: December 4, 2025  
**Next Review**: After completing Week 1 tasks
