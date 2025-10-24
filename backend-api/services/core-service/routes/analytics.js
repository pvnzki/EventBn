const express = require('express');
const router = express.Router();
const prisma = require('../lib/database');

// Helper function to generate colors for pie chart
const categoryColors = ['#8884d8', '#82ca9d', '#ffc658', '#ff7300', '#00ff00', '#0088fe', '#ff8042'];
let colorIndex = 0;
const getRandomColor = () => {
  const color = categoryColors[colorIndex % categoryColors.length];
  colorIndex++;
  return color;
};

// PLATFORM-WIDE ANALYTICS ENDPOINTS (ADMIN)
router.get('/platform/dashboard/overview', async (req, res) => {
  try {
    const timeRange = req.query.timeRange || '6months';
    // Get all events
    const events = await prisma.event.findMany({});
    const eventIds = events.map(e => e.event_id);
    // Get all tickets
    const tickets = await prisma.ticket_purchase.findMany({});
    const totalTicketsSold = tickets.length;
    const totalRevenue = tickets.reduce((sum, ticket) => sum + Number(ticket.price), 0);
    const totalAttendees = tickets.filter(ticket => ticket.attended).length;
    const avgTicketPrice = totalTicketsSold > 0 ? totalRevenue / totalTicketsSold : 0;
    const attendanceRate = totalTicketsSold > 0 ? (totalAttendees / totalTicketsSold) * 100 : 0;
    const totalCapacity = events.reduce((sum, event) => sum + (event.capacity || 0), 0);
    const conversionRate = totalCapacity > 0 ? (totalTicketsSold / totalCapacity) * 100 : 0;
    // Growth rates (compare with previous period)
    const currentDate = new Date();
    let periodDays = 180;
    switch (timeRange) {
      case '1month': periodDays = 30; break;
      case '3months': periodDays = 90; break;
      case '6months': periodDays = 180; break;
      case '1year': periodDays = 365; break;
    }
    const currentPeriodStart = new Date(currentDate.getTime() - (periodDays * 24 * 60 * 60 * 1000));
    const previousPeriodStart = new Date(currentPeriodStart.getTime() - (periodDays * 24 * 60 * 60 * 1000));
    const currentPeriodTickets = tickets.filter(ticket => new Date(ticket.purchase_date) >= currentPeriodStart);
    const previousPeriodTickets = tickets.filter(ticket => {
      const purchaseDate = new Date(ticket.purchase_date);
      return purchaseDate >= previousPeriodStart && purchaseDate < currentPeriodStart;
    });
    const currentRevenue = currentPeriodTickets.reduce((sum, ticket) => sum + Number(ticket.price), 0);
    const previousRevenue = previousPeriodTickets.reduce((sum, ticket) => sum + Number(ticket.price), 0);
    const revenueGrowth = previousRevenue > 0 ? ((currentRevenue - previousRevenue) / previousRevenue) * 100 : 0;
    const currentAttendees = currentPeriodTickets.filter(ticket => ticket.attended).length;
    const previousAttendees = previousPeriodTickets.filter(ticket => ticket.attended).length;
    const attendeeGrowth = previousAttendees > 0 ? ((currentAttendees - previousAttendees) / previousAttendees) * 100 : 0;
    const result = {
      totalEvents: events.length,
      ticketsSold: totalTicketsSold,
      totalRevenue: Math.round(totalRevenue * 100) / 100,
      totalAttendees: totalAttendees,
      conversionRate: Math.round(conversionRate * 100) / 100,
      avgTicketPrice: Math.round(avgTicketPrice * 100) / 100,
      revenueGrowth: Math.round(revenueGrowth * 100) / 100,
      attendeeGrowth: Math.round(attendeeGrowth * 100) / 100,
      attendanceRate: Math.round(attendanceRate * 100) / 100,
      totalCapacity: totalCapacity,
      activeEvents: events.filter(event => new Date(event.start_time) > new Date()).length,
      currentPeriodTickets: currentPeriodTickets.length,
      currentPeriodRevenue: Math.round(currentRevenue * 100) / 100
    };
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Platform analytics overview error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/platform/dashboard/revenue-trend', async (req, res) => {
  try {
    const timeRange = req.query.timeRange || '6months';
    const events = await prisma.event.findMany({});
    const eventIds = events.map(e => e.event_id);
    const tickets = await prisma.ticket_purchase.findMany({ orderBy: { purchase_date: 'asc' } });
    const revenueByMonth = {};
    const ticketsByMonth = {};
    tickets.forEach(ticket => {
      const date = new Date(ticket.purchase_date);
      const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      if (!revenueByMonth[monthKey]) {
        revenueByMonth[monthKey] = 0;
        ticketsByMonth[monthKey] = 0;
      }
      revenueByMonth[monthKey] += Number(ticket.price);
      ticketsByMonth[monthKey] += 1;
    });
    const data = Object.entries(revenueByMonth).map(([month, revenue]) => ({
      month,
      revenue,
      tickets: ticketsByMonth[month] || 0
    }));
    res.json({ success: true, data });
  } catch (error) {
    console.error('Platform revenue trend error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/platform/dashboard/categories', async (req, res) => {
  try {
    const events = await prisma.event.findMany({});
    const eventIds = events.map(e => e.event_id);
    const ticketCounts = await prisma.ticket_purchase.groupBy({
      by: ['event_id'],
      where: { event_id: { in: eventIds } },
      _count: true
    });
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
      name: category,
      value: count,
      color: getRandomColor()
    }));
    res.json({ success: true, data });
  } catch (error) {
    console.error('Platform categories error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/platform/dashboard/daily-attendees', async (req, res) => {
  try {
    const events = await prisma.event.findMany({});
    const eventIds = events.map(e => e.event_id);
    const tickets = await prisma.ticket_purchase.findMany({ orderBy: { purchase_date: 'asc' } });
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const attendeesByDay = {};
    dayNames.forEach(day => { attendeesByDay[day] = 0; });
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const recentTickets = tickets.filter(ticket => new Date(ticket.purchase_date) >= sevenDaysAgo);
    recentTickets.forEach(ticket => {
      const date = new Date(ticket.purchase_date);
      const dayName = dayNames[date.getDay()];
      attendeesByDay[dayName]++;
    });
    const data = dayNames.map(day => ({ day, attendees: attendeesByDay[day] }));
    res.json({ success: true, data });
  } catch (error) {
    console.error('Platform daily attendees error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.get('/platform/dashboard/top-events', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 5;
    const events = await prisma.event.findMany({});
    const eventIds = events.map(e => e.event_id);
    const ticketCounts = await prisma.ticket_purchase.groupBy({
      by: ['event_id'],
      where: { event_id: { in: eventIds } },
      _count: true,
      _sum: { price: true }
    });
    const eventsWithStats = events.map(event => {
      const stats = ticketCounts.find(tc => tc.event_id === event.event_id);
      const ticketsSold = stats?._count || 0;
      const revenue = Number(stats?._sum?.price || 0);
      const capacity = event.capacity || 0;
      const conversion = capacity > 0 ? (ticketsSold / capacity) * 100 : 0;
      return {
        event_id: event.event_id,
        name: event.title,
        title: event.title,
        start_time: event.start_time,
        venue: event.venue,
        attendees: ticketsSold,
        ticketsSold: ticketsSold,
        revenue: revenue,
        conversion: conversion
      };
    });
    const topEvents = eventsWithStats.sort((a, b) => b.ticketsSold - a.ticketsSold).slice(0, limit);
    res.json({ success: true, data: topEvents });
  } catch (error) {
    console.error('Platform top events error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Real analytics endpoint - NO AUTHENTICATION REQUIRED
router.get('/organizer/:organizationId/dashboard/overview', async (req, res) => {
  try {
    const organizationId = parseInt(req.params.organizationId);
    const timeRange = req.query.timeRange || '6months';
    console.log('=== ANALYTICS OVERVIEW REQUEST FOR ORG:', organizationId, 'TIME RANGE:', timeRange, '===');
    
    // Get events for this organization
    const events = await prisma.event.findMany({
      where: { organization_id: organizationId },
      select: { 
        event_id: true, 
        title: true,
        start_time: true,
        capacity: true
      }
    });
    console.log('EVENTS FOUND:', events.length);
    
    const eventIds = events.map(e => e.event_id);
    
    // Get all tickets for these events
    const tickets = await prisma.ticket_purchase.findMany({
      where: { event_id: { in: eventIds } },
      select: {
        ticket_id: true,
        event_id: true,
        purchase_date: true,
        price: true,
        attended: true
      }
    });
    console.log('TICKETS FOUND:', tickets.length);
    
    // Calculate current period data
    const totalTicketsSold = tickets.length;
    const totalRevenue = tickets.reduce((sum, ticket) => sum + Number(ticket.price), 0);
    const totalAttendees = tickets.filter(ticket => ticket.attended).length;
    const avgTicketPrice = totalTicketsSold > 0 ? totalRevenue / totalTicketsSold : 0;
    const attendanceRate = totalTicketsSold > 0 ? (totalAttendees / totalTicketsSold) * 100 : 0;
    
    // Calculate conversion rate (tickets sold vs total capacity)
    const totalCapacity = events.reduce((sum, event) => sum + (event.capacity || 0), 0);
    const conversionRate = totalCapacity > 0 ? (totalTicketsSold / totalCapacity) * 100 : 0;
    
    // Calculate growth rates (compare with previous period)
    const currentDate = new Date();
    let periodDays = 180; // Default 6 months
    
    switch (timeRange) {
      case '1month':
        periodDays = 30;
        break;
      case '3months':
        periodDays = 90;
        break;
      case '6months':
        periodDays = 180;
        break;
      case '1year':
        periodDays = 365;
        break;
    }
    
    const currentPeriodStart = new Date(currentDate.getTime() - (periodDays * 24 * 60 * 60 * 1000));
    const previousPeriodStart = new Date(currentPeriodStart.getTime() - (periodDays * 24 * 60 * 60 * 1000));
    
    // Current period tickets
    const currentPeriodTickets = tickets.filter(ticket => 
      new Date(ticket.purchase_date) >= currentPeriodStart
    );
    
    // Previous period tickets
    const previousPeriodTickets = tickets.filter(ticket => {
      const purchaseDate = new Date(ticket.purchase_date);
      return purchaseDate >= previousPeriodStart && purchaseDate < currentPeriodStart;
    });
    
    // Calculate growth
    const currentRevenue = currentPeriodTickets.reduce((sum, ticket) => sum + Number(ticket.price), 0);
    const previousRevenue = previousPeriodTickets.reduce((sum, ticket) => sum + Number(ticket.price), 0);
    const revenueGrowth = previousRevenue > 0 ? ((currentRevenue - previousRevenue) / previousRevenue) * 100 : 0;
    
    const currentAttendees = currentPeriodTickets.filter(ticket => ticket.attended).length;
    const previousAttendees = previousPeriodTickets.filter(ticket => ticket.attended).length;
    const attendeeGrowth = previousAttendees > 0 ? ((currentAttendees - previousAttendees) / previousAttendees) * 100 : 0;
    
    const result = {
      totalEvents: events.length,
      ticketsSold: totalTicketsSold,
      totalRevenue: Math.round(totalRevenue * 100) / 100, // Round to 2 decimal places
      totalAttendees: totalAttendees,
      conversionRate: Math.round(conversionRate * 100) / 100,
      avgTicketPrice: Math.round(avgTicketPrice * 100) / 100,
      revenueGrowth: Math.round(revenueGrowth * 100) / 100,
      attendeeGrowth: Math.round(attendeeGrowth * 100) / 100,
      attendanceRate: Math.round(attendanceRate * 100) / 100,
      totalCapacity: totalCapacity,
      // Additional metrics
      activeEvents: events.filter(event => new Date(event.start_time) > new Date()).length,
      currentPeriodTickets: currentPeriodTickets.length,
      currentPeriodRevenue: Math.round(currentRevenue * 100) / 100
    };
    
    console.log('ANALYTICS OVERVIEW RESULT:', result);
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Analytics overview error:', error);
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
    const ticketsByMonth = {};
    
    tickets.forEach(ticket => {
      const date = new Date(ticket.purchase_date);
      const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      
      if (!revenueByMonth[monthKey]) {
        revenueByMonth[monthKey] = 0;
        ticketsByMonth[monthKey] = 0;
      }
      
      revenueByMonth[monthKey] += Number(ticket.price);
      ticketsByMonth[monthKey] += 1;
    });
    
    const data = Object.entries(revenueByMonth).map(([month, revenue]) => ({
      month,
      revenue,
      tickets: ticketsByMonth[month] || 0
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
      name: category,
      value: count,
      color: getRandomColor() // We'll add a color helper function
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
    
    // Group by day of week for last 7 days
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const attendeesByDay = {};
    
    // Initialize with 0 for each day
    dayNames.forEach(day => {
      attendeesByDay[day] = 0;
    });
    
    // Get tickets from last 7 days
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const recentTickets = tickets.filter(ticket => 
      new Date(ticket.purchase_date) >= sevenDaysAgo
    );
    
    recentTickets.forEach(ticket => {
      const date = new Date(ticket.purchase_date);
      const dayName = dayNames[date.getDay()];
      attendeesByDay[dayName]++;
    });
    
    const data = dayNames.map(day => ({
      day,
      attendees: attendeesByDay[day]
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