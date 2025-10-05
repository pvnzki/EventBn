-- ================================================================
-- SPINNING WHEEL GAME DATABASE SCHEMAS FOR SUPABASE
-- TEMU-Style Mini Game System
-- ================================================================

-- 1. WHEEL CONFIGURATION TABLE
-- Defines different wheel types, segments, and prizes
CREATE TABLE wheel_configurations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  wheel_name VARCHAR(100) NOT NULL,
  wheel_type VARCHAR(50) DEFAULT 'daily_spin',
  is_active BOOLEAN DEFAULT true,
  min_user_level INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. WHEEL SEGMENTS TABLE
-- Individual segments on the spinning wheel with prizes
CREATE TABLE wheel_segments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  wheel_configuration_id UUID REFERENCES wheel_configurations(id) ON DELETE CASCADE,
  segment_order INTEGER NOT NULL, -- Position on wheel (0-7 for 8 segments)
  prize_type VARCHAR(50) NOT NULL, -- 'coins', 'freespins', 'discount', 'voucher', 'nothing'
  prize_value INTEGER NOT NULL, -- Amount of prize (coins, percentage, etc.)
  prize_label VARCHAR(100) NOT NULL, -- Display text like "$300", "60 freespins"
  win_probability DECIMAL(5,4) NOT NULL, -- 0.0001 to 1.0000 (0.01% to 100%)
  segment_color VARCHAR(20) NOT NULL, -- Hex color for UI
  icon_name VARCHAR(50), -- Icon identifier for the prize
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. USER GAME STATS TABLE
-- Track user's overall game statistics
CREATE TABLE user_game_stats (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id INTEGER NOT NULL, -- References your existing users table
  total_spins INTEGER DEFAULT 0,
  total_wins INTEGER DEFAULT 0,
  total_coins_won INTEGER DEFAULT 0,
  total_freespins_won INTEGER DEFAULT 0,
  current_coins INTEGER DEFAULT 0,
  current_freespins INTEGER DEFAULT 3, -- Start with 3 free spins
  last_free_spin_date DATE,
  consecutive_days INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  experience_points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 4. USER SPIN HISTORY TABLE
-- Record every spin attempt and result
CREATE TABLE user_spin_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id INTEGER NOT NULL,
  wheel_configuration_id UUID REFERENCES wheel_configurations(id),
  segment_won_id UUID REFERENCES wheel_segments(id),
  prize_type VARCHAR(50) NOT NULL,
  prize_value INTEGER NOT NULL,
  prize_label VARCHAR(100) NOT NULL,
  spin_type VARCHAR(30) DEFAULT 'free', -- 'free', 'purchased', 'bonus'
  spin_result_angle DECIMAL(6,2), -- Final wheel angle for animation
  is_big_win BOOLEAN DEFAULT false, -- For special animations
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. DAILY CHALLENGES TABLE
-- Special challenges that give extra spins
CREATE TABLE daily_challenges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  challenge_name VARCHAR(100) NOT NULL,
  challenge_description TEXT NOT NULL,
  challenge_type VARCHAR(50) NOT NULL, -- 'login', 'post', 'share', 'event_attend'
  required_count INTEGER DEFAULT 1,
  reward_type VARCHAR(50) DEFAULT 'freespins',
  reward_amount INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  start_date DATE NOT NULL,
  end_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. USER CHALLENGE PROGRESS TABLE
-- Track user progress on daily challenges
CREATE TABLE user_challenge_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id INTEGER NOT NULL,
  challenge_id UUID REFERENCES daily_challenges(id) ON DELETE CASCADE,
  current_progress INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  reward_claimed BOOLEAN DEFAULT false,
  completion_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, challenge_id)
);

-- 7. SPIN COOLDOWNS TABLE
-- Manage spin availability and cooldown timers
CREATE TABLE spin_cooldowns (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id INTEGER NOT NULL,
  cooldown_type VARCHAR(50) NOT NULL, -- 'daily_free', 'hourly_bonus', 'video_ad'
  last_used_at TIMESTAMP WITH TIME ZONE NOT NULL,
  next_available_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, cooldown_type)
);

-- 8. REWARD REDEMPTIONS TABLE
-- Track when users spend coins or redeem prizes
CREATE TABLE reward_redemptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id INTEGER NOT NULL,
  redemption_type VARCHAR(50) NOT NULL, -- 'discount_coupon', 'event_ticket', 'premium_feature'
  item_name VARCHAR(100) NOT NULL,
  coins_spent INTEGER NOT NULL,
  redemption_code VARCHAR(50),
  is_used BOOLEAN DEFAULT false,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================================
-- INDEXES FOR PERFORMANCE
-- ================================================================

-- User-based queries
CREATE INDEX idx_user_game_stats_user_id ON user_game_stats(user_id);
CREATE INDEX idx_user_spin_history_user_id ON user_spin_history(user_id);
CREATE INDEX idx_user_spin_history_created_at ON user_spin_history(created_at DESC);
CREATE INDEX idx_user_challenge_progress_user_id ON user_challenge_progress(user_id);
CREATE INDEX idx_spin_cooldowns_user_id ON spin_cooldowns(user_id);
CREATE INDEX idx_reward_redemptions_user_id ON reward_redemptions(user_id);

-- Game configuration queries
CREATE INDEX idx_wheel_segments_config_id ON wheel_segments(wheel_configuration_id);
CREATE INDEX idx_wheel_segments_order ON wheel_segments(wheel_configuration_id, segment_order);

-- Time-based queries
CREATE INDEX idx_daily_challenges_dates ON daily_challenges(start_date, end_date);
CREATE INDEX idx_spin_cooldowns_next_available ON spin_cooldowns(next_available_at);

-- ================================================================
-- INITIAL DATA SETUP
-- ================================================================

-- Insert default wheel configuration
INSERT INTO wheel_configurations (wheel_name, wheel_type, is_active) 
VALUES ('Daily Lucky Wheel', 'daily_spin', true);

-- Get the wheel configuration ID for segments (replace with actual UUID after creation)
-- INSERT INTO wheel_segments (wheel_configuration_id, segment_order, prize_type, prize_value, prize_label, win_probability, segment_color, icon_name) VALUES
-- Replace 'YOUR_WHEEL_CONFIG_ID' with the actual UUID from wheel_configurations table

-- Example segments (uncomment and replace UUID after creating wheel configuration):
/*
INSERT INTO wheel_segments (wheel_configuration_id, segment_order, prize_type, prize_value, prize_label, win_probability, segment_color, icon_name) VALUES
('YOUR_WHEEL_CONFIG_ID', 0, 'coins', 100, '100$', 0.2500, '#FF6B6B', 'coins'),
('YOUR_WHEEL_CONFIG_ID', 1, 'freespins', 5, '5 spins', 0.1500, '#4ECDC4', 'spin'),
('YOUR_WHEEL_CONFIG_ID', 2, 'coins', 300, '300$', 0.1500, '#45B7D1', 'coins'),
('YOUR_WHEEL_CONFIG_ID', 3, 'nothing', 0, 'Try Again', 0.2000, '#96CEB4', 'retry'),
('YOUR_WHEEL_CONFIG_ID', 4, 'coins', 200, '200$', 0.1500, '#FECA57', 'coins'),
('YOUR_WHEEL_CONFIG_ID', 5, 'freespins', 60, '60 freespins', 0.0300, '#FF9FF3', 'jackpot'),
('YOUR_WHEEL_CONFIG_ID', 6, 'coins', 500, '500$', 0.0500, '#54A0FF', 'coins'),
('YOUR_WHEEL_CONFIG_ID', 7, 'nothing', 0, 'Better Luck', 0.1200, '#5F27CD', 'retry');
*/

-- Insert sample daily challenges
INSERT INTO daily_challenges (challenge_name, challenge_description, challenge_type, required_count, reward_type, reward_amount, start_date) VALUES
('Daily Login Bonus', 'Login to the app every day', 'login', 1, 'freespins', 1, CURRENT_DATE),
('Social Butterfly', 'Create a post and share with friends', 'post', 1, 'freespins', 2, CURRENT_DATE),
('Event Explorer', 'Browse and check out 3 events', 'event_view', 3, 'freespins', 3, CURRENT_DATE);

-- ================================================================
-- FUNCTIONS AND TRIGGERS
-- ================================================================

-- Function to update user stats timestamp
CREATE OR REPLACE FUNCTION update_user_game_stats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user_game_stats
CREATE TRIGGER trigger_update_user_game_stats_updated_at
  BEFORE UPDATE ON user_game_stats
  FOR EACH ROW
  EXECUTE FUNCTION update_user_game_stats_updated_at();

-- Function to automatically create user game stats when user spins for first time
CREATE OR REPLACE FUNCTION create_user_game_stats_if_not_exists()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_game_stats (user_id, current_freespins)
  VALUES (NEW.user_id, 3)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create user stats on first spin
CREATE TRIGGER trigger_create_user_game_stats
  BEFORE INSERT ON user_spin_history
  FOR EACH ROW
  EXECUTE FUNCTION create_user_game_stats_if_not_exists();