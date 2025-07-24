import 'package:flutter/material.dart';

class CheckoutScreen extends StatelessWidget {
  final String eventId;
  final String ticketType;
  final int quantity;

  const CheckoutScreen({
    super.key,
    required this.eventId,
    required this.ticketType,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Checkout Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Event: $eventId', style: const TextStyle(fontSize: 16)),
            Text(
              'Ticket Type: $ticketType',
              style: const TextStyle(fontSize: 16),
            ),
            Text('Quantity: $quantity', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
