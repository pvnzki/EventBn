import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';

class TicketTypeSelectionScreen extends StatefulWidget {
  final String eventId;
  final String ticketType;
  final int initialCount;

  const TicketTypeSelectionScreen({
    super.key,
    required this.eventId,
    required this.ticketType,
    this.initialCount = 1,
  });

  @override
  State<TicketTypeSelectionScreen> createState() =>
      _TicketTypeSelectionScreenState();
}

class _TicketTypeSelectionScreenState extends State<TicketTypeSelectionScreen> {
  Map<String, Map<String, dynamic>> ticketTypes = {};
  Map<String, int> selectedQuantities = {};
  bool isLoading = true;
  String eventName = '';
  String eventDate = '';

  @override
  void initState() {
    super.initState();
    _loadTicketTypes();
    _loadEventDetails();
  }

  Future<void> _loadTicketTypes() async {
    try {
      final String baseUrl = AppConfig.baseUrl;
      print('🔧 TicketTypeSelection - BaseURL: "$baseUrl"');
      print('🔧 TicketTypeSelection - EventID: "${widget.eventId}"');

      final uri = '$baseUrl/api/events/${widget.eventId}/seatmap';
      print('🔧 TicketTypeSelection - Full URI: "$uri"');

      final response = await http.get(
        Uri.parse(uri),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final seatMapData = data['data'];
          
          // If this screen is loaded, it means the event has no custom seating
          // and the backend should provide standard ticket types
          if (seatMapData['ticketTypes'] != null) {
            final backendTicketTypes = seatMapData['ticketTypes'] as Map<String, dynamic>;
            
            // Convert the backend response to the expected format with proper type conversion
            final Map<String, Map<String, dynamic>> convertedTicketTypes = {};
            backendTicketTypes.forEach((key, value) {
              final ticketTypeData = value as Map<String, dynamic>;
              convertedTicketTypes[key] = {
                'price': (ticketTypeData['price'] as num).toDouble(),
                'totalSeats': ticketTypeData['totalSeats'] as int,
                'availableSeats': ticketTypeData['availableSeats'] as int,
              };
            });

            setState(() {
              ticketTypes = convertedTicketTypes;
              selectedQuantities = Map.fromIterable(
                convertedTicketTypes.keys,
                key: (type) => type,
                value: (type) => 0,
              );
              isLoading = false;
            });
          } else {
            throw Exception('No ticket types provided by backend');
          }
        } else {
          throw Exception('Invalid response from server');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error loading ticket types: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadEventDetails() async {
    try {
      final String baseUrl = AppConfig.baseUrl;
      print('🔧 TicketTypeSelection - Event Details BaseURL: "$baseUrl"');

      final uri = '$baseUrl/api/events/${widget.eventId}';
      print('🔧 TicketTypeSelection - Event Details URI: "$uri"');

      final response = await http.get(
        Uri.parse(uri),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final event = data['data'];
          setState(() {
            eventName = event['title'] ?? 'Event';
            if (event['start_time'] != null) {
              final DateTime startTime = DateTime.parse(event['start_time']);
              eventDate =
                  '${startTime.day}/${startTime.month}/${startTime.year} ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
            } else {
              eventDate = 'Date TBA';
            }
          });
        }
      }
    } catch (e) {
      print('Error loading event details: $e');
      setState(() {
        eventName = 'Event';
        eventDate = 'Date TBA';
      });
    }
  }

  void _updateQuantity(String ticketType, int change) {
    setState(() {
      final currentQuantity = selectedQuantities[ticketType] ?? 0;
      final maxAvailable = ticketTypes[ticketType]?['availableSeats'] ?? 0;
      final newQuantity =
          (currentQuantity + change).clamp(0, maxAvailable).toInt();
      selectedQuantities[ticketType] = newQuantity;
    });
  }

  int get totalTickets {
    return selectedQuantities.values.fold(0, (sum, quantity) => sum + quantity);
  }

  double get totalPrice {
    double total = 0;
    selectedQuantities.forEach((type, quantity) {
      final dynamic priceValue = ticketTypes[type]?['price'] ?? 0.0;
      final double price =
          (priceValue is int) ? priceValue.toDouble() : priceValue as double;
      total += price * quantity;
    });
    return total;
  }

  void _proceedToPayment() {
    if (totalTickets == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one ticket')),
      );
      return;
    }

    // Create selected seat data for compatibility with existing flow
    List<Map<String, dynamic>> selectedSeatData = [];
    List<String> selectedSeats = [];
    int seatIdCounter = 1;

    selectedQuantities.forEach((type, quantity) {
      final dynamic priceValue = ticketTypes[type]?['price'] ?? 0.0;
      final double price =
          (priceValue is int) ? priceValue.toDouble() : priceValue as double;
      for (int i = 0; i < quantity; i++) {
        final String seatLabel = '$type Ticket ${i + 1}';
        selectedSeatData.add({
          'id': seatIdCounter++,
          'label': seatLabel,
          'ticketType': type,
          'price': price,
          'available': true,
        });
        selectedSeats.add(seatLabel);
      }
    });

    context.go('/booking/${widget.eventId}/order-summary', extra: {
      'eventId': widget.eventId,
      'eventName': eventName,
      'eventDate': eventDate,
      'selectedSeatData': selectedSeatData,
      'selectedSeats': selectedSeats,
      'totalPrice': totalPrice,
      'ticketCount': totalTickets,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text(
          'Select Tickets',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Event info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              eventDate,
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Select Ticket Types',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ticket types list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ticketTypes.length,
                    itemBuilder: (context, index) {
                        final type = ticketTypes.keys.elementAt(index);
                        final data = ticketTypes[type]!;
                        final price = data['price'] as double;
                        final availableSeats = data['availableSeats'] as int;
                        final selectedQuantity = selectedQuantities[type] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedQuantity > 0
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                              width: selectedQuantity > 0 ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$availableSeats seats available',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity selector
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: selectedQuantity > 0
                                          ? () => _updateQuantity(type, -1)
                                          : null,
                                      icon: Icon(
                                        Icons.remove,
                                        color: selectedQuantity > 0
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.3),
                                      ),
                                    ),
                                    Container(
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Text(
                                        selectedQuantity.toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          selectedQuantity < availableSeats
                                              ? () => _updateQuantity(type, 1)
                                              : null,
                                      icon: Icon(
                                        Icons.add,
                                        color: selectedQuantity < availableSeats
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface
                                                .withOpacity(0.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Bottom section with total and proceed button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total: $totalTickets tickets',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            '\$${totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: totalTickets > 0 ? _proceedToPayment : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Proceed',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
