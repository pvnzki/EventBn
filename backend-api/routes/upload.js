//This file handles the upload of profile pictures to Cloudinary and updates the user's profile picture URL in the Supabase database.


const express = require('express');
// const multer = require('multer');
const cloudinary = require('../config/cloudinary');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const router = express.Router();
// const storage = multer.memoryStorage();
// const upload = multer({ storage });

router.post('/upload-profile-pic', upload.single('profilePic'), async (req, res) => {
  try {
    const fileStr = `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`;

    const result = await cloudinary.uploader.upload(fileStr, {
      folder: 'user_profiles',
      public_id: `profile_${Date.now()}`,
    });

    const userId = req.body.userId;

    // Update Supabase DB with Cloudinary URL
    await prisma.user.update({
      where: { id: parseInt(userId) },
      data: { profile_pic_url: result.secure_url },
    });

    res.json({ url: result.secure_url });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Image upload failed' });
  }
});

module.exports = router;
