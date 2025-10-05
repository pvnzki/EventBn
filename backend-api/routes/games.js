const express = require("express");
const router = express.Router();
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

// Helper function to parse user ID
function parseUserId(userIdString) {
  if (!userIdString) return null;

  // If it's already a number, return it
  if (typeof userIdString === "number") return userIdString;

  // If it's a string like "user_123", extract the number
  if (typeof userIdString === "string") {
    const match = userIdString.match(/^user_(\d+)$|^(\d+)$/);
    if (match) {
      return parseInt(match[1] || match[2], 10);
    }
  }

  return null;
}

// Get user's game statistics
router.get("/stats/:userId", async (req, res) => {
  try {
    const userIdParam = req.params.userId;
    const userId = parseUserId(userIdParam);

    if (!userId) {
      return res.status(400).json({ error: "Invalid user ID format" });
    }

    // Get or create user game stats
    let userStats = await prisma.$queryRaw`
      SELECT * FROM user_game_stats WHERE user_id = ${userId}
    `;

    if (!userStats || userStats.length === 0) {
      // Create initial stats for new user
      await prisma.$executeRaw`
        INSERT INTO user_game_stats (user_id, current_freespins, total_spins, total_wins, total_coins_won, total_freespins_won, current_coins, consecutive_days, level, experience_points)
        VALUES (${userId}, 3, 0, 0, 0, 0, 0, 0, 1, 0)
        ON CONFLICT (user_id) DO NOTHING
      `;

      userStats = await prisma.$queryRaw`
        SELECT * FROM user_game_stats WHERE user_id = ${userId}
      `;
    }

    res.json(userStats[0]);
  } catch (error) {
    console.error("Error fetching user game stats:", error);
    res.status(500).json({ error: "Failed to fetch user game stats" });
  }
});

// Get wheel configuration
router.get("/wheel-config", async (req, res) => {
  try {
    const wheelConfig = await prisma.$queryRaw`
      SELECT wc.*, ws.segment_order, ws.prize_type, ws.prize_value, ws.prize_label, 
             ws.win_probability, ws.segment_color, ws.icon_name
      FROM wheel_configurations wc
      LEFT JOIN wheel_segments ws ON wc.id = ws.wheel_configuration_id
      WHERE wc.is_active = true
      ORDER BY ws.segment_order
    `;

    if (!wheelConfig || wheelConfig.length === 0) {
      return res
        .status(404)
        .json({ error: "No active wheel configuration found" });
    }

    // Group segments by wheel configuration
    const result = {
      id: wheelConfig[0].id,
      wheel_name: wheelConfig[0].wheel_name,
      wheel_type: wheelConfig[0].wheel_type,
      segments: wheelConfig.map((item) => ({
        segment_order: item.segment_order,
        prize_type: item.prize_type,
        prize_value: item.prize_value,
        prize_label: item.prize_label,
        win_probability: parseFloat(item.win_probability),
        segment_color: item.segment_color,
        icon_name: item.icon_name,
      })),
    };

    res.json(result);
  } catch (error) {
    console.error("Error fetching wheel configuration:", error);
    res.status(500).json({ error: "Failed to fetch wheel configuration" });
  }
});

// Perform a spin
router.post("/spin", async (req, res) => {
  try {
    const { userId: userIdParam, spinType = "free" } = req.body;
    const userId = parseUserId(userIdParam);

    if (!userId) {
      return res.status(400).json({ error: "Invalid user ID format" });
    }

    // Check if user has spins available
    const userStats = await prisma.$queryRaw`
      SELECT * FROM user_game_stats WHERE user_id = ${userId}
    `;

    if (!userStats || userStats.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    const stats = userStats[0];

    if (spinType === "free" && stats.current_freespins <= 0) {
      return res.status(400).json({ error: "No free spins available" });
    }

    // Get wheel segments
    const segments = await prisma.$queryRaw`
      SELECT ws.*, wc.id as config_id
      FROM wheel_segments ws
      JOIN wheel_configurations wc ON ws.wheel_configuration_id = wc.id
      WHERE wc.is_active = true
      ORDER BY ws.segment_order
    `;

    if (!segments || segments.length === 0) {
      return res.status(500).json({ error: "No wheel segments configured" });
    }

    // Weighted random selection based on probabilities
    const random = Math.random();
    let cumulativeProbability = 0;
    let selectedSegment = null;

    for (const segment of segments) {
      cumulativeProbability += parseFloat(segment.win_probability);
      if (random <= cumulativeProbability) {
        selectedSegment = segment;
        break;
      }
    }

    // Fallback to first segment if no segment selected
    if (!selectedSegment) {
      selectedSegment = segments[0];
    }

    // Calculate spin result angle (for animation)
    const segmentAngle = 360 / segments.length;
    const baseAngle = selectedSegment.segment_order * segmentAngle;
    const spinAngle = baseAngle + Math.random() * segmentAngle;

    // Determine if it's a big win
    const isBigWin =
      selectedSegment.prize_value >= 500 ||
      (selectedSegment.prize_type === "freespins" &&
        selectedSegment.prize_value >= 50);

    // Record the spin in history
    await prisma.$executeRaw`
      INSERT INTO user_spin_history (user_id, wheel_configuration_id, segment_won_id, prize_type, prize_value, prize_label, spin_type, spin_result_angle, is_big_win)
      VALUES (${userId}, ${selectedSegment.config_id}, ${selectedSegment.id}, ${selectedSegment.prize_type}, ${selectedSegment.prize_value}, ${selectedSegment.prize_label}, ${spinType}, ${spinAngle}, ${isBigWin})
    `;

    // Update user stats
    const prizeValue = parseInt(selectedSegment.prize_value);

    if (spinType === "free") {
      await prisma.$executeRaw`
        UPDATE user_game_stats 
        SET current_freespins = current_freespins - 1,
            total_spins = total_spins + 1,
            total_wins = total_wins + ${prizeValue > 0 ? 1 : 0},
            current_coins = current_coins + ${
              selectedSegment.prize_type === "coins" ? prizeValue : 0
            },
            total_coins_won = total_coins_won + ${
              selectedSegment.prize_type === "coins" ? prizeValue : 0
            },
            current_freespins = current_freespins + ${
              selectedSegment.prize_type === "freespins" ? prizeValue : 0
            },
            total_freespins_won = total_freespins_won + ${
              selectedSegment.prize_type === "freespins" ? prizeValue : 0
            },
            experience_points = experience_points + 10,
            updated_at = NOW()
        WHERE user_id = ${userId}
      `;
    }

    // Return spin result
    res.json({
      success: true,
      prize_type: selectedSegment.prize_type,
      prize_value: selectedSegment.prize_value,
      prize_label: selectedSegment.prize_label,
      spin_result_angle: spinAngle,
      is_big_win: isBigWin,
      segment_index: selectedSegment.segment_order,
      segment_color: selectedSegment.segment_color,
    });
  } catch (error) {
    console.error("Error performing spin:", error);
    res.status(500).json({ error: "Failed to perform spin" });
  }
});

// Get user's spin history
router.get("/history/:userId", async (req, res) => {
  try {
    const userIdParam = req.params.userId;
    const userId = parseUserId(userIdParam);
    const limit = parseInt(req.query.limit) || 10;

    if (!userId) {
      return res.status(400).json({ error: "Invalid user ID format" });
    }

    const history = await prisma.$queryRaw`
      SELECT prize_type, prize_value, prize_label, spin_type, is_big_win, created_at
      FROM user_spin_history 
      WHERE user_id = ${userId}
      ORDER BY created_at DESC
      LIMIT ${limit}
    `;

    res.json(history);
  } catch (error) {
    console.error("Error fetching spin history:", error);
    res.status(500).json({ error: "Failed to fetch spin history" });
  }
});

// Check spin availability
router.get("/spin-availability/:userId", async (req, res) => {
  try {
    const userIdParam = req.params.userId;
    const userId = parseUserId(userIdParam);

    if (!userId) {
      return res.status(400).json({ error: "Invalid user ID format" });
    }

    const userStats = await prisma.$queryRaw`
      SELECT current_freespins, last_free_spin_date FROM user_game_stats WHERE user_id = ${userId}
    `;

    if (!userStats || userStats.length === 0) {
      return res.json({
        can_spin: true,
        free_spins_left: 3,
        next_free_spin_at: null,
        cooldown_message: null,
      });
    }

    const stats = userStats[0];
    const now = new Date();
    const lastSpinDate = stats.last_free_spin_date
      ? new Date(stats.last_free_spin_date)
      : null;

    // Check if it's a new day (reset free spins)
    const isNewDay =
      !lastSpinDate || lastSpinDate.toDateString() !== now.toDateString();

    if (isNewDay && stats.current_freespins < 3) {
      // Reset daily free spins
      await prisma.$executeRaw`
        UPDATE user_game_stats 
        SET current_freespins = 3, last_free_spin_date = CURRENT_DATE
        WHERE user_id = ${userId}
      `;
    }

    // Get updated stats
    const updatedStats = await prisma.$queryRaw`
      SELECT current_freespins FROM user_game_stats WHERE user_id = ${userId}
    `;

    const currentFreespins = updatedStats[0]?.current_freespins || 0;
    const canSpin = currentFreespins > 0;

    // Calculate next free spin time (next day at midnight)
    const nextDay = new Date(now);
    nextDay.setDate(nextDay.getDate() + 1);
    nextDay.setHours(0, 0, 0, 0);

    res.json({
      can_spin: canSpin,
      free_spins_left: currentFreespins,
      next_free_spin_at: canSpin ? null : nextDay.toISOString(),
      cooldown_message: canSpin ? null : "Free spins reset daily at midnight",
    });
  } catch (error) {
    console.error("Error checking spin availability:", error);
    res.status(500).json({ error: "Failed to check spin availability" });
  }
});

// Get daily challenges
router.get("/challenges/:userId", async (req, res) => {
  try {
    const userIdParam = req.params.userId;
    const userId = parseUserId(userIdParam);

    if (!userId) {
      return res.status(400).json({ error: "Invalid user ID format" });
    }

    const challenges = await prisma.$queryRaw`
      SELECT dc.*, 
             COALESCE(ucp.current_progress, 0) as current_progress,
             COALESCE(ucp.is_completed, false) as is_completed,
             COALESCE(ucp.reward_claimed, false) as reward_claimed
      FROM daily_challenges dc
      LEFT JOIN user_challenge_progress ucp ON dc.id = ucp.challenge_id AND ucp.user_id = ${userId}
      WHERE dc.is_active = true 
        AND dc.start_date <= CURRENT_DATE 
        AND (dc.end_date IS NULL OR dc.end_date >= CURRENT_DATE)
      ORDER BY dc.created_at
    `;

    res.json(challenges);
  } catch (error) {
    console.error("Error fetching daily challenges:", error);
    res.status(500).json({ error: "Failed to fetch daily challenges" });
  }
});

// Claim challenge reward
router.post("/claim-challenge", async (req, res) => {
  try {
    const { userId: userIdParam, challengeId } = req.body;
    const userId = parseUserId(userIdParam);

    if (!userId || !challengeId) {
      return res.status(400).json({ error: "Invalid parameters" });
    }

    // Check if challenge is completed and not claimed
    const progress = await prisma.$queryRaw`
      SELECT ucp.*, dc.reward_type, dc.reward_amount
      FROM user_challenge_progress ucp
      JOIN daily_challenges dc ON ucp.challenge_id = dc.id
      WHERE ucp.user_id = ${userId} AND ucp.challenge_id = ${challengeId}
        AND ucp.is_completed = true AND ucp.reward_claimed = false
    `;

    if (!progress || progress.length === 0) {
      return res
        .status(400)
        .json({ error: "Challenge not completed or already claimed" });
    }

    const challengeProgress = progress[0];

    // Mark reward as claimed
    await prisma.$executeRaw`
      UPDATE user_challenge_progress 
      SET reward_claimed = true 
      WHERE user_id = ${userId} AND challenge_id = ${challengeId}
    `;

    // Add reward to user stats
    if (challengeProgress.reward_type === "freespins") {
      await prisma.$executeRaw`
        UPDATE user_game_stats 
        SET current_freespins = current_freespins + ${challengeProgress.reward_amount}
        WHERE user_id = ${userId}
      `;
    } else if (challengeProgress.reward_type === "coins") {
      await prisma.$executeRaw`
        UPDATE user_game_stats 
        SET current_coins = current_coins + ${challengeProgress.reward_amount}
        WHERE user_id = ${userId}
      `;
    }

    res.json({ success: true, message: "Reward claimed successfully" });
  } catch (error) {
    console.error("Error claiming challenge reward:", error);
    res.status(500).json({ error: "Failed to claim challenge reward" });
  }
});

module.exports = router;
