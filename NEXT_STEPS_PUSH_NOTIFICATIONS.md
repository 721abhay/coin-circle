# 🎯 NEXT STEPS - Push Notifications Setup

## ✅ What's Done:

1. ✅ FlutterFire CLI installed
2. ✅ Firebase configuration extracted from google-services.json
3. ✅ `firebase_options_TEMPLATE.dart` created with your values
4. ✅ `main.dart` updated (Firebase lines uncommented)

---

## 📝 What You Need to Do Now:

### Step 1: Rename the Template File (30 seconds)

**Rename this file**:
```
lib/firebase_options_TEMPLATE.dart
```

**To**:
```
lib/firebase_options.dart
```

**How**: Right-click the file in VS Code → Rename → Remove `_TEMPLATE`

---

### Step 2: Update Android Build Files (2 minutes)

#### 2a. Update `android/build.gradle`

Open `android/build.gradle` and find the `buildscript` section.

Add this line in the `dependencies` block:

```gradle
buildscript {
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'  // existing
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"  // existing
        classpath 'com.google.gms:google-services:4.4.0'  // ← ADD THIS LINE
    }
}
```

#### 2b. Update `android/app/build.gradle`

Open `android/app/build.gradle` and add this line **at the very end** of the file:

```gradle
apply plugin: 'com.google.gms.google-services'  // ← ADD THIS AT THE END
```

---

### Step 3: Run Database Migration (2 minutes)

1. Open **Supabase Dashboard** (https://supabase.com)
2. Go to your project
3. Click **SQL Editor** in the left menu
4. Click **New Query**
5. Copy and paste this SQL:

```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON profiles(fcm_token) WHERE fcm_token IS NOT NULL;
```

6. Click **Run** (or press F5)

---

### Step 4: Test It! (5 minutes)

```powershell
flutter clean
flutter pub get
flutter run
```

**Watch the console output**. You should see:

```
✅ Firebase initialized successfully
✅ User granted notification permission
📱 FCM Token: eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
✅ FCM token saved to database
✅ Push Notifications initialized successfully
```

---

### Step 5: Send Test Notification (Optional)

1. Go to **Firebase Console** (https://console.firebase.google.com)
2. Select your project: **coin-circle**
3. Click **Cloud Messaging** in the left menu
4. Click **"Send your first message"**
5. Enter:
   - **Notification title**: "Test from Firebase"
   - **Notification text**: "Push notifications are working!"
6. Click **"Send test message"**
7. Paste your **FCM token** (from Step 4 console output)
8. Click **"Test"**

**You should receive the notification!** 🎉

---

## 🐛 If You Get Errors:

### "firebase_options.dart not found"
→ Make sure you renamed `firebase_options_TEMPLATE.dart` to `firebase_options.dart`

### "Google Services plugin not found"
→ Check you added the classpath to `android/build.gradle`

### "Failed to apply plugin"
→ Check you added `apply plugin` at the END of `android/app/build.gradle`

### Build errors
→ Run: `flutter clean && flutter pub get`

---

## 📊 Your Firebase Configuration:

- **Project ID**: coin-circle
- **Project Number**: 518979386371
- **Package Name**: com.example.coin_circle
- **Storage Bucket**: coin-circle.firebasestorage.app

---

## ✅ Checklist:

- [ ] Rename `firebase_options_TEMPLATE.dart` to `firebase_options.dart`
- [ ] Update `android/build.gradle` (add Google Services classpath)
- [ ] Update `android/app/build.gradle` (add apply plugin at end)
- [ ] Run SQL migration in Supabase
- [ ] Run `flutter clean && flutter pub get`
- [ ] Run `flutter run`
- [ ] Check console for FCM token
- [ ] Test notification from Firebase Console

---

**Start with Step 1** (rename the file) and work your way down! 🚀

**Estimated Time**: 10 minutes total
