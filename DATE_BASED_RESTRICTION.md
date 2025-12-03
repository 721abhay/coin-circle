# ✅ DATE-BASED DRAW RESTRICTION

## 📅 The New Logic

The app now strictly enforces the pool schedule based on the calendar.

### **How it Works:**
1.  **Calculate Time Passed**: It checks how many months have passed since the **Pool Start Date**.
2.  **Determine Max Round**: `Max Round = Months Passed + 1`.
3.  **Compare**: It compares the **Current Active Round** (based on winners selected) with the **Max Round**.

### **Example Scenario:**
- **Pool Start Date:** Jan 1st
- **Current Date:** Jan 15th (Month 1)
- **Round 1 Status:** Complete (Winner Selected)
- **Next Round:** Round 2

**Result:**
- `Max Round` = 1 (Since we are still in Month 1).
- `Current Round` = 2.
- **Action:** Draw is **DISABLED**.
- **Message:** *"Round 2 is locked until Feb 1st. Please wait for the next cycle."*

### **When Feb 1st Arrives:**
- `Max Round` becomes 2.
- `Current Round` is 2.
- **Action:** Draw is **ENABLED**.

## 🛠️ Benefits
- Prevents admins from accidentally drawing all winners at once.
- Ensures the pool runs on the agreed monthly schedule.
- Provides clear feedback on when the next draw is available.

The system is now fully synchronized with the calendar! 🗓️
