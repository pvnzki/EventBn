import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/app_colors.dart';
import '../../../common_widgets/app_screen_header.dart';
import '../../../common_widgets/app_dark_text_field.dart';
import '../../../common_widgets/app_primary_button.dart';
import '../providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SignUpProfileScreen — "Personal information" form in the sign-up flow.
// Matches Figma nodes 2131:24803 (empty) and 2131:24855 (filled).
//
// This screen is FUNCTIONAL — it calls AuthProvider.register() on submit.
// ─────────────────────────────────────────────────────────────────────────────
class SignUpProfileScreen extends StatefulWidget {
  final String email;
  final String phone;
  final String password;

  const SignUpProfileScreen({
    super.key,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  State<SignUpProfileScreen> createState() => _SignUpProfileScreenState();
}

class _SignUpProfileScreenState extends State<SignUpProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;
  File? _profileImage;

  bool get _isFormValid =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _dateOfBirth != null &&
      _gender != null &&
      _agreedToTerms;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // ── Pick profile image ──────────────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked != null) {
        setState(() => _profileImage = File(picked.path));
      }
    } catch (_) {
      // Silently ignore if picker is unavailable
    }
  }

  // ── Pick date of birth ──────────────────────────────────────────────────
  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.dark,
              surface: AppColors.surface,
              onSurface: AppColors.white,
            ),
            dialogBackgroundColor: AppColors.background,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  // ── Pick gender ─────────────────────────────────────────────────────────
  void _pickGender() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              for (final g in ['Male', 'Female', 'Other', 'Prefer not to say'])
                ListTile(
                  title: Text(
                    g,
                    style: TextStyle(
                      fontFamily: appFontFamily,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: _gender == g ? AppColors.primary : AppColors.white,
                    ),
                  ),
                  trailing: _gender == g
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _gender = g);
                    Navigator.of(ctx).pop();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Show notification permission dialog (Figma 2131:24906) ─────────────
  void _showNotificationDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.grey200,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Title
                const Text(
                  'We would like to send you notifications',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: appFontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    height: 1.2,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                const Text(
                  'Notification may include alerts, sounds, and icon badges. These can be configured in settings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: appFontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1.2,
                    color: AppColors.grey200,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _proceedToRegister();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.divider,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: const Text(
                            "Don't Allow",
                            style: TextStyle(
                              fontFamily: appFontFamily,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _proceedToRegister();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.dark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Allow',
                            style: TextStyle(
                              fontFamily: appFontFamily,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Register and proceed ────────────────────────────────────────────────
  Future<void> _proceedToRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      final success = await authProvider.register(
        name: fullName,
        email: widget.email,
        password: widget.password,
        phoneNumber: widget.phone,
        dateOfBirth: _dateOfBirth,
      );

      if (!mounted) return;

      if (success) {
        context.go('/signup/success');
      } else {
        setState(() {
          _errorMessage = authProvider.error ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleContinue() {
    if (!_isFormValid) return;
    _showNotificationDialog();
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            const AppScreenHeader(title: 'Personal information'),

            // ── Scrollable body ─────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Profile picture ─────────────────────────
                    _buildProfileAvatar(),
                    const SizedBox(height: 20),

                    // ── Section title ───────────────────────────
                    const Text(
                      'Your Profile',
                      style: TextStyle(
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        height: 28 / 20,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Introduce yourself to others in your events',
                      style: TextStyle(
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                        color: AppColors.grey200,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── First name ──────────────────────────────
                    _buildLabel('First name'),
                    const SizedBox(height: 8),
                    AppDarkTextField(
                      controller: _firstNameController,
                      placeholder: 'Enter your first name',
                    ),
                    const SizedBox(height: 16),

                    // ── Last name ───────────────────────────────
                    _buildLabel('Last name'),
                    const SizedBox(height: 8),
                    AppDarkTextField(
                      controller: _lastNameController,
                      placeholder: 'Enter your last name',
                    ),
                    const SizedBox(height: 16),

                    // ── Date of Birth ───────────────────────────
                    _buildLabel('Date of Birth'),
                    const SizedBox(height: 8),
                    _buildDatePickerField(),
                    const SizedBox(height: 16),

                    // ── Gender ──────────────────────────────────
                    _buildLabel('Gender'),
                    const SizedBox(height: 8),
                    _buildGenderField(),
                    const SizedBox(height: 20),

                    // ── Terms checkbox ──────────────────────────
                    _buildTermsCheckbox(),

                    // ── Error message ───────────────────────────
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontFamily: appFontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1.2,
                          color: AppColors.dangerText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // ── Continue button ─────────────────────────
                    AppPrimaryButton(
                      label: 'Continue',
                      onPressed: _isFormValid ? _handleContinue : null,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Small builders ──────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: appFontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1.2,
        color: AppColors.grey200,
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.surface,
            backgroundImage:
                _profileImage != null ? FileImage(_profileImage!) : null,
            child: _profileImage == null
                ? Image.asset(
                    'assets/images/user placeholder image.png',
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_outline,
                      color: AppColors.grey200,
                      size: 36,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.grey200,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField() {
    final hasValue = _dateOfBirth != null;
    final displayText = hasValue
        ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
        : 'Enter your date of birth';

    return GestureDetector(
      onTap: _pickDateOfBirth,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontFamily: appFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.2,
                  color: hasValue ? AppColors.white : AppColors.grey200,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.grey200,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    final hasValue = _gender != null;

    return GestureDetector(
      onTap: _pickGender,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? _gender! : 'Select gender',
                style: TextStyle(
                  fontFamily: appFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.2,
                  color: hasValue ? AppColors.white : AppColors.grey200,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.grey200,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _agreedToTerms ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: _agreedToTerms
                  ? null
                  : Border.all(color: AppColors.grey300, width: 1.5),
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check, color: AppColors.dark, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: appFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.2,
                  color: AppColors.grey200,
                ),
                children: [
                  TextSpan(text: 'I agree to events  '),
                  TextSpan(
                    text: 'terms of use and privacy policy',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
