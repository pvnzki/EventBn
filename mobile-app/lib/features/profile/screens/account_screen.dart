import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../common_widgets/app_primary_button.dart';
import '../../../common_widgets/custom_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import 'edit_personal_info_screen.dart';
import 'billing_details_screen.dart';
import 'notifications_preferences_screen.dart';
import 'password_security_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ACCOUNT SCREEN — Figma node 40000056:4544
//
// Cover photo at top fading into #121212, circular avatar, user info,
// Edit Profile / Share Profile buttons, settings list, sign-out.
// ─────────────────────────────────────────────────────────────────────────────

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          return FadeTransition(
            opacity: _fadeAnim,
            child: Stack(
            children: [
              // ── Cover photo as full-width background ──
              _buildCoverBackground(context, user, isDark),
              // ── Scrollable content overlapping the cover ──
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Column(
                  children: [
                    // Transparent spacer — cover photo visible through
                    const SizedBox(height: 280),
                    // Stack: gradient overlaps content from above
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Gradient fade — behind the content
                        Positioned(
                          top: -120,
                          left: 0,
                          right: 0,
                          height: 120,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  bgColor.withOpacity(0),
                                  bgColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Solid dark BG — joins the gradient seamlessly
                        Container(
                          width: double.infinity,
                          color: bgColor,
                          padding: const EdgeInsets.only(top: 0),
                          child: Column(
                            children: [
                              // Pull content back up so it doesn't move
                              Transform.translate(
                                offset: const Offset(0, -200),
                                child: Column(
                                  children: [
                              _buildAvatarOverlay(context, user, isDark),
                              _buildUserInfo(context, user, isDark),
                              const SizedBox(height: 16),
                              _buildActionButtons(context, user, isDark),
                              const SizedBox(height: 28),
                              _buildSection(
                            context,
                            title: 'Account settings',
                            isDark: isDark,
                            items: [
                              _SettingItem(
                                icon: Icons.receipt_long_rounded,
                                label: 'Billing Details',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (_) =>
                                          const BillingDetailsScreen(),
                                    ),
                                  );
                                },
                              ),
                              _SettingItem(
                                icon: Icons.lock_outline_rounded,
                                label: 'Password & Security',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (_) =>
                                          const PasswordSecurityScreen(),
                                    ),
                                  );
                                },
                              ),
                              _SettingItem(
                                icon: Icons.notifications_none_rounded,
                                label: 'Notifications Preferences',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (_) =>
                                          const NotificationsPreferencesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            context,
                            title: 'Other',
                            isDark: isDark,
                            items: [
                              _SettingItem(
                                icon: Icons.help_outline_rounded,
                                label: 'FAQs',
                                onTap: () {},
                              ),
                              _SettingItem(
                                icon: Icons.headset_mic_outlined,
                                label: 'Help Center',
                                onTap: () {},
                              ),
                              _SettingItem(
                                icon: Icons.settings_outlined,
                                label: 'Settings',
                                onTap: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildThemeToggle(context, isDark),
                          const SizedBox(height: 8),
                          _buildSignOutTile(context, isDark),
                          const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          );
        },
      ),
    );
  }

  // ── Cover photo background (tall, sits behind everything) ─────────────
  Widget _buildCoverBackground(BuildContext context, User? user, bool isDark) {
    final bgColor = isDark ? AppColors.background : AppColors.bgLight;
    const coverHeight = 320.0;

    return SizedBox(
      height: coverHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image
          user?.coverPhotoUrl != null
              ? CachedNetworkImage(
                  imageUrl: user!.coverPhotoUrl!,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 150),
                  placeholder: (_, __) => Container(
                    color: isDark
                        ? const Color(0xFF252525)
                        : const Color(0xFFE0E0E0),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: isDark
                        ? const Color(0xFF252525)
                        : const Color(0xFFE0E0E0),
                    child: const Icon(Icons.image_outlined,
                        size: 48, color: AppColors.grey),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF2A2A2A),
                              const Color(0xFF1A1A1A)
                            ]
                          : [
                              const Color(0xFFE0E0E0),
                              const Color(0xFFC0C0C0)
                            ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Avatar section (inside the solid-bg container) ──────────────────────
  Widget _buildAvatarOverlay(BuildContext context, User? user, bool isDark) {
    final bgColor = isDark ? AppColors.background : AppColors.bgLight;
    const avatarRadius = 48.0;

    return Column(
      children: [
        const SizedBox(height: 16),
        // Circular avatar
        Center(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: bgColor, width: 4),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor:
                  isDark ? const Color(0xFF252525) : const Color(0xFFE0E0E0),
              backgroundImage: user?.profileImageUrl != null
                  ? CachedNetworkImageProvider(user!.profileImageUrl!)
                  : null,
              child: user?.profileImageUrl == null
                  ? Text(
                      _initials(user),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        fontFamily: kFontFamily,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Name, email, role badge ──────────────────────────────────────────────
  Widget _buildUserInfo(BuildContext context, User? user, bool isDark) {
    final nameColor = isDark ? AppColors.white : AppColors.dark;
    final emailColor = isDark ? AppColors.grey : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            user?.fullName ?? 'Guest User',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: nameColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: emailColor,
            ),
          ),
          const SizedBox(height: 10),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Attendee',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit Profile / Share Profile buttons ─────────────────────────────────
  Widget _buildActionButtons(BuildContext context, User? user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Edit Profile — outlined green
          Expanded(
            child: CustomButton(
              text: 'Edit Profile',
              isOutlined: true,
              textColor: AppColors.primary,
              height: 44,
              fontSize: 14,
              borderRadius: BorderRadius.circular(10),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const EditPersonalInfoScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Share Profile — filled green
          Expanded(
            child: CustomButton(
              text: 'Share Profile',
              backgroundColor: AppColors.primary,
              textColor: AppColors.dark,
              height: 44,
              fontSize: 14,
              borderRadius: BorderRadius.circular(10),
              onPressed: () => _shareProfile(user),
            ),
          ),
        ],
      ),
    );
  }

  // ── Settings section ─────────────────────────────────────────────────────
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required bool isDark,
    required List<_SettingItem> items,
  }) {
    final titleColor = isDark ? AppColors.grey : AppColors.textSecondaryLight;
    final itemColor = isDark ? AppColors.white : AppColors.dark;
    final chevronColor = isDark ? AppColors.grey : AppColors.textSecondaryLight;
    final iconColor = isDark ? AppColors.grey300 : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: titleColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isLast = i == items.length - 1;
                final isFirst = i == 0;
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: item.onTap,
                        splashColor: AppColors.primary.withOpacity(0.08),
                        highlightColor: AppColors.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.vertical(
                          top: isFirst
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottom: isLast
                              ? const Radius.circular(12)
                              : Radius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          child: Row(
                            children: [
                              Icon(item.icon, color: iconColor, size: 22),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontFamily: kFontFamily,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: itemColor,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: chevronColor, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 54,
                        color: isDark
                            ? AppColors.divider
                            : const Color(0xFFE8E9EA),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dark / Light mode toggle ──────────────────────────────────────────
  Widget _buildThemeToggle(BuildContext context, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final itemColor = isDark ? AppColors.white : AppColors.dark;
    final iconColor = isDark ? AppColors.grey300 : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: itemColor,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: themeProvider.isDarkMode,
                  activeColor: AppColors.primary,
                  onChanged: (_) async {
                    if (themeProvider.isDarkMode) {
                      await themeProvider.setThemeMode(ThemeMode.light);
                    } else {
                      await themeProvider.setThemeMode(ThemeMode.dark);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sign out tile ────────────────────────────────────────────────────────
  Widget _buildSignOutTile(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showSignOutDialog(context),
            splashColor: AppColors.dangerText.withOpacity(0.08),
            highlightColor: AppColors.dangerText.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded,
                      color: AppColors.dangerText, size: 22),
                  const SizedBox(width: 16),
                  const Text(
                    'Sign out',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.dangerText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sign-out confirmation dialog (Figma node 2131:22254) ─────────────────
  void _showSignOutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you\nwant to sign out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.dark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You will be logged out of your account and will need to sign in again to access your profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark ? AppColors.grey : AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // "Yes" — outlined rounded button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go('/onboarding');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.divider
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Text(
                      'Yes',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.dark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // "Cancel" — filled green (reusable primary button)
                AppPrimaryButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _initials(User? user) {
    if (user == null) return '?';
    final f = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final l = user.lastName.isNotEmpty ? user.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  void _shareProfile(User? user) {
    final name = user?.fullName ?? 'a user';
    Share.share('Check out $name on EventBn!');
  }
}

// ── Data holder ────────────────────────────────────────────────────────────
class _SettingItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
