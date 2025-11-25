# 🔧 Immediate Fixes Needed

## Priority 1: Join Pool Flow (CRITICAL)

### 1. Joining Fee Payment ✅
- [ ] Add payment step before joining pool
- [ ] User must pay joining fee (contribution_amount)
- [ ] Only after payment, join request is sent
- [ ] Status: pending → active after payment

### 2. Admin Approval System ✅
- [ ] Show join requests in admin panel
- [ ] Display user profile before approval
- [ ] Approve/Reject buttons
- [ ] Notification to user on approval/rejection

### 3. Copy Invite Code ✅
- [ ] Fix copy to clipboard functionality
- [ ] Show success message after copy

## Priority 2: Data Integration

### 4. Wallet Summary ✅
- [ ] Remove demo data
- [ ] Connect to real Supabase wallet data
- [ ] Show actual balance, locked amount, winnings

### 5. Transaction History ✅
- [ ] Remove demo transactions
- [ ] Fetch from Supabase transactions table
- [ ] Show real transaction data

## Priority 3: UI Cleanup

### 6. Remove Draft Status ✅
- [ ] Remove "draft" from pool status options
- [ ] Only use: pending, active, completed, cancelled

### 7. Fix Pool Management Overflow ✅
- [ ] Fix admin panel bottom overflow
- [ ] Make scrollable or adjust layout

### 8. Remove Future Features ❌
- [ ] Remove Financial Goals screen
- [ ] Remove Smart Savings screen
- [ ] Remove "Find Pools Near You" from Discover
- [ ] Remove "Trending Now" from Discover
- [ ] Remove QR Code scan option

## Implementation Order:
1. Fix copy invite code (quick win)
2. Add payment before joining
3. Admin approval UI
4. Connect wallet/transaction data
5. UI cleanup and removals
