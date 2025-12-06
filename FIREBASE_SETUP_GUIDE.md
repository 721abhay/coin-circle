# 🔥 Firebase Cloud Messaging Setup Guide

## Why Firebase Cloud Messaging (FCM)?
- ✅ **100% FREE** (unlimited notifications)
- ✅ Works when app is **closed or in background**
- ✅ Industry standard used by WhatsApp, Instagram, etc.
- ✅ Supports Android & iOS
- ✅ Better battery life than polling

## Step 1: Create Firebase Project (5 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `coin-circle`
4. Disable Google Analytics (optional)
5. Click **"Create project"**

## Step 2: Add Android App to Firebase

1. In Firebase Console, click **Android icon** (⚙️)
2. Enter package name: `com.example.coin_circle`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

## Step 3: Configure Android

### 3.1 Update `android/build.gradle`
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### 3.2 Update `android/app/build.gradle.kts`
Add at the **very bottom** of the file:
```kotlin
apply(plugin = "com.google.gms.google-services")
```

### 3.3 Update `AndroidManifest.xml`
Add inside `<application>` tag:
```xml
        <!-- Firebase Cloud Messaging -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="coin_circle_notifications" />
        
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
```

## Step 4: Update Database (Add FCM Token Column)

Run this in **Supabase SQL Editor**:
```sql
-- Add fcm_token column to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token 
ON profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;
```

## Step 5: Initialize in Your App

The code is already added! Just run:
```bash
flutter pub get
flutter run
```

## Step 6: Test Notifications

### Option A: From Firebase Console (Easy)
1. Go to Firebase Console > **Cloud Messaging**
2. Click **"Send your first message"**
3. Enter title & body
4. Click **"Send test message"**
5. Paste your FCM token (check console logs)

### Option B: From Your Backend (Production)
You'll need to create a backend service (Node.js, Python, etc.) that uses Firebase Admin SDK.

Example Node.js code:
```javascript
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function sendNotification(fcmToken, title, body, data) {
  const message = {
    notification: { title, body },
    data: data,
    token: fcmToken
  };
  
  await admin.messaging().send(message);
}
```

## Comparison: Local vs Cloud Notifications

| Feature | Local (Current) | Cloud (FCM) |
|---------|----------------|-------------|
| **Cost** | Free | Free |
| **Works when app closed** | ❌ No | ✅ Yes |
| **Battery efficient** | ❌ No (polling) | ✅ Yes |
| **Delivery guarantee** | ❌ No | ✅ Yes |
| **Setup complexity** | Easy | Medium |
| **Best for** | In-app only | Production apps |

## Next Steps

1. ✅ Dependencies added
2. ✅ Service created
3. ⏳ **YOU NEED TO DO**: Firebase setup (Steps 1-3 above)
4. ⏳ **YOU NEED TO DO**: Run SQL (Step 4)
5. ⏳ **YOU NEED TO DO**: `flutter pub get`

## Troubleshooting

### "MissingPluginException"
- Run `flutter clean && flutter pub get`
- Restart your IDE

### "google-services.json not found"
- Make sure file is in `android/app/` folder
- Check file name is exactly `google-services.json`

### Notifications not received
- Check FCM token is saved in database
- Check app has notification permission
- Test from Firebase Console first

## Need Help?
- [Firebase Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/messaging/overview)
