# Google Services JSON Validation Guide

## ❌ Error: "Malformed root json"

This means your `google-services.json` file has a syntax error.

## ✅ How to Fix

### Option 1: Re-download from Firebase (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the **Settings gear** ⚙️ > **Project settings**
4. Scroll to "Your apps" section
5. Find your Android app
6. Click **Download google-services.json**
7. **Replace** the file at: `android/app/google-services.json`

### Option 2: Validate Current File
Check for these common issues:

1. **Missing commas** between objects
2. **Extra commas** at the end of arrays
3. **Unmatched brackets** `{ }` or `[ ]`
4. **Incorrect quotes** (must use double quotes `"`, not single `'`)

### Required Structure
```json
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "your-project-id",
    "storage_bucket": "your-project.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123:android:abc",
        "android_client_info": {
          "package_name": "com.example.coin_circle"
        }
      },
      "oauth_client": [...],
      "api_key": [...],
      "services": {...}
    }
  ],
  "configuration_version": "1"
}
```

### Critical Checks
- ✅ `package_name` MUST be `"com.example.coin_circle"`
- ✅ File MUST be valid JSON
- ✅ No trailing commas
- ✅ All brackets matched

## 🔧 Quick Fix

**Easiest solution**: Delete the current file and re-download from Firebase Console.

The file should be **exactly** as Firebase generates it - don't edit it manually.

## 🧪 Test JSON Validity

You can paste your JSON here to validate:
https://jsonlint.com/

If it shows errors, re-download from Firebase.
