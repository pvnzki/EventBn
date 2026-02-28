import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../auth/providers/auth_provider.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                cursorColor: theme.primaryColor,
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Search event',
                  hintStyle: TextStyle(
                    fontFamily: kFontFamily,
                    color: isDark
                        ? AppColors.grey
                        : Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Image.asset(
                      'assets/icons/search.png',
                      width: 20,
                      height: 20,
                      color: isDark
                          ? AppColors.grey
                          : Colors.grey[500],
                    ),
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          onPressed: onClear,
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? AppColors.grey
                                : Colors.grey[500],
                            size: 20,
                          ),
                        )
                      : IconButton(
                          onPressed: onFilterTap,
                          icon: Icon(
                            Icons.tune_rounded,
                            color: hasActiveFilters
                                ? theme.primaryColor
                                : (isDark
                                    ? AppColors.grey
                                    : Colors.grey[500]),
                            size: 20,
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Bell notification button (or Login for guests)
          if (authProvider.isGuestMode)
            _GuestLoginButton(isDark: isDark)
          else
            _NotificationBellButton(isDark: isDark),
        ],
      ),
    );
  }
}

class _GuestLoginButton extends StatelessWidget {
  final bool isDark;
  const _GuestLoginButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/onboarding'),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg01 : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.login_rounded,
          color: isDark ? AppColors.white : Colors.grey[800],
          size: 22,
        ),
      ),
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  final bool isDark;
  const _NotificationBellButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg01 : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(13),
              child: Image.asset(
                'assets/icons/bell.png',
                width: 22,
                height: 22,
                color: isDark ? AppColors.white : Colors.grey[800],
              ),
            ),
            Positioned(
              right: 14,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
