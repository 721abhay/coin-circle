# Coin Circle - Comprehensive Profile & Settings Implementation Plan

## 📱 Feature Categories

### 1. Personal Details Screen
**Route:** `/profile/personal-details`

#### Features to Implement:
- [ ] **Contact Details Section**
  - Phone Number (editable, with verification)
  - Email (editable, with verification)
  - Address (editable, multi-line)
  - Edit icons for each field
  
- [ ] **Identity Section**
  - Name and Date of Birth (editable)
  - PAN Number (with copy-to-clipboard)
  - Aadhaar Number (optional, masked)
  
- [ ] **Nominee Details**
  - Nominee Name
  - Relationship
  - Date of Birth
  - Allocation percentage
  
- [ ] **Income Details**
  - Annual Income range
  - Occupation
  - Source of funds

#### Database Schema:
```sql
-- Add to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS aadhaar_number VARCHAR(12);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS annual_income VARCHAR(50);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS occupation VARCHAR(100);

-- Create nominees table
CREATE TABLE IF NOT EXISTS nominees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  relationship VARCHAR(50) NOT NULL,
  date_of_birth DATE,
  allocation_percentage INTEGER DEFAULT 100,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

### 2. Bank Account Management
**Route:** `/profile/bank-accounts`

#### Features to Implement:
- [ ] **Bank Account List**
  - Bank name with logo
  - Masked account number
  - Primary badge
  - Three-dot menu (Edit, Delete, Set as Primary)
  
- [ ] **Add Bank Account**
  - Account holder name
  - Account number
  - IFSC code
  - Bank name (auto-filled from IFSC)
  - Account type (Savings/Current)
  - Verification via penny drop or manual upload
  
- [ ] **Bank Verification**
  - Penny drop verification
  - Cheque/Passbook upload
  - Verification status tracking

#### Database Schema:
```sql
CREATE TABLE IF NOT EXISTS bank_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  account_holder_name VARCHAR(255) NOT NULL,
  account_number VARCHAR(20) NOT NULL,
  ifsc_code VARCHAR(11) NOT NULL,
  bank_name VARCHAR(255) NOT NULL,
  account_type VARCHAR(20) DEFAULT 'savings',
  is_primary BOOLEAN DEFAULT false,
  is_verified BOOLEAN DEFAULT false,
  verification_method VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, account_number)
);
```

---

### 3. KYC & Document Management
**Route:** `/profile/kyc`

#### Features to Implement:
- [ ] **KYC Status Dashboard**
  - Overall KYC status (Pending/In Progress/Verified/Rejected)
  - Document checklist
  - Verification timeline
  
- [ ] **Document Upload**
  - PAN Card (front)
  - Aadhaar Card (front & back)
  - Bank Proof (cheque/passbook)
  - Selfie/Photo
  - Signature
  
- [ ] **Document Viewer**
  - View uploaded documents
  - Download signed documents
  - Re-upload if rejected

#### Database Schema:
```sql
CREATE TABLE IF NOT EXISTS kyc_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  document_type VARCHAR(50) NOT NULL,
  document_url TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  rejection_reason TEXT,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  verified_at TIMESTAMP WITH TIME ZONE,
  verified_by UUID REFERENCES auth.users(id)
);

CREATE TABLE IF NOT EXISTS kyc_status (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  overall_status VARCHAR(20) DEFAULT 'pending',
  pan_verified BOOLEAN DEFAULT false,
  aadhaar_verified BOOLEAN DEFAULT false,
  bank_verified BOOLEAN DEFAULT false,
  selfie_verified BOOLEAN DEFAULT false,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

### 4. Track Requests
**Route:** `/profile/track-requests`

#### Features to Implement:
- [ ] **Request List**
  - Profile modification requests
  - Bank account change requests
  - Nominee update requests
  - Status (Pending/Approved/Rejected)
  
- [ ] **Request Details**
  - Request type
  - Requested changes
  - Current vs. New values
  - Submission date
  - Approval/Rejection date
  - Reason for rejection

#### Database Schema:
```sql
CREATE TABLE IF NOT EXISTS profile_change_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  request_type VARCHAR(50) NOT NULL,
  field_name VARCHAR(100) NOT NULL,
  current_value TEXT,
  requested_value TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by UUID REFERENCES auth.users(id)
);
```

---

### 5. Help & Support
**Route:** `/help`

#### Features to Implement:
- [ ] **AI Chat Support ("Ask Angel" equivalent)**
  - AI-powered chatbot
  - Quick responses
  - Escalation to human agent
  
- [ ] **Call Us**
  - Display support phone numbers
  - Click-to-call functionality
  - Business hours display
  
- [ ] **FAQs**
  - Categorized questions
  - Search functionality
  - Helpful/Not helpful feedback
  
- [ ] **Submit Ticket**
  - Issue category selection
  - Description
  - Attachment support
  - Ticket tracking

#### Database Schema:
```sql
CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  category VARCHAR(100) NOT NULL,
  subject VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'open',
  priority VARCHAR(20) DEFAULT 'medium',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  closed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS support_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_id UUID REFERENCES support_tickets(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES auth.users(id),
  message TEXT NOT NULL,
  is_staff BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

### 6. Enhanced Settings Screen
**Route:** `/settings`

#### Features to Add:
- [ ] **Account Settings**
  - Personal Details
  - Bank Accounts
  - Nominee Details
  - KYC Status
  
- [ ] **Security Settings**
  - Change Password
  - Two-Factor Authentication
  - Biometric Login
  - Session Management
  - Login History
  
- [ ] **Privacy Settings**
  - Profile Visibility
  - Data Sharing Preferences
  - Marketing Communications
  - Download My Data (GDPR)
  - Delete Account
  
- [ ] **Notification Settings**
  - Push Notifications (by category)
  - Email Notifications
  - SMS Notifications
  - Quiet Hours
  
- [ ] **App Preferences**
  - Language
  - Currency
  - Theme (Light/Dark/Auto)
  - Data Saver Mode
  
- [ ] **About**
  - App Version
  - Terms of Service
  - Privacy Policy
  - Licenses
  - Rate App

---

### 7. Social & Community Features
**Route:** `/community`

#### Features to Implement:
- [ ] **Community Forum**
  - Discussion threads
  - Categories (Tips, Success Stories, Questions)
  - Upvote/Downvote
  - Comments
  
- [ ] **Social Media Integration**
  - Follow Us links (Instagram, Twitter, YouTube, Facebook, LinkedIn)
  - Share achievements
  
- [ ] **Referral Program**
  - Referral code
  - Track referrals
  - Rewards

---

## 🗂️ File Structure

```
lib/
├── features/
│   ├── profile/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── personal_details_model.dart
│   │   │   │   ├── bank_account_model.dart
│   │   │   │   ├── nominee_model.dart
│   │   │   │   └── kyc_document_model.dart
│   │   │   └── repositories/
│   │   │       └── profile_repository.dart
│   │   ├── domain/
│   │   │   └── services/
│   │   │       ├── profile_service.dart (existing)
│   │   │       ├── bank_service.dart
│   │   │       └── kyc_service.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── personal_details_screen.dart
│   │       │   ├── bank_accounts_screen.dart
│   │       │   ├── add_bank_account_screen.dart
│   │       │   ├── nominee_details_screen.dart
│   │       │   ├── income_details_screen.dart
│   │       │   ├── kyc_screen.dart
│   │       │   ├── track_requests_screen.dart
│   │       │   └── settings_screen.dart (existing)
│   │       └── widgets/
│   │           ├── editable_field.dart
│   │           ├── bank_account_card.dart
│   │           └── document_upload_widget.dart
│   ├── support/
│   │   ├── data/
│   │   │   └── models/
│   │   │       ├── support_ticket_model.dart
│   │   │       └── faq_model.dart
│   │   ├── domain/
│   │   │   └── services/
│   │   │       └── support_service.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── help_center_screen.dart
│   │       │   ├── ai_chat_screen.dart
│   │       │   ├── submit_ticket_screen.dart
│   │       │   └── faq_screen.dart
│   │       └── widgets/
│   │           └── chat_bubble.dart
│   └── community/
│       └── presentation/
│           └── screens/
│               └── community_screen.dart
```

---

## 🚀 Implementation Priority

### Phase 1: Core Profile Features (Week 1)
1. Personal Details Screen
2. Bank Account Management
3. Enhanced Settings Screen

### Phase 2: Verification & Security (Week 2)
4. KYC Document Upload
5. Track Requests
6. Security Settings

### Phase 3: Support & Engagement (Week 3)
7. Help & Support System
8. AI Chat Integration
9. Social & Community Features

---

## 🎨 UI/UX Guidelines

- Use Material Design 3 components
- Follow the existing app theme (primary color: #F97A53)
- Implement smooth transitions and micro-animations
- Add loading states for all async operations
- Show success/error feedback with SnackBars
- Use bottom sheets for quick actions
- Implement pull-to-refresh where applicable
- Add skeleton loaders for better perceived performance

---

## 🔒 Security Considerations

- Mask sensitive data (PAN, Aadhaar, Bank Account)
- Implement rate limiting for OTP requests
- Add CAPTCHA for sensitive operations
- Log all profile modification attempts
- Require re-authentication for critical changes
- Encrypt sensitive data at rest
- Implement audit trails

---

## 📊 Analytics Events to Track

- Profile view
- Field edit attempts
- Bank account additions
- KYC document uploads
- Support ticket creation
- Settings changes
- Feature usage patterns
