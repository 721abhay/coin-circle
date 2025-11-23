-- Migration: Payment Reminder Automation
-- Description: Daily scheduled function to send payment reminder notifications for overdue contributions.

-- Create a function that checks for contributions due within the next 2 days and sends notifications.
CREATE OR REPLACE FUNCTION send_payment_reminders()
RETURNS void AS ₹₹
DECLARE
    rec RECORD;
    notification_payload JSONB;
BEGIN
    FOR rec IN
        SELECT 
            p.id AS pool_id,
            u.id AS user_id,
            u.email,
            get_contribution_status(p.id, u.id) AS status
        FROM pools p
        JOIN pool_members pm ON pm.pool_id = p.id
        JOIN profiles u ON u.id = pm.user_id
        WHERE p.contribution_frequency IS NOT NULL
    LOOP
        -- status is a composite type from get_contribution_status
        IF NOT rec.status.is_paid AND rec.status.due_date <= (NOW() + INTERVAL '2 days') THEN
            notification_payload := jsonb_build_object(
                'type', 'payment_reminder',
                'title', 'Payment Due Soon',
                'message', format('Your contribution for pool %s is due on %s.', rec.pool_id::text, to_char(rec.status.due_date, 'YYYY-MM-DD')),
                'user_id', rec.user_id,
                'pool_id', rec.pool_id,
                'due_date', rec.status.due_date
            );
            PERFORM pg_notify('notifications', notification_payload::text);
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Schedule the function to run daily at 02:00 AM UTC.
-- Supabase uses pg_cron; ensure the extension is enabled.
SELECT cron.schedule('daily_payment_reminders', '0 2 * * *', $$SELECT send_payment_reminders();$$);

-- Grant execute rights to the anon role.
GRANT EXECUTE ON FUNCTION send_payment_reminders() TO anon;
