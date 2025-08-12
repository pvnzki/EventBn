import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  Set<String> selectedSeats = {};

  // Example seat map: 5 rows x 8 columns
  final int rows = 5;
  final int cols = 8;

  @override
  void initState() {
    super.initState();
    seatCount = widget.initialCount;
  }

  void _toggleSeat(String seatId) {
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
            _buildSeatMap(theme),
            const Spacer(),
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
                          'selectedSeats': selectedSeats.toList(),
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
    return SizedBox(
      height: 220,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: rows * cols,
        itemBuilder: (context, index) {
          final row = index ~/ cols;
          final col = index % cols;
          final seatId = String.fromCharCode(65 + row) + (col + 1).toString();
          final isSelected = selectedSeats.contains(seatId);
          return GestureDetector(
            onTap: () => _toggleSeat(seatId),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : theme.cardColor,
                border: Border.all(
                  color: isSelected
                      ? theme.primaryColor
                      : theme.dividerColor.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  seatId,
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
