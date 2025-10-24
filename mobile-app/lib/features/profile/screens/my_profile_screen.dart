import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../explore/services/explore_post_service.dart';
import '../../explore/models/post_model.dart';
import '../../auth/screens/security_settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBillingAddress;

  const ProfileScreen({super.key, this.showBillingAddress = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExplorePostService _postService = ExplorePostService();
  final AuthService _authService = AuthService();
  List<ExplorePost> _userPosts = [];
  bool _isLoadingPosts = true;
  String? _lastLoadedUserId; // Track the last user ID we loaded posts for

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Wait for the next frame to ensure AuthProvider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProfileData();
    });
  }

  Future<void> _initializeProfileData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for auth to be fully initialized AND user to be available
    print('🔄 [PROFILE] Waiting for authentication to complete...');

    // More robust waiting with both polling and listener approach
    if (authProvider.isLoading || authProvider.user == null) {
      // Create a completer to wait for auth completion
      final completer = Completer<void>();
      late VoidCallback listener;

      // Set up listener to complete when auth is ready
      listener = () {
        if (!authProvider.isLoading && authProvider.user != null) {
          print(
              '✅ [PROFILE] Authentication ready via listener - user: ${authProvider.user?.id}');
          authProvider.removeListener(listener);
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      };

      // Add listener to auth provider
      authProvider.addListener(listener);

      // Also use polling as backup with timeout
      int waitAttempts = 0;
      const maxWaitAttempts = 100; // 10 seconds total (100 * 100ms)

      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        waitAttempts++;

        final stillWaiting =
            authProvider.isLoading || authProvider.user == null;
        if (stillWaiting) {
          print(
              '🔄 [PROFILE] Still waiting ($waitAttempts/100) - isLoading: ${authProvider.isLoading}, user: ${authProvider.user?.id ?? 'null'}');
        }

        // Complete if auth is ready
        if (!stillWaiting && !completer.isCompleted) {
          print(
              '✅ [PROFILE] Authentication ready via polling - user: ${authProvider.user?.id}');
          authProvider.removeListener(listener);
          completer.complete();
          return false;
        }

        // Stop waiting if we've reached timeout
        if (waitAttempts >= maxWaitAttempts) {
          print(
              '⚠️ [PROFILE] Timeout waiting for authentication - proceeding anyway');
          authProvider.removeListener(listener);
          if (!completer.isCompleted) {
            completer.complete();
          }
          return false;
        }

        return stillWaiting && !completer.isCompleted;
      });

      // Wait for completion
      await completer.future;
    } else {
      print(
          '✅ [PROFILE] Authentication already ready - user: ${authProvider.user?.id}');
    }

    if (authProvider.user != null) {
      print(
          '✅ [PROFILE] Final check - authentication ready - user: ${authProvider.user?.id}');
    } else {
      print(
          '❌ [PROFILE] Final check - authentication timeout - user still null after waiting');
    }

    // Now load user posts
    _loadUserPosts();

    // Show billing address modal if requested
    if (widget.showBillingAddress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBillingAddressModal(context);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser?.id != null) {
        print('📋 [PROFILE] Loading posts for user: ${currentUser!.id}');
        _lastLoadedUserId = currentUser.id; // Update the tracked user ID

        // Fetch posts for the current user
        final posts = await _postService.getExplorePostsForUser(
          userId: currentUser.id,
          page: 1,
          limit: 50, // Load more posts for the grid
        );
        setState(() {
          _userPosts = posts;
          _isLoadingPosts = false;
        });
        print(
            '✅ [PROFILE] Successfully loaded ${posts.length} posts for user: ${currentUser.id}');
      } else {
        print(
            '❌ [PROFILE] No user ID available for loading posts - currentUser: $currentUser');
        setState(() {
          _userPosts = [];
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('Error loading user posts: $e');
      setState(() {
        _userPosts = [];
        _isLoadingPosts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          // Check if user has changed and reload posts if needed
          if (user?.id != null &&
              user!.id != _lastLoadedUserId &&
              !_isLoadingPosts) {
            _lastLoadedUserId = user.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadUserPosts();
            });
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                floating: false,
                title: Row(
                  children: [
                    Text(
                      user?.firstName ?? 'user',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.onSurface,
                      size: 20,
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: () => _showCreateMenu(context),
                    icon: Icon(
                      Icons.add_box_outlined,
                      color: colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showOptionsMenu(context, authProvider),
                    icon: Icon(
                      Icons.menu,
                      color: colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
            body: RefreshIndicator(
              onRefresh: _loadUserPosts,
              child: CustomScrollView(
                slivers: [
                  // Profile Header
                  SliverToBoxAdapter(
                    child: _buildProfileHeader(context, user, colorScheme),
                  ),

                  // Story Highlights
                  SliverToBoxAdapter(
                    child: _buildStoryHighlights(context, colorScheme),
                  ),

                  // Tab Bar
                  SliverToBoxAdapter(
                    child: _buildTabBar(context, colorScheme),
                  ),

                  // Posts Grid
                  _isLoadingPosts
                      ? SliverToBoxAdapter(
                          child: _buildLoadingGrid(context),
                        )
                      : _userPosts.isEmpty
                          ? SliverToBoxAdapter(
                              child:
                                  _buildEmptyPostsState(context, colorScheme),
                            )
                          : SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index < _userPosts.length) {
                                    return _buildPostGridItem(
                                      context,
                                      _userPosts[index],
                                      colorScheme,
                                    );
                                  }
                                  return null;
                                },
                                childCount: _userPosts.length,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                                childAspectRatio: 1.0,
                              ),
                            ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  void _showBillingAddressModal(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _BillingAddressModal(
        currentUser: authProvider.user,
        onSave: (billingData) async {
          // Handle billing address save using backend API
          try {
            print('💾 [BILLING] Saving billing address: $billingData');

            // Create updated user with new billing data
            final updatedUser = authProvider.user!.copyWith(
              billingAddress: billingData['billingAddress']?.toString(),
              billingCity: billingData['billingCity']?.toString(),
              billingState: billingData['billingState']?.toString(),
              billingCountry: billingData['billingCountry']?.toString(),
              billingPostalCode: billingData['billingPostalCode']?.toString(),
              profileCompleted: true,
            );

            // Use AuthService to update profile with billing data
            final result = await _authService.updateUserProfile(updatedUser);

            if (result['success'] == true) {
              print('✅ [BILLING] Billing address updated successfully');

              // Update the AuthProvider with the new user data
              authProvider.updateUser(updatedUser);

              // Check if widget is still mounted before showing snackbar
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Billing address updated successfully!')),
                );
              }
            } else {
              throw Exception(
                  result['message'] ?? 'Failed to update billing address');
            }
          } catch (e) {
            print('❌ [BILLING] Failed to update billing address: $e');
            // Check if widget is still mounted before showing snackbar
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update billing address: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEmergencyContactModal(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EmergencyContactModal(
        currentUser: authProvider.user,
        onSave: (emergencyData) async {
          // Handle emergency contact save
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Emergency contact updated successfully!')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update emergency contact: $e')),
            );
          }
        },
      ),
    );
  }

  void _showCommunicationPreferencesModal(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CommunicationPreferencesModal(
        currentUser: authProvider.user,
        onSave: (preferencesData) async {
          // Handle communication preferences save
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Communication preferences updated successfully!')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Failed to update communication preferences: $e')),
            );
          }
        },
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  void _showSettingsModal(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.only(
          bottom:
              kBottomNavigationBarHeight + 32, // Add space for bottom navbar
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsOption(
                      context, Icons.tune_outlined, 'Preferences', () {
                    Navigator.pop(context);
                    _showPreferencesModal(context, authProvider);
                  }),
                  _buildSettingsOption(context, Icons.palette_outlined, 'Theme',
                      () {
                    Navigator.pop(context);
                    _showThemeDialog(context,
                        Provider.of<ThemeProvider>(context, listen: false));
                  }),
                  // Help & Support removed until implemented
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreferencesModal(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.only(
          bottom:
              kBottomNavigationBarHeight + 32, // Add space for bottom navbar
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Text(
                        'Preferences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsOption(
                      context, Icons.location_on_outlined, 'Billing Address',
                      () {
                    Navigator.pop(context);
                    _showBillingAddressModal(context);
                  }),
                  _buildSettingsOption(
                      context, Icons.emergency_outlined, 'Emergency Contact',
                      () {
                    Navigator.pop(context);
                    _showEmergencyContactModal(context);
                  }),
                  _buildSettingsOption(context, Icons.settings_outlined,
                      'Communication Preferences', () {
                    Navigator.pop(context);
                    _showCommunicationPreferencesModal(context);
                  }),
                  // Notifications and Privacy removed until implemented
                  _buildSettingsOption(
                      context, Icons.security_outlined, 'Security', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecuritySettingsScreen(),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
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
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 0.5)
              : null,
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
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.7)
                          : colorScheme.onSurfaceVariant,
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

  Widget _buildProfileHeader(
      BuildContext context, dynamic user, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and Stats Row
          Row(
            children: [
              // Profile Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: user?.profileImageUrl != null &&
                          user!.profileImageUrl!.isNotEmpty
                      ? ClipOval(
                          child: user!.profileImageUrl!.startsWith('file://')
                              ? Image.file(
                                  File(user!.profileImageUrl!
                                      .replaceFirst('file://', '')
                                      .split(
                                          '?')[0]), // Remove query parameters
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 45,
                                      color: colorScheme.onSurfaceVariant,
                                    );
                                  },
                                )
                              : CachedNetworkImage(
                                  imageUrl: user!.profileImageUrl!,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Icon(
                                    Icons.person,
                                    size: 45,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    size: 45,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        )
                      : Icon(
                          Icons.person,
                          size: 45,
                          color: colorScheme.onSurfaceVariant,
                        ),
                ),
              ),

              const SizedBox(width: 24),

              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                        '${_userPosts.length}', 'Posts', colorScheme),
                    // Followers & Following removed until backend is implemented
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name and Bio
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    user?.firstName != null && user?.lastName != null
                        ? '${user!.firstName} ${user!.lastName}'
                        : user?.firstName ?? 'User',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'User',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              // if (user?.email != null) ...[
              //   const SizedBox(height: 4),
              //   Text(
              //     user!.email,
              //     style: TextStyle(
              //       fontSize: 12,
              //       color: colorScheme.onSurfaceVariant,
              //     ),
              //   ),
              // ],
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Edit Profile',
                  colorScheme,
                  icon: Icons.edit_outlined,
                  onTap: () => _editProfile(context),
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    ColorScheme colorScheme, {
    IconData? icon,
    VoidCallback? onTap,
    bool isIconOnly = false,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isPrimary
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Center(
          child: isIconOnly
              ? Icon(
                  icon,
                  size: 18,
                  color:
                      isPrimary ? colorScheme.onPrimary : colorScheme.onSurface,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 16,
                        color: isPrimary
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPrimary
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStoryHighlights(BuildContext context, ColorScheme colorScheme) {
    // Story highlights section removed for cleaner UI
    return const SizedBox.shrink();
  }

  Widget _buildTabBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: colorScheme.onPrimaryContainer,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.grid_on, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Posts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.video_library_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Videos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bookmark_border, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Saved',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid(BuildContext context) {
    return SizedBox(
      height: 400,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPostsState(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your first post to get started!',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateMenu(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGridItem(
    BuildContext context,
    ExplorePost post,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to IGTV feed screen (same as explore page)
        print('🎯 Profile post tapped! Post ID: ${post.id}');
        print('🚀 Navigating to: /explore/igtv/${post.id}');
        try {
          context.push('/explore/igtv/${post.id}');
          print('✅ Navigation call successful');
        } catch (e) {
          print('❌ Navigation failed: $e');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Post Image or Video Thumbnail
            if (post.videoUrls.isNotEmpty && post.videoThumbnails.isNotEmpty)
              // Show video thumbnail for video posts
              CachedNetworkImage(
                imageUrl: post.videoThumbnails.first,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.video_library,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else if (post.imageUrls.isNotEmpty)
              // Show image for photo posts
              CachedNetworkImage(
                imageUrl: post.imageUrls.first,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              // Default placeholder
              Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

            // Multiple Photos Indicator
            if (post.imageUrls.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.copy_outlined,
                  color: Colors.white,
                  size: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),

            // Video Indicator
            if (post.videoUrls.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              kBottomNavigationBarHeight +
              32, // Add more space for bottom navbar
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCreateOption(context, Icons.add_box_outlined, 'Post',
                        () {
                      Navigator.pop(context);
                      context.push('/create-post');
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOption(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showOptionsMenu(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Container(
        margin: const EdgeInsets.only(
          bottom: kBottomNavigationBarHeight +
              32, // Add more space for bottom navbar
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuOption(context, Icons.edit_outlined, 'Edit Profile',
                      () {
                    Navigator.pop(context);
                    _editProfile(context);
                  }),
                  _buildMenuOption(context, Icons.settings_outlined, 'Settings',
                      () {
                    Navigator.pop(context);
                    _showSettingsModal(context, authProvider);
                  }),
                  _buildMenuOption(context, Icons.logout, 'Log Out', () {
                    Navigator.pop(context);
                    _showLogoutDialog(context, authProvider);
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _editProfile(BuildContext context) async {
    // Navigate to edit profile screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );

    // If profile was updated successfully, refresh the current screen
    if (result == true) {
      setState(() {
        // This will trigger a rebuild and reload user data
      });
    }
  }
}

// Settings Modal Widgets
class _BillingAddressModal extends StatefulWidget {
  final User? currentUser;
  final Function(Map<String, dynamic>) onSave;

  const _BillingAddressModal({
    required this.currentUser,
    required this.onSave,
  });

  @override
  State<_BillingAddressModal> createState() => _BillingAddressModalState();
}

class _BillingAddressModalState extends State<_BillingAddressModal> {
  final _formKey = GlobalKey<FormState>();
  final _billingAddressController = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingCountryController = TextEditingController();
  final _billingPostalCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with current user data if available
    if (widget.currentUser != null) {
      _billingAddressController.text = widget.currentUser!.billingAddress ?? '';
      _billingCityController.text = widget.currentUser!.billingCity ?? '';
      _billingStateController.text = widget.currentUser!.billingState ?? '';
      _billingCountryController.text = widget.currentUser!.billingCountry ?? '';
      _billingPostalCodeController.text =
          widget.currentUser!.billingPostalCode ?? '';
    }
  }

  @override
  void dispose() {
    _billingAddressController.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingCountryController.dispose();
    _billingPostalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            kBottomNavigationBarHeight +
            32,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Billing Address',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This information will be used for payment processing and receipts.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Billing Address
                    TextFormField(
                      controller: _billingAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Address Line *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home_outlined),
                        helperText: 'Street address, apartment, building, etc.',
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Address is required for payment processing';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // City and State Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _billingCityController,
                            decoration: const InputDecoration(
                              labelText: 'City *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'City is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _billingStateController,
                            decoration: const InputDecoration(
                              labelText: 'State/Province',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Country and Postal Code Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _billingCountryController,
                            decoration: const InputDecoration(
                              labelText: 'Country *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.public_outlined),
                            ),
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'Country is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _billingPostalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your billing address is securely stored and used only for payment verification and receipt generation.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final billingData = {
                              'firstName': widget.currentUser?.firstName ?? '',
                              'lastName': widget.currentUser?.lastName ?? '',
                              'phoneNumber':
                                  widget.currentUser?.phoneNumber ?? '',
                              'billingAddress':
                                  _billingAddressController.text.trim(),
                              'billingCity': _billingCityController.text.trim(),
                              'billingState':
                                  _billingStateController.text.trim(),
                              'billingCountry':
                                  _billingCountryController.text.trim(),
                              'billingPostalCode':
                                  _billingPostalCodeController.text.trim(),
                            };
                            widget.onSave(billingData);
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Save Billing Address'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmergencyContactModal extends StatefulWidget {
  final User? currentUser;
  final Function(Map<String, dynamic>) onSave;

  const _EmergencyContactModal({
    required this.currentUser,
    required this.onSave,
  });

  @override
  State<_EmergencyContactModal> createState() => _EmergencyContactModalState();
}

class _EmergencyContactModalState extends State<_EmergencyContactModal> {
  final _formKey = GlobalKey<FormState>();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _emergencyContactRelationshipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with current user emergency contact data if available
    if (widget.currentUser != null) {
      _emergencyContactNameController.text =
          widget.currentUser?.emergencyContactName ?? '';
      _emergencyContactPhoneController.text =
          widget.currentUser?.emergencyContactPhone ?? '';
      _emergencyContactRelationshipController.text =
          widget.currentUser?.emergencyContactRelationship ?? '';
    }
  }

  @override
  void dispose() {
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emergencyContactRelationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            kBottomNavigationBarHeight +
            32,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Emergency Contact',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emergency contact information for safety at events.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Emergency Contact Name
                    TextFormField(
                      controller: _emergencyContactNameController,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Contact Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                        helperText:
                            'Optional - Full name of your emergency contact',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Emergency Contact Phone
                    TextFormField(
                      controller: _emergencyContactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Contact Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                        helperText:
                            'Optional - Include country code (e.g., +94xxxxxxxxx)',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.trim().isNotEmpty == true) {
                          if (!RegExp(r'^\+\d{10,15}$')
                              .hasMatch(value!.trim())) {
                            return 'Enter a valid phone number with country code';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Emergency Contact Relationship
                    TextFormField(
                      controller: _emergencyContactRelationshipController,
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.family_restroom_outlined),
                        helperText:
                            'Optional - e.g., Parent, Spouse, Sibling, Friend',
                      ),
                    ),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.emergency_outlined,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Emergency Contact Information',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This information will only be used in case of emergency during events. Your privacy is protected.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final emergencyData = {
                              'emergencyContactName':
                                  _emergencyContactNameController.text.trim(),
                              'emergencyContactPhone':
                                  _emergencyContactPhoneController.text.trim(),
                              'emergencyContactRelationship':
                                  _emergencyContactRelationshipController.text
                                      .trim(),
                            };
                            widget.onSave(emergencyData);
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Save Emergency Contact'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CommunicationPreferencesModal extends StatefulWidget {
  final User? currentUser;
  final Function(Map<String, dynamic>) onSave;

  const _CommunicationPreferencesModal({
    required this.currentUser,
    required this.onSave,
  });

  @override
  State<_CommunicationPreferencesModal> createState() =>
      _CommunicationPreferencesModalState();
}

class _CommunicationPreferencesModalState
    extends State<_CommunicationPreferencesModal> {
  bool _eventNotifications = true;
  bool _marketingEmails = false;
  bool _smsNotifications = true;

  @override
  void initState() {
    super.initState();
    // Initialize with current user preferences if available
    if (widget.currentUser != null) {
      _eventNotifications =
          widget.currentUser?.eventNotificationsEnabled ?? true;
      _marketingEmails = widget.currentUser?.marketingEmailsEnabled ?? false;
      _smsNotifications = widget.currentUser?.smsNotificationsEnabled ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            kBottomNavigationBarHeight +
            32,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Communication Preferences',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to receive notifications and updates.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Event Notifications
                  Card(
                    child: SwitchListTile(
                      title: const Text('Event Notifications'),
                      subtitle: const Text(
                          'Receive notifications about your booked events'),
                      value: _eventNotifications,
                      onChanged: (value) {
                        setState(() {
                          _eventNotifications = value;
                        });
                      },
                      secondary: const Icon(Icons.event_outlined),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Marketing Emails
                  Card(
                    child: SwitchListTile(
                      title: const Text('Marketing Emails'),
                      subtitle: const Text(
                          'Receive promotional offers and event recommendations'),
                      value: _marketingEmails,
                      onChanged: (value) {
                        setState(() {
                          _marketingEmails = value;
                        });
                      },
                      secondary: const Icon(Icons.mail_outline),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // SMS Notifications
                  Card(
                    child: SwitchListTile(
                      title: const Text('SMS Notifications'),
                      subtitle: const Text('Receive important updates via SMS'),
                      value: _smsNotifications,
                      onChanged: (value) {
                        setState(() {
                          _smsNotifications = value;
                        });
                      },
                      secondary: const Icon(Icons.sms_outlined),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can change these preferences at any time. We respect your privacy and follow data protection regulations.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final preferencesData = {
                          'eventNotifications': _eventNotifications,
                          'marketingEmails': _marketingEmails,
                          'smsNotifications': _smsNotifications,
                        };
                        widget.onSave(preferencesData);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save Communication Preferences'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
