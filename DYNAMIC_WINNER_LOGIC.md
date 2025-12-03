# ✅ DYNAMIC WINNER SELECTION IMPLEMENTED

## 🧠 The New Logic

The app now automatically calculates how many winners are needed for each round based on the pool's progress.

### **How it Works:**
1.  **Simulation**: The app simulates the pool from Round 1 to the end.
2.  **Formula**: For each round, it calculates:
    `Winners Needed = CEIL(Remaining Members / Remaining Rounds)`
3.  **Current Status**: It compares the "Winners Needed" with the "Actual Winners" in the database.
    - If `Actual < Needed`, the round is **Active**.
    - If `Actual == Needed`, the round is **Complete**, and it moves to the next round.

### **Example Scenarios:**

#### **Scenario A: 10 Members, 5 Months**
- **Round 1:** 10 members / 5 months = **2 Winners Needed**.
    - *Draw 1:* "Winner 1 of 2"
    - *Draw 2:* "Winner 2 of 2"
- **Round 2:** 8 members / 4 months = **2 Winners Needed**.

#### **Scenario B: 10 Members, 10 Months**
- **Round 1:** 10 members / 10 months = **1 Winner Needed**.

### **UI Updates**
- **Progress Badge:** Shows "Round X • Winner Y of Z" at the top.
- **Auto-Disable:** The "Start Live Draw" button is automatically disabled when the current round's quota is met.
- **Smart Validation:** Prevents drawing if the pool hasn't reached the `start_month`.

## 🛠️ How to Test
1.  Run `flutter run`.
2.  Go to a Pool with a short duration (e.g., 10 members, 5 months).
3.  Open **Winner Selection**.
4.  You should see "Winner 1 of 2".
5.  Draw a winner.
6.  Return to the screen.
7.  You should see "Winner 2 of 2".
8.  Draw again.
9.  Return to the screen.
10. You should see "Round 1 is complete".

The system is now fully dynamic and robust! 🚀
