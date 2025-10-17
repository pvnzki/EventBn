-- 2FA Schema Updates for User Table
-- Add these columns to support Two-Factor Authentication

DO $$ 
BEGIN
    -- Add 2FA secret field to store TOTP secret
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'two_factor_secret') THEN
        ALTER TABLE public."User" ADD COLUMN two_factor_secret VARCHAR(255);
    END IF;

    -- Add 2FA enabled flag
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'two_factor_enabled') THEN
        ALTER TABLE public."User" ADD COLUMN two_factor_enabled BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add backup codes field (JSON array)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'two_factor_backup_codes') THEN
        ALTER TABLE public."User" ADD COLUMN two_factor_backup_codes JSONB;
    END IF;

    -- Add recovery codes used counter
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'two_factor_recovery_used') THEN
        ALTER TABLE public."User" ADD COLUMN two_factor_recovery_used INTEGER DEFAULT 0;
    END IF;

    -- Add last 2FA verification timestamp
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'last_two_factor_at') THEN
        ALTER TABLE public."User" ADD COLUMN last_two_factor_at TIMESTAMP WITH TIME ZONE;
    END IF;

END $$;

-- Create index for 2FA queries
CREATE INDEX IF NOT EXISTS idx_user_two_factor_enabled ON public."User" (two_factor_enabled) WHERE two_factor_enabled = true;

-- Comments for documentation
COMMENT ON COLUMN public."User".two_factor_secret IS 'TOTP secret key for 2FA (base32 encoded)';
COMMENT ON COLUMN public."User".two_factor_enabled IS 'Whether 2FA is enabled for this user';
COMMENT ON COLUMN public."User".two_factor_backup_codes IS 'JSON array of backup/recovery codes';
COMMENT ON COLUMN public."User".two_factor_recovery_used IS 'Number of recovery codes used';
COMMENT ON COLUMN public."User".last_two_factor_at IS 'Last successful 2FA verification timestamp';