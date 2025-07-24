import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  String _selectedMethod = 'sms'; // 'sms' or 'email'

  void _handleContinue() {
    // Navigate to OTP verification with the selected method
    context.push('/otp-verification', extra: {
      'method': _selectedMethod,
      'contact': _selectedMethod == 'sms' ? '+1 111 ******99' : 'and***ley@yourdomain.com'
    });
  }

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
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Illustration
            _buildIllustration(),
            
            const SizedBox(height: 60),
            
            // Instructions text
            const Text(
              'Select which contact details should we use to reset your password',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF212121),
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // SMS Option
            _buildContactOption(
              isSelected: _selectedMethod == 'sms',
              icon: Icons.sms_outlined,
              title: 'via SMS:',
              contact: '+1 111 ******99',
              onTap: () => setState(() => _selectedMethod = 'sms'),
            ),
            
            const SizedBox(height: 24),
            
            // Email Option
            _buildContactOption(
              isSelected: _selectedMethod == 'email',
              icon: Icons.email_outlined,
              title: 'via Email:',
              contact: 'and***ley@yourdomain.com',
              onTap: () => setState(() => _selectedMethod = 'email'),
            ),
            
            const Spacer(),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      height: 200,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Phone mockup
          Container(
            width: 120,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 3),
            ),
            child: Column(
              children: [
                // Phone notch
                Container(
                  width: 60,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Spacer(),
                // Document icon
                Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 20,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 2,
                        width: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: const Color(0xFF6C5CE7),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: 2,
                        width: 25,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: const Color(0xFF6C5CE7),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: 2,
                        width: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: const Color(0xFF6C5CE7),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          
          // Person sitting
          Positioned(
            left: 40,
            bottom: 20,
            child: Container(
              width: 80,
              height: 100,
              child: Stack(
                children: [
                  // Person body
                  Positioned(
                    bottom: 0,
                    left: 20,
                    child: Container(
                      width: 40,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  // Person head
                  Positioned(
                    top: 0,
                    left: 28,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFDBCF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Person legs
                  Positioned(
                    bottom: 0,
                    left: 10,
                    child: Container(
                      width: 16,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D3748),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 10,
                    child: Container(
                      width: 16,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D3748),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Lock icons
          Positioned(
            left: 20,
            top: 60,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF6C5CE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 80,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF6C5CE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required bool isSelected,
    required IconData icon,
    required String title,
    required String contact,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7).withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
