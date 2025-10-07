import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';

/// Professional edit profile screen for enterprise-level user management
/// Handles billing information, emergency contacts, and profile completion
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Tab controller for professional sections
  late TabController _tabController;

  // Loading states
  bool _isLoading = false;
  bool _isSaving = false;

  // Form controllers - Personal Information
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dateOfBirthController;

  // Form controllers - Billing Address
  late TextEditingController _billingAddressController;
  late TextEditingController _billingCityController;
  late TextEditingController _billingStateController;
  late TextEditingController _billingCountryController;
  late TextEditingController _billingPostalCodeController;

  // Form controllers - Emergency Contact
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactPhoneController;
  late TextEditingController _emergencyContactRelationshipController;

  // Form controllers - Communication Preferences
  bool _marketingEmails = false;
  bool _eventNotifications = true;
  bool _smsNotifications = false;

  User? _currentUser;
  double _profileCompletionProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeControllers();
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    // Personal Information
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _dateOfBirthController = TextEditingController();

    // Billing Address
    _billingAddressController = TextEditingController();
    _billingCityController = TextEditingController();
    _billingStateController = TextEditingController();
    _billingCountryController = TextEditingController();
    _billingPostalCodeController = TextEditingController();

    // Emergency Contact
    _emergencyContactNameController = TextEditingController();
    _emergencyContactPhoneController = TextEditingController();
    _emergencyContactRelationshipController = TextEditingController();
  }

  void _disposeControllers() {
    // Personal Information
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();

    // Billing Address
    _billingAddressController.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingCountryController.dispose();
    _billingPostalCodeController.dispose();

    // Emergency Contact
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emergencyContactRelationshipController.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _populateFields(user);
          _calculateProfileCompletion();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFields(User user) {
    // Personal Information
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
    _dateOfBirthController.text = user.dateOfBirth != null
        ? '${user.dateOfBirth!.year}-${user.dateOfBirth!.month.toString().padLeft(2, '0')}-${user.dateOfBirth!.day.toString().padLeft(2, '0')}'
        : '';

    // Billing Address
    _billingAddressController.text = user.billingAddress ?? '';
    _billingCityController.text = user.billingCity ?? '';
    _billingStateController.text = user.billingState ?? '';
    _billingCountryController.text = user.billingCountry ?? '';
    _billingPostalCodeController.text = user.billingPostalCode ?? '';

    // Emergency Contact
    _emergencyContactNameController.text = user.emergencyContactName ?? '';
    _emergencyContactPhoneController.text = user.emergencyContactPhone ?? '';
    _emergencyContactRelationshipController.text =
        user.emergencyContactRelationship ?? '';

    // Communication Preferences
    _marketingEmails = user.marketingEmailsEnabled;
    _eventNotifications = user.eventNotificationsEnabled;
    _smsNotifications = user.smsNotificationsEnabled;
  }

  void _calculateProfileCompletion() {
    if (_currentUser == null) return;

    int completedFields = 0;
    int totalFields = 11; // Total required fields for professional profile

    // Personal Information (5 fields)
    if (_currentUser!.firstName.isNotEmpty) completedFields++;
    if (_currentUser!.lastName.isNotEmpty) completedFields++;
    if (_currentUser!.email.isNotEmpty) completedFields++;
    if (_currentUser!.phoneNumber?.isNotEmpty == true) completedFields++;
    if (_currentUser!.dateOfBirth != null) completedFields++;

    // Billing Address (5 fields)
    if (_currentUser!.billingAddress?.isNotEmpty == true) completedFields++;
    if (_currentUser!.billingCity?.isNotEmpty == true) completedFields++;
    if (_currentUser!.billingCountry?.isNotEmpty == true) completedFields++;
    if (_currentUser!.billingPostalCode?.isNotEmpty == true) completedFields++;

    // Emergency Contact (2 fields - relationship removed from calculation)
    if (_currentUser!.emergencyContactName?.isNotEmpty == true)
      completedFields++;
    if (_currentUser!.emergencyContactPhone?.isNotEmpty == true)
      completedFields++;

    setState(() {
      _profileCompletionProgress = completedFields / totalFields;
    });
  }

  Future<void> _saveProfile() async {
    print('🔄 [EditProfile] Save button clicked');

    // Check individual field validation for debugging
    print('🔍 [EditProfile] Checking individual fields:');
    print('   First Name: "${_firstNameController.text}"');
    print('   Last Name: "${_lastNameController.text}"');
    print('   Phone: "${_phoneController.text}"');
    print('   Date of Birth: "${_dateOfBirthController.text}"');
    print('   Billing Address: "${_billingAddressController.text}"');
    print('   Billing City: "${_billingCityController.text}"');
    print('   Billing Country: "${_billingCountryController.text}"');

    final isValid = _formKey.currentState!.validate();
    print('🔍 [EditProfile] Form validation result: $isValid');

    if (!isValid) {
      print('❌ [EditProfile] Form validation failed, aborting save');
      _showErrorSnackBar('Please fill in all required fields marked with *');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create updated user object
      final updatedUser = _currentUser!.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _dateOfBirthController.text.trim().isNotEmpty
            ? DateTime.parse(_dateOfBirthController.text.trim())
            : null,
        billingAddress: _billingAddressController.text.trim(),
        billingCity: _billingCityController.text.trim(),
        billingState: _billingStateController.text.trim(),
        billingCountry: _billingCountryController.text.trim(),
        billingPostalCode: _billingPostalCodeController.text.trim(),
        emergencyContactName: _emergencyContactNameController.text.trim(),
        emergencyContactPhone: _emergencyContactPhoneController.text.trim(),
        emergencyContactRelationship:
            _emergencyContactRelationshipController.text.trim(),
        marketingEmailsEnabled: _marketingEmails,
        eventNotificationsEnabled: _eventNotifications,
        smsNotificationsEnabled: _smsNotifications,
        profileCompleted:
            _profileCompletionProgress >= 0.8, // 80% completion required
      );

      print('💾 Attempting to save profile:');
      print('   Phone: "${updatedUser.phoneNumber}"');
      print('   Billing Address: "${updatedUser.billingAddress}"');
      print('   Billing City: "${updatedUser.billingCity}"');
      print('   Billing Country: "${updatedUser.billingCountry}"');
      print('   Emergency Name: "${updatedUser.emergencyContactName}"');
      print('   Emergency Phone: "${updatedUser.emergencyContactPhone}"');

      // Update user profile using AuthService
      final result = await _authService.updateUserProfile(updatedUser);

      if (result['success'] == true) {
        // Update local state
        setState(() {
          _currentUser = updatedUser;
        });

        if (result['warning'] != null) {
          _showSuccessSnackBar(
              'Profile updated successfully! (${result['warning']})');
        } else {
          _showSuccessSnackBar('Profile updated successfully in database!');
        }
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        _showErrorSnackBar('Failed to update profile: ${result['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dateOfBirthController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Personal', icon: Icon(Icons.person_outline)),
            Tab(text: 'Billing', icon: Icon(Icons.location_on_outlined)),
            Tab(text: 'Emergency', icon: Icon(Icons.emergency_outlined)),
            Tab(text: 'Preferences', icon: Icon(Icons.settings_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile Completion Progress
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile Completion',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '${(_profileCompletionProgress * 100).round()}%',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _profileCompletionProgress,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _profileCompletionProgress >= 0.8
                              ? Colors.green
                              : colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profileCompletionProgress >= 0.8
                            ? 'Profile complete - Ready for seamless payments!'
                            : 'Complete your profile for faster checkout',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Tab Content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPersonalInfoTab(),
                        _buildBillingAddressTab(),
                        _buildEmergencyContactTab(),
                        _buildPreferencesTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Basic information for your account and event bookings.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // First Name
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'First name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Last Name
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Last name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email (readonly)
          TextFormField(
            controller: _emailController,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
              helperText: 'Email cannot be changed from this screen',
            ),
          ),
          const SizedBox(height: 16),

          // Phone Number
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_outlined),
              helperText:
                  'Enter your phone number (with or without country code)',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Phone number is required';
              }
              // More flexible phone validation - accept various formats
              final phoneValue = value!.trim();
              if (phoneValue.length < 7) {
                return 'Phone number must be at least 7 digits';
              }
              // Allow numbers with or without country codes, with or without special characters
              if (!RegExp(r'^[\+\-\s\(\)0-9]+$').hasMatch(phoneValue)) {
                return 'Phone number contains invalid characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Date of Birth
          TextFormField(
            controller: _dateOfBirthController,
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today_outlined),
              helperText: 'Optional - for age verification at events',
            ),
            readOnly: true,
            onTap: _selectDate,
            validator: null, // Make date of birth optional
          ),
        ],
      ),
    );
  }

  Widget _buildBillingAddressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Billing Address',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This information will be used for payment processing and receipts.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Billing Address
          TextFormField(
            controller: _billingAddressController,
            decoration: const InputDecoration(
              labelText: 'Address Line *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home_outlined),
              helperText: 'Street address, apartment, building, etc.',
            ),
            maxLines: 2,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Address is required for payment processing';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // City and State Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _billingCityController,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'City is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _billingStateController,
                  decoration: const InputDecoration(
                    labelText: 'State/Province',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Country and Postal Code Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _billingCountryController,
                  decoration: const InputDecoration(
                    labelText: 'Country *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.public_outlined),
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Country is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _billingPostalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Postal Code',
                    border: OutlineInputBorder(),
                  ),
                  validator: null, // Make postal code optional
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your billing address is securely stored and used only for payment verification and receipt generation.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Contact',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Emergency contact information for safety at events.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Emergency Contact Name
          TextFormField(
            controller: _emergencyContactNameController,
            decoration: const InputDecoration(
              labelText: 'Emergency Contact Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
              helperText: 'Optional - Full name of your emergency contact',
            ),
            validator: (value) {
              // Emergency contact is optional for basic profile saving
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Emergency Contact Phone
          TextFormField(
            controller: _emergencyContactPhoneController,
            decoration: const InputDecoration(
              labelText: 'Emergency Contact Phone',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_outlined),
              helperText:
                  'Optional - Include country code (e.g., +94xxxxxxxxx)',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              // Emergency contact phone is optional for basic profile saving
              if (value?.trim().isNotEmpty == true) {
                if (!RegExp(r'^\+\d{10,15}$').hasMatch(value!.trim())) {
                  return 'Enter a valid phone number with country code';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Emergency Contact Relationship
          TextFormField(
            controller: _emergencyContactRelationshipController,
            decoration: const InputDecoration(
              labelText: 'Relationship',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.family_restroom_outlined),
              helperText: 'Optional - e.g., Parent, Spouse, Sibling, Friend',
            ),
            validator: (value) {
              // Emergency contact relationship is optional for basic profile saving
              return null;
            },
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.emergency_outlined,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Contact Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This information will only be used in case of emergency during events. Your privacy is protected.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Communication Preferences',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to receive notifications and updates.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Event Notifications
          Card(
            child: SwitchListTile(
              title: const Text('Event Notifications'),
              subtitle:
                  const Text('Receive notifications about your booked events'),
              value: _eventNotifications,
              onChanged: (value) {
                setState(() {
                  _eventNotifications = value;
                });
              },
              secondary: const Icon(Icons.event_outlined),
            ),
          ),

          const SizedBox(height: 8),

          // Marketing Emails
          Card(
            child: SwitchListTile(
              title: const Text('Marketing Emails'),
              subtitle: const Text(
                  'Receive promotional offers and event recommendations'),
              value: _marketingEmails,
              onChanged: (value) {
                setState(() {
                  _marketingEmails = value;
                });
              },
              secondary: const Icon(Icons.mail_outline),
            ),
          ),

          const SizedBox(height: 8),

          // SMS Notifications
          Card(
            child: SwitchListTile(
              title: const Text('SMS Notifications'),
              subtitle: const Text('Receive important updates via SMS'),
              value: _smsNotifications,
              onChanged: (value) {
                setState(() {
                  _smsNotifications = value;
                });
              },
              secondary: const Icon(Icons.sms_outlined),
            ),
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can change these preferences at any time. We respect your privacy and follow data protection regulations.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
