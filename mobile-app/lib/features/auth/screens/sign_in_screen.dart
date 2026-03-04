import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../common_widgets/app_bottom_sheet.dart';
import '../../../common_widgets/app_dark_text_field.dart';
import '../../../common_widgets/app_primary_button.dart';
import '../../../common_widgets/app_divider_with_text.dart';
import '../../../common_widgets/app_social_icon_button.dart';
import '../providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SignInBottomSheet — modal sheet used from the onboarding screen.
// Matches Figma nodes 2131:26118 (normal) and 2131:26258 (error).
// ─────────────────────────────────────────────────────────────────────────────
class SignInBottomSheet extends StatefulWidget {
  const SignInBottomSheet({super.key});

  /// Convenience helper so callers don't need to know about AppBottomSheet.
  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show(
      context: context,
      builder: (_) => const _SignInSheetContent(),
    );
  }

  @override
  State<SignInBottomSheet> createState() => _SignInBottomSheetState();
}

class _SignInBottomSheetState extends State<SignInBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(child: const _SignInSheetContent());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The actual content rendered inside the bottom sheet.
// ─────────────────────────────────────────────────────────────────────────────
class _SignInSheetContent extends StatefulWidget {
  const _SignInSheetContent();

  @override
  State<_SignInSheetContent> createState() => _SignInSheetContentState();
}

class _SignInSheetContentState extends State<_SignInSheetContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = false;

  bool get _hasInput =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {
        if (_errorMessage != null) _errorMessage = null;
      });

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Login handler ─────────────────────────────────────────────────────────
  Future<void> _handleSignIn() async {
    if (!_hasInput) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      // Capture navigator BEFORE async gap — bottom-sheet context dies after pop.
      final navigator = Navigator.of(context);
      // Use the static GoRouter instance directly — avoids InheritedWidget
      // lookup issues that occur inside modal bottom sheets.
      final router = AppRouter.router;

      final result = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      print('🔍 [SIGN_IN] Login result: $result');

      if (!mounted) {
        print('⚠️ [SIGN_IN] Widget not mounted after login');
        return;
      }

      if (result['success'] == true) {
        print('✅ [SIGN_IN] Login success → navigating to /home');
        navigator.pop();
        router.go('/home');
      } else if (result['requiresTwoFactor'] == true) {
        print('🔐 [SIGN_IN] 2FA required → navigating to /two-factor-login');
        navigator.pop();
        router.push('/two-factor-login', extra: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'twoFactorMethod': result['twoFactorMethod'] ?? 'app',
        });
      } else {
        print('❌ [SIGN_IN] Login failed → showing error');
        setState(() {
          _errorMessage =
              'Oops! The email or password you entered is incorrect, please check your email and password!';
        });
      }
    } catch (e, stackTrace) {
      print('💥 [SIGN_IN] Exception caught: $e');
      print('💥 [SIGN_IN] Stack trace: $stackTrace');
      setState(() {
        _errorMessage =
            'Oops! The email or password you entered is incorrect, please check your email and password!';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────────────
        _buildHeader(context),
        const SizedBox(height: 12),

        // ── Description ─────────────────────────────────────────
        const Text(
          "Get an account and find your event wherever you are or wherever you're going",
          style: TextStyle(
            fontFamily: appFontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 1.2,
            color: AppColors.grey200,
          ),
        ),
        const SizedBox(height: 24),

        // ── Email field ─────────────────────────────────────────
        AppDarkTextField(
          controller: _emailController,
          placeholder: 'Enter your email',
          hasError: hasError,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),

        // ── Password field ──────────────────────────────────────
        AppDarkTextField(
          controller: _passwordController,
          placeholder: 'Enter your password',
          hasError: hasError,
          obscureText: _obscurePassword,
          suffix: GestureDetector(
            onTap: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            child: Image.asset(
              'assets/icons/eye closed.png',
              width: 24,
              height: 24,
              color: _obscurePassword
                  ? AppColors.grey300
                  : AppColors.primary,
            ),
          ),
        ),

        // ── Error message ───────────────────────────────────────
        if (hasError) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontFamily: appFontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.2,
              color: AppColors.dangerText,
            ),
          ),
        ],
        const SizedBox(height: 12),

        // ── Continue button ─────────────────────────────────────
        AppPrimaryButton(
          label: 'Continue',
          onPressed: _hasInput ? _handleSignIn : null,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 24),

        // ── "or sign in with" divider ───────────────────────────
        const AppDividerWithText(text: 'or sign in with'),
        const SizedBox(height: 24),

        // ── Social sign-in row ──────────────────────────────────
        AppSocialSignInRow(
          onSocialTap: (provider) {
            // TODO: implement social sign-in per provider
          },
        ),
        const SizedBox(height: 24),

        // ── Terms & Privacy ─────────────────────────────────────
        _buildTermsText(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Small builders (screen-specific, not worth extracting) ────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Sign in',
            style: TextStyle(
              fontFamily: appFontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 20,
              height: 28 / 20,
              color: AppColors.white,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Image.asset(
            'assets/icons/Close.png',
            width: 24,
            height: 24,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsText() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(
            fontFamily: appFontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: AppColors.grey200,
          ),
          children: [
            TextSpan(
                text:
                    'By signing up you acknowledge and agree to event.com '),
            TextSpan(
              text: 'General Terms of Use',
              style: TextStyle(color: AppColors.primary),
            ),
            TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
