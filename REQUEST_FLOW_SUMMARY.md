# 🔄 Request-Based Joining Flow Implementation

## Overview
Implemented a 3-step joining process as requested:
1.  **Request:** User requests to join (Status: `pending`).
2.  **Approval:** Creator accepts request (Status: `approved`).
3.  **Payment:** User pays Joining Fee + 1st Contribution (Status: `active`).

## 🛠️ Changes Made

### 1. `PoolService` (`lib/core/services/pool_service.dart`)
- **`joinPool`**: Now only inserts a member record with `status: 'pending'`. No money is deducted.
- **`respondToJoinRequest`**: Now updates status to `'approved'` instead of `'active'`.
- **`completeJoinPayment`**: New method that:
    - Checks Wallet Balance (`Joining Fee` + `Contribution`).
    - Deducts `Joining Fee`.
    - Deducts `Contribution` (Round 1).
    - Updates status to `'active'`.
- **`getUserPools`**: Now returns `membership_status` so the UI knows if a user is pending, approved, or active.

### 2. `JoinPoolScreen` (`lib/features/pools/presentation/screens/join_pool_screen.dart`)
- **UI Update**: Changed "Pay & Join" button to "Send Request".
- **Logic**: Calls `joinPool` to send the request and shows a success message telling the user to wait for approval.

### 3. `MyPoolsScreen` (`lib/features/pools/presentation/screens/my_pools_screen.dart`)
- **"Pending" Tab**: Now shows both `pending` (waiting for approval) and `approved` (waiting for payment) pools.
- **"Pay Joining Fee" Button**: Added a button for `approved` pools.
- **Action**: Clicking the button triggers `completeJoinPayment`, deducting the funds and activating the membership.

## 🚀 How to Test
1.  **User A (Creator)**: Create a pool. Share Invite Code.
2.  **User B (Joiner)**:
    - Go to "Join Pool" -> "Have Code?".
    - Enter Code -> Click "Send Request".
    - See "Request Sent" dialog.
3.  **User A (Creator)**:
    - Go to Pool Details -> "Members" -> "Requests".
    - Click "Accept".
4.  **User B (Joiner)**:
    - Go to "My Pools" -> "Pending" tab.
    - See the pool with status "Approved - Pay Now".
    - Click "Pay Joining Fee".
    - Confirm Payment.
    - Pool moves to "Active" tab.

## ⚠️ Database Note
Ensure your `pool_members` table allows `status` values of `'pending'`, `'approved'`, and `'active'`. If it's an enum, you might need to add `'approved'`.
