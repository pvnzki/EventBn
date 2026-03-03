import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../common_widgets/app_bottom_sheet.dart';
import '../../../common_widgets/app_primary_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/two_factor_service.dart';
import '../../auth/screens/security_settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PASSWORD & SECURITY — Figma node 2131:22476
//
// List items:
//   • Change Password    (lock icon + chevron → bottom sheet)
//   • Phone Number       (value + "Verified" tag)
//   • Email Address      (value + "Verified" tag)
//
// Two-Factor Authentication section:
//   • Toggle to enable / disable 2FA
// ─────────────────────────────────────────────────────────────────────────────

class PasswordSecurityScreen extends StatefulWidget {
  const PasswordSecurityScreen({super.key});

  @override
  State<PasswordSecurityScreen> createState() => _PasswordSecurityScreenState();
}

class _PasswordSecurityScreenState extends State<PasswordSecurityScreen> {
  final TwoFactorService _twoFactorService = TwoFactorService();
  bool _twoFactorEnabled = false;
  bool _isLoading2FA = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final result = await _twoFactorService.getSecuritySettings();
      if (result['success'] == true && mounted) {
        setState(() {
          _twoFactorEnabled = result['twoFactorEnabled'] ?? false;
          _isLoading2FA = false;
        });
      } else if (mounted) {
        setState(() => _isLoading2FA = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading2FA = false);
    }
  }

  void _showTwoFactorSetup() {
    Navigator.of(context)
        .push(CupertinoPageRoute(
          builder: (_) => const TwoFactorSetupScreen(),
        ))
        .then((_) => _loadSecuritySettings());
  }

  void _showTwoFactorDisable() {
    Navigator.of(context)
        .push(CupertinoPageRoute(
          builder: (_) => const TwoFactorDisableScreen(),
        ))
        .then((_) => _loadSecuritySettings());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.bgLight;
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow icon.png',
            width: 24,
            height: 24,
            color: isDark ? AppColors.white : AppColors.dark,
            errorBuilder: (_, __, ___) => Icon(
              Icons.chevron_left,
              color: isDark ? AppColors.white : AppColors.dark,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Password & Security',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.dark,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Credentials section ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Change Password
                  _SecurityTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    isDark: isDark,
                    onTap: () => _showChangePasswordSheet(context, isDark),
                  ),
                  _divider(isDark),
                  // Phone Number
                  _SecurityTile(
                    icon: Icons.phone_outlined,
                    title: 'Phone Number',
                    subtitle: user?.phoneNumber ?? 'Not set',
                    verified: user?.phoneNumber != null &&
                        user!.phoneNumber!.isNotEmpty,
                    isDark: isDark,
                    onTap: () => _showChangePhoneSheet(context, isDark),
                  ),
                  _divider(isDark),
                  // Email Address
                  _SecurityTile(
                    icon: Icons.email_outlined,
                    title: 'Email Address',
                    subtitle: user?.email ?? 'Not set',
                    verified: user?.email.isNotEmpty == true,
                    isDark: isDark,
                    onTap: () => _showChangeEmailSheet(context, isDark),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Two-Factor Authentication section ────────────────────
            _sectionLabel('Two-Factor Authentication', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.security_rounded,
                      color: isDark
                          ? AppColors.grey300
                          : AppColors.textSecondaryLight,
                      size: 22,
                    ),
                    title: Text(
                      'Enable 2FA',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.white : AppColors.dark,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _twoFactorEnabled
                            ? '2FA is enabled — your account is more secure'
                            : 'Add an extra layer of security',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? AppColors.grey
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    trailing: _isLoading2FA
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Switch(
                            value: _twoFactorEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              if (val) {
                                _showTwoFactorSetup();
                              } else {
                                _showTwoFactorDisable();
                              }
                            },
                          ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: kFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.grey : AppColors.textSecondaryLight,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 54,
      color: isDark ? AppColors.divider : const Color(0xFFE8E9EA),
    );
  }

  // ── Change Password Bottom Sheet ─────────────────────────────────────────
  void _showChangePasswordSheet(BuildContext context, bool isDark) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final authService = AuthService();

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => _ChangePasswordSheet(
        formKey: formKey,
        currentCtrl: currentCtrl,
        newCtrl: newCtrl,
        confirmCtrl: confirmCtrl,
        isDark: isDark,
        onSave: () async {
          if (!formKey.currentState!.validate()) return;
          final result = await authService.changePassword(
            currentPassword: currentCtrl.text.trim(),
            newPassword: newCtrl.text.trim(),
          );
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['success'] == true
                      ? 'Password changed successfully'
                      : result['message'] ?? 'Failed',
                ),
                backgroundColor:
                    result['success'] == true ? AppColors.primary : AppColors.error,
              ),
            );
          }
        },
      ),
    );
  }

  // ── Change Phone Bottom Sheet ────────────────────────────────────────────
  void _showChangePhoneSheet(BuildContext context, bool isDark) {
    final phoneCtrl = TextEditingController(
      text: Provider.of<AuthProvider>(context, listen: false).user?.phoneNumber ?? '',
    );

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => _SingleFieldSheet(
        title: 'Change Phone Number',
        label: 'Phone Number',
        controller: phoneCtrl,
        isDark: isDark,
        keyboardType: TextInputType.phone,
        onSave: () {
          // TODO: integrate backend phone update + OTP verification
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number update coming soon'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  // ── Change Email Bottom Sheet ────────────────────────────────────────────
  void _showChangeEmailSheet(BuildContext context, bool isDark) {
    final emailCtrl = TextEditingController(
      text: Provider.of<AuthProvider>(context, listen: false).user?.email ?? '',
    );

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => _SingleFieldSheet(
        title: 'Change Email Address',
        label: 'Email Address',
        controller: emailCtrl,
        isDark: isDark,
        keyboardType: TextInputType.emailAddress,
        onSave: () {
          // TODO: integrate backend email update + verification
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email address update coming soon'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }
}

// ── Tile widget ────────────────────────────────────────────────────────────
class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool verified;
  final bool isDark;
  final VoidCallback onTap;

  const _SecurityTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.verified = false,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.white : AppColors.dark;
    final subColor = isDark ? AppColors.grey : AppColors.textSecondaryLight;

    return ListTile(
      leading: Icon(icon, color: subColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: subColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (verified) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          color: isDark ? AppColors.grey : AppColors.textSecondaryLight,
          size: 22),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── Change Password Sheet ──────────────────────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController currentCtrl;
  final TextEditingController newCtrl;
  final TextEditingController confirmCtrl;
  final bool isDark;
  final VoidCallback onSave;

  const _ChangePasswordSheet({
    required this.formKey,
    required this.currentCtrl,
    required this.newCtrl,
    required this.confirmCtrl,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Change Password',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? AppColors.white : AppColors.dark,
            ),
          ),
          const SizedBox(height: 20),
          _passwordField(
            label: 'Current Password',
            controller: widget.currentCtrl,
            obscure: _obscureCurrent,
            toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            validator: (v) =>
                v == null || v.isEmpty ? 'Enter current password' : null,
          ),
          const SizedBox(height: 14),
          _passwordField(
            label: 'New Password',
            controller: widget.newCtrl,
            obscure: _obscureNew,
            toggle: () => setState(() => _obscureNew = !_obscureNew),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter new password';
              if (v.length < 8) return 'Min 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _passwordField(
            label: 'Confirm New Password',
            controller: widget.confirmCtrl,
            obscure: _obscureConfirm,
            toggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (v) {
              if (v != widget.newCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Update Password',
            onPressed: _isSaving ? null : () async {
              setState(() => _isSaving = true);
              widget.onSave();
            },
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    final fillColor =
        widget.isDark ? AppColors.bg01 : const Color(0xFFF2F4F7);
    final labelColor =
        widget.isDark ? AppColors.grey : AppColors.textSecondaryLight;
    final textColor = widget.isDark ? AppColors.white : AppColors.dark;

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
          obscureText: obscure,
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
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: labelColor,
                size: 20,
              ),
              onPressed: toggle,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Single-field sheet (phone / email) ─────────────────────────────────────
class _SingleFieldSheet extends StatelessWidget {
  final String title;
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final TextInputType? keyboardType;
  final VoidCallback onSave;

  const _SingleFieldSheet({
    required this.title,
    required this.label,
    required this.controller,
    required this.isDark,
    this.keyboardType,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = isDark ? AppColors.bg01 : const Color(0xFFF2F4F7);
    final labelColor = isDark ? AppColors.grey : AppColors.textSecondaryLight;
    final textColor = isDark ? AppColors.white : AppColors.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.dark,
          ),
        ),
        const SizedBox(height: 20),
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
          keyboardType: keyboardType,
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
          ),
        ),
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'Save',
          onPressed: onSave,
        ),
      ],
    );
  }
}
