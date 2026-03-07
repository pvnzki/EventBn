-- Notification System Schema Migration
-- EventBn In-App Notifications (Observer Pattern via RabbitMQ)
--
-- IMPORTANT: This table lives in a SEPARATE "notification-service" database
-- on the same Neon project. It does NOT share the core-service database.
-- No cross-DB foreign keys — user_id is stored as a plain integer;
-- referential integrity is enforced at the application / RabbitMQ level.
--
-- To create the database on Neon (run once via psql connected to any existing DB
-- on the same Neon project branch):
--   CREATE DATABASE "notification-service";

CREATE TABLE IF NOT EXISTS "Notification" (
    notification_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,  -- references User in core-service DB (no cross-DB FK)
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,  -- ticket_purchased, payment_confirmed, event_created, event_updated, event_cancelled, event_reminder
    data JSONB DEFAULT '{}',    -- deep-link payload: { eventId, ticketId, paymentId, etc }
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fetching user's notifications (most common query)
CREATE INDEX IF NOT EXISTS idx_notification_user_id ON "Notification"(user_id);

-- Partial index for fast unread count queries
CREATE INDEX IF NOT EXISTS idx_notification_user_unread ON "Notification"(user_id, is_read) WHERE is_read = FALSE;

-- Index for ordering by created_at descending
CREATE INDEX IF NOT EXISTS idx_notification_created_at ON "Notification"(created_at DESC);

-- Index for type-based filtering
CREATE INDEX IF NOT EXISTS idx_notification_type ON "Notification"(type);
