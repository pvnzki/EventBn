import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CongratulationsScreen extends StatefulWidget {
  const CongratulationsScreen({super.key});

  @override
  State<CongratulationsScreen> createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _dialogController;
  late Animation<double> _dialogAnimation;

  @override
  void initState() {
    super.initState();

    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _dialogAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dialogController,
      curve: Curves.elasticOut,
    ));

    // Start animation immediately
    _dialogController.forward();

    // Auto-navigate to home after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    context.go('/home');
  }

  void _skipToHome() {
    context.go('/home');
  }

  @override
  void dispose() {
    _dialogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _dialogAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _dialogAnimation.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success icon with decorative dots
                      _buildSuccessIcon(),

                      const SizedBox(height: 32),

                      // Success title
                      const Text(
                        'Congratulations!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Success message
                      const Text(
                        'Your account is ready to use. You will\nbe redirected to the Home page in a\nfew seconds.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF636E72),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Loading indicator
                      const LoadingDotsIndicator(),

                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _skipToHome,
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF636E72),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _navigateToHome,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative dots around the icon
          ...List.generate(8, (index) {
            final angle = (index * 45.0) * (pi / 180);
            return Transform.translate(
              offset: Offset(
                45 * cos(angle),
                45 * sin(angle),
              ),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C5CE7),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),

          // Main success icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF6C5CE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingDotsIndicator extends StatefulWidget {
  const LoadingDotsIndicator({super.key});

  @override
  State<LoadingDotsIndicator> createState() => _LoadingDotsIndicatorState();
}

class _LoadingDotsIndicatorState extends State<LoadingDotsIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animations = List.generate(6, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.1,
            (index * 0.1) + 0.3,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7)
                    .withValues(alpha: _animations[index].value),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
