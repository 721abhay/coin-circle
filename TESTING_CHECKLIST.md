# 🧪 CORE FEATURES TESTING CHECKLIST

## ✅ **Test 1: User Authentication**

### Login/Logout
- [ ] Login with existing account
- [ ] Logout
- [ ] Login again
- [ ] Session persists after app restart

**Expected**: ✅ All work smoothly

---

## ✅ **Test 2: Wallet Operations**

### View Wallet
- [ ] Go to Wallet tab
- [ ] See balance (₹0.00 initially)
- [ ] See breakdown (Available, Locked, Pending, Winnings)
- [ ] **NO ERROR** at bottom

### Add Money (Simulated)
1. Click **"Add Money"** button
2. Enter amount: ₹1000
3. Select payment method: UPI/Card
4. Click **"Proceed to Pay"**
5. Should show success (simulated)
6. Balance should update to ₹1000

**Expected**: ✅ Balance increases

### Transaction History
- [ ] Click on transaction history
- [ ] See deposit transaction
- [ ] Shows correct amount, date, status

**Expected**: ✅ Transaction logged

---

### Join Pool (as another user - optional)
1. Create another test account
2. Browse pools
3. Join "Test Pool 1"
4. Pay joining fee

**Expected**: ✅ Can join pool

---

## ✅ **Test 4: Pool Contributions**

### Make Contribution
1. Go to pool details
2. Click **"Contribute"** or **"Pay"**
3. Enter amount: ₹500
4. **If PIN is set**: Enter PIN
5. Confirm payment

**Expected**: 
- ✅ Balance deducted from wallet
- ✅ Contribution recorded
- ✅ Pool balance updated

### View Contribution History
- [ ] See contribution in pool history
- [ ] See contribution in wallet transactions
- [ ] Status shows "Completed"

**Expected**: ✅ All records match

---

## ✅ **Test 5: Profile Management**

### View Profile
- [ ] Go to Profile tab
- [ ] See your name (not "User")
- [ ] See email
- [ ] See phone number
- [ ] See stats (Pools Joined, Active Pools, Balance)

**Expected**: ✅ All data displays correctly

### Edit Profile
1. Click edit icon
2. Update name/phone
3. Save changes
4. Go back to profile
5. Changes should be visible

**Expected**: ✅ Updates saved

### Security Settings
1. Go to Security Settings
2. See options:
   - Transaction PIN
   - Biometric Login
   - 2FA
3. Try enabling Transaction PIN
4. Set 4-digit PIN
5. Confirm PIN

**Expected**: ✅ PIN set successfully

---

## ✅ **Test 6: Notifications**

### View Notifications
- [ ] Go to Notifications
- [ ] See system notifications
- [ ] See pool updates
- [ ] Mark as read

**Expected**: ✅ Notifications work

---

## ✅ **Test 7: Chat (if in pool)**

### Pool Chat
1. Go to pool details
2. Click Chat tab
3. Send a message
4. See message appear
5. Try sending image (optional)

**Expected**: ✅ Chat functional

---

## ✅ **Test 8: Winner Selection (Admin)**

### Random Draw
1. Go to pool (as admin)
2. Click "Select Winner"
3. Click "Random Draw"
4. See animation
5. Winner selected

**Expected**: ✅ Winner chosen randomly

### Manual Selection
1. Go to pool (as admin)
2. Click "Select Winner"
3. Choose member manually
4. Confirm selection

**Expected**: ✅ Winner set

---

## ✅ **Test 9: Voting**

### Create Vote
1. Go to pool (as admin)
2. Create new vote
3. Add question and options
4. Submit vote

**Expected**: ✅ Vote created

### Cast Vote
1. View active vote
2. Select option
3. Submit vote
4. See results

**Expected**: ✅ Vote recorded

---

## ✅ **Test 10: KYC Submission**

### Submit KYC
1. Go to Profile → KYC
2. Upload documents:
   - Aadhaar
   - PAN
3. Fill in details
4. Submit

**Expected**: ✅ KYC submitted, status "Pending"

---

## ✅ **Test 11: Withdrawal**

### Request Withdrawal
1. Go to Wallet
2. Click **"Withdraw"**
3. Enter amount: ₹500
4. Enter bank details
5. **If PIN set**: Enter PIN
6. **If 2FA enabled**: Enter OTP
7. Submit request

**Expected**: 
- ✅ Request submitted
- ✅ Status "Pending approval"
- ✅ Balance locked

---

## ✅ **Test 12: Admin Dashboard (if admin)**

### View Dashboard
- [ ] Go to Admin section
- [ ] See statistics
- [ ] See pending KYC
- [ ] See pending withdrawals
- [ ] See all pools

**Expected**: ✅ Admin features accessible

### Approve KYC
1. Click on pending KYC
2. Review documents
3. Approve/Reject
4. User status updates

**Expected**: ✅ KYC approval works

### Approve Withdrawal
1. Click on pending withdrawal
2. Review details
3. Approve
4. User receives money

**Expected**: ✅ Withdrawal processed

---

## 🐛 **BUGS TO WATCH FOR**

### Common Issues:
- [ ] App crashes on any action
- [ ] Data not saving
- [ ] Balance not updating
- [ ] Transactions not appearing
- [ ] Profile data missing
- [ ] Images not loading
- [ ] Chat not sending
- [ ] Notifications not showing

### Performance Issues:
- [ ] Slow loading
- [ ] Laggy scrolling
- [ ] Memory leaks
- [ ] Battery drain

---

## 📊 **TEST RESULTS TEMPLATE**

### Feature: _____________
**Status**: ✅ Pass / ❌ Fail / ⚠️ Partial

**What Worked**:
- 

**What Failed**:
- 

**Error Messages**:
- 

**Screenshots**: (if any issues)

---

## 🎯 **PRIORITY TESTS** (Do These First)

1. ✅ **Wallet Error Fix** - MUST work
2. ✅ **Add Money** - Core feature
3. ✅ **Create Pool** - Core feature
4. ✅ **Contribute to Pool** - Core feature
5. ✅ **Profile Data** - Should show real info

---

## 📝 **TESTING NOTES**

**Date**: 2025-11-24
**Tester**: You
**App Version**: Development
**Device**: Motorola Edge 50 Fusion

**Start Time**: ___________
**End Time**: ___________

**Overall Status**: 
- Features Working: ___/12
- Features Broken: ___/12
- Critical Bugs: ___

---

**START TESTING NOW!**

1. Run the SQL fix for wallet
2. Hot restart app (press `r`)
3. Go through tests 1-5 first
4. Report any issues you find

Good luck! 🚀
