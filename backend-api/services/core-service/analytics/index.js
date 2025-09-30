const prisma = require('../../../lib/database');

module.exports = {
  // Get all analytics
  async getAllAnalytics() {
    try {
      return await prisma.monthlyAnalytics.findMany({
        orderBy: [{ year: 'desc' }, { month: 'desc' }]
      });
    } catch (error) {
      throw new Error(`Failed to fetch analytics: ${error.message}`);
    }
  },

  // Get analytics by year
  async getAnalyticsByYear(year) {
    try {
      return await prisma.monthly_analytics.findMany({
        where: { year: parseInt(year) },
        orderBy: { month: 'asc' }
      });
    } catch (error) {
      throw new Error(`Failed to fetch analytics by year: ${error.message}`);
    }
  },

  // Get analytics by year + month
  async getAnalyticsByMonth(year, month) {
    try {
      return await prisma.monthly_analytics.findUnique({
        where: {
          year_month: {
            year: parseInt(year),
            month: parseInt(month),
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to fetch analytics by month: ${error.message}`);
    }
  },

  // Create analytics record
  async createAnalytics(data) {
    try {
      return await prisma.monthly_analytics.create({
        data
      });
    } catch (error) {
      throw new Error(`Failed to create analytics: ${error.message}`);
    }
  },

  // Update analytics record
  async updateAnalytics(id, data) {
    try {
      return await prisma.monthly_analytics.update({
        where: { id: parseInt(id) },
        data
      });
    } catch (error) {
      throw new Error(`Failed to update analytics: ${error.message}`);
    }
  },

  // Delete analytics record
  async deleteAnalytics(id) {
    try {
      return await prisma.monthly_analytics.delete({
        where: { id: parseInt(id) }
      });
    } catch (error) {
      throw new Error(`Failed to delete analytics: ${error.message}`);
    }
  },

  // Get dashboard overview data
  async getDashboardOverview(timeRange = '6months') {
    try {
      const now = new Date();
      let startDate;

      // Calculate start date based on time range
      switch (timeRange) {
        case '7days':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case '30days':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case '3months':
          startDate = new Date(now.getFullYear(), now.getMonth() - 3, now.getDate());
          break;
        case '6months':
          startDate = new Date(now.getFullYear(), now.getMonth() - 6, now.getDate());
          break;
        case '1year':
          startDate = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
          break;
        default:
          startDate = new Date(now.getFullYear(), now.getMonth() - 6, now.getDate());
      }

      // Get total revenue from payments
      const revenueData = await prisma.payment.aggregate({
        where: {
          status: 'completed',
          payment_date: {
            gte: startDate
          }
        },
        _sum: {
          amount: true
        },
        _count: true
      });

      // Get tickets sold
      const ticketsData = await prisma.ticketPurchase.count({
        where: {
          purchase_date: {
            gte: startDate
          }
        }
      });

      // Get page views (using search logs as proxy)
      const pageViews = await prisma.search_Log.count({
        where: {
          search_time: {
            gte: startDate
          }
        }
      });

      // Get total events in the period
      const totalEvents = await prisma.event.count({
        where: {
          created_at: {
            gte: startDate
          },
          status: 'ACTIVE'
        }
      });

      // Calculate conversion rate (tickets sold / total events)
      const conversionRate = totalEvents > 0 ? (ticketsData / totalEvents) * 100 : 0;

      return {
        totalRevenue: revenueData._sum.amount || 0,
        ticketsSold: ticketsData,
        conversionRate: Math.round(conversionRate * 10) / 10,
        pageViews: pageViews,
        totalPayments: revenueData._count,
        totalEvents
      };
    } catch (error) {
      throw new Error(`Failed to fetch dashboard overview: ${error.message}`);
    }
  },

  // Get revenue trend data
  async getRevenueTrend(timeRange = '6months') {
    try {
      const now = new Date();
      let months = 6;

      switch (timeRange) {
        case '3months':
          months = 3;
          break;
        case '6months':
          months = 6;
          break;
        case '1year':
          months = 12;
          break;
      }

      const revenueByMonth = await prisma.$queryRaw`
        SELECT 
          EXTRACT(YEAR FROM payment_date) as year,
          EXTRACT(MONTH FROM payment_date) as month,
          SUM(amount) as revenue,
          COUNT(*) as tickets
        FROM payment 
        WHERE status = 'completed' 
          AND payment_date >= NOW() - INTERVAL '${months} months'
        GROUP BY EXTRACT(YEAR FROM payment_date), EXTRACT(MONTH FROM payment_date)
        ORDER BY year, month
      `;

      const eventsByMonth = await prisma.$queryRaw`
        SELECT 
          EXTRACT(YEAR FROM created_at) as year,
          EXTRACT(MONTH FROM created_at) as month,
          COUNT(*) as events
        FROM "Event" 
        WHERE status = 'ACTIVE' 
          AND created_at >= NOW() - INTERVAL '${months} months'
        GROUP BY EXTRACT(YEAR FROM created_at), EXTRACT(MONTH FROM created_at)
        ORDER BY year, month
      `;

      // Merge data and format for chart
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const mergedData = [];

      for (let i = months - 1; i >= 0; i--) {
        const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const year = date.getFullYear();
        const month = date.getMonth() + 1;

        const revenueRecord = revenueByMonth.find(r => parseInt(r.year) === year && parseInt(r.month) === month);
        const eventRecord = eventsByMonth.find(e => parseInt(e.year) === year && parseInt(e.month) === month);

        mergedData.push({
          month: monthNames[month - 1],
          revenue: revenueRecord ? parseFloat(revenueRecord.revenue) : 0,
          tickets: revenueRecord ? parseInt(revenueRecord.tickets) : 0,
          events: eventRecord ? parseInt(eventRecord.events) : 0
        });
      }

      return mergedData;
    } catch (error) {
      throw new Error(`Failed to fetch revenue trend: ${error.message}`);
    }
  },

  // Get event categories distribution
  async getEventCategories() {
    try {
      const categoriesData = await prisma.$queryRaw`
        SELECT 
          category,
          COUNT(*) as count
        FROM "Event" 
        WHERE status = 'ACTIVE' 
          AND category IS NOT NULL
        GROUP BY category
        ORDER BY count DESC
      `;

      const total = categoriesData.reduce((sum, cat) => sum + parseInt(cat.count), 0);
      
      const colors = ['#8884d8', '#82ca9d', '#ffc658', '#ff7300', '#00ff00', '#8dd1e1', '#d084d0'];
      
      return categoriesData.map((cat, index) => ({
        name: cat.category,
        value: Math.round((parseInt(cat.count) / total) * 100),
        color: colors[index % colors.length]
      }));
    } catch (error) {
      throw new Error(`Failed to fetch event categories: ${error.message}`);
    }
  },

  // Get top performing events
  async getTopEvents(limit = 5) {
    try {
      const topEventsData = await prisma.$queryRaw`
        SELECT 
          e.title,
          e.event_id,
          COUNT(DISTINCT tp.ticket_id) as attendees,
          COALESCE(SUM(CAST(p.amount AS DECIMAL)), 0) as revenue,
          CASE 
            WHEN e.capacity > 0 THEN ROUND((COUNT(DISTINCT tp.ticket_id)::decimal / e.capacity) * 100, 1)
            ELSE 0 
          END as conversion
        FROM "Event" e
        LEFT JOIN "ticket_purchase" tp ON e.event_id = tp.event_id
        LEFT JOIN "payment" p ON tp.payment_id = p.payment_id AND p.status = 'completed'
        WHERE e.status = 'ACTIVE'
        GROUP BY e.event_id, e.title, e.capacity
        HAVING COUNT(DISTINCT tp.ticket_id) > 0
        ORDER BY revenue DESC, attendees DESC
        LIMIT ${limit}
      `;

      return topEventsData.map(event => ({
        name: event.title,
        attendees: parseInt(event.attendees),
        revenue: parseFloat(event.revenue),
        conversion: parseFloat(event.conversion)
      }));
    } catch (error) {
      throw new Error(`Failed to fetch top events: ${error.message}`);
    }
  },

  // Get daily attendees data (for the last week)
  async getDailyAttendees() {
    try {
      const weeklyData = await prisma.$queryRaw`
        SELECT 
          TO_CHAR(tp.purchase_date, 'Dy') as day,
          COUNT(*) as attendees
        FROM "ticket_purchase" tp
        WHERE tp.purchase_date >= NOW() - INTERVAL '7 days'
        GROUP BY TO_CHAR(tp.purchase_date, 'Dy'), EXTRACT(DOW FROM tp.purchase_date)
        ORDER BY EXTRACT(DOW FROM tp.purchase_date)
      `;

      // Ensure we have data for all days of the week
      const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      const dailyAttendees = daysOfWeek.map(day => {
        const record = weeklyData.find(d => d.day === day);
        return {
          day: day,
          attendees: record ? parseInt(record.attendees) : 0
        };
      });

      return dailyAttendees;
    } catch (error) {
      throw new Error(`Failed to fetch daily attendees: ${error.message}`);
    }
  },

  // Organizer-specific analytics methods
  
  // Get dashboard overview data for a specific organizer
  async getOrganizerDashboardOverview(organizationId, timeRange = '6months') {
    try {
      const now = new Date();
      let startDate;

      // Calculate start date based on time range
      switch (timeRange) {
        case '7days':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case '30days':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case '3months':
          startDate = new Date(now.getFullYear(), now.getMonth() - 3, now.getDate());
          break;
        case '6months':
          startDate = new Date(now.getFullYear(), now.getMonth() - 6, now.getDate());
          break;
        case '1year':
          startDate = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
          break;
        default:
          startDate = new Date(now.getFullYear(), now.getMonth() - 6, now.getDate());
      }

      // Get total revenue from payments for organizer's events
      const revenueData = await prisma.payment.aggregate({
        where: {
          status: 'completed',
          payment_date: {
            gte: startDate
          },
          event: {
            organization_id: parseInt(organizationId)
          }
        },
        _sum: {
          amount: true
        },
        _count: true
      });

      // Get tickets sold for organizer's events
      const ticketsData = await prisma.ticketPurchase.count({
        where: {
          purchase_date: {
            gte: startDate
          },
          event: {
            organization_id: parseInt(organizationId)
          }
        }
      });

      // Get page views for organizer's events (using search logs as proxy - would need event_id in search logs for exact tracking)
      const pageViews = await prisma.search_Log.count({
        where: {
          search_time: {
            gte: startDate
          }
        }
      });

      // Get total events in the period for this organizer
      const totalEvents = await prisma.event.count({
        where: {
          organization_id: parseInt(organizationId),
          created_at: {
            gte: startDate
          },
          status: 'ACTIVE'
        }
      });

      // Calculate conversion rate (tickets sold / total events)
      const conversionRate = totalEvents > 0 ? (ticketsData / totalEvents) * 100 : 0;

      return {
        totalRevenue: revenueData._sum.amount || 0,
        ticketsSold: ticketsData,
        conversionRate: Math.round(conversionRate * 10) / 10,
        pageViews: pageViews,
        totalPayments: revenueData._count,
        totalEvents
      };
    } catch (error) {
      throw new Error(`Failed to fetch organizer dashboard overview: ${error.message}`);
    }
  },

  // Get revenue trend data for organizer
  async getOrganizerRevenueTrend(organizationId, timeRange = '6months') {
    try {
      const now = new Date();
      let months = 6;

      switch (timeRange) {
        case '3months':
          months = 3;
          break;
        case '6months':
          months = 6;
          break;
        case '1year':
          months = 12;
          break;
      }

      const revenueByMonth = await prisma.$queryRaw`
        SELECT 
          EXTRACT(YEAR FROM p.payment_date) as year,
          EXTRACT(MONTH FROM p.payment_date) as month,
          SUM(p.amount) as revenue,
          COUNT(*) as tickets
        FROM payment p
        JOIN "Event" e ON p.event_id = e.event_id
        WHERE p.status = 'completed' 
          AND e.organization_id = ${parseInt(organizationId)}
          AND p.payment_date >= NOW() - INTERVAL '${months} months'
        GROUP BY EXTRACT(YEAR FROM p.payment_date), EXTRACT(MONTH FROM p.payment_date)
        ORDER BY year, month
      `;

      const eventsByMonth = await prisma.$queryRaw`
        SELECT 
          EXTRACT(YEAR FROM created_at) as year,
          EXTRACT(MONTH FROM created_at) as month,
          COUNT(*) as events
        FROM "Event" 
        WHERE status = 'ACTIVE' 
          AND organization_id = ${parseInt(organizationId)}
          AND created_at >= NOW() - INTERVAL '${months} months'
        GROUP BY EXTRACT(YEAR FROM created_at), EXTRACT(MONTH FROM created_at)
        ORDER BY year, month
      `;

      // Merge data and format for chart
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const mergedData = [];

      for (let i = months - 1; i >= 0; i--) {
        const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const year = date.getFullYear();
        const month = date.getMonth() + 1;

        const revenueRecord = revenueByMonth.find(r => parseInt(r.year) === year && parseInt(r.month) === month);
        const eventRecord = eventsByMonth.find(e => parseInt(e.year) === year && parseInt(e.month) === month);

        mergedData.push({
          month: monthNames[month - 1],
          revenue: revenueRecord ? parseFloat(revenueRecord.revenue) : 0,
          tickets: revenueRecord ? parseInt(revenueRecord.tickets) : 0,
          events: eventRecord ? parseInt(eventRecord.events) : 0
        });
      }

      return mergedData;
    } catch (error) {
      throw new Error(`Failed to fetch organizer revenue trend: ${error.message}`);
    }
  },

  // Get event categories distribution for organizer
  async getOrganizerEventCategories(organizationId) {
    try {
      const categoriesData = await prisma.$queryRaw`
        SELECT 
          category,
          COUNT(*) as count
        FROM "Event" 
        WHERE status = 'ACTIVE' 
          AND organization_id = ${parseInt(organizationId)}
          AND category IS NOT NULL
        GROUP BY category
        ORDER BY count DESC
      `;

      const total = categoriesData.reduce((sum, cat) => sum + parseInt(cat.count), 0);
      
      const colors = ['#8884d8', '#82ca9d', '#ffc658', '#ff7300', '#00ff00', '#8dd1e1', '#d084d0'];
      
      return categoriesData.map((cat, index) => ({
        name: cat.category,
        value: Math.round((parseInt(cat.count) / total) * 100),
        color: colors[index % colors.length]
      }));
    } catch (error) {
      throw new Error(`Failed to fetch organizer event categories: ${error.message}`);
    }
  },

  // Get top performing events for organizer
  async getOrganizerTopEvents(organizationId, limit = 5) {
    try {
      const topEventsData = await prisma.$queryRaw`
        SELECT 
          e.title,
          e.event_id,
          COUNT(DISTINCT tp.ticket_id) as attendees,
          COALESCE(SUM(CAST(p.amount AS DECIMAL)), 0) as revenue,
          CASE 
            WHEN e.capacity > 0 THEN ROUND((COUNT(DISTINCT tp.ticket_id)::decimal / e.capacity) * 100, 1)
            ELSE 0 
          END as conversion
        FROM "Event" e
        LEFT JOIN "ticket_purchase" tp ON e.event_id = tp.event_id
        LEFT JOIN "payment" p ON tp.payment_id = p.payment_id AND p.status = 'completed'
        WHERE e.status = 'ACTIVE'
          AND e.organization_id = ${parseInt(organizationId)}
        GROUP BY e.event_id, e.title, e.capacity
        HAVING COUNT(DISTINCT tp.ticket_id) > 0
        ORDER BY revenue DESC, attendees DESC
        LIMIT ${limit}
      `;

      return topEventsData.map(event => ({
        name: event.title,
        attendees: parseInt(event.attendees),
        revenue: parseFloat(event.revenue),
        conversion: parseFloat(event.conversion)
      }));
    } catch (error) {
      throw new Error(`Failed to fetch organizer top events: ${error.message}`);
    }
  },

  // Get daily attendees data for organizer (for the last week)
  async getOrganizerDailyAttendees(organizationId) {
    try {
      const weeklyData = await prisma.$queryRaw`
        SELECT 
          TO_CHAR(tp.purchase_date, 'Dy') as day,
          COUNT(*) as attendees
        FROM "ticket_purchase" tp
        JOIN "Event" e ON tp.event_id = e.event_id
        WHERE tp.purchase_date >= NOW() - INTERVAL '7 days'
          AND e.organization_id = ${parseInt(organizationId)}
        GROUP BY TO_CHAR(tp.purchase_date, 'Dy'), EXTRACT(DOW FROM tp.purchase_date)
        ORDER BY EXTRACT(DOW FROM tp.purchase_date)
      `;

      // Ensure we have data for all days of the week
      const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      const dailyAttendees = daysOfWeek.map(day => {
        const record = weeklyData.find(d => d.day === day);
        return {
          day: day,
          attendees: record ? parseInt(record.attendees) : 0
        };
      });

      return dailyAttendees;
    } catch (error) {
      throw new Error(`Failed to fetch organizer daily attendees: ${error.message}`);
    }
  }
};