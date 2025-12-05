# 🔔 Push Notifications Setup Guide - Win Pool App

**Date**: December 4, 2025  
**Status**: Ready to Configure  
**Priority**: HIGH

---

## ✅ WHAT'S ALREADY DONE

### 1. **Dependencies Added** ✅
All required packages are already in `pubspec.yaml`:
```yaml
firebase_core: ^3.8.1
firebase_messaging: ^15.1.5
flutter_local_notifications: ^18.0.1
```

### 2. **Services Implemented** ✅
Two complete notification services exist:

**`push_notification_service.dart`** - Firebase Cloud Messaging
- FCM token management
- Foreground message handling
- Background message handling
- Local notification display
- Topic subscription
- Token saving to Supabase

**`notification_service.dart`** - Database Notifications
- Get notifications from Supabase
- Mark as read/unread
- Delete notifications
- Real-time subscription
- Notification preferences

### 3. **Main.dart Integration** ✅
Firebase initialization code is already in `main.dart`:
```dart
// Register background message handler
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

// Initialize Firebase
await Firebase.initializeApp();

// Initialize Push Notifications
await PushNotificationService.initialize();
```

### 4. **Android Configuration** ✅
`google-services.json` file exists in `android/app/`

---

## ⚠️ WHAT NEEDS TO BE DONE

### Step 1: Generate Firebase Options File

You need to run the FlutterFire CLI to generate `firebase_options.dart`:

```powershell
# Install FlutterFire CLI (if not already installed)
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

**What this does**:
1. Connects to your Firebase project
2. Generates `lib/firebase_options.dart`
3. Configures all platforms (Android, iOS, Web)

**Select**:
- Your existing Firebase project
- Platforms: Android, iOS (if needed), Web (if needed)

---

### Step 2: Update main.dart

After generating `firebase_options.dart`, uncomment these lines in `main.dart`:

**Current (lines 14, 25)**:
```dart
// import 'firebase_options.dart'; // Uncomment after running 'flutterfire configure'

await Firebase.initializeApp(
  // options: DefaultFirebaseOptions.currentPlatform, // Uncomment after setup
);
```

**Change to**:
```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

### Step 3: Update Android Configuration

#### 3.1 Update `android/build.gradle`

Add Google Services classpath:

```gradle
buildscript {
    dependencies {
        // ... existing dependencies
        classpath 'com.google.gms:google-services:4.4.0'  // Add this line
    }
}
```

#### 3.2 Update `android/app/build.gradle`

Add at the **bottom** of the file:

```gradle
apply plugin: 'com.google.gms.google-services'  // Add this line at the very end
```

Also ensure minSdkVersion is at least 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Must be 21 or higher
    }
}
```

---

### Step 4: Add Database Column for FCM Token

The service tries to save FCM tokens to the `profiles` table. Ensure this column exists:

```sql
-- Run this in Supabase SQL Editor
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
```

---

### Step 5: Test Push Notifications

#### 5.1 Run the App

```powershell
cd "c:\Users\ABHAY\coin circle\coin_circle"
flutter run
```

#### 5.2 Check Console Output

You should see:
```
✅ Firebase initialized successfully
✅ User granted notification permission
📱 FCM Token: [long token string]
✅ FCM token saved to database
✅ Push Notifications initialized successfully
```

#### 5.3 Test with Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter:
   - **Notification title**: "Test Notification"
   - **Notification text**: "This is a test from Firebase"
4. Click "Send test message"
5. Paste your FCM token (from console output)
6. Click "Test"

You should receive the notification!

---

## 🎯 HOW IT WORKS

### Notification Flow

```
┌─────────────────────────────────────────────────────────┐
│                    NOTIFICATION FLOW                     │
└─────────────────────────────────────────────────────────┘

1. USER ACTION (e.g., joins pool)
   ↓
2. NotificationService.createNotification()
   → Saves to Supabase 'notifications' table
   ↓
3. BACKEND TRIGGER (Supabase Function/Edge Function)
   → Reads user's FCM token from profiles
   → Calls Firebase Admin SDK
   ↓
4. FIREBASE CLOUD MESSAGING
   → Sends push notification to device
   ↓
5. APP RECEIVES NOTIFICATION
   ├─ Foreground: PushNotificationService._handleForegroundMessage()
   ├─ Background: firebaseMessagingBackgroundHandler()
   └─ Terminated: Opens app with notification data
   ↓
6. LOCAL NOTIFICATION DISPLAYED
   → User sees notification
   → Taps → Navigates to relevant screen
```

---

## 📱 NOTIFICATION TYPES ALREADY IMPLEMENTED

The app already creates notifications for:

1. **Pool Events**:
   - Join request received
   - Join request approved/rejected
   - New member joined
   - Pool created

2. **Voting Events**:
   - Voting period opened
   - Vote cast
   - Voting period closed
   - Winner announced

3. **Payment Events**:
   - Payment due reminder
   - Payment received
   - Late payment warning
   - Payout approved

4. **System Events**:
   - KYC approved/rejected
   - Withdrawal processed
   - Security alerts

---

## 🔧 BACKEND SETUP (For Sending Push Notifications)

### Option 1: Supabase Edge Function (Recommended)

Create a Supabase Edge Function to send notifications:

```typescript
// supabase/functions/send-push-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { userId, title, body, data } = await req.json()
  
  // Get user's FCM token
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )
  
  const { data: profile } = await supabase
    .from('profiles')
    .select('fcm_token')
    .eq('id', userId)
    .single()
  
  if (!profile?.fcm_token) {
    return new Response(JSON.stringify({ error: 'No FCM token' }), { status: 400 })
  }
  
  // Send notification using Firebase Admin SDK
  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Authorization': `key=${Deno.env.get('FCM_SERVER_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      to: profile.fcm_token,
      notification: { title, body },
      data: data || {},
    }),
  })
  
  return new Response(JSON.stringify({ success: true }), { status: 200 })
})
```

### Option 2: Database Trigger

Create a trigger that sends push notification when a notification is inserted:

```sql
-- Create trigger function
CREATE OR REPLACE FUNCTION send_push_notification_trigger()
RETURNS TRIGGER AS $$
BEGIN
  -- Call Edge Function to send push notification
  PERFORM net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object(
      'userId', NEW.user_id,
      'title', NEW.title,
      'body', NEW.message,
      'data', NEW.metadata
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER on_notification_created
AFTER INSERT ON notifications
FOR EACH ROW
EXECUTE FUNCTION send_push_notification_trigger();
```

---

## 🧪 TESTING CHECKLIST

### Local Notifications
- [ ] App shows notification when in foreground
- [ ] Notification appears in system tray
- [ ] Tapping notification opens app
- [ ] Notification sound plays

### Push Notifications
- [ ] FCM token generated and saved to database
- [ ] Test notification received from Firebase Console
- [ ] Notification received when app is in background
- [ ] Notification received when app is terminated
- [ ] Notification data passed correctly

### Notification Preferences
- [ ] User can enable/disable notification types
- [ ] Preferences saved to database
- [ ] Notifications respect user preferences

---

## 🐛 TROUBLESHOOTING

### Issue: "Firebase not configured yet"

**Solution**: Run `flutterfire configure` and uncomment lines in main.dart

### Issue: "No FCM token generated"

**Solution**: 
1. Check internet connection
2. Ensure Google Services plugin is applied
3. Check Firebase project configuration
4. Verify google-services.json is in android/app/

### Issue: "Notifications not received"

**Solution**:
1. Check notification permissions granted
2. Verify FCM token saved to database
3. Check Firebase Console for delivery status
4. Ensure device has internet connection

### Issue: "Build fails with Google Services error"

**Solution**:
1. Check google-services.json is valid JSON
2. Ensure Google Services plugin version matches
3. Clean and rebuild: `flutter clean && flutter pub get`

---

## 📊 CURRENT STATUS

| Component | Status | Notes |
|-----------|--------|-------|
| Dependencies | ✅ Complete | All packages added |
| Services | ✅ Complete | Both services implemented |
| Main.dart | ⚠️ Needs Update | Uncomment firebase_options |
| Android Config | ⚠️ Needs Update | Add Google Services plugin |
| Firebase Options | ❌ Not Generated | Run flutterfire configure |
| Database Column | ⚠️ Check | Verify fcm_token column exists |
| Backend | ❌ Not Set Up | Need Edge Function or trigger |
| Testing | ❌ Not Done | Need to test after setup |

---

## 🎯 QUICK START (5 Minutes)

```powershell
# 1. Install FlutterFire CLI
dart pub global activate flutterfire_cli

# 2. Configure Firebase
cd "c:\Users\ABHAY\coin circle\coin_circle"
flutterfire configure

# 3. Update main.dart (uncomment lines 14 and 25)

# 4. Add Google Services plugin to android/app/build.gradle
# (Add: apply plugin: 'com.google.gms.google-services' at the end)

# 5. Run the app
flutter run

# 6. Check console for FCM token
# 7. Test with Firebase Console
```

---

## 📝 NEXT STEPS

1. **Run `flutterfire configure`** (5 min)
2. **Update main.dart** (1 min)
3. **Update Android build files** (2 min)
4. **Test notifications** (5 min)
5. **Set up backend** (30 min - optional for now)

**Total Time**: ~15 minutes for basic setup

---

**Ready to configure?** Just run the commands above and you'll have push notifications working! 🚀
