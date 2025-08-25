import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

class BottomNavBar extends StatefulWidget {
  final Widget child;

  const BottomNavBar({super.key, required this.child});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: '/home',
    ),
    NavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explore',
      route: '/search',
    ),
    NavItem(
      icon: Icons.confirmation_number_outlined,
      activeIcon: Icons.confirmation_number,
      label: 'Tickets',
      route: '/my-tickets',
    ),
    NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      // Trigger animation
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      // Navigate to the selected route
      context.go(_navItems[index].route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get the current route more reliably
    final routerState =
        GoRouter.of(context).routerDelegate.currentConfiguration;
    final currentLocation = routerState.uri.toString();

    // Debug: Print current location
    print('BottomNavBar - Current location: $currentLocation');
    print(
        'BottomNavBar - Route matches: ${routerState.matches.map((m) => m.matchedLocation).toList()}');

    // Don't show bottom nav on event detail pages or other specific pages
    if (currentLocation.startsWith('/events/') ||
        currentLocation.startsWith('/checkout/') ||
        currentLocation.startsWith('/organizer/') ||
        routerState.matches
            .any((match) => match.matchedLocation.startsWith('/events/'))) {
      print('BottomNavBar - Hiding bottom nav for: $currentLocation');
      return widget.child;
    }

    for (int i = 0; i < _navItems.length; i++) {
      if (currentLocation.contains(_navItems[i].route)) {
        _selectedIndex = i;
        break;
      }
    }

    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main navigation bar background
            Container(
              height: 75,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color.fromARGB(255, 15, 15, 15) // Dark grey background
                    : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF404040)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0), // Home
                  _buildNavItem(1), // Search
                  const SizedBox(width: 60), // Space for create button
                  _buildNavItem(2), // Tickets
                  _buildNavItem(3), // Profile
                ],
              ),
            ),
            // Central create button that extends above (no clipping)
            Positioned(
              top: -20,
              left: 0,
              right: 0,
              child: Center(
                child: _buildCreateButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF32CD32)
                  .withValues(alpha: 0.1) // Light lime green for selected
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add a small indicator line above selected items (like Profile in the image)
            if (isSelected)
              Container(
                width: 20,
                height: 2,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF32CD32), // Lime Green
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isSelected ? _scaleAnimation.value : 1.0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey(isSelected),
                      color: isSelected
                          ? const Color(0xFF32CD32) // Lime Green for selected
                          : isDark
                              ? const Color(
                                  0xFFB0B0B0) // Light grey for dark theme
                              : const Color(
                                  0xFF6B7280), // Medium grey for light theme
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF32CD32) // Lime Green for selected
                    : isDark
                        ? const Color(0xFFB0B0B0) // Light grey for dark theme
                        : const Color(
                            0xFF6B7280), // Medium grey for light theme
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () {
        _animationController.forward().then((_) {
          _animationController.reverse();
          context.go('/create-post');
        });
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFF32CD32), // Lime Green
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF32CD32).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_circle,
                color: Colors.white,
                size: 36,
              ),
            ),
          );
        },
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
