import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeLoginScreen extends StatelessWidget {
  const WelcomeLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Illustration
              Expanded(
                flex: 3,
                child: Container(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background decorative shapes
                      Positioned(
                        top: 20,
                        left: 40,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B9D),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                              bottomLeft: Radius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        right: 30,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6C5CE7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      
                      // Main illustration - Person working
                      Center(
                        child: Container(
                          width: 280,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              // Person illustration
                              Positioned(
                                bottom: 20,
                                left: 60,
                                child: Container(
                                  width: 80,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C5CE7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Head
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Color(0xFFFFB8B8),
                                        child: Text('👩🏻', style: TextStyle(fontSize: 20)),
                                      ),
                                      SizedBox(height: 10),
                                      // Body
                                      Icon(Icons.person, color: Colors.white, size: 30),
                                    ],
                                  ),
                                ),
                              ),
                              // Tree/plant
                              Positioned(
                                bottom: 20,
                                right: 40,
                                child: Container(
                                  width: 60,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6C5CE7),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      topRight: Radius.circular(30),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.nature,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                              // Laptop/desk
                              Positioned(
                                bottom: 10,
                                left: 40,
                                right: 40,
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title
              const Text(
                "Let's you in",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Social login buttons
              _buildSocialButton(
                context,
                'Continue with Facebook',
                'assets/icons/facebook.png',
                const Color(0xFF1877F2),
                Colors.white,
                () {
                  // Handle Facebook login
                  _handleSocialLogin(context, 'Facebook');
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildSocialButton(
                context,
                'Continue with Google',
                'assets/icons/google.png',
                Colors.white,
                Colors.black,
                () {
                  // Handle Google login
                  _handleSocialLogin(context, 'Google');
                },
                hasBorder: true,
              ),
              
              const SizedBox(height: 16),
              
              _buildSocialButton(
                context,
                'Continue with Apple',
                'assets/icons/apple.png',
                Colors.black,
                Colors.white,
                () {
                  // Handle Apple login
                  _handleSocialLogin(context, 'Apple');
                },
              ),
              
              const SizedBox(height: 32),
              
              // Or divider
              const Text(
                'or',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF636E72),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Sign in with password button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/email-login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign in with password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Color(0xFF636E72),
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.go('/register');
                    },
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                        color: Color(0xFF6C5CE7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context,
    String text,
    String iconPath,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed, {
    bool hasBorder = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: hasBorder 
              ? const BorderSide(color: Color(0xFFE0E0E0), width: 1)
              : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon placeholder (you can replace with actual icons)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: text.contains('Facebook') 
                  ? Colors.white 
                  : text.contains('Google')
                    ? const Color(0xFF4285F4)
                    : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                text.contains('Facebook') 
                  ? Icons.facebook 
                  : text.contains('Google')
                    ? Icons.g_mobiledata
                    : Icons.apple,
                color: text.contains('Facebook') 
                  ? const Color(0xFF1877F2)
                  : text.contains('Google')
                    ? Colors.white
                    : Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSocialLogin(BuildContext context, String provider) {
    // Simulate social login and navigate to profile setup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider login successful!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate to profile setup
    Future.delayed(const Duration(seconds: 1), () {
      context.go('/profile-setup');
    });
  }
}
