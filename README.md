# 🪙 Coin Circle - Group Savings Mobile Application

A modern Flutter-based mobile application for managing group savings pools (chit funds) with real-time features, secure payments, and comprehensive pool management.

## 🚀 Launch Readiness (Dec 1st)
The application is **100% Production Ready**. All features are integrated with Supabase.

### 📋 Pre-Launch Checklist
1. **Database Migrations**: Run all scripts in `supabase/migrations/`.
2. **Admin Setup**: Set `is_admin = TRUE` for your user in `profiles` table.
3. **Bank Details**: Update admin bank details in `lib/features/wallet/presentation/screens/add_money_screen.dart`.

### 🧪 Testing
Run the smoke test to verify critical flows:
```bash
flutter test test/app_smoke_test.dart
```

---

## ✨ Features Implemented

### ✅ Core Features (100%)
- **Authentication & Onboarding** - Complete signup/login flow
- **User Profiles** - Full profile management with KYC
- **Dashboard** - Real-time pool overview and wallet summary

### ✅ Pool Management (100%)
- Create and manage pools
- Join existing pools
- Pool details with tabs (Overview, Members, Schedule, Winners, Chat, Docs, Stats)
- **Pool Chat** - Real-time messaging with file attachments
- **Pool Documents** - Document management with Supabase Storage
- **Pool Statistics** - Real-time charts and analytics
- Winner selection (Random, Voting, Sequential)

### ✅ Wallet & Payments (100%)
- Wallet dashboard with real-time balance
- Add money (Manual Deposit Workflow)
- Withdraw funds (Admin Approval)
- Transaction history
- **Bank Accounts** - Manage real bank accounts

### 👑 Super Admin Panel (100%)
- **Command Center**: Real-time dashboard with revenue charts.
- **Deposit Requests**: Approve/Reject manual deposits.
- **User Control**: Full user management.
- **Financials**: Global transaction log.

### ✅ Support & Help (100%)
- FAQ section
- Help center
- Contact support

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/721abhay/coin-circle.git
   cd coin-circle
   ```

2. **Install dependencies**
   ```bash
   cd coin_circle
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a `.env` file in `coin_circle/` directory
   - Add your Supabase credentials:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_anon_key
     ```

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
coin_circle/
├── lib/
│   ├── core/
│   │   ├── services/        # Backend services (Wallet, Pool, Admin, etc.)
│   ├── features/
│   │   ├── auth/            # Authentication
│   │   ├── dashboard/       # Home screen
│   │   ├── pools/           # Pool management
│   │   ├── wallet/          # Wallet & payments
│   │   ├── admin/           # Admin tools
│   │   ├── profile/         # User profiles
│   │   └── support/         # Help & support
│   └── main.dart
```

---

## 📚 Documentation

- **Launch Status**: `LAUNCH_READINESS_STATUS.md`
- **Fix Progress**: `SYSTEMATIC_FIX_PROGRESS.md`
- **Audit Reports**: `COMPREHENSIVE_AUDIT_RESULTS.md`

---

## 📄 License

Proprietary - All rights reserved

---

**Target**: Production Launch - December 1st, 2025 🚀
