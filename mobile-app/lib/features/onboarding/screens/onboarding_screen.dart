import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/screens/sign_in_screen.dart';
import '../../auth/screens/signup_method_sheet.dart';

/// Onboarding screen shown to new users after the splash screen.
/// Matches the Figma design: node 2131:24135
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            // ── Background image ──────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.67,
              child: Image.asset(
                'assets/images/onboarding image.png',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),

            // ── Gradient overlay (image → dark) ───────────────────
            Positioned(
              top: screenHeight * 0.48,
              left: 0,
              right: 0,
              height: screenHeight * 0.22,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xFF121212),
                    ],
                    stops: [0.0, 0.75],
                  ),
                ),
              ),
            ),

            // ── Bottom content ────────────────────────────────────
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    const Text(
                      'Your Perfect Event Starts Here',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.w500,
                        fontSize: 24,
                        height: 32 / 24,
                        color: Color(0xFFFCFCFD),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const SizedBox(
                      width: 329,
                      child: Text(
                        'Secure your spot now and be a part of an unforgettable experience for your perfect event starts here',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          height: 1.2,
                          color: Color(0xFFBABCC0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // "Get started" CTA button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _showSignUpSheet(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF01DB5F),
                          foregroundColor: const Color(0xFF070B0F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Get started',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // "Already have an account? Sign in"
                    Center(
                      child: GestureDetector(
                        onTap: () => _showSignInSheet(context),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              height: 1.2,
                              color: Color(0xFFBABCC0),
                            ),
                            children: [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign in',
                                style: TextStyle(color: Color(0xFF01DB5F)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the Sign-Up method selection bottom sheet.
  void _showSignUpSheet(BuildContext context) {
    SignUpMethodSheet.show(context);
  }

  /// Opens the Sign-In bottom sheet over the onboarding background.
  void _showSignInSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const SignInBottomSheet(),
    );
  }
}
