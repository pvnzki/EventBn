// Tickets service module within core-service
const prisma = require('../../../lib/database');

class TicketService {
  // Get ticket by ID
  async getTicketById(id) {
    try {
      return await prisma.ticket.findUnique({ 
        where: { id },
        include: {
          event: {
            select: {
              id: true,
              title: true,
              startDate: true,
              endDate: true,
              location: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to get ticket: ${error.message}`);
    }
  }

  // Create new ticket type for event
  async createTicket(ticketData) {
    try {
      const { 
        eventId, type, name, description, price, 
        quantity, available, saleStartDate, saleEndDate,
        maxPerUser, isTransferable, benefits 
      } = ticketData;
      
      return await prisma.ticket.create({
        data: {
          eventId,
          type,
          name,
          description,
          price,
          quantity,
          available: available || quantity,
          saleStartDate: saleStartDate ? new Date(saleStartDate) : new Date(),
          saleEndDate: saleEndDate ? new Date(saleEndDate) : null,
          maxPerUser: maxPerUser || 10,
          isTransferable: isTransferable || true,
          benefits: benefits || [],
        },
        include: {
          event: {
            select: {
              id: true,
              title: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to create ticket: ${error.message}`);
    }
  }

  // Update ticket
  async updateTicket(id, updateData) {
    try {
      return await prisma.ticket.update({
        where: { id },
        data: {
          ...updateData,
          updatedAt: new Date(),
        },
      });
    } catch (error) {
      throw new Error(`Failed to update ticket: ${error.message}`);
    }
  }

  // Delete ticket
  async deleteTicket(id) {
    try {
      return await prisma.ticket.delete({
        where: { id }
      });
    } catch (error) {
      throw new Error(`Failed to delete ticket: ${error.message}`);
    }
  }

  // Get tickets for an event
  async getEventTickets(eventId) {
    try {
      return await prisma.ticket.findMany({
        where: { eventId },
        orderBy: { price: 'asc' }
      });
    } catch (error) {
      throw new Error(`Failed to get event tickets: ${error.message}`);
    }
  }

  // Purchase tickets
  async purchaseTickets(ticketPurchaseData) {
    try {
      const { ticketId, userId, quantity, paymentDetails } = ticketPurchaseData;

      // Get ticket information
      const ticket = await this.getTicketById(ticketId);
      if (!ticket) {
        throw new Error('Ticket not found');
      }

      // Check availability
      if (ticket.available < quantity) {
        throw new Error('Not enough tickets available');
      }

      // Check sale period
      const now = new Date();
      if (ticket.saleStartDate && now < ticket.saleStartDate) {
        throw new Error('Ticket sale has not started yet');
      }
      if (ticket.saleEndDate && now > ticket.saleEndDate) {
        throw new Error('Ticket sale has ended');
      }

      // Check max per user limit
      const userTickets = await prisma.ticketPurchase.count({
        where: {
          ticketId,
          userId,
        }
      });

      if (userTickets + quantity > ticket.maxPerUser) {
        throw new Error(`Maximum ${ticket.maxPerUser} tickets allowed per user`);
      }

      const totalAmount = ticket.price * quantity;

      // Create ticket purchase transaction
      return await prisma.$transaction(async (tx) => {
        // Create purchase record
        const purchase = await tx.ticketPurchase.create({
          data: {
            ticketId,
            userId,
            quantity,
            totalAmount,
            paymentStatus: 'PENDING',
            paymentDetails,
            purchaseDate: new Date(),
          },
        });

        // Update ticket availability
        await tx.ticket.update({
          where: { id: ticketId },
          data: {
            available: {
              decrement: quantity,
            }
          }
        });

        // Generate ticket codes for each purchased ticket
        const ticketCodes = [];
        for (let i = 0; i < quantity; i++) {
          const ticketCode = await tx.userTicket.create({
            data: {
              purchaseId: purchase.id,
              userId,
              ticketId,
              eventId: ticket.eventId,
              code: this.generateTicketCode(),
              status: 'ACTIVE',
            }
          });
          ticketCodes.push(ticketCode);
        }

        return {
          purchase,
          ticketCodes,
        };
      });
    } catch (error) {
      throw new Error(`Failed to purchase tickets: ${error.message}`);
    }
  }

  // Confirm payment and activate tickets
  async confirmPayment(purchaseId, paymentConfirmation) {
    try {
      return await prisma.$transaction(async (tx) => {
        // Update purchase status
        const purchase = await tx.ticketPurchase.update({
          where: { id: purchaseId },
          data: {
            paymentStatus: 'COMPLETED',
            paymentConfirmation,
          }
        });

        // Activate all tickets for this purchase
        await tx.userTicket.updateMany({
          where: { purchaseId },
          data: {
            status: 'ACTIVE',
          }
        });

        return purchase;
      });
    } catch (error) {
      throw new Error(`Failed to confirm payment: ${error.message}`);
    }
  }

  // Get user's tickets
  async getUserTickets(userId, status = 'ACTIVE') {
    try {
      return await prisma.userTicket.findMany({
        where: { 
          userId,
          ...(status && { status })
        },
        include: {
          ticket: {
            include: {
              event: {
                select: {
                  id: true,
                  title: true,
                  startDate: true,
                  endDate: true,
                  location: true,
                  imageUrl: true,
                }
              }
            }
          },
          purchase: {
            select: {
              id: true,
              purchaseDate: true,
              totalAmount: true,
            }
          }
        },
        orderBy: { createdAt: 'desc' }
      });
    } catch (error) {
      throw new Error(`Failed to get user tickets: ${error.message}`);
    }
  }

  // Validate ticket code
  async validateTicket(code) {
    try {
      const ticket = await prisma.userTicket.findUnique({
        where: { code },
        include: {
          ticket: {
            include: {
              event: {
                select: {
                  id: true,
                  title: true,
                  startDate: true,
                  endDate: true,
                  location: true,
                }
              }
            }
          },
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
            }
          }
        }
      });

      if (!ticket) {
        throw new Error('Invalid ticket code');
      }

      if (ticket.status !== 'ACTIVE') {
        throw new Error(`Ticket is ${ticket.status.toLowerCase()}`);
      }

      return ticket;
    } catch (error) {
      throw new Error(`Failed to validate ticket: ${error.message}`);
    }
  }

  // Use ticket (mark as used)
  async useTicket(code) {
    try {
      return await prisma.userTicket.update({
        where: { code },
        data: {
          status: 'USED',
          usedAt: new Date(),
        }
      });
    } catch (error) {
      throw new Error(`Failed to use ticket: ${error.message}`);
    }
  }

  // Transfer ticket to another user
  async transferTicket(code, newUserId) {
    try {
      const ticket = await this.validateTicket(code);
      
      if (!ticket.ticket.isTransferable) {
        throw new Error('This ticket is not transferable');
      }

      return await prisma.userTicket.update({
        where: { code },
        data: {
          userId: newUserId,
          transferredAt: new Date(),
        }
      });
    } catch (error) {
      throw new Error(`Failed to transfer ticket: ${error.message}`);
    }
  }

  // Generate unique ticket code
  generateTicketCode() {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substr(2, 5);
    return `TIX-${timestamp}-${random}`.toUpperCase();
  }

  // Get ticket sales analytics for an event
  async getTicketSalesAnalytics(eventId) {
    try {
      const tickets = await prisma.ticket.findMany({
        where: { eventId },
        include: {
          _count: {
            select: {
              purchases: true,
            }
          }
        }
      });

      const totalRevenue = await prisma.ticketPurchase.aggregate({
        where: {
          ticket: {
            eventId,
          },
          paymentStatus: 'COMPLETED',
        },
        _sum: {
          totalAmount: true,
        }
      });

      const totalSold = await prisma.userTicket.count({
        where: {
          ticket: {
            eventId,
          },
          status: {
            in: ['ACTIVE', 'USED'],
          }
        }
      });

      return {
        tickets,
        totalRevenue: totalRevenue._sum.totalAmount || 0,
        totalSold,
        totalCapacity: tickets.reduce((sum, ticket) => sum + ticket.quantity, 0),
      };
    } catch (error) {
      throw new Error(`Failed to get ticket analytics: ${error.message}`);
    }
  }
}

module.exports = new TicketService();
