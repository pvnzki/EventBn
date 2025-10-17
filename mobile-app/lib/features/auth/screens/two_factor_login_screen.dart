import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/two_factor_service.dart';

class TwoFactorLoginScreen extends StatefulWidget {
  final String email;
  final String password;
  final String? twoFactorMethod;

  const TwoFactorLoginScreen({
    super.key,
    required this.email,
    required this.password,
    this.twoFactorMethod,
  });

  @override
  State<TwoFactorLoginScreen> createState() => _TwoFactorLoginScreenState();
}

class _TwoFactorLoginScreenState extends State<TwoFactorLoginScreen> {
  final _codeController = TextEditingController();
  final _twoFactorService = TwoFactorService();
  bool _isLoading = false;
  bool _useEmailOTP = false;
  String? _developmentOTP;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleVerification() async {
    if (_codeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 6-digit verification code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (_useEmailOTP) {
        result = await _twoFactorService.verifyEmailOTP(
          widget.email,
          widget.password,
          _codeController.text.trim(),
        );
      } else {
        result = await _twoFactorService.verifyTwoFactorLogin(
          widget.email,
          widget.password,
          _codeController.text.trim(),
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Complete the login process
        final authProvider = context.read<AuthProvider>();
        await authProvider.completeTwoFactorLogin(result);

        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Invalid verification code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendEmailOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _twoFactorService.sendEmailOTP(
        widget.email,
        widget.password,
      );

      setState(() {
        _isLoading = false;
        _useEmailOTP = true;
        // In development, show the OTP
        if (result['otp'] != null) {
          _developmentOTP = result['otp'];
        }
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'OTP sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send OTP'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _useEmailOTP = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _useEmailOTP = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: theme.primaryColor,
            ),

            const SizedBox(height: 32),

            Text(
              'Enter Verification Code',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              _useEmailOTP
                  ? 'Please enter the 6-digit code sent to your email address.'
                  : 'Please enter the 6-digit code from your authenticator app to complete your login.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            // Development OTP display
            if (_developmentOTP != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  'Development OTP: $_developmentOTP',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 32),

            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
              onChanged: (value) {
                if (value.length == 6) {
                  _handleVerification();
                }
              },
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerification,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Verify & Login',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 24),

            // Alternative method button
            if (!_useEmailOTP)
              TextButton(
                onPressed: _isLoading ? null : _sendEmailOTP,
                child: const Text(
                  'Send code via Email instead',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () {
                  setState(() {
                    _useEmailOTP = false;
                    _developmentOTP = null;
                    _codeController.clear();
                  });
                },
                child: const Text(
                  'Use Authenticator App instead',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Text(
              _useEmailOTP
                  ? 'Check your email for the verification code. It may take a few minutes to arrive.'
                  : 'Having trouble? Make sure your device time is correct and your authenticator app is up to date.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
