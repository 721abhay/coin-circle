# Navigation Issue - Personal Details & Bank Accounts

## Problem
When clicking "Personal Details" or "Bank Accounts" from the Settings screen, the app shows the `PublicProfileScreen` instead of the dedicated screens.

## Root Cause Analysis

### Expected Behavior
- **Personal Details** button → Navigate to `/profile/personal-details` → Show `PersonalDetailsScreen`
- **Bank Accounts** button → Navigate to `/profile/bank-accounts` → Show `BankAccountsScreen`

### Actual Behavior
- Both buttons → Navigate to `/profile/:userId` → Show `PublicProfileScreen` (with "User", "0 Pools", "No reviews yet")

## Code Verification

### ✅ Routes are Correctly Defined (`app_router.dart`)
```dart
// Line 345-346
GoRoute(
  path: '/profile/personal-details',
  builder: (context, state) => const PersonalDetailsScreen(),
),

// Line 337-338
GoRoute(
  path: '/profile/bank-accounts',
  builder: (context, state) => const profile.BankAccountsScreen(),
),

// Line 307-311 (This might be catching the navigation)
GoRoute(
  path: '/profile/:userId',
  builder: (context, state) {
    final userId = state.pathParameters['userId']!;
    return PublicProfileScreen(userId: userId);
  },
),
```

### ✅ Settings Screen Navigation is Correct (`settings_screen.dart`)
```dart
// Line 127-130
_buildListTile(
  icon: Icons.person_outline,
  title: 'Personal Details',
  subtitle: 'Contact, PAN, Income details',
  onTap: () => context.push('/profile/personal-details'),
),

// Line 131-136
_buildListTile(
  icon: Icons.account_balance,
  title: 'Bank Accounts',
  subtitle: 'Manage your bank accounts',
  onTap: () => context.push('/profile/bank-accounts'),
),
```

## Possible Causes

### 1. **Route Matching Order Issue**
GoRouter matches routes in order. The route `/profile/:userId` (line 307) might be catching `/profile/personal-details` before it reaches the specific route.

**Solution**: Move specific routes BEFORE parameterized routes in `app_router.dart`.

### 2. **Navigation Context Issue**
The `context.push()` might be resolving incorrectly.

### 3. **Caching/Hot Reload Issue**
The app might need a full restart to pick up route changes.

## Recommended Fix

### Option 1: Reorder Routes (RECOMMENDED)
Move the specific `/profile/personal-details` and `/profile/bank-accounts` routes BEFORE the `/profile/:userId` route in `app_router.dart`:

```dart
// Put these BEFORE line 307
GoRoute(
  path: '/profile/personal-details',
  builder: (context, state) => const PersonalDetailsScreen(),
),
GoRoute(
  path: '/profile/bank-accounts',
  builder: (context, state) => const profile.BankAccountsScreen(),
),

// Then the parameterized route
GoRoute(
  path: '/profile/:userId',
  builder: (context, state) {
    final userId = state.pathParameters['userId']!;
    return PublicProfileScreen(userId: userId);
  },
),
```

### Option 2: Use Different Path Structure
Change the routes to avoid conflict:
- `/settings/personal-details` instead of `/profile/personal-details`
- `/settings/bank-accounts` instead of `/profile/bank-accounts`

## Testing Steps

1. **Stop the app completely** (not just hot reload)
2. Run `flutter clean`
3. Run `flutter pub get`
4. Run `flutter run`
5. Navigate to Settings → Personal Details
6. Verify it shows the PersonalDetailsScreen (with Alice Smith, PAN, Aadhaar, etc.)
7. Navigate to Settings → Bank Accounts
8. Verify it shows the BankAccountsScreen

## Current Screen Status

### ✅ PersonalDetailsScreen (`personal_details_screen.dart`)
- **Status**: Exists and fully implemented
- **Data**: Currently shows hardcoded demo data (Alice Smith, +91 98765 43210, etc.)
- **Features**: Contact info, Identity docs (PAN, Aadhaar), Financial info, Quick actions
- **Route**: `/profile/personal-details`

### ✅ BankAccountsScreen (`bank_accounts_screen.dart`)
- **Status**: Exists (two versions - one in profile, one in wallet)
- **Route**: `/profile/bank-accounts` → `profile.BankAccountsScreen()`

### ✅ PublicProfileScreen (`public_profile_screen.dart`)
- **Status**: Just updated to fetch real data
- **Features**: Shows user profile, badges, reviews, pool stats
- **Route**: `/profile/:userId`

## Next Steps

1. ✅ Reorder routes in `app_router.dart` to fix navigation
2. ⏳ Test navigation after full app restart
3. ⏳ Update PersonalDetailsScreen to fetch real data from Supabase
4. ⏳ Update BankAccountsScreen to fetch real data from Supabase

## Files to Modify

1. `lib/core/router/app_router.dart` - Reorder routes
2. `lib/features/profile/presentation/screens/personal_details_screen.dart` - Connect to backend (future)
3. `lib/features/profile/presentation/screens/bank_accounts_screen.dart` - Verify backend connection (future)
