# Supabase Setup Guide - Coin Circle

This guide will walk you through setting up Supabase for the Coin Circle app.

## 📋 Prerequisites

- A web browser
- Email address for Supabase account
- 10 minutes of your time

---

## Step 1: Create Supabase Account

1. Go to [https://supabase.com](https://supabase.com)
2. Click **"Start your project"** or **"Sign Up"**
3. Sign up with:
   - GitHub account (recommended), OR
   - Email and password

---

## Step 2: Create New Project

1. After logging in, click **"New Project"**
2. Fill in the project details:
   - **Name**: `coin-circle` (or any name you prefer)
   - **Database Password**: Create a strong password (save this!)
   - **Region**: Choose closest to your location (e.g., `ap-south-1` for India)
   - **Pricing Plan**: Select **"Free"** (perfect for 10,000+ users)

3. Click **"Create new project"**
4. Wait 2-3 minutes for the project to be provisioned

---

## Step 3: Get Your API Credentials

1. Once the project is ready, go to **Settings** (gear icon in sidebar)
2. Click on **API** in the settings menu
3. You'll see two important values:

   ### Project URL
   ```
   https://xxxxxxxxxxxxx.supabase.co
   ```
   
   ### Anon/Public Key (anon key)
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6...
   ```

4. **Copy these values** - you'll need them in the next step!

---

## Step 4: Configure Your Flutter App

1. Open your project folder: `c:\Users\ABHAY\coin circle\coin_circle`

2. Create a file named `.env` in the root directory (next to `pubspec.yaml`)

3. Add your Supabase credentials to the `.env` file:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

**Replace** `your-project-id` and `your-anon-key-here` with the values you copied in Step 3.

### Example `.env` file:
```env
SUPABASE_URL=https://abcdefghijklmnop.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYzODMxNjQwMCwiZXhwIjoxOTUzODkyNDAwfQ.abcdefghijklmnopqrstuvwxyz1234567890
```

> ⚠️ **Important**: Never commit the `.env` file to Git! It's already in `.gitignore`.

---

## Step 5: Run Database Migrations

Now we need to create the database tables. You have two options:

### Option A: Using Supabase SQL Editor (Recommended)

1. In your Supabase dashboard, click **SQL Editor** in the sidebar
2. Click **"New query"**
3. Open each migration file from `supabase/migrations/` folder:
   - `001_create_profiles.sql`
   - `002_create_wallets.sql`
   - `003_create_pools.sql`
   - `004_create_pool_members.sql`
   - `005_create_transactions.sql`
   - `006_create_winner_history.sql`
   - `007_create_notifications.sql`
   - `008_create_bids.sql`

4. Copy the contents of each file and paste into the SQL Editor
5. Click **"Run"** for each migration (in order!)
6. You should see "Success. No rows returned" for each one

### Option B: Using Supabase CLI (Advanced)

If you prefer using the command line:

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref your-project-id

# Run migrations
supabase db push
```

---

## Step 6: Verify Database Setup

1. In Supabase dashboard, click **Table Editor** in the sidebar
2. You should see all 8 tables:
   - ✅ profiles
   - ✅ wallets
   - ✅ pools
   - ✅ pool_members
   - ✅ transactions
   - ✅ winner_history
   - ✅ notifications
   - ✅ bids

3. Click on each table to verify the columns are created correctly

---

## Step 7: Enable Realtime (Optional but Recommended)

1. Go to **Database** → **Replication** in the sidebar
2. Enable replication for these tables:
   - ✅ pools
   - ✅ pool_members
   - ✅ transactions
   - ✅ notifications
   - ✅ winner_history

This allows real-time updates in your Flutter app!

---

## Step 8: Test the Connection

1. Open a terminal in your project folder
2. Run the Flutter app:

```bash
cd "c:\Users\ABHAY\coin circle\coin_circle"
flutter run
```

3. Check the console output. You should see:
   ```
   ✅ Supabase initialized successfully
   ```

4. If you see an error, double-check your `.env` file credentials.

---

## Step 9: Configure Authentication Providers (Optional)

### For Google Sign-In:

1. Go to **Authentication** → **Providers** in Supabase dashboard
2. Enable **Google** provider
3. Follow the instructions to set up Google OAuth:
   - Create a project in [Google Cloud Console](https://console.cloud.google.com)
   - Enable Google+ API
   - Create OAuth 2.0 credentials
   - Add authorized redirect URIs from Supabase
   - Copy Client ID and Client Secret to Supabase

### For Apple Sign-In:

1. Enable **Apple** provider in Supabase
2. Follow Apple's setup instructions
3. Add your Apple Service ID and Key

---

## 🎉 Setup Complete!

Your Supabase backend is now ready! Here's what you have:

✅ Database with 8 tables
✅ Row Level Security enabled
✅ Automatic triggers for data integrity
✅ Authentication ready
✅ Real-time subscriptions (if enabled)
✅ Flutter app connected

---

## Next Steps

1. **Test Authentication**: Try signing up a new user
2. **Create a Pool**: Test pool creation functionality
3. **Join a Pool**: Test pool joining
4. **Make a Transaction**: Test wallet operations

---

## Troubleshooting

### Error: "Supabase credentials not found"
- Make sure `.env` file exists in the project root
- Check that `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set correctly
- Restart the Flutter app after creating `.env`

### Error: "Table does not exist"
- Run all migration files in order
- Check SQL Editor for any errors
- Verify tables exist in Table Editor

### Error: "Row Level Security policy violation"
- Make sure RLS policies are created (they're in the migration files)
- Check that you're authenticated when accessing protected data

---

## Useful Supabase Dashboard Links

- **SQL Editor**: Write and run SQL queries
- **Table Editor**: View and edit table data
- **Authentication**: Manage users
- **Storage**: Upload files (for profile pictures, etc.)
- **Database**: View schema, run migrations
- **API Docs**: Auto-generated API documentation

---

## Free Tier Limits

Your Supabase free tier includes:

- ✅ 500 MB database storage
- ✅ 1 GB file storage
- ✅ 2 GB bandwidth per month
- ✅ 50,000 monthly active users
- ✅ Unlimited API requests
- ✅ Unlimited database reads/writes
- ✅ 2 million Edge Function invocations

**Perfect for 10,000+ users!** 🚀

---

## Security Best Practices

1. ✅ Never commit `.env` file to Git
2. ✅ Use Row Level Security (already enabled)
3. ✅ Validate user input in your Flutter app
4. ✅ Use HTTPS only (Supabase enforces this)
5. ✅ Regularly update dependencies
6. ✅ Monitor usage in Supabase dashboard

---

## Support

- **Supabase Docs**: [https://supabase.com/docs](https://supabase.com/docs)
- **Flutter Supabase**: [https://supabase.com/docs/guides/getting-started/tutorials/with-flutter](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- **Community**: [https://github.com/supabase/supabase/discussions](https://github.com/supabase/supabase/discussions)

---

**Happy coding!** 🎉
