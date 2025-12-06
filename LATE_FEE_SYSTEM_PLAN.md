# 🏦 LATE FEE & JOINING FEE SYSTEM - IMPLEMENTATION PLAN

## Current System (To Remove):
- ❌ Pool creators can set late fees
- ❌ Late fees go to the pool fund
- ❌ No joining fee

## New System (To Implement):

### 1. LATE FEE STRUCTURE (Admin-Controlled)
**Automatic calculation based on days late:**
- 0-1 days late: ₹0 (Grace period)
- 2-3 days late: ₹50
- 4-5 days late: ₹70
- 6-7 days late: ₹90
- **Pattern:** +₹20 for every 2 additional days

**Formula:**
```
days_late = payment_due_date - actual_payment_date
if days_late <= 1:
    late_fee = 0
else:
    periods = ceil((days_late - 1) / 2)
    late_fee = 30 + (periods * 20)
```

### 2. JOINING FEE
- **One-time fee** when a user joins a pool
- **Amount:** ₹20 (configurable by admin)
- **Goes to:** Platform revenue (your profit)

### 3. PLATFORM REVENUE TRACKING
Create a new table `platform_revenue`:
```sql
CREATE TABLE platform_revenue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id),
  pool_id UUID REFERENCES pools(id),
  type TEXT, -- 'late_fee' or 'joining_fee'
  amount DECIMAL(10,2),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 4. CODE CHANGES NEEDED:

#### A. Remove Late Fee from Create Pool Screen
- Remove late fee input field (lines 319-328 in create_pool_screen.dart)
- Keep grace period (users can still set grace period)

#### B. Add Joining Fee to Pool Settings
- Add `joining_fee` column to `pools` table (default ₹20)
- Only admins can modify this

#### C. Update Payment Service
- Calculate late fee automatically when payment is made
- Deduct late fee from user's wallet
- Add late fee to `platform_revenue` table
- Do NOT add late fee to pool fund

#### D. Update Join Pool Logic
- Charge joining fee when user joins
- Add joining fee to `platform_revenue` table

### 5. DATABASE CHANGES:

```sql
-- Add platform revenue table
CREATE TABLE IF NOT EXISTS platform_revenue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id),
  pool_id UUID REFERENCES pools(id),
  type TEXT CHECK (type IN ('late_fee', 'joining_fee')),
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Add joining fee to pools table
ALTER TABLE pools ADD COLUMN IF NOT EXISTS joining_fee DECIMAL(10,2) DEFAULT 20.00;

-- Remove late_fee from pools (optional - or keep for backward compatibility)
-- ALTER TABLE pools DROP COLUMN late_fee;

-- Add index for revenue queries
CREATE INDEX IF NOT EXISTS idx_platform_revenue_type ON platform_revenue(type);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_created ON platform_revenue(created_at);
```

### 6. ADMIN DASHBOARD ADDITIONS:

Create a "Platform Revenue" section showing:
- Total late fees collected
- Total joining fees collected
- Revenue by pool
- Revenue over time (chart)

---

## IMPLEMENTATION STEPS:

1. ✅ Create database migration SQL
2. ⏳ Update Create Pool Screen (remove late fee input)
3. ⏳ Create Late Fee calculation service
4. ⏳ Update Payment Service to charge late fees
5. ⏳ Update Join Pool logic to charge joining fee
6. ⏳ Create Platform Revenue dashboard

**Ready to implement?**
