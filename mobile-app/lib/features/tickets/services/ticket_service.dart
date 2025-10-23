import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';
import '../models/ticket_model.dart';

class TicketService {
  final String baseUrl = AppConfig.baseUrl;
  final AuthService _authService = AuthService();

  // Fetch user's tickets
  Future<Map<String, dynamic>> getUserTickets() async {
    try {
      final token = await _authService.getStoredToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/tickets/my-tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Process all tickets for backward compatibility
          final List<dynamic> allTicketsData = data['tickets'] ?? [];
          final List<Ticket> allTickets = _parseTicketsFromData(allTicketsData);

          // Process upcoming payment groups from the new API structure
          final List<dynamic> upcomingGroupsData = data['upcoming']?['payment_groups'] ?? [];
          final List<PaymentGroup> upcomingPaymentGroups = _parsePaymentGroupsFromData(upcomingGroupsData);

          // Process completed tickets
          final List<dynamic> completedTicketsData = data['completed']?['tickets'] ?? [];
          final List<Ticket> completedTickets = _parseTicketsFromData(completedTicketsData);

          // Process cancelled tickets
          final List<dynamic> cancelledTicketsData = data['cancelled']?['tickets'] ?? [];
          final List<Ticket> cancelledTickets = _parseTicketsFromData(cancelledTicketsData);

          return {
            'success': true,
            'tickets': allTickets, // For backward compatibility
            'upcoming_payment_groups': upcomingPaymentGroups,
            'completed_tickets': completedTickets,
            'cancelled_tickets': cancelledTickets,
            'upcoming_count': data['upcoming']?['count'] ?? 0,
            'completed_count': data['completed']?['count'] ?? 0,
            'cancelled_count': data['cancelled']?['count'] ?? 0,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch tickets',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch tickets. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred: ${e.toString()}',
      };
    }
  }

  // Helper method to parse tickets from API data
  List<Ticket> _parseTicketsFromData(List<dynamic> ticketsData) {
    return ticketsData.map((ticketData) {
      return Ticket(
        id: ticketData['ticket_id'] ?? '',
        eventId: ticketData['event_id']?.toString() ?? '',
        eventTitle: ticketData['Event']?['title'] ?? ticketData['event']?['title'] ?? '',
        eventImageUrl: ticketData['Event']?['cover_image_url'] ?? ticketData['event']?['cover_image_url'] ?? '',
        userId: ticketData['user_id']?.toString() ?? '',
        ticketTypeId: ticketData['seat_id']?.toString() ?? '',
        ticketTypeName: ticketData['seat_label'] ?? 'General',
        price: (ticketData['price']?.toDouble() ?? 0.0) / 100, // Convert from cents to LKR
        quantity: 1,
        totalAmount: (ticketData['price']?.toDouble() ?? 0.0) / 100, // Convert from cents to LKR
        qrCode: ticketData['qr_code'] ?? '',
    status: ticketData['attended'] == true
      ? TicketStatus.used
      : ((ticketData['status'] == 'CANCELLED' || ticketData['status'] == 'refunded' ||
        (ticketData['payment'] != null && ticketData['payment']['status'] == 'refunded'))
        ? TicketStatus.cancelled
        : TicketStatus.active),
        purchaseDate: ticketData['purchase_date'] != null
            ? DateTime.parse(ticketData['purchase_date'])
            : DateTime.now(),
        eventStartDate: ticketData['Event']?['start_time'] != null
            ? DateTime.parse(ticketData['Event']['start_time'])
            : (ticketData['event']?['start_time'] != null
                ? DateTime.parse(ticketData['event']['start_time'])
                : DateTime.now()),
        venue: ticketData['Event']?['venue'] ?? ticketData['event']?['venue'] ?? '',
        address: ticketData['Event']?['location'] ?? ticketData['event']?['location'] ?? '',
        paymentId: ticketData['payment_id']?.toString() ?? '',
      );
    }).toList();
  }

  // Helper method to parse payment groups from API data
  List<PaymentGroup> _parsePaymentGroupsFromData(List<dynamic> groupsData) {
    return groupsData.map((groupData) {
      // Parse tickets within this group
      final List<dynamic> ticketsData = groupData['tickets'] ?? [];
      final List<Ticket> tickets = _parseTicketsFromData(ticketsData);

      return PaymentGroup(
        paymentId: groupData['payment_id'] ?? '',
        tickets: tickets,
        totalAmount: (groupData['total_amount']?.toDouble() ?? 0.0) / 100, // Convert from cents
        purchaseDate: tickets.isNotEmpty ? tickets.first.purchaseDate : DateTime.now(),
        paymentMethod: groupData['payment_method'] ?? 'Card',
        paymentStatus: groupData['payment_status'] ?? 'completed',
        eventTitle: groupData['event_title'],
        eventStartTime: groupData['event_start_time'] != null 
            ? DateTime.parse(groupData['event_start_time']) 
            : null,
        eventVenue: groupData['event_venue'],
        eventLocation: groupData['event_location'],
        coverImageUrl: groupData['cover_image_url'],
        ticketCount: groupData['ticket_count']?.toInt() ?? tickets.length,
        canCancel: groupData['can_cancel'] ?? false,
        hoursUntilEvent: groupData['hours_until_event']?.toDouble(),
      );
    }).toList();
  }

  // Get ticket by QR code
  Future<Map<String, dynamic>> getTicketByQR(String qrCode) async {
    try {
      final token = await _authService.getStoredToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/tickets/qr/$qrCode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'message': 'Ticket not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred: ${e.toString()}',
      };
    }
  }

  // Get individual ticket details by ticket ID
  Future<Map<String, dynamic>> getTicketDetails(String ticketId) async {
    try {
      final token = await _authService.getStoredToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/tickets/$ticketId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final ticketData = data['ticket'];

          // Convert to Ticket object
          final ticket = Ticket(
            id: ticketData['ticket_id'] ?? '',
            eventId: ticketData['event_id']?.toString() ?? '',
            eventTitle: ticketData['event']?['title'] ?? '',
            eventImageUrl: ticketData['event']?['cover_image_url'] ?? '',
            userId: ticketData['user_id']?.toString() ?? '',
            ticketTypeId: ticketData['seat_id']?.toString() ?? '',
            ticketTypeName: ticketData['seat_label'] ?? 'General',
            price: (ticketData['price']?.toDouble() ?? 0.0) /
                100, // Convert from cents to LKR
            quantity: 1,
            totalAmount: (ticketData['price']?.toDouble() ?? 0.0) /
                100, // Convert from cents to LKR
            qrCode: ticketData['qr_code'] ?? '',
            status: ticketData['attended'] == true
                ? TicketStatus.used
                : (ticketData['status'] == 'CANCELLED' 
                    ? TicketStatus.cancelled 
                    : TicketStatus.active),
            purchaseDate: ticketData['purchase_date'] != null
                ? DateTime.parse(ticketData['purchase_date'])
                : DateTime.now(),
            eventStartDate: ticketData['event']?['start_time'] != null
                ? DateTime.parse(ticketData['event']['start_time'])
                : DateTime.now(),
            venue: ticketData['event']?['venue'] ?? '',
            address: ticketData['event']?['location'] ?? '',
            paymentId: ticketData['payment_id']?.toString() ?? '',
          );

          return {
            'success': true,
            'ticket': ticket,
            'rawData': ticketData, // Include raw data for additional fields
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch ticket details',
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Ticket not found or access denied',
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch ticket details. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred: ${e.toString()}',
      };
    }
  }

  // Mark ticket as attended (for organizers)
  Future<Map<String, dynamic>> markTicketAttended(String ticketId) async {
    try {
      final token = await _authService.getStoredToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/tickets/$ticketId/attend'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'message': 'Failed to mark ticket as attended',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred: ${e.toString()}',
      };
    }
  }

  // Get individual ticket details by payment ID
  Future<Map<String, dynamic>> getTicketDetailsByPaymentId(
      String paymentId) async {
    try {
      final token = await _authService.getStoredToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/tickets/by-payment/$paymentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final ticketData = data['ticket'];

          // Convert to Ticket object
          final ticket = Ticket(
            id: ticketData['ticket_id'] ?? '',
            eventId: ticketData['event_id']?.toString() ?? '',
            eventTitle: ticketData['event']?['title'] ?? '',
            eventImageUrl: ticketData['event']?['cover_image_url'] ?? '',
            userId: ticketData['user_id']?.toString() ?? '',
            ticketTypeId: ticketData['seat_id']?.toString() ?? '',
            ticketTypeName: ticketData['seat_label'] ?? 'General',
            price: (ticketData['price']?.toDouble() ?? 0.0) /
                100, // Convert from cents to LKR
            quantity: 1,
            totalAmount: (ticketData['price']?.toDouble() ?? 0.0) /
                100, // Convert from cents to LKR
            qrCode: ticketData['qr_code'] ?? '',
            status: ticketData['attended'] == true
                ? TicketStatus.used
                : (ticketData['status'] == 'CANCELLED' 
                    ? TicketStatus.cancelled 
                    : TicketStatus.active),
            purchaseDate: ticketData['purchase_date'] != null
                ? DateTime.parse(ticketData['purchase_date'])
                : DateTime.now(),
            eventStartDate: ticketData['event']?['start_time'] != null
                ? DateTime.parse(ticketData['event']['start_time'])
                : DateTime.now(),
            venue: ticketData['event']?['venue'] ?? '',
            address: ticketData['event']?['location'] ?? '',
            paymentId: ticketData['payment_id']?.toString() ?? '',
          );

          return {
            'success': true,
            'ticket': ticket,
            'rawData': ticketData, // Include raw data for additional fields
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch ticket details',
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Ticket not found or access denied',
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to fetch ticket details. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred: ${e.toString()}',
      };
    }
  }

  // Cancel all tickets for a specific payment
  Future<Map<String, dynamic>> cancelTicketsByPayment(String paymentId) async {
    try {
      final token = await _authService.getStoredToken();

      if (token == null) {
        print('🚨 TicketService: User not authenticated');
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      print('🎫 TicketService: Starting cancellation for payment: $paymentId');
      print('🔗 TicketService: API URL: $baseUrl/api/tickets/payment/$paymentId/cancel');

      final response = await http.put(
        Uri.parse('$baseUrl/api/tickets/payment/$paymentId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🎫 TicketService: Response status: ${response.statusCode}');
      print('🎫 TicketService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ TicketService: Cancellation successful');
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Tickets cancelled successfully',
          'tickets': data['tickets'],
          'cancelledCount': data['cancelledCount'],
        };
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        print('❌ TicketService: Bad request - ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Unable to cancel tickets',
        };
      } else if (response.statusCode == 404) {
        print('❌ TicketService: Payment not found');
        return {
          'success': false,
          'message': 'Payment not found',
        };
      } else {
        print('❌ TicketService: Unexpected status code: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to cancel tickets. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('🚨 TicketService: Network error during cancellation: $e');
      return {
        'success': false,
        'message': 'Network error occurred: ${e.toString()}',
      };
    }
  }
}
