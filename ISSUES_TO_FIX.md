# 🔧 ISSUES TO FIX - User Report

## Issues Reported:

### 1. ❌ Quick Actions Not Working
- Privacy Settings
- Refer and Earn
- Payment Methods

### 2. ❌ Support Section Not Working
- Help and Support
- Privacy Policy
- Export Data
- Terms of Service

### 3. ❌ No Add Bank Option
- Need to add bank account management

### 4. ❌ Created Pool Not Showing
- Pool created successfully
- Not appearing in My Pools screen
- Need to check all tabs: Active, Pending, Completed, Draft

---

## FIXES TO APPLY:

### Fix 1: Quick Actions - Connect to Real Screens
**File**: `home_screen.dart` or settings screen

### Fix 2: Support Links - Create Missing Screens
**Files Needed**:
- `privacy_policy_screen.dart` ✅ (exists)
- `terms_of_service_screen.dart` ✅ (exists)
- `export_data_screen.dart` ❌ (missing)
- `help_support_screen.dart` ❌ (missing)

### Fix 3: Add Bank Account Management
**Files Needed**:
- `bank_accounts_screen.dart` ❌ (missing)
- Update wallet screen to show bank accounts

### Fix 4: Pool Not Showing After Creation
**Root Cause**: Likely caching or refresh issue
**Fix**: Add auto-refresh after pool creation

---

## Priority Order:
1. 🔴 HIGH: Pool not showing (affects core functionality)
2. 🟡 MEDIUM: Add bank option (needed for withdrawals)
3. 🟢 LOW: Support screens (can use placeholders)
4. 🟢 LOW: Quick actions (nice to have)
