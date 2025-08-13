const express = require('express');
const router = express.Router();
const prisma = require('../lib/database');

// Create organization
router.post('/', async (req, res) => {
  try {
    const {
      user_id,
      name,
      description,
      logo_url,
      contact_email,
      contact_number,
      website_url
    } = req.body;

    if (!user_id || !name) {
      return res.status(400).json({ error: 'user_id and name are required.' });
    }

    const organization = await prisma.organization.create({
      data: {
        user_id,
        name,
        description,
        logo_url,
        contact_email,
        contact_number,
        website_url
      }
    });

    res.status(201).json(organization);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
