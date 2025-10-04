import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../explore/services/explore_post_service.dart';
import '../../explore/models/post_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExplorePostService _postService = ExplorePostService();
  List<ExplorePost> _userPosts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserPosts();
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
        // Fetch posts for the current user
        final posts = await _postService.getExplorePostsForUser(
          userId: currentUser!.id,
          page: 1,
          limit: 50, // Load more posts for the grid
        );
        setState(() {
          _userPosts = posts;
          _isLoadingPosts = false;
        });
      } else {
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
                      context, Icons.notifications_outlined, 'Notifications',
                      () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Notifications settings coming soon!')),
                    );
                  }),
                  _buildSettingsOption(
                      context, Icons.privacy_tip_outlined, 'Privacy', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Privacy settings coming soon!')),
                    );
                  }),
                  _buildSettingsOption(
                      context, Icons.security_outlined, 'Security', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Security settings coming soon!')),
                    );
                  }),
                  _buildSettingsOption(context, Icons.palette_outlined, 'Theme',
                      () {
                    Navigator.pop(context);
                    _showThemeDialog(context,
                        Provider.of<ThemeProvider>(context, listen: false));
                  }),
                  _buildSettingsOption(
                      context, Icons.help_outline, 'Help & Support', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Help & Support coming soon!')),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: user?.profileImageUrl != null
                      ? CachedNetworkImageProvider(user!.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        )
                      : null,
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
                    _buildStatColumn('0', 'Followers', colorScheme),
                    _buildStatColumn('0', 'Following', colorScheme),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Name and Bio
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.firstName != null && user?.lastName != null
                    ? '${user!.firstName} ${user!.lastName}'
                    : user?.firstName ?? 'User',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'EventBn user • Event enthusiast 🎉',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
              if (user?.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  user!.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildActionButton(
                  'Edit Profile',
                  colorScheme,
                  onTap: () => _editProfile(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildActionButton(
                  'Share Profile',
                  colorScheme,
                  onTap: () => _shareProfile(context),
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                '',
                colorScheme,
                icon: Icons.person_add_outlined,
                onTap: () => _suggestPeople(context),
                isIconOnly: true,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Center(
          child: isIconOnly
              ? Icon(
                  icon,
                  size: 16,
                  color: colorScheme.onSurface,
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStoryHighlights(BuildContext context, ColorScheme colorScheme) {
    // Simplified highlights section for minimal UI
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Add New Highlight
          Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'New',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: colorScheme.onSurface,
        indicatorWeight: 1,
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        tabs: const [
          Tab(
            icon: Icon(Icons.grid_on, size: 22),
          ),
          Tab(
            icon: Icon(Icons.video_library_outlined, size: 22),
          ),
          Tab(
            icon: Icon(Icons.bookmark_border, size: 22),
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
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1.0,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  Widget _buildPostGridItem(
    BuildContext context,
    ExplorePost post,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to post detail screen (same as explore page)
        print('🎯 Profile post tapped! Post ID: ${post.id}');
        print('🚀 Navigating to: /explore/post/${post.id}');
        try {
          context.push('/explore/post/${post.id}');
          print('✅ Navigation call successful');
        } catch (e) {
          print('❌ Navigation failed: $e');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Post Image
            if (post.imageUrls.isNotEmpty)
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
      builder: (context) => Container(
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
                  _buildCreateOption(context, Icons.video_call_outlined, 'Reel',
                      () {
                    Navigator.pop(context);
                  }),
                  _buildCreateOption(context, Icons.add_circle_outline, 'Story',
                      () {
                    Navigator.pop(context);
                  }),
                ],
              ),
            ),
          ],
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
      builder: (context) => Container(
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
                  _buildMenuOption(context, Icons.settings_outlined, 'Settings',
                      () {
                    Navigator.pop(context);
                    _showSettingsModal(context, authProvider);
                  }),
                  _buildMenuOption(context, Icons.archive_outlined, 'Archive',
                      () {
                    Navigator.pop(context);
                  }),
                  _buildMenuOption(context, Icons.history, 'Your Activity', () {
                    Navigator.pop(context);
                  }),
                  _buildMenuOption(context, Icons.qr_code, 'QR Code', () {
                    Navigator.pop(context);
                  }),
                  _buildMenuOption(context, Icons.logout, 'Log Out', () {
                    Navigator.pop(context);
                    _showLogoutDialog(context, authProvider);
                  }),
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

  void _editProfile(BuildContext context) {
    // Navigate to edit profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Profile coming soon!')),
    );
  }

  void _shareProfile(BuildContext context) {
    // Implement share profile functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share Profile coming soon!')),
    );
  }

  void _suggestPeople(BuildContext context) {
    // Navigate to suggest people screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Suggest People coming soon!')),
    );
  }
}
