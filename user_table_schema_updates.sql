-- User Table Schema Updates for Payment Integration
-- Add these columns to your existing "User" table in Supabase
-- Note: Your table name is "User" (with quotes and capital U)

-- First, check if columns already exist and add them if they don't
DO $$ 
BEGIN
    -- phone_number already exists in your schema, so we skip this
    -- IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    --                WHERE table_name = 'User' AND column_name = 'phone_number') THEN
    --     ALTER TABLE public."User" ADD COLUMN phone_number VARCHAR(20);
    -- END IF;

    -- Add billing address fields
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'billing_address') THEN
        ALTER TABLE public."User" ADD COLUMN billing_address TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'billing_city') THEN
        ALTER TABLE public."User" ADD COLUMN billing_city VARCHAR(100);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'billing_state') THEN
        ALTER TABLE public."User" ADD COLUMN billing_state VARCHAR(100);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'billing_country') THEN
        ALTER TABLE public."User" ADD COLUMN billing_country VARCHAR(100) DEFAULT 'Sri Lanka';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'billing_postal_code') THEN
        ALTER TABLE public."User" ADD COLUMN billing_postal_code VARCHAR(20);
    END IF;

    -- Add profile completion status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'profile_completed') THEN
        ALTER TABLE public."User" ADD COLUMN profile_completed BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add date of birth (useful for age verification for certain events)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'date_of_birth') THEN
        ALTER TABLE public."User" ADD COLUMN date_of_birth DATE;
    END IF;

    -- Add emergency contact (useful for event bookings)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'emergency_contact_name') THEN
        ALTER TABLE public."User" ADD COLUMN emergency_contact_name VARCHAR(255);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'emergency_contact_phone') THEN
        ALTER TABLE public."User" ADD COLUMN emergency_contact_phone VARCHAR(20);
    END IF;

    -- Add emergency contact relationship
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'emergency_contact_relationship') THEN
        ALTER TABLE public."User" ADD COLUMN emergency_contact_relationship VARCHAR(100);
    END IF;

    -- Add preferences for marketing communications
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'marketing_emails_enabled') THEN
        ALTER TABLE public."User" ADD COLUMN marketing_emails_enabled BOOLEAN DEFAULT TRUE;
    END IF;

    -- Add event notifications preference
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'event_notifications_enabled') THEN
        ALTER TABLE public."User" ADD COLUMN event_notifications_enabled BOOLEAN DEFAULT TRUE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'User' AND column_name = 'sms_notifications_enabled') THEN
        ALTER TABLE public."User" ADD COLUMN sms_notifications_enabled BOOLEAN DEFAULT TRUE;
    END IF;

END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_User_phone_number ON public."User"(phone_number);
CREATE INDEX IF NOT EXISTS idx_User_billing_country ON public."User"(billing_country);
CREATE INDEX IF NOT EXISTS idx_User_profile_completed ON public."User"(profile_completed);

-- Add comments to document the new columns
COMMENT ON COLUMN public."User".phone_number IS 'User phone number for SMS notifications and payment verification';
COMMENT ON COLUMN public."User".billing_address IS 'Street address for billing and payment processing';
COMMENT ON COLUMN public."User".billing_city IS 'City for billing address';
COMMENT ON COLUMN public."User".billing_state IS 'State/Province for billing address';
COMMENT ON COLUMN public."User".billing_country IS 'Country for billing address';
COMMENT ON COLUMN public."User".billing_postal_code IS 'Postal/ZIP code for billing address';
COMMENT ON COLUMN public."User".profile_completed IS 'Flag to indicate if user has completed their profile setup';
COMMENT ON COLUMN public."User".date_of_birth IS 'User date of birth for age verification';
COMMENT ON COLUMN public."User".emergency_contact_name IS 'Emergency contact name for event safety';
COMMENT ON COLUMN public."User".emergency_contact_phone IS 'Emergency contact phone number';
COMMENT ON COLUMN public."User".emergency_contact_relationship IS 'Relationship to emergency contact (parent, spouse, etc.)';
COMMENT ON COLUMN public."User".marketing_emails_enabled IS 'User preference for receiving marketing emails';
COMMENT ON COLUMN public."User".event_notifications_enabled IS 'User preference for event-related notifications';
COMMENT ON COLUMN public."User".sms_notifications_enabled IS 'User preference for receiving SMS notifications';

-- Optional: Update existing users to have profile_completed = false
-- This will prompt them to complete their profile on next login
UPDATE public."User" SET profile_completed = FALSE WHERE profile_completed IS NULL;