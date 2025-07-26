import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key}); // Removed const to allow theme access

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Grab all events now only\nin your hands",
      description:
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor.",
      illustration: const OnboardingIllustration1(),
    ),
    OnboardingPage(
      title: "Discover amazing events\nnear you",
      description:
          "Find concerts, festivals, workshops and more happening in your city.",
      illustration: const OnboardingIllustration2(),
    ),
    OnboardingPage(
      title: "Book tickets with\njust a few taps",
      description:
          "Simple and secure ticket booking process with instant confirmation.",
      illustration: const OnboardingIllustration3(),
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to welcome login screen
      context.go('/welcome-login');
    }
  }

  void _skipToLogin() {
    context.go('/welcome-login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipToLogin,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF74B9FF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const Spacer(flex: 1),

                        // Illustration
                        Expanded(
                          flex: 4,
                          child: _pages[index].illustration,
                        ),

                        const SizedBox(height: 40),

                        // Title
                        Text(
                          _pages[index].title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .primaryColor, // Theme-aware color
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          _pages[index].description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF636E72),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: index == _currentPage ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: index == _currentPage
                                    ? Theme.of(context)
                                        .primaryColor // Theme-aware color
                                    : Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Next button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .primaryColor, // Theme-aware color
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final Widget illustration;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

// Illustration widgets
class OnboardingIllustration1 extends StatelessWidget {
  const OnboardingIllustration1({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decorative circles
          Positioned(
            top: 50,
            left: 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF74B9FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 60,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor, // Theme-aware color
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 40,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFFF7675),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFDCB6E),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main illustration area
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor, // Theme-aware color
                borderRadius: BorderRadius.circular(140),
              ),
              child: Stack(
                children: [
                  // Woman illustration placeholder
                  Center(
                    child: Container(
                      width: 200,
                      height: 240,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD93D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Face
                            const CircleAvatar(
                              radius: 40,
                              backgroundColor: Color(0xFFFFB8B8),
                              child: Text(
                                '😊',
                                style: TextStyle(fontSize: 40),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Phone in hand
                            Container(
                              width: 60,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  '📱',
                                  style: TextStyle(fontSize: 30),
                                ),
                              ),
                            ),
                          ],
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
}

class OnboardingIllustration2 extends StatelessWidget {
  const OnboardingIllustration2({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decorative elements
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF00B894),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: 30,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFE17055),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main illustration
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                color: Color(0xFF74B9FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 20),
                    Icon(
                      Icons.location_on,
                      size: 60,
                      color: Color(0xFFFFD93D),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingIllustration3 extends StatelessWidget {
  const OnboardingIllustration3({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background decorative elements
          Positioned(
            top: 30,
            right: 40,
            child: Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                color: Color(0xFFA29BFE),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 25,
            child: Container(
              width: 55,
              height: 55,
              decoration: const BoxDecoration(
                color: Color(0xFF55A3FF),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main illustration
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                color: Color(0xFF00B894),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 20),
                    Icon(
                      Icons.touch_app,
                      size: 60,
                      color: Color(0xFFFFD93D),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
