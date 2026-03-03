import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/design_tokens.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDIT PERSONAL INFORMATION — Figma node 2131:22429
//
// Cover photo background, centred avatar with camera overlay,
// form: First Name, Last Name, Date of Birth (picker), Gender (dropdown),
// "Save" action in the header.
// ─────────────────────────────────────────────────────────────────────────────

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _dobCtrl;

  String? _selectedGender;
  File? _selectedAvatar;
  File? _selectedCoverPhoto;
  bool _isSaving = false;
  User? _currentUser;

  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _dobCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  void _loadUser() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      setState(() {
        _currentUser = user;
        _firstNameCtrl.text = user.firstName;
        _lastNameCtrl.text = user.lastName;
        if (user.gender != null && _genders.contains(user.gender)) {
          _selectedGender = user.gender;
        }
        if (user.dateOfBirth != null) {
          _dobCtrl.text =
              '${user.dateOfBirth!.day.toString().padLeft(2, '0')}/${user.dateOfBirth!.month.toString().padLeft(2, '0')}/${user.dateOfBirth!.year}';
        }
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildHeader(context, isDark, bgColor),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(
                      label: 'First name',
                      controller: _firstNameCtrl,
                      isDark: isDark,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Last name',
                      controller: _lastNameCtrl,
                      isDark: isDark,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(isDark),
                    const SizedBox(height: 16),
                    _buildGenderField(isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header with cover photo, avatar, back, save ──────────────────────────
  Widget _buildHeader(BuildContext context, bool isDark, Color bgColor) {
    const coverHeight = 240.0;
    const avatarRadius = 44.0;
    final topPad = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: coverHeight + avatarRadius + topPad,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover photo — entire area tappable
          GestureDetector(
            onTap: _pickCoverPhoto,
            child: SizedBox(
              height: coverHeight + topPad,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _selectedCoverPhoto != null
                      ? Image.file(
                          _selectedCoverPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultCover(isDark),
                        )
                      : _currentUser?.coverPhotoUrl != null
                          ? Image.network(
                              _currentUser!.coverPhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _defaultCover(isDark),
                            )
                          : _defaultCover(isDark),
                  // Gradient fade
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 70,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [bgColor.withOpacity(0), bgColor],
                        ),
                      ),
                    ),
                  ),
                  // Camera hint icon — centred, low opacity
                  Center(
                    child: Opacity(
                      opacity: 0.35,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icons/camera icon.png',
                            width: 22,
                            height: 22,
                            color: Colors.white,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.camera_alt_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Safe-area bar: back + title + Save
          Positioned(
            top: topPad + 4,
            left: 8,
            right: 8,
            child: Row(
              children: [
                _circleButton(
                  child: Image.asset(
                    'assets/icons/arrow icon.png',
                    width: 20,
                    height: 20,
                    color: Colors.white,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit Personal Information',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.dark,
                    ),
                  ),
                ),
                _isSaving
                    ? const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: _save,
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),

          // Camera icon on cover photo — removed (cover is fully tappable)

          // Avatar with camera icon
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: bgColor, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: isDark
                          ? const Color(0xFF252525)
                          : const Color(0xFFE0E0E0),
                      backgroundImage: _avatarImage(),
                      child: _avatarImage() == null
                          ? Text(
                              _initials(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                fontFamily: kFontFamily,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.24),
                          shape: BoxShape.circle,
                          border: Border.all(color: bgColor, width: 2),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icons/camera icon.png',
                            width: 15,
                            height: 15,
                            color: Colors.white,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.camera_alt_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form fields ──────────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffix,
  }) {
    final fillColor = isDark ? AppColors.bg01 : const Color(0xFFF2F4F7);
    final labelColor = isDark ? AppColors.grey : AppColors.textSecondaryLight;
    final textColor = isDark ? AppColors.white : AppColors.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(bool isDark) {
    return _buildField(
      label: 'Date of Birth',
      controller: _dobCtrl,
      isDark: isDark,
      readOnly: true,
      onTap: _pickDate,
      suffix: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: isDark ? AppColors.grey : AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildGenderField(bool isDark) {
    final fillColor = isDark ? AppColors.bg01 : const Color(0xFFF2F4F7);
    final labelColor = isDark ? AppColors.grey : AppColors.textSecondaryLight;
    final textColor = isDark ? AppColors.white : AppColors.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          dropdownColor: isDark ? AppColors.surface : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? AppColors.grey : AppColors.textSecondaryLight,
          ),
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          hint: Text(
            'Select',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.grey : AppColors.textTertiaryLight,
            ),
          ),
          items: _genders.map((g) {
            return DropdownMenuItem(value: g, child: Text(g));
          }).toList(),
          onChanged: (val) => setState(() => _selectedGender = val),
        ),
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final initial =
        _currentUser?.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 20));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.surface,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _pickAvatar() async {
    final xfile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (xfile != null) {
      setState(() => _selectedAvatar = File(xfile.path));
    }
  }

  Future<void> _pickCoverPhoto() async {
    final xfile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 1200,
      imageQuality: 100,
    );
    if (xfile != null) {
      setState(() => _selectedCoverPhoto = File(xfile.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      DateTime? dob;
      if (_dobCtrl.text.isNotEmpty) {
        final parts = _dobCtrl.text.split('/'); // dd/MM/yyyy
        if (parts.length == 3) {
          dob = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      // Upload avatar & cover photo in parallel for speed
      String? newAvatarUrl;
      String? newCoverUrl;

      final uploads = await Future.wait([
        if (_selectedAvatar != null)
          _authService.uploadProfileImageFile(_selectedAvatar!)
        else
          Future.value(<String, dynamic>{'skip': true}),
        if (_selectedCoverPhoto != null)
          _authService.uploadCoverPhotoFile(_selectedCoverPhoto!)
        else
          Future.value(<String, dynamic>{'skip': true}),
      ]);

      final avatarResult = uploads[0];
      if (avatarResult['skip'] != true) {
        if (avatarResult['success'] == true) {
          newAvatarUrl = avatarResult['imageUrl'] as String?;
        } else {
          _showError('Avatar upload failed: ${avatarResult['message']}');
        }
      }

      final coverResult = uploads[1];
      if (coverResult['skip'] != true) {
        if (coverResult['success'] == true) {
          newCoverUrl = coverResult['imageUrl'] as String?;
        } else {
          _showError('Cover photo upload failed: ${coverResult['message']}');
        }
      }

      final updated = _currentUser!.copyWith(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        dateOfBirth: dob,
        gender: _selectedGender,
        profileImageUrl: newAvatarUrl ?? _currentUser!.profileImageUrl,
        coverPhotoUrl: newCoverUrl ?? _currentUser!.coverPhotoUrl,
        profileCompleted: true,
      );

      final result = await _authService.updateUserProfile(updated);

      if (result['success'] == true) {
        if (mounted) {
          Provider.of<AuthProvider>(context, listen: false).updateUser(updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        _showError('Failed to update: ${result['message']}');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _defaultCover(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)]
              : [const Color(0xFFE0E0E0), const Color(0xFFC0C0C0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _circleButton({
    required Widget child,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.24),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }

  ImageProvider? _avatarImage() {
    if (_selectedAvatar != null) return FileImage(_selectedAvatar!);
    if (_currentUser?.profileImageUrl != null) {
      return NetworkImage(_currentUser!.profileImageUrl!);
    }
    return null;
  }

  String _initials() {
    final f =
        _currentUser?.firstName.isNotEmpty == true ? _currentUser!.firstName[0] : '';
    final l =
        _currentUser?.lastName.isNotEmpty == true ? _currentUser!.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }
}
