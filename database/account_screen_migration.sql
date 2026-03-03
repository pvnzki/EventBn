-- ─────────────────────────────────────────────────────────────────────────────
-- Account Screen Schema Updates
-- Adds cover_photo and gender columns to the "User" table.
-- Safe to run multiple times (IF NOT EXISTS guards).
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
    -- cover_photo: URL of the user's cover/banner photo
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'User' AND column_name = 'cover_photo'
    ) THEN
        ALTER TABLE public."User" ADD COLUMN cover_photo TEXT;
        RAISE NOTICE 'Added cover_photo column';
    ELSE
        RAISE NOTICE 'cover_photo column already exists';
    END IF;

    -- gender: Male / Female / Other / Prefer not to say
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'User' AND column_name = 'gender'
    ) THEN
        ALTER TABLE public."User" ADD COLUMN gender VARCHAR(30);
        RAISE NOTICE 'Added gender column';
    ELSE
        RAISE NOTICE 'gender column already exists';
    END IF;
END $$;
