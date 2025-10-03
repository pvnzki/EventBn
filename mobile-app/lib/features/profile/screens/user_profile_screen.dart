import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../explore/services/explore_post_service.dart';
import '../../explore/models/post_model.dart';
import '../../explore/widgets/explore_post_card.dart';
import '../services/user_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isFollowing = false;
  final ExplorePostService _postService = ExplorePostService();
  final UserService _userService = UserService();
  List<ExplorePost> _userPosts = [];
  bool _isLoadingPosts = false;
  bool _isLoadingUser = false;

  // User data - will be fetched from API
  Map<String, dynamic>? userData;

  // Helper getters for safe access to userData
  String get userName => userData?['name'] ?? 'Unknown User';
  String get userUsername => userData?['username'] ?? '@user';
  String get userAvatar => userData?['avatar'] ?? 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200';
  String get userCoverImage => userData?['coverImage'] ?? 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800';
  String? get userBio => userData?['bio'];
  String? get userLocation => userData?['location'];
  String? get userWebsite => userData?['website'];
  String get userJoinedDate => userData?['joinedDate'] ?? 'Recently';
  bool get userIsVerified => userData?['isVerified'] ?? false;
  String get userPostsCount => userData?['posts']?.toString() ?? '0';
  String get userFollowersCount => userData?['followers']?.toString() ?? '0';
  String get userFollowingCount => userData?['following']?.toString() ?? '0';
  List<String> get userInterests => List<String>.from(userData?['interests'] ?? ['Events']);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadUserPosts();
  }

  void _loadUserData() async {
    setState(() => _isLoadingUser = true);
    
    try {
      print('👤 [UserProfile] Loading user data for ID: ${widget.userId}');
      final fetchedUserData = await _userService.getUserById(widget.userId);
      
      if (fetchedUserData != null) {
        setState(() {
          userData = {
            'id': fetchedUserData['id'] ?? widget.userId,
            'name': fetchedUserData['fullName'] ?? fetchedUserData['name'] ?? 'Unknown User',
            'username': '@${fetchedUserData['username'] ?? fetchedUserData['email']?.split('@')[0] ?? 'user'}',
            'avatar': fetchedUserData['profileImageUrl'] ?? 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
            'coverImage': fetchedUserData['coverImageUrl'] ?? 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
            'bio': fetchedUserData['bio'] ?? 'Event enthusiast. Love exploring new places and meeting new people through amazing events.',
            'posts': 0, // Will be updated when posts are loaded
            'followers': fetchedUserData['followersCount']?.toString() ?? '0',
            'following': fetchedUserData['followingCount'] ?? 0,
            'location': fetchedUserData['location'] ?? null,
            'website': fetchedUserData['website'] ?? null,
            'joinedDate': _formatJoinDate(fetchedUserData['createdAt']),
            'isVerified': fetchedUserData['isVerified'] ?? false,
            'interests': fetchedUserData['interests'] ?? ['Events', 'Networking'],
          };
        });
        print('✅ [UserProfile] User data loaded successfully');
      } else {
        // Fallback to enhanced mock data based on userId
        print('⚠️ [UserProfile] User not found, using enhanced fallback data for userId: ${widget.userId}');
        setState(() {
          userData = _getEnhancedFallbackUserData(widget.userId);
        });
      }
    } catch (e) {
      print('❌ [UserProfile] Error loading user data: $e');
      setState(() {
        userData = _getEnhancedFallbackUserData(widget.userId);
      });
    } finally {
      setState(() => _isLoadingUser = false);
    }
  }

  Map<String, dynamic> _getEnhancedFallbackUserData(String userId) {
    // Create realistic fallback data based on userId
    final List<Map<String, dynamic>> fallbackUsers = [
      {
        'id': '1',
        'name': 'John Smith',
        'username': '@johnsmith',
        'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
        'coverImage': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
        'bio': 'Event enthusiast and photographer. Love exploring new places and meeting new people through amazing events.',
        'followers': '2.1K',
        'following': 156,
        'location': 'New York, NY',
        'website': 'johnsmith.com',
        'isVerified': true,
        'interests': ['Music', 'Photography', 'Travel', 'Food'],
      },
      {
        'id': '2',
        'name': 'Sarah Johnson',
        'username': '@sarahj',
        'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200',
        'coverImage': 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800',
        'bio': 'Event organizer and community builder. Creating memorable experiences one event at a time.',
        'followers': '5.3K',
        'following': 289,
        'location': 'Los Angeles, CA',
        'website': 'sarahevent.com',
        'isVerified': false,
        'interests': ['Events', 'Community', 'Design', 'Business'],
      },
      {
        'id': '3',
        'name': 'Mike Chen',
        'username': '@mikechen',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        'coverImage': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
        'bio': 'Tech enthusiast and startup founder. Building the future of events.',
        'followers': '8.7K',
        'following': 523,
        'location': 'San Francisco, CA',
        'website': null,
        'isVerified': true,
        'interests': ['Technology', 'Startups', 'Innovation', 'Networking'],
      },
    ];

    // Find matching user or create generic one
    final matchingUser = fallbackUsers.firstWhere(
      (user) => user['id'] == userId,
      orElse: () => {
        'id': userId,
        'name': 'EventBn User',
        'username': '@user$userId',
        'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
        'coverImage': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
        'bio': 'Event enthusiast and community member.',
        'followers': '${(int.tryParse(userId) ?? 1) * 100}',
        'following': (int.tryParse(userId) ?? 1) * 50,
        'location': 'EventBn Community',
        'website': null,
        'isVerified': false,
        'interests': ['Events', 'Networking', 'Community'],
      },
    );

    return {
      'id': matchingUser['id'],
      'name': matchingUser['name'],
      'username': matchingUser['username'],
      'avatar': matchingUser['avatar'],
      'coverImage': matchingUser['coverImage'],
      'bio': matchingUser['bio'],
      'posts': 0, // Will be updated when posts are loaded
      'followers': matchingUser['followers'],
      'following': matchingUser['following'],
      'location': matchingUser['location'],
      'website': matchingUser['website'],
      'joinedDate': 'March 2023',
      'isVerified': matchingUser['isVerified'],
      'interests': matchingUser['interests'],
    };
  }

  String _formatJoinDate(String? createdAt) {
    if (createdAt == null) return 'Recently';
    
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays < 30) {
        return 'Recently';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).round();
        return '${months} month${months > 1 ? 's' : ''} ago';
      } else {
        final years = (difference.inDays / 365).round();
        return '${years} year${years > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() => _isLoadingPosts = true);
    
    try {
      // Load all posts if not already loaded
      if (_postService.posts.isEmpty) {
        await _postService.loadPosts(refresh: true);
      }
      
      // Filter posts by user ID
      _userPosts = _postService.posts
          .where((post) => post.userId == widget.userId)
          .toList();
      
      // Update post count in userData if available
      if (userData != null) {
        userData!['posts'] = _userPosts.length;
      }
      
      print('📱 Loaded ${_userPosts.length} posts for user ${widget.userId}');
    } catch (e) {
      print('❌ Error loading user posts: $e');
    } finally {
      setState(() => _isLoadingPosts = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show loading screen while user data is being fetched
    if (_isLoadingUser || userData == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.surface,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
                  onPressed: () => _showProfileOptions(),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    // Cover Image
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(userCoverImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Profile Info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Avatar and basic info
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.surface,
                                      width: 4,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundImage:
                                        NetworkImage(userAvatar),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Stats
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatColumn('Posts',
                                          userPostsCount),
                                      _buildStatColumn(
                                          'Followers', userFollowersCount),
                                      _buildStatColumn('Following',
                                          userFollowingCount),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Name and username
                            Row(
                              children: [
                                Text(
                                  userName,
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (userIsVerified) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                userUsername,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Bio
                            if (userBio != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  userBio!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            const SizedBox(height: 8),
                            // Location and join date
                            Row(
                              children: [
                                if (userLocation != null) ...[
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    userLocation!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Joined $userJoinedDate',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Action buttons (Instagram style)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    text: isFollowing ? 'Following' : 'Follow',
                                    isPrimary: !isFollowing,
                                    onPressed: () {
                                      setState(() {
                                        isFollowing = !isFollowing;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildActionButton(
                                    text: 'Message',
                                    isPrimary: false,
                                    onPressed: _sendMessage,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  text: '',
                                  isPrimary: false,
                                  isIconOnly: true,
                                  icon: Icons.person_add,
                                  onPressed: () {
                                    // Add to close friends or similar action
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  indicatorColor: colorScheme.primary,
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Events'),
                    Tab(text: 'About'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildEventsTab(),
            _buildAboutTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Follow/Following Button (Instagram style)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isFollowing = !isFollowing;
                    });
                    // TODO: Implement actual follow/unfollow logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing 
                        ? colorScheme.surfaceContainerHighest 
                        : colorScheme.primary,
                    foregroundColor: isFollowing 
                        ? colorScheme.onSurface 
                        : colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: isFollowing 
                          ? BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Message Button (Instagram style)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _sendMessage(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Message',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // More Options Button (Instagram style)
              Container(
                width: 44,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _showProfileOptions(),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: colorScheme.onSurface,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required bool isPrimary,
    required VoidCallback onPressed,
    bool isIconOnly = false,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isIconOnly) {
      return SizedBox(
        width: 44,
        height: 32,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Icon(
            icon ?? Icons.more_horiz,
            size: 16,
          ),
        ),
      );
    }

    return SizedBox(
      height: 32,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
    );
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When this user shares photos and videos, they\'ll appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return GestureDetector(
          onTap: () {
            // Navigate to post detail
            context.push('/post/${post.id}');
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Display image or video thumbnail
                  if (post.imageUrls.isNotEmpty)
                    Image.network(
                      post.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    )
                  else if (post.videoThumbnails.isNotEmpty)
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          post.videoThumbnails.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.video_library,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                        // Video play icon overlay
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    )
                  else
                    // Fallback for posts without media
                    Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.text_fields,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Text Post',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        );
      },
    );
  }

  Widget _buildEventsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=100',
              ),
            ),
            title: Text('Event ${index + 1}'),
            subtitle: const Text('Event description'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to event details
            },
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Interests
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interests',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: userInterests.map<Widget>((interest) {
                    return Chip(
                      label: Text(interest),
                      backgroundColor: colorScheme.primaryContainer,
                      labelStyle:
                          TextStyle(color: colorScheme.onPrimaryContainer),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Contact Info
        if (userWebsite != null)
          Card(
            child: ListTile(
              leading: Icon(Icons.language, color: colorScheme.primary),
              title: Text(userWebsite!),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () {
                // Open website
              },
            ),
          ),
      ],
    );
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(
              bottom: 90), // Account for bottom nav height + padding
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // Share profile
                },
              ),
              ListTile(
                leading: Icon(Icons.block,
                    color: Theme.of(context).colorScheme.error),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  // Block user
                },
              ),
              ListTile(
                leading: Icon(Icons.report,
                    color: Theme.of(context).colorScheme.error),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  // Report user
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() {
    // Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messaging feature coming soon!')),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
