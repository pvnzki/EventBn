import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _loadingController;
  late Animation<double> _logoAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    print('SplashScreen initialized');

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Loading animation controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation
    await _logoController.forward();

    // Start loading animation
    _loadingController.forward();

    // Check authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    // Navigate after checking auth
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  void _checkAuthAndNavigate() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    print('========== SplashScreen Authentication Check ==========');
    print('SplashScreen: Checking authentication status...');
    print('SplashScreen: isAuthenticated: ${authProvider.isAuthenticated}');
    print('SplashScreen: User object: ${authProvider.user}');
    print('SplashScreen: User null check: ${authProvider.user == null ? "NULL" : "NOT NULL"}');
    
    if (authProvider.isAuthenticated && authProvider.user != null) {
      print('SplashScreen: ✅ User is authenticated, navigating to home');
      print('SplashScreen: User email: ${authProvider.user!.email}');
      context.go('/home');
    } else {
      print('SplashScreen: ❌ User not authenticated, navigating to login');
      print('SplashScreen: Reason - isAuthenticated: ${authProvider.isAuthenticated}, user: ${authProvider.user}');
      context.go('/login');
    }
    print('========== End Authentication Check ==========');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Theme-aware background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Logo with animation
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: Opacity(
                    opacity: _logoAnimation.value,
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Image.asset(
                        isDark
                            ? 'assets/images/White icon logo transparent.png'
                            : 'assets/images/Black icon logo transparent.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to circular logo if image not found
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'E',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            const Spacer(flex: 1),

            // Loading indicator with animation
            AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _loadingAnimation.value,
                  child: const SizedBox(
                    height: 120,
                    child: LoadingIndicator(),
                  ),
                );
              },
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatefulWidget {
  const LoadingIndicator({super.key});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main loading animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Pulse animation for the container
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loadingColor = isDark ? Colors.white : theme.primaryColor;
    final loadingBgColor =
        isDark ? Colors.white24 : theme.primaryColor.withOpacity(0.2);
    final loadingShadow =
        isDark ? Colors.white30 : theme.primaryColor.withOpacity(0.3);
    final loadingGradient = isDark
        ? [Colors.white60, Colors.white, Colors.white60]
        : [
            theme.primaryColor.withOpacity(0.6),
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.6)
          ];

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _pulseAnimation]),
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern dot loading animation
            SizedBox(
              width: 80,
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  final animationValue =
                      (_controller.value * 3 - index).clamp(0.0, 1.0);
                  final scale =
                      (math.sin(animationValue * math.pi) * 0.5) + 0.5;
                  final opacity =
                      (math.sin(animationValue * math.pi) * 0.7) + 0.3;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: loadingColor.withOpacity(opacity),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: loadingShadow,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // Elegant progress bar
            Container(
              width: 120,
              height: 3,
              decoration: BoxDecoration(
                color: loadingBgColor,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 120 * _controller.value,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: loadingGradient,
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: loadingShadow,
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Loading text with subtle animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              child: Text(
                'Loading...',
                style: TextStyle(
                  color: loadingColor.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.1,
                  child: Opacity(
                    opacity: 0.6 + (_pulseAnimation.value - 0.8) * 0.4,
                    child: child,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
