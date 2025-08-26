import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String eventId;
  final String ticketType;
  final int initialCount;
  const SeatSelectionScreen(
      {super.key,
      required this.eventId,
      required this.ticketType,
      this.initialCount = 1});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  int seatCount = 1;
  Set<int> selectedSeats = {};
  List<Map<String, dynamic>> seatMap = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    seatCount = widget.initialCount;
    _loadSeatMap();
  }

  Future<void> _loadSeatMap() async {
    try {
      final String baseUrl = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/${widget.eventId}/seatmap'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            seatMap = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load seat map');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error loading seat map: $e');
      // Fallback to local JSON if API fails
      final String jsonString = await rootBundle.loadString('assets/seat_map.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        seatMap = jsonData.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    }
  }

  void _toggleSeat(int seatId) {
    setState(() {
      if (selectedSeats.contains(seatId)) {
        selectedSeats.remove(seatId);
      } else if (selectedSeats.length < seatCount) {
        selectedSeats.add(seatId);
      }
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
        title: Text('Book Event',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTicketTypeTab('Economy'),
                const SizedBox(width: 32),
                _buildTicketTypeTab('VIP'),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: theme.dividerColor, thickness: 2),
            const SizedBox(height: 24),
            Text('Choose number of seats',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCountButton('-', () {
                  if (seatCount > 1) setState(() => seatCount--);
                  selectedSeats = selectedSeats.take(seatCount).toSet();
                }, theme),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text('$seatCount',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface)),
                ),
                _buildCountButton('+', () {
                  setState(() => seatCount++);
                }, theme),
              ],
            ),
            const SizedBox(height: 32),
            Text('Select your seats',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            Expanded(
              child: _buildSeatMap(theme),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                elevation: 4,
              ),
              onPressed: selectedSeats.length == seatCount && seatCount > 0
                  ? () {
                      // Navigate to contact info page using GoRouter
                      context.push(
                        '/checkout/${widget.eventId}/contact',
                        extra: {
                          'eventId': widget.eventId,
                          'ticketType': widget.ticketType,
                          'seatCount': seatCount,
                          'selectedSeats': selectedSeats.map((id) => id.toString()).toList(),
                        },
                      );
                    }
                  : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypeTab(String type) {
    final theme = Theme.of(context);
    final isSelected = widget.ticketType == type;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          Navigator.of(context).pushReplacementNamed(
              '/checkout/${widget.eventId}?ticketType=$type');
        }
      },
      child: Column(
        children: [
          Text(
            type,
            style: TextStyle(
              color: isSelected
                  ? theme.primaryColor
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            width: 60,
            decoration: BoxDecoration(
              color: isSelected ? theme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountButton(String label, VoidCallback onTap, ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatMap(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: false,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8, // 8 columns as before
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: seatMap.length,
      itemBuilder: (context, index) {
        final seat = seatMap[index];
        final seatLabel = seat['label'] as String;
        final seatId = seat['id'] as int;
        final isAvailable = seat['available'] as bool;
        final isSelected = selectedSeats.contains(seatId);
        final ticketType = seat['ticketType'] as String;
        final price = seat['price'];
        Color seatColor;
        if (!isAvailable) {
          seatColor = Colors.grey;
        } else if (isSelected) {
          seatColor = theme.primaryColor;
        } else if (ticketType == 'VIP') {
          seatColor = Colors.amber;
        } else {
          seatColor = theme.cardColor;
        }
        return GestureDetector(
          onTap: isAvailable ? () => _toggleSeat(seatId) : null,
          child: Container(
            decoration: BoxDecoration(
              color: seatColor,
              border: Border.all(
                color: isSelected
                    ? theme.primaryColor
                    : theme.dividerColor.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    seatLabel,
                    style: TextStyle(
                      color: isSelected || !isAvailable
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${price.toString()}',
                    style: TextStyle(
                      color: isSelected || !isAvailable
                          ? Colors.white70
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
