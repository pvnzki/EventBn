// Main routes file - Entry point for all API routes
const express = require('express');
const coreService = require('../services/core-service');
const postService = require('../services/post-service');
const { authenticateToken, optionalAuth, requireVerified } = require('../middleware/auth');

const router = express.Router();

// Health check routes
router.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {
      'core-service': 'healthy',
      'post-service': 'healthy',
    }
  });
});

router.get('/health/core', async (req, res) => {
  try {
    const health = await coreService.healthCheck();
    res.json(health);
  } catch (error) {
    res.status(500).json({ error: 'Core service unhealthy' });
  }
});

router.get('/health/posts', async (req, res) => {
  try {
    const health = await postService.healthCheck();
    res.json(health);
  } catch (error) {
    res.status(500).json({ error: 'Post service unhealthy' });
  }
});

// ============================================================================
// CORE SERVICE ROUTES
// ============================================================================

// Auth routes
router.post('/auth/register', async (req, res) => {
  try {
    const result = await coreService.auth.register(req.body);
    res.status(201).json(result);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/auth/login', async (req, res) => {
  try {
    const result = await coreService.auth.login(req.body);
    res.json(result);
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
});

router.post('/auth/refresh', async (req, res) => {
  try {
    const { token } = req.body;
    const result = await coreService.auth.refreshToken(token);
    res.json(result);
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
});

router.post('/auth/logout', authenticateToken, async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    await coreService.auth.logout(token);
    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/auth/change-password', authenticateToken, async (req, res) => {
  try {
    const result = await coreService.auth.changePassword(req.user.id, req.body);
    res.json(result);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/auth/forgot-password', async (req, res) => {
  try {
    const result = await coreService.auth.forgotPassword(req.body.email);
    res.json(result);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/auth/reset-password', async (req, res) => {
  try {
    const result = await coreService.auth.resetPassword(req.body);
    res.json(result);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// User routes
router.get('/users', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const result = await coreService.users.getAllUsers(parseInt(page), parseInt(limit));
    res.json(result);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/users/:id', optionalAuth, async (req, res) => {
  try {
    const user = await coreService.users.getUserById(req.params.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.put('/users/:id', authenticateToken, async (req, res) => {
  try {
    if (req.user.id !== req.params.id) {
      return res.status(403).json({ error: 'Access denied' });
    }
    const user = await coreService.users.updateUser(req.params.id, req.body);
    res.json(user);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.delete('/users/:id', authenticateToken, async (req, res) => {
  try {
    if (req.user.id !== req.params.id) {
      return res.status(403).json({ error: 'Access denied' });
    }
    await coreService.users.deleteUser(req.params.id);
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Organization routes
router.get('/organizations', optionalAuth, async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const result = await coreService.organizations.getAllOrganizations(parseInt(page), parseInt(limit));
    res.json(result);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/organizations/:id', optionalAuth, async (req, res) => {
  try {
    const organization = await coreService.organizations.getOrganizationById(req.params.id);
    if (!organization) {
      return res.status(404).json({ error: 'Organization not found' });
    }
    res.json(organization);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/organizations', authenticateToken, async (req, res) => {
  try {
    const organization = await coreService.organizations.createOrganization(req.body, req.user.id);
    res.status(201).json(organization);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.put('/organizations/:id', authenticateToken, async (req, res) => {
  try {
    const organization = await coreService.organizations.updateOrganization(req.params.id, req.body);
    res.json(organization);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Event routes
router.get('/events', optionalAuth, async (req, res) => {
  try {
    const { page = 1, limit = 10, ...filters } = req.query;
    const result = await coreService.events.getAllEvents(filters, parseInt(page), parseInt(limit));
    
    // Transform events to match frontend expectations
    const transformedEvents = result.events.map(event => ({
      ...event,
      // Add UI-friendly fields
      displayDate: formatEventDate(event.start_time),
      displayLocation: event.location || event.venue || 'TBD',
      price: generateEventPrice(event),
      image: event.cover_image_url || generatePlaceholderImage(event.category),
      // Keep original fields for compatibility
      event_id: event.event_id,
      start_time: event.start_time,
      end_time: event.end_time,
    }));

    res.json({
      ...result,
      events: transformedEvents
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Helper function to format event date for UI
function formatEventDate(dateTime) {
  const date = new Date(dateTime);
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  
  const dayName = days[date.getDay()];
  const monthName = months[date.getMonth()];
  const day = date.getDate();
  const hours = date.getHours();
  const minutes = date.getMinutes();
  
  const time = `${hours % 12 || 12}:${minutes.toString().padStart(2, '0')} ${hours >= 12 ? 'PM' : 'AM'}`;
  
  return `${dayName}, ${monthName} ${day} • ${time}`;
}

// Helper function to generate price based on event category
function generateEventPrice(event) {
  const basePrices = {
    'Music': { min: 25, max: 65 },
    'Entertainment': { min: 20, max: 45 },
    'Sports': { min: 30, max: 80 },
    'Technology': { min: 15, max: 35 },
    'Education': { min: 10, max: 25 },
    'Food': { min: 15, max: 30 }
  };
  
  const categoryPrice = basePrices[event.category] || { min: 15, max: 40 };
  const price = Math.floor(Math.random() * (categoryPrice.max - categoryPrice.min + 1)) + categoryPrice.min;
  
  return `$${price}`;
}

// Helper function to generate placeholder images based on category
function generatePlaceholderImage(category) {
  const images = {
    'Music': 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400&h=200&fit=crop',
    'Entertainment': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=200&fit=crop',
    'Sports': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=200&fit=crop',
    'Technology': 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400&h=200&fit=crop',
    'Education': 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=400&h=200&fit=crop',
    'Food': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=180&fit=crop'
  };
  
  return images[category] || 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=300&h=180&fit=crop';
}

router.get('/events/:id', optionalAuth, async (req, res) => {
  try {
    const event = await coreService.events.getEventById(req.params.id);
    if (!event) {
      return res.status(404).json({ error: 'Event not found' });
    }
    res.json(event);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/events', authenticateToken, async (req, res) => {
  try {
    const event = await coreService.events.createEvent(req.body, req.user.id);
    res.status(201).json(event);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.put('/events/:id', authenticateToken, async (req, res) => {
  try {
    const event = await coreService.events.updateEvent(req.params.id, req.body);
    res.json(event);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/events/:id/register', authenticateToken, async (req, res) => {
  try {
    const registration = await coreService.events.registerForEvent(
      req.params.id, 
      req.user.id, 
      req.body.ticketId
    );
    res.status(201).json(registration);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.delete('/events/:id/register', authenticateToken, async (req, res) => {
  try {
    await coreService.events.unregisterFromEvent(req.params.id, req.user.id);
    res.json({ message: 'Unregistered from event successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Ticket routes
router.get('/events/:eventId/tickets', optionalAuth, async (req, res) => {
  try {
    const tickets = await coreService.tickets.getEventTickets(req.params.eventId);
    res.json(tickets);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/events/:eventId/tickets', authenticateToken, async (req, res) => {
  try {
    const ticket = await coreService.tickets.createTicket({
      ...req.body,
      eventId: req.params.eventId
    });
    res.status(201).json(ticket);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/tickets/:ticketId/purchase', authenticateToken, async (req, res) => {
  try {
    const purchase = await coreService.tickets.purchaseTickets({
      ...req.body,
      ticketId: req.params.ticketId,
      userId: req.user.id
    });
    res.status(201).json(purchase);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/users/:userId/tickets', authenticateToken, async (req, res) => {
  try {
    if (req.user.id !== req.params.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }
    const tickets = await coreService.tickets.getUserTickets(req.params.userId, req.query.status);
    res.json(tickets);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// ============================================================================
// POST SERVICE ROUTES
// ============================================================================

// Post routes
router.get('/posts/feed', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const result = await postService.posts.getFeedPosts(req.user.id, parseInt(page), parseInt(limit));
    res.json(result);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/posts/:id', optionalAuth, async (req, res) => {
  try {
    const post = await postService.posts.getPostById(req.params.id);
    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }
    
    // Track view if user is authenticated
    if (req.user) {
      await postService.posts.trackView(req.params.id, req.user.id);
    }
    
    res.json(post);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/posts', authenticateToken, async (req, res) => {
  try {
    const post = await postService.posts.createPost(req.body, req.user.id);
    res.status(201).json(post);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.put('/posts/:id', authenticateToken, async (req, res) => {
  try {
    const post = await postService.posts.updatePost(req.params.id, req.body, req.user.id);
    res.json(post);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.delete('/posts/:id', authenticateToken, async (req, res) => {
  try {
    await postService.posts.deletePost(req.params.id, req.user.id);
    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/users/:userId/posts', optionalAuth, async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const viewerId = req.user?.id;
    const result = await postService.posts.getUserPosts(
      req.params.userId, 
      viewerId, 
      parseInt(page), 
      parseInt(limit)
    );
    res.json(result);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Post interaction routes
router.post('/posts/:id/like', authenticateToken, async (req, res) => {
  try {
    const result = await postService.posts.toggleLike(req.params.id, req.user.id);
    res.json(result);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/posts/:id/comments', authenticateToken, async (req, res) => {
  try {
    const comment = await postService.posts.addComment(req.params.id, req.body, req.user.id);
    res.status(201).json(comment);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.delete('/comments/:id', authenticateToken, async (req, res) => {
  try {
    await postService.posts.deleteComment(req.params.id, req.user.id);
    res.json({ message: 'Comment deleted successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/posts/:id/share', authenticateToken, async (req, res) => {
  try {
    const share = await postService.posts.sharePost(req.params.id, req.user.id, req.body);
    res.status(201).json(share);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
