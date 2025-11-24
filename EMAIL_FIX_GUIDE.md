# 🔧 SUPABASE EMAIL CONFIGURATION FIX

## Problem: OTP emails not arriving during signup

### Solution: Disable email confirmation for development

1. Go to **Supabase Dashboard**
2. Click on **Authentication** in left sidebar
3. Click on **Providers**
4. Find **Email** provider
5. **Disable** "Confirm email" toggle
6. Click **Save**

### Alternative: Configure Email Provider

If you want emails to work:

1. Go to **Authentication** → **Email Templates**
2. Click **Settings** (gear icon)
3. Configure SMTP settings:
   - **SMTP Host**: smtp.gmail.com (for Gmail)
   - **SMTP Port**: 587
   - **SMTP User**: your-email@gmail.com
   - **SMTP Password**: your-app-password
   - **Sender Email**: your-email@gmail.com
   - **Sender Name**: Coin Circle

### For Gmail App Password:
1. Go to Google Account Settings
2. Security → 2-Step Verification
3. App Passwords → Generate new
4. Use that password in SMTP settings

---

## ✅ Quick Fix (Recommended for now):

**Just disable email confirmation** - users can register without OTP verification during development.

In production, you'll need proper SMTP configured.
