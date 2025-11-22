# 👑 SUPER ADMIN UPGRADE PLAN

## 1. 🎨 UI Overhaul (Premium Dashboard)
- **New Layout**: Sidebar navigation (desktop-style) for better access to many features.
- **Theme**: Dark/Professional mode option, dense data tables.
- **Dashboard**: Real-time graphs, critical alerts, system health.

## 2. 👥 User Control (Full Access)
- **User List**: Searchable, filterable list of all users.
- **User Detail View**:
    - View full profile & KYC data.
    - **Actions**: Ban/Unban, Reset Password, Edit Details.
    - **Wallet View**: See their exact balance, transaction history.
    - **Manual Adjustment**: Credit/Debit their wallet (Admin Override).

## 3. 🎱 Pool Control (God Mode)
- **Pool List**: See ALL pools (Active, Draft, Private).
- **Pool Detail View**:
    - **Actions**: Force Close, Pause, Delete.
    - **Member Management**: Kick member, Force add member.
    - **Winner**: Force select winner, Re-roll winner.

## 4. 💰 Financial Control
- **System Wallet**: View total system holdings, fees collected.
- **Transaction Log**: Global view of every penny moving in the app.
- **Withdrawals**: Bulk approve/reject with reasons.

## 5. ⚙️ System Control
- **Maintenance Mode**: One-click switch to lock the app for users.
- **Announcements**: Push global banners/notifications.
- **Database**: View raw table data (optional).

---

## 🛠 Implementation Steps
1. Create `AdminLayout` (Sidebar + Content area).
2. Revamp `AdminDashboardScreen` with charts and summary cards.
3. Create `AdminAllUsersScreen` with advanced actions.
4. Create `AdminAllPoolsScreen` with "God Mode" actions.
5. Create `AdminSystemSettingsScreen`.
