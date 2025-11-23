-- Create audit_logs table
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    record_id UUID NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_by UUID REFERENCES auth.users(id),
    changed_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on audit_logs
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Admins can view all logs (assuming an admin role exists or for now just service role)
-- For now, let's allow users to see their own logs if 'changed_by' matches, 
-- but audit logs are usually internal. Let's restrict to service_role only for now 
-- or specific admin users. 
-- Since we don't have a robust admin system yet, we'll leave it restricted (no policies = deny all by default for anon/authenticated).
-- This means only the service role (backend/dashboard) can read them, which is secure.

-- Function to handle audit logging
CREATE OR REPLACE FUNCTION public.log_audit_event()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.audit_logs (
        table_name,
        operation,
        record_id,
        old_data,
        new_data,
        changed_by
    )
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        CASE
            WHEN TG_OP = 'DELETE' THEN OLD.id
            ELSE NEW.id
        END,
        CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE to_jsonb(OLD) END,
        CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE to_jsonb(NEW) END,
        auth.uid()
    );
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers for sensitive tables

-- Wallets
DROP TRIGGER IF EXISTS audit_wallets_trigger ON public.wallets;
CREATE TRIGGER audit_wallets_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.wallets
FOR EACH ROW EXECUTE FUNCTION public.log_audit_event();

-- Transactions
DROP TRIGGER IF EXISTS audit_transactions_trigger ON public.transactions;
CREATE TRIGGER audit_transactions_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.transactions
FOR EACH ROW EXECUTE FUNCTION public.log_audit_event();

-- Pools
DROP TRIGGER IF EXISTS audit_pools_trigger ON public.pools;
CREATE TRIGGER audit_pools_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.pools
FOR EACH ROW EXECUTE FUNCTION public.log_audit_event();

-- Pool Members
DROP TRIGGER IF EXISTS audit_pool_members_trigger ON public.pool_members;
CREATE TRIGGER audit_pool_members_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.pool_members
FOR EACH ROW EXECUTE FUNCTION public.log_audit_event();
