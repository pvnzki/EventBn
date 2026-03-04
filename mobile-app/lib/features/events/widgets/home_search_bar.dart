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

    final inputBg = isDark ? AppColors.surface : Colors.grey[100]!;
    final iconColor = isDark ? AppColors.grey200 : Colors.grey[500]!;
    final hintColor = isDark ? AppColors.grey200 : Colors.grey[500]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Tappable fake search field → navigates to SearchScreen
          Expanded(
            child: Material(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => context.push('/search-screen'),
                borderRadius: BorderRadius.circular(12),
                splashColor: AppColors.primary.withOpacity(0.08),
                highlightColor: AppColors.primary.withOpacity(0.04),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/search.png',
                        width: 24,
                        height: 24,
                        color: iconColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Search event',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            color: hintColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
    return Material(
      color: isDark ? AppColors.bg01 : Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.go('/onboarding'),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            Icons.login_rounded,
            color: isDark ? AppColors.white : Colors.grey[800],
            size: 22,
          ),
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
    return Material(
      color: isDark ? AppColors.bg01 : Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push('/notifications'),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 50,
          height: 50,
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
      ),
    );
  }
}
