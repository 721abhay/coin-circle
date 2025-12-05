# 🚀 Push Notifications - Simple Setup Steps

**Follow these steps in order** (15 minutes total)

---

## Step 1: Install FlutterFire CLI (2 min)

```powershell
dart pub global activate flutterfire_cli
```

Wait for installation to complete.

---

## Step 2: Configure Firebase (3 min)

```powershell
cd "c:\Users\ABHAY\coin circle\coin_circle"
flutterfire configure
```

**What to do**:
1. Browser will open
2. Select your Firebase project (or create new one)
3. Choose **Android** platform
4. Press Enter to confirm

**Result**: Creates `lib/firebase_options.dart`

---

## Step 3: Update main.dart (1 min)

Open `lib/main.dart` and make these 2 changes:

**Line 14** - Uncomment:
```dart
// BEFORE:
// import 'firebase_options.dart';

// AFTER:
import 'firebase_options.dart';
```

**Line 25** - Uncomment:
```dart
// BEFORE:
  // options: DefaultFirebaseOptions.currentPlatform,

// AFTER:
  options: DefaultFirebaseOptions.currentPlatform,
```

---

## Step 4: Update Android Build Files (2 min)

### 4a. Update `android/build.gradle`

Find the `buildscript` section and add this line in `dependencies`:

```gradle
buildscript {
    dependencies {
        // ... existing dependencies
        classpath 'com.google.gms:google-services:4.4.0'  // ← ADD THIS
    }
}
```

### 4b. Update `android/app/build.gradle`

Add this line **at the very end** of the file:

```gradle
apply plugin: 'com.google.gms.google-services'  // ← ADD THIS AT THE END
```

---

## Step 5: Run Database Migration (2 min)

1. Open **Supabase Dashboard**
2. Go to **SQL Editor**
3. Click **New Query**
4. Copy and paste this SQL:

```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
```

5. Click **Run**

---

## Step 6: Test It! (5 min)

```powershell
flutter run
```

**Check the console output**. You should see:

```
✅ Firebase initialized successfully
✅ User granted notification permission
📱 FCM Token: eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
✅ FCM token saved to database
✅ Push Notifications initialized successfully
```

---

## Step 7: Send Test Notification (Optional)

1. Go to **Firebase Console** → **Cloud Messaging**
2. Click **"Send your first message"**
3. Enter:
   - **Title**: "Test Notification"
   - **Text**: "This works!"
4. Click **"Send test message"**
5. Paste your **FCM token** (from Step 6 console output)
6. Click **"Test"**

**You should receive the notification!** 🎉

---

## ✅ Checklist

- [ ] FlutterFire CLI installed
- [ ] `flutterfire configure` completed
- [ ] `lib/firebase_options.dart` created
- [ ] `lib/main.dart` updated (2 lines uncommented)
- [ ] `android/build.gradle` updated (Google Services added)
- [ ] `android/app/build.gradle` updated (plugin applied)
- [ ] Database migration run (fcm_token column added)
- [ ] App runs successfully
- [ ] FCM token printed in console
- [ ] Test notification received

---

## 🐛 Troubleshooting

### "Firebase not initialized"
→ Make sure you uncommented both lines in main.dart

### "Google Services plugin not found"
→ Check android/build.gradle has the classpath

### "No FCM token"
→ Check notification permissions granted

### Build fails
→ Run: `flutter clean && flutter pub get`

---

## 📝 What's Next?

After setup works:
- Notifications will be saved to database ✅
- Local notifications will show ✅
- Push notifications will work ✅
- Test with Firebase Console ✅

For production:
- Set up Supabase Edge Function for automatic push
- See `PUSH_NOTIFICATIONS_SETUP.md` for details

---

**Need help?** Check `PUSH_NOTIFICATIONS_SETUP.md` for detailed guide!
