import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/two_factor_service.dart';

class TwoFactorVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  const TwoFactorVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<TwoFactorVerificationScreen> createState() =>
      _TwoFactorVerificationScreenState();
}

class _TwoFactorVerificationScreenState
    extends State<TwoFactorVerificationScreen> {
  final TwoFactorService _twoFactorService = TwoFactorService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyAndLogin() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _twoFactorService.verifyTwoFactorLogin(
      widget.email,
      widget.password,
      _codeController.text,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      // Store token and user data here if needed
      // Navigate to main app
      context.go('/explore'); // Adjust based on your routing
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Verification failed')),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),

            // Icon
            Icon(
              Icons.security,
              size: 80,
              color: theme.primaryColor,
            ),

            const SizedBox(height: 32),

            // Title
            const Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'Please enter the 6-digit code from your authenticator app to complete the login process.',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Code Input
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 8,
              ),
              decoration: const InputDecoration(
                hintText: '123456',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onChanged: (value) {
                if (value.length == 6) {
                  _verifyAndLogin();
                }
              },
            ),

            const SizedBox(height: 32),

            // Verify Button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyAndLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Verify & Login',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 24),

            // Help text
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Having trouble?'),
                    content: const Text(
                      'If you don\'t have access to your authenticator app, please contact support for assistance.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Having trouble accessing your code?'),
            ),
          ],
        ),
      ),
    );
  }
}
