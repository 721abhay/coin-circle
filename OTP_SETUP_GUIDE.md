# 📧 OTP EMAIL VERIFICATION SETUP

## ✅ CHANGES MADE

I've updated your app to use **OTP (6-digit code)** instead of email confirmation links.

### **New Features:**
1. ✅ OTP verification screen created
2. ✅ 6-digit code input
3. ✅ Resend OTP button
4. ✅ Auto-navigation after signup

---

## 🔧 SUPABASE CONFIGURATION (REQUIRED)

### **Step 1: Switch to OTP Mode**

1. Go to **Supabase Dashboard**: https://supabase.com
2. Click **Authentication** → **Providers**
3. Click **Email** provider
4. Find **"Email Confirmation"** section
5. Change dropdown from **"Confirm via email link"** to **"Confirm via OTP"**
6. Click **Save**

### **Step 2: Configure SMTP (So emails actually send)**

You need to configure email sending. Choose one:

#### **Option A: Gmail (Quick Setup)**

1. Get Gmail App Password:
   - Go to https://myaccount.google.com/apppasswords
   - Generate password for "Coin Circle"
   - Copy the 16-character code

2. In Supabase Dashboard:
   - Go to **Authentication** → **Email Templates**
   - Click **Settings** (gear icon)
   - Fill in:
     ```
     SMTP Host: smtp.gmail.com
     SMTP Port: 587
     SMTP User: your-email@gmail.com
     SMTP Password: [16-char app password]
     Sender Email: your-email@gmail.com
     Sender Name: Coin Circle
     ```
   - Click **Save**

#### **Option B: Use Supabase Default**

- Supabase has built-in email
- Limited to 4 emails/hour on free tier
- Emails might go to spam
- No setup needed, just enable OTP mode

---

## 🧪 HOW IT WORKS NOW

### **User Registration Flow:**

1. User fills signup form
2. Clicks "Sign Up"
3. **NEW**: Redirected to OTP screen
4. Receives email with **6-digit code**
5. Enters code in app
6. Email verified ✅
7. Redirected to home

### **OTP Screen Features:**

- Large 6-digit input field
- "Verify" button
- "Resend OTP" button
- Shows email address
- Spam folder reminder

---

## 📱 TEST THE NEW FLOW

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Register new user**:
   - Name: Test User
   - Email: your-real-email@gmail.com
   - Phone: 9876543210
   - Password: Test@123

3. **Check your email**:
   - Subject: "Confirm Your Signup"
   - Body: 6-digit OTP code
   - Check spam if not in inbox

4. **Enter OTP in app**:
   - Type the 6-digit code
   - Click "Verify"
   - Should redirect to home

---

## 🎯 WHAT YOU NEED TO DO

### **CRITICAL (Do Now):**

1. **Go to Supabase Dashboard**
2. **Authentication** → **Providers** → **Email**
3. **Change to "Confirm via OTP"**
4. **Save**

### **IMPORTANT (For emails to work):**

5. **Configure SMTP** (Gmail or SendGrid)
6. **Test with your real email**

### **OPTIONAL:**

7. Customize OTP email template
8. Set OTP expiry time (default: 1 hour)

---

## 📧 EMAIL TEMPLATE

The OTP email will look like:

```
Subject: Confirm Your Signup

Your verification code is: 123456

This code will expire in 1 hour.

If you didn't request this, please ignore this email.
```

You can customize this in:
**Authentication** → **Email Templates** → **Confirm Signup**

---

## ⚠️ TROUBLESHOOTING

### **Not receiving OTP emails?**

1. **Check spam folder**
2. **Verify SMTP is configured** (Authentication → Email Templates → Settings)
3. **Check Supabase Logs** (Dashboard → Logs → Edge Logs)
4. **Try with different email** (Gmail, Yahoo, etc.)

### **"Invalid OTP" error?**

1. **Check if code expired** (default: 1 hour)
2. **Try resending** (click "Resend OTP")
3. **Make sure you're using the latest code**

### **Email goes to spam?**

1. **Add sender to contacts**
2. **Mark as "Not Spam"**
3. **Use professional SMTP** (SendGrid, AWS SES)

---

## 🚀 NEXT STEPS

After OTP is working:

1. ✅ Test full registration flow
2. ✅ Test OTP resend
3. ✅ Test with multiple email providers
4. ✅ Customize email template
5. ✅ Set up professional SMTP for production

---

## 📊 COMPARISON

| Feature | Email Link | OTP Code |
|---------|-----------|----------|
| User Experience | Click link | Type 6 digits |
| Security | Medium | High |
| Mobile Friendly | No | Yes |
| Works Offline | No | Yes (after receiving) |
| Expiry | 24 hours | 1 hour |
| **Your Choice** | ❌ | ✅ |

---

**Status**: ✅ OTP verification implemented
**Action Required**: Configure Supabase to use OTP mode
**Time**: 5 minutes

Run the app and test it! 🎉
