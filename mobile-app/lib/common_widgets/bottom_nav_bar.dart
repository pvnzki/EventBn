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
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      label: 'Search',
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
    if (currentLocation.startsWith('/event/') ||
        currentLocation.startsWith('/checkout/') ||
        currentLocation.startsWith('/organizer/') ||
        routerState.matches
            .any((match) => match.matchedLocation.startsWith('/event/'))) {
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
        // Removed margin for true floating effect
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.black.withValues(alpha: 0.9),
                          Colors.black.withValues(alpha: 0.7),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.9),
                          Colors.white.withValues(alpha: 0.7),
                        ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _navItems.length,
                  (index) => _buildNavItem(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;
    final activeColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                          ? activeColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                    ? activeColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              child: Text(item.label),
            ),
          ],
        ),
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
