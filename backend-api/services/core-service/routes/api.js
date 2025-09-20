const express = require("express");
const router = express.Router();
const coreService = require("../index");
const jwt = require("jsonwebtoken");
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

// Authentication middleware (production style)
const authenticateUser = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res
        .status(401)
        .json({ success: false, error: "Unauthorized: Bearer token required" });
    }
    const token = authHeader.slice(7);
    if (!process.env.JWT_SECRET) {
      return res
        .status(500)
        .json({ success: false, error: "JWT secret not configured" });
    }
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    // Standardize userId
    req.userId = decoded.userId || decoded.user_id || decoded.id;
    if (!req.userId) {
      return res
        .status(401)
        .json({
          success: false,
          error: "Invalid token payload (missing userId)",
        });
    }
    next();
  } catch (e) {
    return res
      .status(401)
      .json({
        success: false,
        error: "Invalid or expired token",
        message: e.message,
      });
  }
};

// Sample fallback events (used when DB or service layer unavailable)
const FALLBACK_EVENTS = [
  {
    event_id: 1001,
    title: "Sample Tech Conference",
    description: "A placeholder tech conference event used in fallback mode.",
    category: "Technology",
    location: "Virtual",
    start_date: new Date(Date.now() + 86400000).toISOString(),
    end_date: new Date(Date.now() + 90000000).toISOString(),
    banner_url: null,
    created_at: new Date().toISOString(),
    _fallback: true,
  },
  {
    event_id: 1002,
    title: "Community Music Festival",
    description: "Fallback music festival event for development mode.",
    category: "Music",
    location: "Colombo",
    start_date: new Date(Date.now() + 172800000).toISOString(),
    end_date: new Date(Date.now() + 181440000).toISOString(),
    banner_url: null,
    created_at: new Date().toISOString(),
    _fallback: true,
  },
];
console.log("[CORE-SERVICE] Fallback events loaded:", FALLBACK_EVENTS.length);

// Helper utilities (mirroring monolith transformations) --------------------
function formatDisplayDate(dateTime) {
  if (!dateTime) return "";
  const date = new Date(dateTime);
  if (isNaN(date.getTime())) return "";
  const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
  const dayName = days[date.getDay()];
  const monthName = months[date.getMonth()];
  const day = date.getDate();
  const hours = date.getHours();
  const minutes = date.getMinutes();
  const time = `${hours % 12 || 12}:${minutes.toString().padStart(2, "0")} ${
    hours >= 12 ? "PM" : "AM"
  }`;
  return `${dayName}, ${monthName} ${day} • ${time}`;
}

function deriveDisplayPrice(event) {
  // Simple heuristic; could be replaced with real ticket pricing aggregation
  const category = event.category || "General";
  const base = category.length * 3 + 15;
  return `$${base}`;
}

function placeholderImageForCategory(category) {
  const images = {
    Music:
      "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400&h=200&fit=crop",
    Entertainment:
      "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=200&fit=crop",
    Sports:
      "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=200&fit=crop",
    Technology:
      "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400&h=200&fit=crop",
    Education:
      "https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=400&h=200&fit=crop",
    Food: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=180&fit=crop",
  };
  return (
    images[category] ||
    "https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=300&h=180&fit=crop"
  );
}

// Public auth routes (no authentication required)
router.post("/auth/login", async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res
        .status(400)
        .json({
          success: false,
          error: "Email and password are required",
          message: "Email and password are required",
        });
    }
    let result;
    try {
      if (!coreService?.auth?.login)
        throw new Error("Auth service unavailable");
      result = await coreService.auth.login({ email, password });
    } catch (e) {
      return res
        .status(401)
        .json({
          success: false,
          error: e.message || "Login failed",
          message: e.message || "Login failed",
        });
    }
    res.status(200).json({
      success: true,
      message: "Login successful",
      token: result.token,
      // Mobile client expects user in `data`.
      data: result.user,
      // Provide `user` key for any existing web code.
      user: result.user,
      service: "core-service",
    });
  } catch (error) {
    console.error("[API] Login error:", error);
    res
      .status(500)
      .json({ success: false, error: "Login failed", message: error.message });
  }
});

// (Removed) /auth/dev-login - development shortcut deleted for production parity

router.post("/auth/register", async (req, res) => {
  try {
    const { name, email, password, phone_number, profile_picture } =
      req.body || {};
    if (!name || !email || !password) {
      return res
        .status(400)
        .json({
          success: false,
          error: "Name, email, and password are required",
          message: "Name, email, and password are required",
        });
    }
    if (!coreService?.auth?.register) {
      return res
        .status(503)
        .json({
          success: false,
          error: "Auth service unavailable",
          message: "Auth service unavailable",
        });
    }
    let result;
    try {
      result = await coreService.auth.register({
        name,
        email,
        password,
        phone_number,
        profile_picture,
      });
    } catch (e) {
      return res
        .status(400)
        .json({
          success: false,
          error: e.message || "Registration failed",
          message: e.message || "Registration failed",
        });
    }
    res.status(201).json({
      success: true,
      message: "User registered successfully",
      token: result.token,
      data: result.user,
      user: result.user,
      service: "core-service",
    });
  } catch (error) {
    console.error("[API] Registration error:", error);
    res
      .status(500)
      .json({
        success: false,
        error: "Registration failed",
        message: error.message,
      });
  }
});

// Public Events routes (no authentication required)
// GET /events (public)
// Mobile app expects: { success: true, data: [ ... ] }
// Previously we returned { events: [...] }. We now return both for backward compatibility.
router.get("/events", async (req, res) => {
  try {
    const { page = 1, limit = 20, category, location } = req.query;

    let events = [];
    // Prefer real service if available
    if (coreService?.events?.getAllEvents) {
      try {
        const result = await coreService.events.getAllEvents({
          category,
          location,
          page: parseInt(page),
          limit: parseInt(limit),
        });
        if (Array.isArray(result)) {
          events = result;
        } else if (result?.data) {
          // If later we wrap with { data, pagination }
          events = result.data;
        }
      } catch (innerErr) {
        console.warn(
          "[API] getAllEvents failed, using fallback:",
          innerErr.message
        );
      }
    }

    if (!events || events.length === 0) {
      events = FALLBACK_EVENTS;
    }

    res.json({
      success: true,
      fallback: events === FALLBACK_EVENTS,
      count: events.length,
      // Preferred key for mobile client
      data: events,
      // Backward compatibility with earlier microservice shape
      events,
      service: "core-service",
    });
  } catch (error) {
    console.error("[API] Error fetching events:", error);
    res.status(200).json({
      success: true,
      fallback: true,
      data: FALLBACK_EVENTS,
      events: FALLBACK_EVENTS,
      service: "core-service",
      warning: "Operating in fallback mode due to error",
      error: error.message,
    });
  }
});

// GET /events/:eventId (public)
router.get("/events/:eventId", async (req, res) => {
  try {
    const { eventId } = req.params;
    const event = await coreService.events.getEventById(eventId);

    if (!event) {
      return res.status(404).json({
        error: "Event not found",
      });
    }

    res.json({
      success: true,
      // Standardize on 'data' key for mobile client consistency
      data: event,
      event, // backward compatibility
      service: "core-service",
    });
  } catch (error) {
    console.error("[API] Error fetching event:", error);
    res.status(500).json({
      error: "Failed to fetch event",
      message: error.message,
    });
  }
});

// --- Additional public event endpoints to match mobile client expectations ---

// Utility to obtain a unified events array (real or fallback)
async function getUnifiedEvents() {
  if (coreService?.events?.getAllEvents) {
    try {
      const result = await coreService.events.getAllEvents({
        page: 1,
        limit: 500,
      });
      if (Array.isArray(result)) return result;
      if (result?.data && Array.isArray(result.data)) return result.data;
    } catch (e) {
      console.warn("[API] getUnifiedEvents falling back:", e.message);
    }
  }
  return FALLBACK_EVENTS;
}

// GET /events/featured - naive selection (first N or those with a future start_date)
router.get("/events/featured", async (req, res) => {
  try {
    const all = await getUnifiedEvents();
    const now = Date.now();
    let featured = all
      .filter((ev) => {
        const ts = Date.parse(ev.start_time || ev.start_date || "");
        return !isNaN(ts) && ts > now - 24 * 3600 * 1000; // within window
      })
      .slice(0, 10);

    // Optional summary view to mirror monolith UI adaptations
    if (req.query.view === "summary") {
      featured = featured.map((e) => ({
        ...e,
        displayDate: formatDisplayDate(e.start_time || e.start_date),
        displayLocation: e.location || e.venue || "TBD",
        price: deriveDisplayPrice(e),
        image:
          e.cover_image_url ||
          e.banner_url ||
          placeholderImageForCategory(e.category),
      }));
    }

    res.json({
      success: true,
      data: featured,
      events: featured,
      count: featured.length,
      service: "core-service",
    });
  } catch (e) {
    res
      .status(200)
      .json({
        success: true,
        data: [],
        fallback: true,
        service: "core-service",
        error: e.message,
      });
  }
});

// GET /events/search/:query - simple case-insensitive match on title/description/category
router.get("/events/search/:query", async (req, res) => {
  try {
    const { query } = req.params;
    const q = (query || "").trim().toLowerCase();
    let all = await getUnifiedEvents();
    let results = all.filter((ev) =>
      [ev.title, ev.description, ev.category]
        .filter(Boolean)
        .some((val) => String(val).toLowerCase().includes(q))
    );

    if (req.query.view === "summary") {
      results = results.map((e) => ({
        ...e,
        displayDate: formatDisplayDate(e.start_time || e.start_date),
        displayLocation: e.location || e.venue || "TBD",
        price: deriveDisplayPrice(e),
        image:
          e.cover_image_url ||
          e.banner_url ||
          placeholderImageForCategory(e.category),
      }));
    }

    res.json({
      success: true,
      data: results,
      events: results,
      count: results.length,
      service: "core-service",
    });
  } catch (e) {
    res
      .status(200)
      .json({
        success: true,
        data: [],
        fallback: true,
        service: "core-service",
        error: e.message,
      });
  }
});

// GET /events/category/:category - filter by category (exact, case-insensitive)
router.get("/events/category/:category", async (req, res) => {
  try {
    const { category } = req.params;
    const cat = (category || "").trim().toLowerCase();
    let all = await getUnifiedEvents();
    let results = all.filter((ev) => (ev.category || "").toLowerCase() === cat);

    if (req.query.view === "summary") {
      results = results.map((e) => ({
        ...e,
        displayDate: formatDisplayDate(e.start_time || e.start_date),
        displayLocation: e.location || e.venue || "TBD",
        price: deriveDisplayPrice(e),
        image:
          e.cover_image_url ||
          e.banner_url ||
          placeholderImageForCategory(e.category),
      }));
    }

    res.json({
      success: true,
      data: results,
      events: results,
      count: results.length,
      service: "core-service",
    });
  } catch (e) {
    res
      .status(200)
      .json({
        success: true,
        data: [],
        fallback: true,
        service: "core-service",
        error: e.message,
      });
  }
});

// GET /events/:eventId/attendees - placeholder (no attendees service wired yet)
router.get("/events/:eventId/attendees", async (req, res) => {
  try {
    // Future: integrate attendance/tickets service
    res.json({
      success: true,
      data: [],
      service: "core-service",
      note: "Attendees endpoint stub (microservice mode)",
    });
  } catch (e) {
    res
      .status(500)
      .json({
        success: false,
        error: "Failed to fetch attendees",
        message: e.message,
      });
  }
});

// GET /events/:eventId/seatmap - returns seat_map if present or empty list
router.get("/events/:eventId/seatmap", async (req, res) => {
  try {
    const { eventId } = req.params;
    let event = null;
    if (coreService?.events?.getEventById) {
      try {
        event = await coreService.events.getEventById(eventId);
      } catch (_) {}
    }
    if (!event) {
      // attempt from unified fallback list
      const all = await getUnifiedEvents();
      event = all.find((e) => String(e.event_id) === String(eventId));
    }
    if (!event)
      return res.status(404).json({ success: false, error: "Event not found" });
    let seatmap = event.seat_map || event.seatmap || [];
    // annotate availability using in-memory seatLocks if exists
    if (Array.isArray(seatmap) && memory?.seatLocks) {
      const locked = memory.seatLocks.get(String(eventId));
      if (locked) {
        seatmap = seatmap.map((seat) => ({
          ...seat,
          available:
            seat.available === false
              ? false
              : !locked.has(String(seat.id ?? seat.label)),
        }));
      }
    }
    res.json({
      success: true,
      data: seatmap,
      eventId,
      service: "core-service",
    });
  } catch (e) {
    res
      .status(500)
      .json({
        success: false,
        error: "Failed to fetch seatmap",
        message: e.message,
      });
  }
});

// GET /events/:eventId/booked-seats - DB-backed (ticket_purchase + payment status)
router.get("/events/:eventId/booked-seats", async (req, res) => {
  try {
    const { eventId } = req.params;
    const rows = await prisma.ticketPurchase.findMany({
      where: {
        event_id: parseInt(eventId),
        payment: { status: { in: ["pending", "completed"] } },
      },
      select: { seat_id: true, seat_label: true, purchase_date: true },
    });
    const data = rows.map((r) => ({
      seat_id: r.seat_id,
      seat_label: r.seat_label,
      booked_at: r.purchase_date,
    }));
    res.json({
      success: true,
      data,
      count: data.length,
      service: "core-service",
    });
  } catch (e) {
    res
      .status(500)
      .json({
        success: false,
        message: "Failed to fetch booked seats",
        error: e.message,
      });
  }
});

// Protected routes (require authentication)
router.use(authenticateUser);

// (Temporary removal) Ticket & Payment routes will be re-added with DB logic below
// ---------------------------------------------------------------------------
// DB-Backed Payments & Tickets
// Endpoints implemented (JWT protected except where noted):
//   POST   /payments                     -> create payment + ticket purchases
//   GET    /payments/my-payments         -> list user payments
//   GET    /payments/:payment_id         -> single payment (ownership enforced)
//   GET    /tickets/my-tickets           -> list user tickets
//   GET    /tickets/:ticketId            -> single ticket (ownership enforced)
//   GET    /tickets/qr/:qrCode           -> lookup by qr code (ownership enforced)
//   GET    /tickets/by-payment/:paymentId-> first ticket for payment (client parity)
//   PUT    /tickets/:ticketId/attend     -> mark attended (future: organizer authorization)
// Notes:
//  - Prices stored as BigInt cents; returned as integer (client divides if needed)
//  - Seat availability enforced by reading event.seat_map JSON and ensuring seats not already taken
//  - seat_map is updated (if JSON is structured) to mark seats as booked
//  - Basic optimistic locking via transaction + re-check of free seats
// ---------------------------------------------------------------------------

// Helper to extract seat list from event.seat_map JSON structure used by monolith sample maps
function extractSeatNodes(seatMapJson) {
  if (!seatMapJson) return [];
  try {
    // Expect format { sections: [ { rows: [ { seats: [ { id, label, booked } ] } ] } ] }
    const sections = seatMapJson.sections || [];
    const seats = [];
    for (const section of sections) {
      for (const row of section.rows || []) {
        for (const seat of row.seats || []) seats.push(seat);
      }
    }
    return seats;
  } catch {
    return [];
  }
}

function markSeatsBooked(seatMapJson, seatIds) {
  if (!seatMapJson) return seatMapJson;
  try {
    const set = new Set(seatIds.map((s) => parseInt(s) || s));
    for (const section of seatMapJson.sections || []) {
      for (const row of section.rows || []) {
        for (const seat of row.seats || []) {
          if (
            set.has(seat.id) ||
            set.has(seat.seat_id) ||
            set.has(seat.label)
          ) {
            seat.booked = true;
          }
        }
      }
    }
    return seatMapJson;
  } catch {
    return seatMapJson;
  }
}

// POST /payments
router.post("/payments", authenticateUser, express.json(), async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const {
      event_id,
      selected_seats,
      selectedSeatData,
      payment_method = "card",
    } = req.body || {};
    if (
      !event_id ||
      !Array.isArray(selected_seats) ||
      selected_seats.length === 0
    ) {
      return res
        .status(400)
        .json({
          success: false,
          error: "event_id and selected_seats[] required",
          message: "event_id and selected_seats[] required",
        });
    }
    // Fetch event & current booked seats
    const event = await prisma.event.findUnique({
      where: { event_id: parseInt(event_id) },
      select: { event_id: true, seat_map: true, title: true },
    });
    if (!event)
      return res
        .status(404)
        .json({
          success: false,
          error: "Event not found",
          message: "Event not found",
        });

    // Collect already booked seats (pending/completed payments)
    const existingTickets = await prisma.ticketPurchase.findMany({
      where: {
        event_id: event.event_id,
        payment: { status: { in: ["pending", "completed"] } },
      },
      select: { seat_id: true, seat_label: true },
    });
    const taken = new Set(
      existingTickets.map((t) => String(t.seat_id || t.seat_label))
    );
    const conflicts = selected_seats.filter((s) => taken.has(String(s)));
    if (conflicts.length) {
      return res
        .status(409)
        .json({
          success: false,
          error: "Some seats already booked",
          conflicts,
        });
    }

    // Determine price per seat from selectedSeatData or default (1000 cents placeholder)
    let totalCents = 0;
    const ticketRows = selected_seats.map((label, idx) => {
      const seatInfo =
        selectedSeatData && selectedSeatData[idx]
          ? selectedSeatData[idx]
          : null;
      const priceCents = seatInfo?.price_cents
        ? parseInt(seatInfo.price_cents)
        : seatInfo?.price
        ? Math.round(parseFloat(seatInfo.price) * 100)
        : 1000;
      totalCents += priceCents;
      return { label, seatInfo, priceCents };
    });

    // Persist inside transaction
    const result = await prisma.$transaction(async (tx) => {
      // Re-check seats inside transaction for race condition
      const concurrent = await tx.ticketPurchase.findMany({
        where: {
          event_id: event.event_id,
          payment: { status: { in: ["pending", "completed"] } },
        },
        select: { seat_id: true, seat_label: true },
      });
      const takenNow = new Set(
        concurrent.map((t) => String(t.seat_id || t.seat_label))
      );
      const conflictsNow = selected_seats.filter((s) =>
        takenNow.has(String(s))
      );
      if (conflictsNow.length) {
        throw new Error(
          "Seat(s) just booked by another user: " + conflictsNow.join(",")
        );
      }

      const payment = await tx.payment.create({
        data: {
          user_id: userId,
          event_id: event.event_id,
          amount: (totalCents / 100).toFixed(2), // store as decimal string
          status: "completed",
          payment_method,
          transaction_ref: "TX-" + Date.now(),
        },
      });

      const createdTickets = [];
      for (const row of ticketRows) {
        const seatIdParsed = row.seatInfo?.id
          ? parseInt(row.seatInfo.id)
          : null;
        const ticket = await tx.ticketPurchase.create({
          data: {
            event_id: event.event_id,
            user_id: userId,
            payment_id: payment.payment_id,
            seat_id: seatIdParsed,
            seat_label: row.seatInfo?.label || String(row.label),
            purchase_date: new Date(),
            price: BigInt(row.priceCents),
            attended: false,
            qr_code: "QR-" + Math.random().toString(36).slice(2, 10),
          },
        });
        createdTickets.push(ticket);
      }

      // Update seat_map JSON if exists, marking seats as booked
      if (event.seat_map) {
        let seatMapObj = event.seat_map;
        seatMapObj = markSeatsBooked(seatMapObj, selected_seats);
        await tx.event.update({
          where: { event_id: event.event_id },
          data: { seat_map: seatMapObj },
        });
      }

      return { payment, tickets: createdTickets };
    });

    // Enrich tickets with event info (single query fetch)
    const eventInfo = await prisma.event.findUnique({
      where: { event_id: event.event_id },
      select: {
        title: true,
        cover_image_url: true,
        start_time: true,
        venue: true,
        location: true,
      },
    });
    res.status(201).json({
      success: true,
      message: "Payment record created successfully",
      payment: result.payment,
      tickets: result.tickets.map((t) => ({
        ...t,
        price: Number(t.price),
        event: eventInfo,
      })),
    });
  } catch (error) {
    if (error.message && error.message.startsWith("Seat(s) just booked")) {
      return res
        .status(409)
        .json({ success: false, error: error.message, message: error.message });
    }
    res
      .status(500)
      .json({
        success: false,
        error: "Failed to create payment record",
        message: error.message,
      });
  }
});

// GET /payments/my-payments
router.get("/payments/my-payments", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const payments = await prisma.payment.findMany({
      where: { user_id: userId },
      orderBy: { payment_date: "desc" },
    });
    res.json({ success: true, payments });
  } catch (e) {
    res
      .status(500)
      .json({
        success: false,
        error: "Failed to fetch payments",
        message: e.message,
      });
  }
});

// GET /payments/:payment_id
router.get("/payments/:payment_id", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const { payment_id } = req.params;
    const payment = await prisma.payment.findUnique({ where: { payment_id } });
    if (!payment || payment.user_id !== userId)
      return res
        .status(404)
        .json({ success: false, error: "Payment not found" });
    res.json({ success: true, payment });
  } catch (e) {
    res
      .status(500)
      .json({
        success: false,
        error: "Failed to fetch payment",
        message: e.message,
      });
  }
});

// GET /tickets/my-tickets
router.get("/tickets/my-tickets", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const tickets = await prisma.ticketPurchase.findMany({
      where: { user_id: userId },
      orderBy: { purchase_date: "desc" },
      include: {
        event: {
          select: {
            title: true,
            cover_image_url: true,
            start_time: true,
            venue: true,
            location: true,
          },
        },
      },
    });
    res.json({
      success: true,
      tickets: tickets.map((t) => ({
        ...t,
        price: Number(t.price),
        event: t.event,
      })),
    });
  } catch (e) {
    res
      .status(500)
      .json({
        success: false,
        error: "Failed to fetch tickets",
        message: e.message,
      });
  }
});

// GET /tickets/:ticketId
router.get("/tickets/:ticketId", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const { ticketId } = req.params;
    const ticket = await prisma.ticketPurchase.findUnique({
      where: { ticket_id: ticketId },
      include: {
        event: {
          select: {
            title: true,
            cover_image_url: true,
            start_time: true,
            venue: true,
            location: true,
          },
        },
      },
    });
    if (!ticket || ticket.user_id !== userId)
      return res
        .status(404)
        .json({ success: false, error: "Ticket not found" });
    res.json({
      success: true,
      ticket: { ...ticket, price: Number(ticket.price), event: ticket.event },
    });
  } catch (e) {
    res
      .status(500)
      .json({
        success: false,
        error: "Failed to fetch ticket",
        message: e.message,
      });
  }
});

// GET /tickets/qr/:qrCode
router.get("/tickets/qr/:qrCode", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const { qrCode } = req.params;
    const ticket = await prisma.ticketPurchase.findFirst({
      where: { qr_code: qrCode, user_id: userId },
      include: {
        event: {
          select: {
            title: true,
            cover_image_url: true,
            start_time: true,
            venue: true,
            location: true,
          },
        },
      },
    });
    if (!ticket)
      return res
        .status(404)
        .json({ success: false, error: "Ticket not found" });
    res.json({
      success: true,
      ticket: { ...ticket, price: Number(ticket.price), event: ticket.event },
    });
  } catch (e) {
    res
      .status(500)
      .json({
        success: false,
        error: "Failed to fetch ticket by QR",
        message: e.message,
      });
  }
});

// GET /tickets/by-payment/:paymentId (parity first ticket)
router.get(
  "/tickets/by-payment/:paymentId",
  authenticateUser,
  async (req, res) => {
    try {
      const userId = parseInt(req.userId);
      const { paymentId } = req.params;
      const ticket = await prisma.ticketPurchase.findFirst({
        where: { payment_id: paymentId, user_id: userId },
        include: {
          event: {
            select: {
              title: true,
              cover_image_url: true,
              start_time: true,
              venue: true,
              location: true,
            },
          },
        },
      });
      if (!ticket)
        return res
          .status(404)
          .json({ success: false, error: "Ticket not found" });
      res.json({
        success: true,
        ticket: { ...ticket, price: Number(ticket.price), event: ticket.event },
      });
    } catch (e) {
      res
        .status(500)
        .json({
          success: false,
          error: "Failed to fetch ticket by payment",
          message: e.message,
        });
    }
  }
);

// PUT /tickets/:ticketId/attend
router.put("/tickets/:ticketId/attend", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const { ticketId } = req.params;
    // User can only mark own ticket for now (future: organizer scan logic)
    const ticket = await prisma.ticketPurchase.findUnique({
      where: { ticket_id: ticketId },
      include: {
        event: {
          select: {
            title: true,
            cover_image_url: true,
            start_time: true,
            venue: true,
            location: true,
          },
        },
      },
    });
    if (!ticket || ticket.user_id !== userId)
      return res
        .status(404)
        .json({ success: false, error: "Ticket not found" });
    if (ticket.attended)
      return res.json({
        success: true,
        message: "Already marked attended",
        ticket: { ...ticket, price: Number(ticket.price) },
      });
    const updated = await prisma.ticketPurchase.update({
      where: { ticket_id: ticketId },
      data: { attended: true },
    });
    res.json({
      success: true,
      message: "Ticket marked as attended",
      ticket: { ...updated, price: Number(updated.price), event: ticket.event },
    });
  } catch (e) {
    res
      .status(500)
      .json({
        success: false,
        error: "Failed to update ticket attendance",
        message: e.message,
      });
  }
});

// User profile routes
router.get("/users/profile", async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const user = await prisma.user.findUnique({
      where: { user_id: userId },
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
      },
    });
    if (!user)
      return res.status(404).json({ success: false, error: "User not found" });
    res.json({ success: true, user, service: "core-service" });
  } catch (error) {
    res
      .status(500)
      .json({
        success: false,
        error: "Failed to fetch profile",
        message: error.message,
      });
  }
});

router.put("/users/profile", async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const { name, phone_number, profile_picture } = req.body;
    const user = await prisma.user.update({
      where: { user_id: userId },
      data: { name, phone_number, profile_picture },
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
      },
    });
    res.json({
      success: true,
      message: "Profile updated successfully",
      user,
      service: "core-service",
    });
  } catch (error) {
    res
      .status(500)
      .json({
        success: false,
        error: "Failed to update profile",
        message: error.message,
      });
  }
});

// Analytics routes
router.get("/analytics/dashboard", async (req, res) => {
  try {
    const userId = req.headers["x-user-id"];
    const analytics = await coreService.analytics.getUserDashboard(userId);

    res.json({
      success: true,
      analytics,
      service: "core-service",
    });
  } catch (error) {
    console.error("[API] Error fetching analytics:", error);
    res.status(500).json({
      error: "Failed to fetch analytics",
      message: error.message,
    });
  }
});

module.exports = router;
