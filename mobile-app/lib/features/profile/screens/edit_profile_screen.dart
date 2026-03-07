import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Professional edit profile screen for enterprise-level user management
/// Handles billing information, emergency contacts, and profile completion
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Loading states
  bool _isLoading = false;
  bool _isSaving = false;

  // Form controllers - Personal Information
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dateOfBirthController;

  User? _currentUser;

  // Profile picture variables
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }

  @override
  void dispose() {
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
  }

  void _disposeControllers() {
    // Personal Information
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
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
  }

  Future<void> _saveProfile() async {
    print('🔄 [EditProfile] Save button clicked');

    // Check individual field validation for debugging
    print('🔍 [EditProfile] Checking individual fields:');
    print('   First Name: "${_firstNameController.text}"');
    print('   Last Name: "${_lastNameController.text}"');
    print('   Phone: "${_phoneController.text}"');
    print('   Date of Birth: "${_dateOfBirthController.text}"');

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
      // Create updated user object with only personal information
      final updatedUser = _currentUser!.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _dateOfBirthController.text.trim().isNotEmpty
            ? DateTime.parse(_dateOfBirthController.text.trim())
            : null,
        profileCompleted: true, // Mark as completed when personal info is saved
      );

      print('💾 Attempting to save profile:');
      print('   Phone: "${updatedUser.phoneNumber}"');
      print('   Date of Birth: "${updatedUser.dateOfBirth}"');

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

  // Profile picture methods
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_currentUser?.profileImageUrl != null ||
                  _selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // Upload image to Cloudinary
        await _uploadImageToCloudinary();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
    // You might want to also update the backend to remove the image
  }

  Future<void> _uploadImageToCloudinary() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      print('🔄 [EDIT_PROFILE] Frontend-only profile picture update...');

      // Generate a unique image URL using the file path and timestamp for demo purposes
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final demoImageUrl = 'file://${_selectedImage!.path}?t=$timestamp';

      print('✅ [EDIT_PROFILE] Using frontend-only image: $demoImageUrl');

      // Simulate a brief upload delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Update the current user state immediately with the selected image
      setState(() {
        _currentUser = _currentUser!.copyWith(profileImageUrl: demoImageUrl);
        // Keep the selected image for display purposes
      });

      print(
          '🔄 [EDIT_PROFILE] Updated current user with new image URL: $demoImageUrl');

      // Update the auth provider with the new user data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.updateUserData(_currentUser!);

      print('✅ [EDIT_PROFILE] Updated AuthProvider with new user data');

      _showSuccessSnackBar(
          'Profile picture updated successfully! (Frontend demo mode)');
    } catch (e) {
      print('❌ [EDIT_PROFILE] Error in frontend image update: $e');
      _showErrorSnackBar('Failed to update profile picture: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: _buildPersonalInfoTab(),
            ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture Section
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: _selectedImage != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedImage!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _currentUser?.profileImageUrl != null &&
                                  _currentUser!.profileImageUrl!.isNotEmpty
                              ? ClipOval(
                                  child: _currentUser!.profileImageUrl!
                                          .startsWith('file://')
                                      ? Image.file(
                                          File(_currentUser!.profileImageUrl!
                                                  .replaceFirst('file://', '')
                                                  .split('?')[
                                              0]), // Remove query parameters
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            print(
                                                '🖼️ [EDIT_PROFILE] Failed to load local profile image: $error');
                                            return Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            );
                                          },
                                        )
                                      : Image.network(
                                          _currentUser!.profileImageUrl!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          key: ValueKey(_currentUser!
                                              .profileImageUrl), // Force rebuild when URL changes
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            print(
                                                '🖼️ [EDIT_PROFILE] Failed to load network profile image: $error');
                                            return Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            );
                                          },
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isUploadingImage
                              ? null
                              : _showImagePickerOptions,
                          icon: _isUploadingImage
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap the camera icon to change your profile picture',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

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
}
