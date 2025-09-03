import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.user;
            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 36), // Balance the back button
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Profile Card - Horizontal Layout
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Profile Picture
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage: user?.profileImageUrl != null 
                            ? NetworkImage(user!.profileImageUrl!) 
                            : null,
                          child: user?.profileImageUrl == null
                            ? Icon(
                                Icons.person,
                                size: 28,
                                color: colorScheme.onSurfaceVariant,
                              )
                            : null,
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // User Info Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Text(
                                user?.fullName ?? 'Jacob Jones',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Email
                              Text(
                                user?.email ?? 'jacobjones24@gmail.com',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Edit Profile Button (Text only)
                        GestureDetector(
                          onTap: () {
                            // Navigate to edit profile
                          },
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Settings Sections
                  _buildSettingsSection(
                    context, 
                    'Account details',
                    [
                      _SettingItem(
                        icon: Icons.account_circle_outlined,
                        title: 'Account',
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.credit_card_outlined,
                        title: 'Billing',
                        onTap: () {},
                      ),
                    ],
                  ),
                  
                  _buildSettingsSection(
                    context, 
                    'Target',
                    [
                      _SettingItem(
                        icon: Icons.favorite_outline,
                        title: 'Favorites',
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.flag_outlined,
                        title: 'Growth Goals',
                        onTap: () {},
                      ),
                    ],
                  ),
                  
                  _buildSettingsSection(
                    context, 
                    'General',
                    [
                      _SettingItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        onTap: () {},
                      ),
                      _SettingItem(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        trailing: 'English',
                        onTap: () {},
                      ),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return _SettingItem(
                            icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            title: 'Light/Dark Mode',
                            trailing: themeProvider.currentThemeName,
                            onTap: () => _showThemeDialog(context, themeProvider),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  _buildSettingsSection(
                    context, 
                    'Support',
                    [
                      _SettingItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                    ],
                  ),
                  
                  // Logout Button
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(context, authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom spacing to prevent hiding by navbar
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> items) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.map((item) {
              final isLast = item == items.last;
              return Column(
                children: [
                  item,
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.1),
                      indent: 60,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: colorScheme.surface,
          dialogTheme: DialogThemeData(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        child: AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Log Out',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Logged out successfully'),
                      backgroundColor: colorScheme.primary,
                    ),
                  );
                }
              },
              child: Text(
                'Log Out', 
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: colorScheme.surface,
            dialogTheme: DialogThemeData(
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: AlertDialog(
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Choose Theme',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeOption(
                  context,
                  'System',
                  'Follow system setting',
                  Icons.settings_outlined,
                  ThemeMode.system,
                  themeProvider,
                ),
                _buildThemeOption(
                  context,
                  'Light',
                  'Light theme',
                  Icons.light_mode_outlined,
                  ThemeMode.light,
                  themeProvider,
                ),
                _buildThemeOption(
                  context,
                  'Dark',
                  'Dark theme',
                  Icons.dark_mode_outlined,
                  ThemeMode.dark,
                  themeProvider,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    ThemeMode mode,
    ThemeProvider themeProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = themeProvider.themeMode == mode;

    return InkWell(
      onTap: () {
        themeProvider.setThemeMode(mode);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: colorScheme.primary, width: 0.5) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? colorScheme.primary.withValues(alpha: 0.7) : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}