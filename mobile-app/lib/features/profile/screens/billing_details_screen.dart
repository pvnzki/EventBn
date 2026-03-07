import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../common_widgets/app_bottom_sheet.dart';
import '../../../common_widgets/app_primary_button.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BILLING DETAILS SCREEN
//
// Shows current billing information and lets the user edit each field
// via a bottom sheet. Reuses AppBottomSheet, AppPrimaryButton, and the
// existing User model billing fields.
// ─────────────────────────────────────────────────────────────────────────────

class BillingDetailsScreen extends StatefulWidget {
  const BillingDetailsScreen({super.key});

  @override
  State<BillingDetailsScreen> createState() => _BillingDetailsScreenState();
}

class _BillingDetailsScreenState extends State<BillingDetailsScreen> {
  final AuthService _authService = AuthService();
  bool _isSaving = false;

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
          'Billing Details',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.dark,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BillingTile(
                    icon: Icons.location_on_outlined,
                    title: 'Billing Address',
                    subtitle: user?.billingAddress,
                    isDark: isDark,
                    onTap: () => _editField(
                      context,
                      isDark: isDark,
                      title: 'Billing Address',
                      label: 'Address',
                      currentValue: user?.billingAddress ?? '',
                      onSave: (val) => _updateBilling(
                        context,
                        user,
                        billingAddress: val,
                      ),
                    ),
                  ),
                  _divider(isDark),
                  _BillingTile(
                    icon: Icons.location_city_outlined,
                    title: 'City',
                    subtitle: user?.billingCity,
                    isDark: isDark,
                    onTap: () => _editField(
                      context,
                      isDark: isDark,
                      title: 'City',
                      label: 'City',
                      currentValue: user?.billingCity ?? '',
                      onSave: (val) => _updateBilling(
                        context,
                        user,
                        billingCity: val,
                      ),
                    ),
                  ),
                  _divider(isDark),
                  _BillingTile(
                    icon: Icons.map_outlined,
                    title: 'State / Province',
                    subtitle: user?.billingState,
                    isDark: isDark,
                    onTap: () => _editField(
                      context,
                      isDark: isDark,
                      title: 'State / Province',
                      label: 'State',
                      currentValue: user?.billingState ?? '',
                      onSave: (val) => _updateBilling(
                        context,
                        user,
                        billingState: val,
                      ),
                    ),
                  ),
                  _divider(isDark),
                  _BillingTile(
                    icon: Icons.public_outlined,
                    title: 'Country',
                    subtitle: user?.billingCountry,
                    isDark: isDark,
                    onTap: () => _editField(
                      context,
                      isDark: isDark,
                      title: 'Country',
                      label: 'Country',
                      currentValue: user?.billingCountry ?? '',
                      onSave: (val) => _updateBilling(
                        context,
                        user,
                        billingCountry: val,
                      ),
                    ),
                  ),
                  _divider(isDark),
                  _BillingTile(
                    icon: Icons.markunread_mailbox_outlined,
                    title: 'Postal Code',
                    subtitle: user?.billingPostalCode,
                    isDark: isDark,
                    onTap: () => _editField(
                      context,
                      isDark: isDark,
                      title: 'Postal Code',
                      label: 'Postal Code',
                      currentValue: user?.billingPostalCode ?? '',
                      keyboardType: TextInputType.number,
                      onSave: (val) => _updateBilling(
                        context,
                        user,
                        billingPostalCode: val,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  // ── Edit field via AppBottomSheet ────────────────────────────────────────
  void _editField(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String label,
    required String currentValue,
    required ValueChanged<String> onSave,
    TextInputType? keyboardType,
  }) {
    final controller = TextEditingController(text: currentValue);

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => _BillingFieldSheet(
        title: title,
        label: label,
        controller: controller,
        isDark: isDark,
        keyboardType: keyboardType,
        isSaving: _isSaving,
        onSave: () {
          Navigator.of(ctx).pop();
          onSave(controller.text.trim());
        },
      ),
    );
  }

  // ── Persist billing update ──────────────────────────────────────────────
  Future<void> _updateBilling(
    BuildContext context,
    User? user, {
    String? billingAddress,
    String? billingCity,
    String? billingState,
    String? billingCountry,
    String? billingPostalCode,
  }) async {
    if (user == null) return;
    setState(() => _isSaving = true);

    try {
      final updated = user.copyWith(
        billingAddress: billingAddress ?? user.billingAddress,
        billingCity: billingCity ?? user.billingCity,
        billingState: billingState ?? user.billingState,
        billingCountry: billingCountry ?? user.billingCountry,
        billingPostalCode: billingPostalCode ?? user.billingPostalCode,
      );

      final result = await _authService.updateUserProfile(updated);

      if (result['success'] == true && mounted) {
        Provider.of<AuthProvider>(context, listen: false).updateUser(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Billing details updated'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Update failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ── Tile widget ────────────────────────────────────────────────────────────
class _BillingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _BillingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.white : AppColors.dark;
    final subColor = isDark ? AppColors.grey : AppColors.textSecondaryLight;

    final hasValue = subtitle != null && subtitle!.isNotEmpty;

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
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          hasValue ? subtitle! : 'Not set',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: hasValue ? subColor : subColor.withOpacity(0.5),
            fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? AppColors.grey : AppColors.textSecondaryLight,
        size: 22,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── Bottom sheet for editing a single billing field ────────────────────────
class _BillingFieldSheet extends StatelessWidget {
  final String title;
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final TextInputType? keyboardType;
  final bool isSaving;
  final VoidCallback onSave;

  const _BillingFieldSheet({
    required this.title,
    required this.label,
    required this.controller,
    required this.isDark,
    this.keyboardType,
    required this.isSaving,
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
          onPressed: isSaving ? null : onSave,
          isLoading: isSaving,
        ),
      ],
    );
  }
}
