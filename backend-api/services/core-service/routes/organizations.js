const express = require("express");
const router = express.Router();
const prisma = require("../lib/database");
const multer = require("multer");
const { uploadStream } = require("../lib/cloudinary");

// Configure multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({ 
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// Create organization
router.post("/", async (req, res) => {
  try {
    const {
      user_id,
      name,
      description,
      logo_url,
      contact_email,
      contact_number,
      website_url,
    } = req.body;

    if (!user_id || !name) {
      return res.status(400).json({ error: "user_id and name are required." });
    }

    // Check user role
    const user = await prisma.user.findUnique({
      where: { user_id: Number(user_id) },
    });
    if (!user) {
      return res.status(404).json({ error: "User not found." });
    }
    if (user.role !== "ORGANIZER") {
      return res
        .status(403)
        .json({ error: "Only ORGANIZER users can create organizations." });
    }

    const organization = await prisma.organization.create({
      data: {
        user_id,
        name,
        description,
        logo_url,
        contact_email,
        contact_number,
        website_url,
      },
    });

    res.status(201).json(organization);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}),

// Get all organizations
router.get("/", async (req, res) => {
  try {
    const organizations = await prisma.organization.findMany({
      include: {
        user: {
          select: {
            user_id: true,
            name: true,
            email: true,
          },
        },
      },
    });
    res.json(organizations);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create or update organization for a specific user
router.post("/user/:userId", upload.single("logo"), async (req, res) => {
  try {
    const userId = Number(req.params.userId);
    if (!userId) {
      return res.status(400).json({ 
        success: false, 
        error: "Invalid user ID." 
      });
    }

    const {
      name,
      description,
      contact_email,
      contact_number,
      website_url,
    } = req.body;

    if (!name) {
      return res.status(400).json({ 
        success: false, 
        error: "Organization name is required." 
      });
    }

    // Check user role
    const user = await prisma.user.findUnique({
      where: { user_id: userId },
    });
    if (!user) {
      return res.status(404).json({ 
        success: false, 
        error: "User not found." 
      });
    }
    if (user.role !== "ORGANIZER") {
      return res.status(403).json({ 
        success: false, 
        error: "Only ORGANIZER users can create organizations." 
      });
    }

    let logo_url = null;

    // Handle logo upload to Cloudinary if file is provided
    if (req.file) {
      try {
        const result = await uploadStream(req.file.buffer, {
          resource_type: "image",
          transformation: [
            { width: 400, height: 400, crop: "limit" },
            { quality: "auto" }
          ],
          folder: "organization_logos"
        });
        logo_url = result.secure_url;
      } catch (uploadError) {
        console.error("Cloudinary upload error:", uploadError);
        return res.status(500).json({ 
          success: false, 
          error: "Failed to upload logo image" 
        });
      }
    }

    // Check if organization already exists for this user
    const existingOrganization = await prisma.organization.findFirst({
      where: { user_id: userId },
    });

    let organization;
    if (existingOrganization) {
      // Update existing organization
      const updateData = {
        name,
        description,
        contact_email,
        contact_number,
        website_url,
      };
      
      // Only update logo_url if a new logo was uploaded
      if (logo_url) {
        updateData.logo_url = logo_url;
      }

      organization = await prisma.organization.update({
        where: { organization_id: existingOrganization.organization_id },
        data: updateData,
      });
    } else {
      // Create new organization
      organization = await prisma.organization.create({
        data: {
          user_id: userId,
          name,
          description,
          logo_url,
          contact_email,
          contact_number,
          website_url,
        },
      });
    }

    res.status(200).json({ 
      success: true, 
      data: organization 
    });
  } catch (error) {
    console.error("Organization save error:", error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Get organization by user ID
router.get("/user/:userId", async (req, res) => {
  try {
    const userId = Number(req.params.userId);
    if (!userId) {
      return res.status(400).json({ 
        success: false, 
        error: "Invalid user ID." 
      });
    }

    const organization = await prisma.organization.findFirst({
      where: { user_id: userId },
      include: {
        user: {
          select: {
            user_id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    if (!organization) {
      return res.status(404).json({ 
        success: false, 
        error: "Organization not found for this user." 
      });
    }

    res.json({ 
      success: true, 
      data: organization 
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Get organization by ID
router.get("/:organizationId", async (req, res) => {
  try {
    const organization = await prisma.organization.findUnique({
      where: { organization_id: Number(req.params.organizationId) },
      include: {
        user: {
          select: {
            user_id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    if (!organization) {
      return res.status(404).json({ error: "Organization not found." });
    }

    res.json(organization);
  } catch (error) {
    res.status(500).json({ error: error.message });
  } 
});


// Get upcoming and past events for an organization (For Organization Profile in Mobile-App)
router.get('/:organizationId/events', async (req, res) => {
  try {
    const organizationId = Number(req.params.organizationId);
    if (!organizationId) {
      return res.status(400).json({ error: 'Invalid organization ID.' });
    }

    // Upcoming events: start_time >= now
    const upcomingEvents = await prisma.event.findMany({
      where: {
        organization_id: organizationId,
        start_time: { gte: new Date() },
      },
      orderBy: { start_time: 'asc' },
    });

    // Past events: end_time < now
    const pastEvents = await prisma.event.findMany({
      where: {
        organization_id: organizationId,
        end_time: { lt: new Date() },
      },
      orderBy: { end_time: 'desc' },
    });

    res.json({
      upcomingEvents,
      pastEvents,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
