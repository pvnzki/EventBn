const express = require("express");
const router = express.Router();
const prisma = require("../lib/database");

const { authService, authenticateToken } = require("../auth/index.js");

// Register user
router.post("/register", async (req, res) => {
  try {
    // TODO: Implement registration logic
    res.status(501).json({
      success: false,
      message: "Registration endpoint not implemented yet",
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Login user
router.post("/login", async (req, res) => {
  try {
    // TODO: Implement login logic
    res.status(501).json({
      success: false,
      message: "Login endpoint not implemented yet",
    });
  } catch (error) {
    res.status(401).json({
      success: false,
      message: error.message,
    });
  }
});

// Get current user
router.get("/me", authenticateToken, async (req, res) => {
  try {
    res.json({
      success: true,
      user: req.user,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Update user profile
router.put("/profile", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId || req.user.user_id || req.user.id;
    const {
      name,
      phone_number,
      billing_address,
      billing_city,
      billing_state,
      billing_country,
      billing_postal_code,
      date_of_birth,
      emergency_contact_name,
      emergency_contact_phone,
      emergency_contact_relationship,
      marketing_emails_enabled,
      event_notifications_enabled,
      sms_notifications_enabled,
      profile_completed,
    } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "User ID not found in token",
      });
    }

    // Validate input
    if (!name || typeof name !== "string" || name.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: "Name is required and must be a non-empty string",
      });
    }

    console.log("Profile update request:", { userId, body: req.body });

    // Prepare update data object
    const updateData = {
      name: name.trim(),
      updated_at: new Date(),
    };

    // Add optional fields if they exist in the request
    if (phone_number !== undefined)
      updateData.phone_number = phone_number || null;
    if (billing_address !== undefined)
      updateData.billing_address = billing_address || null;
    if (billing_city !== undefined)
      updateData.billing_city = billing_city || null;
    if (billing_state !== undefined)
      updateData.billing_state = billing_state || null;
    if (billing_country !== undefined)
      updateData.billing_country = billing_country || null;
    if (billing_postal_code !== undefined)
      updateData.billing_postal_code = billing_postal_code || null;
    if (date_of_birth !== undefined) {
      updateData.date_of_birth = date_of_birth ? new Date(date_of_birth) : null;
    }
    if (emergency_contact_name !== undefined)
      updateData.emergency_contact_name = emergency_contact_name || null;
    if (emergency_contact_phone !== undefined)
      updateData.emergency_contact_phone = emergency_contact_phone || null;
    if (emergency_contact_relationship !== undefined)
      updateData.emergency_contact_relationship =
        emergency_contact_relationship || null;
    if (marketing_emails_enabled !== undefined)
      updateData.marketing_emails_enabled = marketing_emails_enabled;
    if (event_notifications_enabled !== undefined)
      updateData.event_notifications_enabled = event_notifications_enabled;
    if (sms_notifications_enabled !== undefined)
      updateData.sms_notifications_enabled = sms_notifications_enabled;
    if (profile_completed !== undefined)
      updateData.profile_completed = profile_completed;

    console.log("Update data:", updateData);

    // Update user in database
    const updatedUser = await prisma.user.update({
      where: { user_id: parseInt(userId) },
      data: updateData,
      select: {
        user_id: true,
        name: true,
        email: true,
        phone_number: true,
        profile_picture: true,
        role: true,
        is_active: true,
        is_email_verified: true,
        created_at: true,
        updated_at: true,
        billing_address: true,
        billing_city: true,
        billing_state: true,
        billing_country: true,
        billing_postal_code: true,
        profile_completed: true,
        date_of_birth: true,
        emergency_contact_name: true,
        emergency_contact_phone: true,
        emergency_contact_relationship: true,
        marketing_emails_enabled: true,
        event_notifications_enabled: true,
        sms_notifications_enabled: true,
      },
    });

    res.json({
      success: true,
      message: "Profile updated successfully",
      user: updatedUser,
    });
  } catch (error) {
    console.error("Profile update error:", error);

    if (error.code === "P2025") {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to update profile",
      error: error.message,
    });
  }
});

module.exports = router;
