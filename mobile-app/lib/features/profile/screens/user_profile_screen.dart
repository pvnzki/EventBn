import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  // Mock user data - in real app, this would come from an API
  late Map<String, dynamic> userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  void _loadUserData() {
    // Mock data based on userId - in real app, fetch from API
    userData = {
      'id': widget.userId,
      'name': 'John Smith',
      'username': '@johnsmith',
      'avatar':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
      'coverImage':
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      'bio':
          'Event enthusiast and photographer. Love exploring new places and meeting new people through amazing events.',
      'posts': 45,
      'followers': '2.1K',
      'following': 156,
      'location': 'New York, NY',
      'website': 'johnsmith.com',
      'joinedDate': 'March 2023',
      'isVerified': true,
      'interests': ['Music', 'Photography', 'Travel', 'Food'],
    };
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
                          image: NetworkImage(userData['coverImage']),
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
                                        NetworkImage(userData['avatar']),
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
                                          userData['posts'].toString()),
                                      _buildStatColumn(
                                          'Followers', userData['followers']),
                                      _buildStatColumn('Following',
                                          userData['following'].toString()),
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
                                  userData['name'],
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (userData['isVerified']) ...[
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
                                userData['username'],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Bio
                            if (userData['bio'] != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  userData['bio'],
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            const SizedBox(height: 8),
                            // Location and join date
                            Row(
                              children: [
                                if (userData['location'] != null) ...[
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    userData['location'],
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
                                  'Joined ${userData['joinedDate']}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    isFollowing = !isFollowing;
                  });
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: isFollowing ? colorScheme.primary : null,
                  foregroundColor:
                      isFollowing ? colorScheme.onPrimary : colorScheme.primary,
                ),
                child: Text(isFollowing ? 'Following' : 'Follow'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => _sendMessage(),
              child: const Text('Message'),
            ),
          ],
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

  Widget _buildPostsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 24,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              Icons.image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  children: userData['interests'].map<Widget>((interest) {
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
        if (userData['website'] != null)
          Card(
            child: ListTile(
              leading: Icon(Icons.language, color: colorScheme.primary),
              title: Text(userData['website']),
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
