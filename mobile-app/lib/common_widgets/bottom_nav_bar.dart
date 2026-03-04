import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation bar – matches the Figma design (node 2131:26443).
//
// • Background #141414 (dark) / white (light), height 67 + safe-area padding
// • 4 items: Home, Explore, Ticket, Account
// • Active  → green (#01DB5F) filled icon + Bold 12px label
// • Inactive → grey (#928C97) outlined icon + Medium 12px label
// • Smooth 250ms animated transitions (crossfade icons, color, weight)
// ─────────────────────────────────────────────────────────────────────────────

class BottomNavBar extends StatefulWidget {
  final Widget child;

  const BottomNavBar({super.key, required this.child});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  static const _animDuration = Duration(milliseconds: 250);
  static const _animCurve = Curves.easeInOut;

  // Colors stay the same across themes — icons + green active color are fixed.
  static const _darkNavBarColor = Color(0xFF141414);
  static const _lightNavBarColor = Colors.white;
  static const _activeColor = AppColors.primary; // #01DB5F
  static const _inactiveColor = Color(0xFF928C97);

  static const List<_NavItem> _navItems = [
    _NavItem(
      filledIcon: 'assets/icons/navbar/home filled.png',
      outlinedIcon: 'assets/icons/navbar/home outlined.png',
      label: 'Home',
      route: '/home',
    ),
    _NavItem(
      filledIcon: 'assets/icons/navbar/explore filled.png',
      outlinedIcon: 'assets/icons/navbar/explore outlined.png',
      label: 'Explore',
      route: '/search',
    ),
    _NavItem(
      filledIcon: 'assets/icons/navbar/ticket filled.png',
      outlinedIcon: 'assets/icons/navbar/ticket outlined.png',
      label: 'Ticket',
      route: '/tickets',
    ),
    _NavItem(
      filledIcon: 'assets/icons/navbar/account filled.png',
      outlinedIcon: 'assets/icons/navbar/account outlined.png',
      label: 'Account',
      route: '/profile',
    ),
  ];

  // ── Sync selected index from current route ───────────────────────────────
  void _syncIndex(BuildContext context) {
    final currentLocation = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();

    for (int i = 0; i < _navItems.length; i++) {
      if (currentLocation.contains(_navItems[i].route)) {
        _selectedIndex = i;
        break;
      }
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    context.go(_navItems[index].route);
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    _syncIndex(context);

    // Hide bottom nav on event-detail / checkout / organizer pages
    final currentLocation = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();

    if (currentLocation.startsWith('/events/') ||
        currentLocation.startsWith('/checkout/') ||
        currentLocation.startsWith('/organizer/')) {
      return widget.child;
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDark ? _darkNavBarColor : _lightNavBarColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBarColor,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x14000000)
                  : const Color(0x1A000000),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 67,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              return Expanded(child: _buildNavItem(i));
            }),
          ),
        ),
      ),
    );
  }

  // ── Single nav item with smooth transitions ─────────────────────────────
  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;
    final color = isSelected ? _activeColor : _inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Icon: crossfade between filled ↔ outlined ──────────────
          SizedBox(
            width: 24,
            height: 24,
            child: AnimatedCrossFade(
              duration: _animDuration,
              firstCurve: _animCurve,
              secondCurve: _animCurve,
              sizeCurve: _animCurve,
              crossFadeState: isSelected
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Image.asset(
                item.filledIcon,
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.circle,
                  size: 24,
                  color: _activeColor,
                ),
              ),
              secondChild: Image.asset(
                item.outlinedIcon,
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.circle_outlined,
                  size: 24,
                  color: _inactiveColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ── Label: animated color transition ──────────────────────
          AnimatedDefaultTextStyle(
            duration: _animDuration,
            curve: _animCurve,
            style: TextStyle(
              fontFamily: appFontFamily,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}

// ── Data class ──────────────────────────────────────────────────────────────
class _NavItem {
  final String filledIcon;
  final String outlinedIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.filledIcon,
    required this.outlinedIcon,
    required this.label,
    required this.route,
  });
}
