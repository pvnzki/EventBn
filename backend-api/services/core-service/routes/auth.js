const express = require("express");
const router = express.Router();
const prisma = require("../lib/database");

const { authService, authenticateToken } = require("../auth/index.js");

// Register user (Sign Up)
router.post("/register", async (req, res) => {
  try {
    console.log("[AUTH] Registration request received:", {
      email: req.body.email,
      name: req.body.name,
      hasPassword: !!req.body.password,
    });

    const { name, email, password, phone_number, role } = req.body;

    // Input validation
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: "Name, email, and password are required",
        errors: [
          ...(!name ? [{ field: "name", message: "Name is required" }] : []),
          ...(!email ? [{ field: "email", message: "Email is required" }] : []),
          ...(!password
            ? [{ field: "password", message: "Password is required" }]
            : []),
        ],
      });
    }

    // Use the auth service to register the user
    const result = await authService.register({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password,
      phone_number: phone_number || null,
      role: role || "ATTENDEE",
    });

    console.log("[AUTH] Registration successful for:", result.user.email);

    res.status(201).json({
      success: true,
      message: "Registration successful",
      data: result.user,
      token: result.token,
    });
  } catch (error) {
    console.error("[AUTH] Registration error:", error);

    // Handle validation errors
    if (error.name === "ValidationError") {
      return res.status(400).json({
        success: false,
        message: error.message,
        errors: error.errors || [
          { field: error.field, message: error.message },
        ],
      });
    }

    // Handle duplicate email error
    if (error.message.includes("Email already registered")) {
      return res.status(409).json({
        success: false,
        message: "Email already registered",
        errors: [
          { field: "email", message: "This email is already registered" },
        ],
      });
    }

    // Handle database errors
    if (error.code === "P2002") {
      return res.status(409).json({
        success: false,
        message: "Email already registered",
        errors: [
          { field: "email", message: "This email is already registered" },
        ],
      });
    }

    res.status(500).json({
      success: false,
      message: "Registration failed",
      error:
        process.env.NODE_ENV === "development"
          ? error.message
          : "Internal server error",
    });
  }
});

// Sign up endpoint (alias for register)
router.post("/signup", async (req, res) => {
  try {
    console.log("[AUTH] Signup request received (redirecting to register):", {
      email: req.body.email,
      name: req.body.name,
      hasPassword: !!req.body.password,
    });

    const { name, email, password, phone_number, role } = req.body;

    // Input validation
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: "Name, email, and password are required",
        errors: [
          ...(!name ? [{ field: "name", message: "Name is required" }] : []),
          ...(!email ? [{ field: "email", message: "Email is required" }] : []),
          ...(!password
            ? [{ field: "password", message: "Password is required" }]
            : []),
        ],
      });
    }

    // Use the auth service to register the user
    const result = await authService.register({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password,
      phone_number: phone_number || null,
      role: role || "ATTENDEE",
    });

    console.log("[AUTH] Signup successful for:", result.user.email);

    res.status(201).json({
      success: true,
      message: "Signup successful",
      data: result.user,
      token: result.token,
    });
  } catch (error) {
    console.error("[AUTH] Signup error:", error);

    // Handle validation errors
    if (error.name === "ValidationError") {
      return res.status(400).json({
        success: false,
        message: error.message,
        errors: error.errors || [
          { field: error.field, message: error.message },
        ],
      });
    }

    // Handle duplicate email error
    if (error.message.includes("Email already registered")) {
      return res.status(409).json({
        success: false,
        message: "Email already registered",
        errors: [
          { field: "email", message: "This email is already registered" },
        ],
      });
    }

    // Handle database errors
    if (error.code === "P2002") {
      return res.status(409).json({
        success: false,
        message: "Email already registered",
        errors: [
          { field: "email", message: "This email is already registered" },
        ],
      });
    }

    res.status(500).json({
      success: false,
      message: "Signup failed",
      error:
        process.env.NODE_ENV === "development"
          ? error.message
          : "Internal server error",
    });
  }
});

// Login user
router.post("/login", async (req, res) => {
  try {
    console.log("[AUTH] Login request received:", {
      email: req.body.email,
      hasPassword: !!req.body.password,
    });

    const { email, password } = req.body;

    // Input validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
        errors: [
          ...(!email ? [{ field: "email", message: "Email is required" }] : []),
          ...(!password
            ? [{ field: "password", message: "Password is required" }]
            : []),
        ],
      });
    }

    // Use the auth service to login the user
    const result = await authService.login({
      email: email.toLowerCase().trim(),
      password,
    });

    // Check if 2FA is required
    if (result.requiresTwoFactor) {
      console.log("[AUTH] 2FA required, returning 2FA response");
      return res.status(200).json({
        success: false,
        requiresTwoFactor: true,
        twoFactorMethod: result.twoFactorMethod || "app",
        message: result.message || "2FA required",
      });
    }

    console.log("[AUTH] Login successful for:", result.user.email);

    res.json({
      success: true,
      message: "Login successful",
      data: result.user,
      token: result.token,
    });
  } catch (error) {
    console.error("[AUTH] Login error:", error);

    // Handle validation errors
    if (error.name === "ValidationError") {
      return res.status(400).json({
        success: false,
        message: error.message,
        errors: error.errors || [
          { field: error.field, message: error.message },
        ],
      });
    }

    // Handle invalid credentials
    if (
      error.message.includes("Invalid email or password") ||
      error.message.includes("Account setup incomplete")
    ) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password",
        errors: [
          { field: "credentials", message: "Invalid email or password" },
        ],
      });
    }

    res.status(500).json({
      success: false,
      message: "Login failed",
      error:
        process.env.NODE_ENV === "development"
          ? error.message
          : "Internal server error",
    });
  }
});

// Get current user (complete profile data from database)
router.get("/me", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId || req.user.user_id || req.user.id;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "User ID not found in token",
      });
    }

    console.log(`🔍 [AUTH /me] Fetching complete user data for ID: ${userId}`);

    // Fetch complete user data from database instead of just returning JWT payload
    const usersService = require("../users");
    const completeUser = await usersService.getUserById(userId);

    if (!completeUser) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    console.log(`✅ [AUTH /me] Retrieved complete user data:`, {
      user_id: completeUser.user_id,
      phone_number: completeUser.phone_number,
      date_of_birth: completeUser.date_of_birth,
      billing_address: completeUser.billing_address,
      fieldsCount: Object.keys(completeUser).length
    });

    res.json({
      success: true,
      user: completeUser,
    });
  } catch (error) {
    console.error(`❌ [AUTH /me] Error fetching user data:`, error.message);
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
