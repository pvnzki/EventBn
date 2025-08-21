const express = require("express");
const router = express.Router();
const prisma = require("../lib/database");

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
