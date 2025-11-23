-- Migration: Enable pg_cron extension for scheduled jobs
-- Description: Enables the pg_cron extension in Supabase to allow scheduled functions like payment reminders.

CREATE EXTENSION IF NOT EXISTS pg_cron;
