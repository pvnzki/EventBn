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
          final List<dynamic> ticketsData = data['tickets'] ?? [];
          
          // Convert the ticket data to Ticket objects
          final List<Ticket> tickets = ticketsData.map((ticketData) {
            return Ticket(
              id: ticketData['ticket_id'] ?? '',
              eventId: ticketData['event_id']?.toString() ?? '',
              eventTitle: ticketData['event']?['title'] ?? '',
              eventImageUrl: ticketData['event']?['cover_image_url'] ?? '',
              userId: ticketData['user_id']?.toString() ?? '',
              ticketTypeId: ticketData['seat_id']?.toString() ?? '',
              ticketTypeName: ticketData['seat_label'] ?? 'General',
              price: (ticketData['price']?.toDouble() ?? 0.0) / 100, // Convert from cents to LKR
              quantity: 1,
              totalAmount: (ticketData['price']?.toDouble() ?? 0.0) / 100, // Convert from cents to LKR
              qrCode: ticketData['qr_code'] ?? '',
              status: ticketData['attended'] == true 
                  ? TicketStatus.used 
                  : TicketStatus.active,
              purchaseDate: ticketData['purchase_date'] != null 
                  ? DateTime.parse(ticketData['purchase_date'])
                  : DateTime.now(),
              eventStartDate: ticketData['event']?['start_time'] != null 
                  ? DateTime.parse(ticketData['event']['start_time'])
                  : DateTime.now(),
              venue: ticketData['event']?['venue'] ?? '',
              address: ticketData['event']?['location'] ?? '',
            );
          }).toList();

          return {
            'success': true,
            'tickets': tickets,
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
            price: (ticketData['price']?.toDouble() ?? 0.0) / 100, // Convert from cents to LKR
            quantity: 1,
            totalAmount: (ticketData['price']?.toDouble() ?? 0.0) / 100, // Convert from cents to LKR
            qrCode: ticketData['qr_code'] ?? '',
            status: ticketData['attended'] == true 
                ? TicketStatus.used 
                : TicketStatus.active,
            purchaseDate: ticketData['purchase_date'] != null 
                ? DateTime.parse(ticketData['purchase_date'])
                : DateTime.now(),
            eventStartDate: ticketData['event']?['start_time'] != null 
                ? DateTime.parse(ticketData['event']['start_time'])
                : DateTime.now(),
            venue: ticketData['event']?['venue'] ?? '',
            address: ticketData['event']?['location'] ?? '',
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
          'message': 'Failed to fetch ticket details. Status: ${response.statusCode}',
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
}
