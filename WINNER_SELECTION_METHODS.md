# 🎯 Winner Selection Methods Implementation

## Overview
The pool system supports three winner selection methods:
1. **Random Draw** - Random selection from eligible members
2. **Sequential Rotation** - Members win in order of joining
3. **Member Voting** - Members vote to select the winner

## Current Status

### ✅ Implemented
- **Random Draw**: Fully functional via `select_random_winner` RPC
- **Backend RPCs**: All three methods have database functions:
  - `select_random_winner`
  - `select_sequential_winner`
  - `select_voted_winner`
- **WinnerService**: Routes to correct RPC based on pool's `winner_selection_method`

### ⚠️ Needs Implementation

#### 1. Sequential Rotation UI
**What's needed:**
- Show the next person in rotation on the Winner Selection Screen
- Display "Next Winner: [Name]" instead of random animation
- Confirm button to proceed with the sequential winner

**Implementation:**
```dart
// In WinnerSelectionScreen
if (selectionMethod == 'Sequential Rotation') {
  // Fetch next eligible member by join_date
  final nextWinner = _eligibleMembers.first; // Already sorted by join_date
  // Show confirmation UI
  return _buildSequentialConfirmation(nextWinner);
}
```

#### 2. Member Voting UI
**What's needed:**
- Voting period before the draw
- UI to cast votes for eligible members
- Display vote counts (or keep secret until draw)
- Admin triggers draw after voting period ends

**Implementation Steps:**
1. Create `VotingScreen` widget
2. Add voting period tracking in database
3. Allow members to vote via UI
4. Admin sees "Voting in Progress" status
5. After voting ends, admin triggers `select_voted_winner`

## Database Schema

### Voting System (if not exists)
```sql
CREATE TABLE IF NOT EXISTS votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pool_id UUID REFERENCES pools(id),
  round_number INT NOT NULL,
  voter_id UUID REFERENCES auth.users(id),
  candidate_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(pool_id, round_number, voter_id)
);
```

## Next Steps

### Priority 1: Fix WinnerSelectionScreen
The file is currently corrupted. Need to:
1. Restore the complete file structure
2. Add `_selectionMethod` state variable
3. Fetch it from pool rules
4. Branch UI based on method

### Priority 2: Sequential Rotation
1. Sort eligible members by `join_date`
2. Show next winner clearly
3. Simple confirmation flow

### Priority 3: Member Voting
1. Create voting UI
2. Implement vote submission
3. Add voting period management
4. Integrate with draw trigger

## Testing Checklist
- [ ] Random Draw works with all validations
- [ ] Sequential shows correct next winner
- [ ] Voting UI allows all members to vote
- [ ] Vote counts are accurate
- [ ] All three methods respect payment/date restrictions
