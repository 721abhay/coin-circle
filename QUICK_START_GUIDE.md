# 🚀 QUICK START GUIDE - Launch Preparation

## ⏱️ TIME REQUIRED: 2-3 Hours (Today)

---

## 📋 STEP 1: DATABASE SETUP (30 minutes) - **DO THIS NOW**

### 1.1 Open Supabase Dashboard
1. Go to https://supabase.com
2. Sign in to your account
3. Select your Coin Circle project
4. Click on **SQL Editor** in the left sidebar

### 1.2 Run SQL Scripts (IN ORDER)

#### Script 1: Tables & Indexes
1. Open file: `supabase/01_setup_tables.sql`
2. Copy ALL content
3. Paste into Supabase SQL Editor
4. Click **RUN** button
5. ✅ Wait for "Success" message

#### Script 2: Functions & Triggers
1. Open file: `supabase/02_setup_functions.sql`
2. Copy ALL content
3. Paste into Supabase SQL Editor
4. Click **RUN** button
5. ✅ Wait for "Success" message

### 1.3 Verify Setup
Run this query to check:
```sql
SELECT 
  'Tables' as type, 
  COUNT(*) as count 
FROM information_schema.tables 
WHERE table_schema = 'public'
UNION ALL
SELECT 
  'Functions' as type, 
  COUNT(*) as count 
FROM information_schema.routines 
WHERE routine_schema = 'public';
```

Expected result:
- Tables: ~20-25
- Functions: ~10-15

✅ **CHECKPOINT**: Database is ready!

---

## 📋 STEP 2: CONFIGURE STORAGE (10 minutes)

### 2.1 Create KYC Documents Bucket
1. In Supabase Dashboard, click **Storage**
2. Click **New bucket**
3. Name: `kyc_documents`
4. Set to **Private** (important for security)
5. Click **Create bucket**

### 2.2 Set Storage Policies
1. Click on `kyc_documents` bucket
2. Go to **Policies** tab
3. Click **New Policy**
4. Add this policy:

```sql
-- Allow users to upload their own KYC documents
CREATE POLICY "Users can upload own KYC"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'kyc_documents' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view their own KYC documents
CREATE POLICY "Users can view own KYC"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'kyc_documents' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow admins to view all KYC documents
CREATE POLICY "Admins can view all KYC"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'kyc_documents'
  AND EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND is_admin = true
  )
);
```

✅ **CHECKPOINT**: Storage configured!

---

## 📋 STEP 3: TEST BASIC FUNCTIONALITY (30 minutes)

### 3.1 Test User Registration
1. Run the app: `flutter run`
2. Click **Register**
3. Fill in details:
   - Name: Test User
   - Email: test@example.com
   - Password: Test@123
4. Complete registration
5. ✅ Check: User created, wallet auto-created

### 3.2 Verify in Supabase
```sql
-- Check user was created
SELECT * FROM auth.users ORDER BY created_at DESC LIMIT 1;

-- Check wallet was auto-created
SELECT * FROM wallets ORDER BY created_at DESC LIMIT 1;

-- Check profile was created
SELECT * FROM profiles ORDER BY created_at DESC LIMIT 1;
```

### 3.3 Test Wallet Operations
1. In app, go to **Wallet**
2. Click **Add Money**
3. Enter amount: ₹1000
4. Click **Proceed to Pay**
5. ✅ Check: Balance updated (simulated payment)

### 3.4 Test Pool Creation
1. Go to **Pools** tab
2. Click **Create Pool**
3. Fill in details:
   - Name: Test Pool
   - Contribution: ₹500
   - Members: 5
4. Click **Create**
5. ✅ Check: Pool created successfully

✅ **CHECKPOINT**: Basic features working!

---

## 📋 STEP 4: MAKE PIN REQUIRED (30 minutes)

### 4.1 Update Wallet Service
Open: `lib/core/services/wallet_service.dart`

Find the `withdraw` method (around line 148) and change:
```dart
// FROM:
String? pin,

// TO:
required String pin,
```

Find the `contributeToPool` method (around line 253) and change:
```dart
// FROM:
String? pin,

// TO:
required String pin,
```

### 4.2 Update PIN Verification
In both methods, change:
```dart
// FROM:
if (pin != null) {
  final pinValid = await SecurityService.verifyTransactionPin(pin);
  // ...
}

// TO:
final pinValid = await SecurityService.verifyTransactionPin(pin);
if (!pinValid) {
  await SecurityService.incrementFailedPinAttempts();
  throw Exception('Invalid transaction PIN');
}
await SecurityService.resetFailedPinAttempts();
```

### 4.3 Add PIN Input to Withdrawal Screen
Open: `lib/features/wallet/presentation/screens/wallet_screen.dart`

Find the withdrawal dialog (around line 540) and add PIN input:
```dart
// Add this before bank details input
TextField(
  controller: pinController,
  keyboardType: TextInputType.number,
  maxLength: 4,
  obscureText: true,
  decoration: const InputDecoration(
    labelText: 'Transaction PIN',
    hintText: '****',
    prefixIcon: Icon(Icons.lock),
  ),
),
const SizedBox(height: 16),
```

Then pass PIN to withdraw:
```dart
await WalletService.withdraw(
  amount: amount,
  method: selectedMethod,
  bankDetails: bankDetailsController.text.trim(),
  pin: pinController.text.trim(), // Add this
);
```

✅ **CHECKPOINT**: PIN now required!

---

## 📋 STEP 5: ADD ERROR TRACKING (20 minutes)

### 5.1 Add Sentry Package
In `pubspec.yaml`, add:
```yaml
dependencies:
  sentry_flutter: ^7.14.0
```

Run: `flutter pub get`

### 5.2 Initialize Sentry
In `lib/main.dart`, update:
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN'; // Get from sentry.io
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

### 5.3 Get Sentry DSN
1. Go to https://sentry.io
2. Sign up (free tier)
3. Create new project: "Coin Circle"
4. Copy DSN
5. Paste in code above

✅ **CHECKPOINT**: Error tracking active!

---

## 📋 STEP 6: PAYMENT GATEWAY SETUP (1-2 weeks)

### 6.1 Choose Gateway
**Recommended**: Razorpay (India-focused)
- Easy integration
- 2% transaction fee
- Good documentation
- Supports UPI, cards, net banking

**Alternative**: Stripe
- Global platform
- 2.9% + ₹2 per transaction
- More features

### 6.2 Razorpay Setup Steps
1. Go to https://razorpay.com
2. Sign up for merchant account
3. Complete KYC (business documents needed)
4. Get API keys (Test + Live)
5. Install package:
```yaml
dependencies:
  razorpay_flutter: ^1.3.6
```

### 6.3 Replace PaymentService
Open: `lib/core/services/payment_service.dart`

Replace simulation with real Razorpay:
```dart
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  static final _razorpay = Razorpay();
  
  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String method,
    required String currency,
  }) async {
    final options = {
      'key': 'YOUR_RAZORPAY_KEY',
      'amount': (amount * 100).toInt(), // Amount in paise
      'currency': currency,
      'name': 'Coin Circle',
      'description': 'Add money to wallet',
    };
    
    _razorpay.open(options);
    
    // Handle success/failure via callbacks
    // See Razorpay documentation
  }
}
```

⚠️ **NOTE**: This will take 1-2 weeks for approval

---

## 📋 STEP 7: TESTING CHECKLIST (Ongoing)

### Critical Tests (Do Today):
- [ ] User registration works
- [ ] Wallet auto-created
- [ ] Deposit updates balance
- [ ] Pool creation works
- [ ] PIN setup works
- [ ] Security settings work

### Important Tests (This Week):
- [ ] Withdrawal flow (with PIN)
- [ ] Pool contribution (with PIN)
- [ ] Winner selection
- [ ] TDS calculation (>₹10K winning)
- [ ] Rate limiting (100 req/min)
- [ ] Transaction history accurate

### Load Tests (Before Launch):
- [ ] 100 concurrent users
- [ ] 1000 concurrent users
- [ ] Database performance
- [ ] API response times

---

## 📋 STEP 8: LEGAL PREPARATION (Start This Week)

### 8.1 Company Registration
**Options**:
1. **Private Limited** (Recommended)
   - Cost: ₹15,000-25,000
   - Time: 7-10 days
   - Benefits: Limited liability, easier funding

2. **LLP** (Alternative)
   - Cost: ₹10,000-15,000
   - Time: 7-10 days
   - Benefits: Simpler compliance

**How**:
- Use services like Vakilsearch, LegalWiz, or CA
- Documents needed: PAN, Aadhaar, Address proof
- Choose unique company name

### 8.2 Legal Documents (Hire Lawyer)
**Required**:
- [ ] Terms & Conditions
- [ ] Privacy Policy
- [ ] Refund Policy
- [ ] KYC Policy
- [ ] AML Policy
- [ ] User Agreement

**Cost**: ₹20,000-50,000 for all documents

### 8.3 Compliance
- [ ] GST registration (if revenue >₹40L)
- [ ] PAN for company
- [ ] TAN for TDS
- [ ] Bank account for company

---

## 🎯 TODAY'S PRIORITY CHECKLIST

### Must Do Today (2-3 hours):
- [x] ✅ Run `01_setup_tables.sql` in Supabase
- [x] ✅ Run `02_setup_functions.sql` in Supabase
- [ ] ⏳ Create KYC storage bucket
- [ ] ⏳ Test user registration
- [ ] ⏳ Test wallet operations
- [ ] ⏳ Make PIN required
- [ ] ⏳ Add Sentry error tracking

### This Week:
- [ ] Complete all critical tests
- [ ] Start payment gateway registration
- [ ] Start company registration process
- [ ] Hire lawyer for legal docs

### Next 2 Weeks:
- [ ] Complete payment integration
- [ ] Complete legal documents
- [ ] Load testing
- [ ] Bug fixes

---

## 📞 SUPPORT & RESOURCES

### Supabase:
- Docs: https://supabase.com/docs
- Discord: https://discord.supabase.com

### Razorpay:
- Docs: https://razorpay.com/docs
- Support: support@razorpay.com

### Legal:
- Vakilsearch: https://vakilsearch.com
- LegalWiz: https://www.legalwiz.in

### Flutter:
- Docs: https://docs.flutter.dev
- Discord: https://discord.gg/flutter

---

## ✅ SUCCESS CRITERIA

You'll know you're ready when:
- ✅ All database scripts run successfully
- ✅ User registration creates wallet automatically
- ✅ Deposits and withdrawals work
- ✅ PIN is required for transactions
- ✅ Error tracking is active
- ✅ Payment gateway is integrated
- ✅ Legal documents are ready
- ✅ All tests pass
- ✅ 100 users tested successfully

---

**START NOW**: Run the database scripts first!
**Time to Launch**: 6-8 weeks with focused effort
**You've Got This!** 🚀
