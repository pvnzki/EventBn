import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

class ContactInfoScreen extends StatefulWidget {
  final String eventId;
  final String eventName;
  final String eventDate;
  final String ticketType;
  final int seatCount;
  final List<String> selectedSeats;
  final List<Map<String, dynamic>> selectedSeatData; // Full seat data with prices
  
  const ContactInfoScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.ticketType,
    required this.seatCount,
    required this.selectedSeats,
    required this.selectedSeatData,
  });

  @override
  State<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool isLoading = true;
  String name = '';
  String email = '';
  String phone = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService().getCurrentUser();
      
      if (user != null) {
        setState(() {
          name = user.fullName;  // Use fullName getter from User model
          email = user.email;
          phone = user.phoneNumber ?? '';
          
          _nameController.text = name;
          _emailController.text = email;
          _phoneController.text = phone;
          
          isLoading = false;
        });
      } else {
        print('No user found');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => isLoading = false);
    }
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
        title: Text('Contact Info',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter your contact details',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.colorScheme.onSurface)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController, // Add controller for name field
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter your name'
                    : null,
                onChanged: (value) => name = value, // Update onChanged instead of onSaved
              ),
              const SizedBox(height: 16),
              TextFormField(
              controller: _emailController,
              enabled: false, // Make email read-only
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your email';
                }
                if (!value!.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              onChanged: (value) => email = value,
            ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController, // Add controller for phone field
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter your phone number'
                    : null,
                onChanged: (value) => phone = value, // Update onChanged instead of onSaved
              ),
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
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    // Navigate to payment page using GoRouter
                    context.push(
                      '/checkout/${widget.eventId}/payment',
                      extra: {
                        'eventId': widget.eventId,
                        'eventName': widget.eventName,
                        'eventDate': widget.eventDate,
                        'ticketType': widget.ticketType,
                        'seatCount': widget.seatCount,
                        'selectedSeats': widget.selectedSeats,
                        'selectedSeatData': widget.selectedSeatData,
                        'name': name,
                        'email': email,
                        'phone': phone,
                      },
                    );
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
