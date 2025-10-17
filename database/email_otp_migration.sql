-- Add email OTP support for 2FA
ALTER TABLE public."User" 
ADD COLUMN IF NOT EXISTS two_factor_method VARCHAR(10) DEFAULT 'app',
ADD COLUMN IF NOT EXISTS email_otp_code VARCHAR(6),
ADD COLUMN IF NOT EXISTS email_otp_expires_at TIMESTAMP;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_user_email_otp_expires_at ON public."User"(email_otp_expires_at);

-- Update existing users to have default 2FA method
UPDATE public."User" SET two_factor_method = 'app' WHERE two_factor_enabled = true AND two_factor_method IS NULL;