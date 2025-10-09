import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../explore/services/explore_post_service.dart';
import '../../explore/models/post_model.dart';
import 'edit_profile_screen.dart';

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
                      : _userPosts.isEmpty
                          ? SliverToBoxAdapter(
                              child:
                                  _buildEmptyPostsState(context, colorScheme),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              sliver: SliverGrid(
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
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1.0,
                                ),
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
                  backgroundImage: user?.profileImageUrl != null
                      ? CachedNetworkImageProvider(user!.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 45,
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
              const SizedBox(height: 6),
              Text(
                'EventBn user • Event enthusiast 🎉',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              if (user?.email != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user!.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildActionButton(
                  'Edit Profile',
                  colorScheme,
                  icon: Icons.edit_outlined,
                  onTap: () => _editProfile(context),
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildActionButton(
                  'Share',
                  colorScheme,
                  icon: Icons.share_outlined,
                  onTap: () => _shareProfile(context),
                ),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                '',
                colorScheme,
                icon: Icons.settings_outlined,
                onTap: () => _showQuickSettingsModal(context),
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
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Menu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your profile and account settings • Scroll down for more options',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Profile Section
                        _buildSectionHeader(context, 'Profile'),
                        _buildMenuOption(
                            context, Icons.edit_outlined, 'Edit Profile', () {
                          Navigator.pop(context);
                          _editProfile(context);
                        }),
                        _buildMenuOption(
                            context, Icons.share_outlined, 'Share Profile', () {
                          Navigator.pop(context);
                          _shareProfile(context);
                        }),

                        const SizedBox(height: 16),

                        // Account Section
                        _buildSectionHeader(context, 'Account'),
                        _buildMenuOption(
                            context, Icons.settings_outlined, 'Settings', () {
                          Navigator.pop(context);
                          _showSettingsModal(context, authProvider);
                        }),
                        _buildMenuOption(
                            context, Icons.privacy_tip_outlined, 'Privacy', () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Privacy settings coming soon!')),
                          );
                        }),
                        _buildMenuOption(
                            context, Icons.security_outlined, 'Security', () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Security settings coming soon!')),
                          );
                        }),

                        const SizedBox(height: 16),

                        // Activity Section
                        _buildSectionHeader(context, 'Activity'),
                        _buildMenuOption(
                            context, Icons.archive_outlined, 'Archive', () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Archive feature coming soon!')),
                          );
                        }),
                        _buildMenuOption(
                            context, Icons.history, 'Your Activity', () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Activity feature coming soon!')),
                          );
                        }),
                        _buildMenuOption(
                            context, Icons.bookmark_outline, 'Saved Posts', () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Saved posts feature coming soon!')),
                          );
                        }),

                        const SizedBox(height: 16),

                        // Support Section
                        _buildSectionHeader(context, 'Support'),
                        _buildMenuOption(
                            context, Icons.help_outline, 'Help & Support', () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Help & Support coming soon!')),
                          );
                        }),
                        _buildMenuOption(
                            context, Icons.feedback_outlined, 'Send Feedback',
                            () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Feedback feature coming soon!')),
                          );
                        }),

                        const SizedBox(height: 16),

                        // Logout
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .errorContainer
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: _buildMenuOption(
                            context,
                            Icons.logout,
                            'Log Out',
                            () {
                              Navigator.pop(context);
                              _showLogoutDialog(context, authProvider);
                            },
                            isDestructive: true,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Visual indicator that this is the end
                        Center(
                          child: Container(
                            width: 80,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMenuOption(
      BuildContext context, IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? colorScheme.error : colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? colorScheme.error : colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive
            ? colorScheme.error.withOpacity(0.6)
            : colorScheme.onSurfaceVariant,
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

  void _shareProfile(BuildContext context) {
    // Implement share profile functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share Profile coming soon!')),
    );
  }

  void _showQuickSettingsModal(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
                  _buildMenuOption(
                      context, Icons.share_outlined, 'Share Profile', () {
                    Navigator.pop(context);
                    _shareProfile(context);
                  }),
                  _buildMenuOption(context, Icons.archive_outlined, 'Archive',
                      () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Archive feature coming soon!')),
                    );
                  }),
                  _buildMenuOption(context, Icons.history, 'Your Activity', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Activity feature coming soon!')),
                    );
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
}
