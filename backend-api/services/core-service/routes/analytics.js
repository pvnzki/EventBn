const express = require('express');
const router = express.Router();
const prisma = require('../lib/database');

// Real analytics endpoint - NO AUTHENTICATION REQUIRED
router.get('/organizer/:organizationId/dashboard/overview', async (req, res) => {
  try {
    const organizationId = parseInt(req.params.organizationId);
    console.log('=== ANALYTICS REQUEST FOR ORG:', organizationId, '===');
    
    // Get events for this organization
    const events = await prisma.event.findMany({
      where: { organization_id: organizationId },
      select: { event_id: true, title: true }
    });
    console.log('EVENTS FOUND:', events.length, events);
    
    // Get ticket count
    const eventIds = events.map(e => e.event_id);
    const ticketCount = await prisma.ticket_purchase.count({
      where: { event_id: { in: eventIds } }
    });
    console.log('TICKET COUNT:', ticketCount);
    
    const result = {
      totalEvents: events.length,
      ticketsSold: ticketCount,
      totalRevenue: 0,
      totalAttendees: ticketCount,
      conversionRate: 0,
      avgTicketPrice: 0,
      revenueGrowth: 0,
      attendeeGrowth: 0
    };
    
    console.log('FINAL RESULT:', result);
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Analytics error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Revenue trend endpoint
router.get('/organizer/:organizationId/dashboard/revenue-trend', async (req, res) => {
  try {
    const organizationId = parseInt(req.params.organizationId);
    const timeRange = req.query.timeRange || '6months';
    
    // Get events for this organization
    const events = await prisma.event.findMany({
      where: { organization_id: organizationId },
      select: { event_id: true }
    });
    
    const eventIds = events.map(e => e.event_id);
    
    // Get tickets with dates
    const tickets = await prisma.ticket_purchase.findMany({
      where: { event_id: { in: eventIds } },
      select: {
        purchase_date: true,
        price: true
      },
      orderBy: { purchase_date: 'asc' }
    });
    
    // Group by month
    const revenueByMonth = {};
    tickets.forEach(ticket => {
      const date = new Date(ticket.purchase_date);
      const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      if (!revenueByMonth[monthKey]) {
        revenueByMonth[monthKey] = 0;
      }
      revenueByMonth[monthKey] += Number(ticket.price);
    });
    
    const data = Object.entries(revenueByMonth).map(([month, revenue]) => ({
      month,
      revenue
    }));
    
    res.json({ success: true, data });
  } catch (error) {
    console.error('Revenue trend error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Categories endpoint
router.get('/organizer/:organizationId/dashboard/categories', async (req, res) => {
  try {
    const organizationId = parseInt(req.params.organizationId);
    
    // Get events for this organization with categories
    const events = await prisma.event.findMany({
      where: { organization_id: organizationId },
      select: { 
        event_id: true,
        category: true 
      }
    });
    
    const eventIds = events.map(e => e.event_id);
    
    // Get ticket counts per event
    const ticketCounts = await prisma.ticket_purchase.groupBy({
      by: ['event_id'],
      where: { event_id: { in: eventIds } },
      _count: true
    });
    
    // Map tickets to categories
    const categoryMap = {};
    events.forEach(event => {
      const category = event.category || 'Uncategorized';
      const ticketCount = ticketCounts.find(tc => tc.event_id === event.event_id)?._count || 0;
      
      if (!categoryMap[category]) {
        categoryMap[category] = 0;
      }
      categoryMap[category] += ticketCount;
    });
    
    const data = Object.entries(categoryMap).map(([category, count]) => ({
      category,
      count
    }));
    
    res.json({ success: true, data });
  } catch (error) {
    console.error('Categories error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Daily attendees endpoint
router.get('/organizer/:organizationId/dashboard/daily-attendees', async (req, res) => {
  try {
    const organizationId = parseInt(req.params.organizationId);
    
    // Get events for this organization
    const events = await prisma.event.findMany({
      where: { organization_id: organizationId },
      select: { event_id: true }
    });
    
    const eventIds = events.map(e => e.event_id);
    
    // Get tickets grouped by date
    const tickets = await prisma.ticket_purchase.findMany({
      where: { event_id: { in: eventIds } },
      select: {
        purchase_date: true
      },
      orderBy: { purchase_date: 'asc' }
    });
    
    // Group by date
    const attendeesByDate = {};
    tickets.forEach(ticket => {
      const date = new Date(ticket.purchase_date);
      const dateKey = date.toISOString().split('T')[0]; // YYYY-MM-DD
      if (!attendeesByDate[dateKey]) {
        attendeesByDate[dateKey] = 0;
      }
      attendeesByDate[dateKey]++;
    });
    
    const data = Object.entries(attendeesByDate).map(([date, count]) => ({
      date,
      count
    }));
    
    res.json({ success: true, data });
  } catch (error) {
    console.error('Daily attendees error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Top events endpoint
router.get('/organizer/:organizationId/dashboard/top-events', async (req, res) => {
  try {
    const organizationId = parseInt(req.params.organizationId);
    const limit = parseInt(req.query.limit) || 5;
    
    // Get events for this organization
    const events = await prisma.event.findMany({
      where: { organization_id: organizationId },
      select: { 
        event_id: true,
        title: true,
        start_time: true,
        venue: true,
        capacity: true
      }
    });
    
    const eventIds = events.map(e => e.event_id);
    
    // Get ticket counts per event
    const ticketCounts = await prisma.ticket_purchase.groupBy({
      by: ['event_id'],
      where: { event_id: { in: eventIds } },
      _count: true,
      _sum: {
        price: true
      }
    });
    
    // Combine event data with ticket counts
    const eventsWithStats = events.map(event => {
      const stats = ticketCounts.find(tc => tc.event_id === event.event_id);
      const ticketsSold = stats?._count || 0;
      const revenue = Number(stats?._sum?.price || 0);
      const capacity = event.capacity || 0;
      const conversion = capacity > 0 ? (ticketsSold / capacity) * 100 : 0;
      
      return {
        event_id: event.event_id,
        name: event.title,  // Frontend expects "name"
        title: event.title,
        start_time: event.start_time,
        venue: event.venue,
        attendees: ticketsSold,  // Frontend expects "attendees"
        ticketsSold: ticketsSold,
        revenue: revenue,
        conversion: conversion  // Add conversion percentage
      };
    });
    
    // Sort by tickets sold and take top N
    const topEvents = eventsWithStats
      .sort((a, b) => b.ticketsSold - a.ticketsSold)
      .slice(0, limit);
    
    res.json({ success: true, data: topEvents });
  } catch (error) {
    console.error('Top events error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;