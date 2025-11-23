-- ============================================
-- Coin Circle - Database Reset Script
-- ============================================
-- WARNING: THIS WILL DELETE ALL DATA IN YOUR DATABASE!
-- Use this only if you want to start fresh.
-- ============================================

-- 1. Drop Triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_profile_created ON profiles;
DROP TRIGGER IF EXISTS on_pool_member_added ON pool_members;
DROP TRIGGER IF EXISTS on_pool_member_removed ON pool_members;
DROP TRIGGER IF EXISTS on_transaction_completed ON transactions;
DROP TRIGGER IF EXISTS on_winner_selected ON winner_history;
DROP TRIGGER IF EXISTS on_notification_read ON notifications;

-- 2. Drop Functions
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.handle_new_profile();
DROP FUNCTION IF EXISTS public.update_pool_member_count();
DROP FUNCTION IF EXISTS public.handle_transaction_completion();
DROP FUNCTION IF EXISTS public.handle_winner_selection();
DROP FUNCTION IF EXISTS public.handle_notification_read();
DROP FUNCTION IF EXISTS public.send_notification(UUID, TEXT, TEXT, notification_type_enum, notification_category_enum, TEXT, JSONB);
DROP FUNCTION IF EXISTS public.get_highest_bid(UUID, INTEGER);
DROP FUNCTION IF EXISTS public.mark_losing_bids(UUID, INTEGER, UUID);
DROP FUNCTION IF EXISTS public.handle_updated_at();

-- 3. Drop Tables (Order matters due to foreign keys)
DROP TABLE IF EXISTS bids CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS winner_history CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS pool_members CASCADE;
DROP TABLE IF EXISTS pools CASCADE;
DROP TABLE IF EXISTS wallets CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- 4. Drop Types/Enums
DROP TYPE IF EXISTS pool_type_enum CASCADE;
DROP TYPE IF EXISTS pool_status_enum CASCADE;
DROP TYPE IF EXISTS pool_privacy_enum CASCADE;
DROP TYPE IF EXISTS frequency_enum CASCADE;
DROP TYPE IF EXISTS member_role_enum CASCADE;
DROP TYPE IF EXISTS member_status_enum CASCADE;
DROP TYPE IF EXISTS payment_status_enum CASCADE;
DROP TYPE IF EXISTS transaction_type_enum CASCADE;
DROP TYPE IF EXISTS transaction_status_enum CASCADE;
DROP TYPE IF EXISTS payment_method_enum CASCADE;
DROP TYPE IF EXISTS selection_method_enum CASCADE;
DROP TYPE IF EXISTS payout_status_enum CASCADE;
DROP TYPE IF EXISTS notification_type_enum CASCADE;
DROP TYPE IF EXISTS notification_category_enum CASCADE;
DROP TYPE IF EXISTS bid_status_enum CASCADE;

-- ============================================
-- Reset Complete
-- Now run 'complete_setup.sql' to recreate everything.
-- ============================================
