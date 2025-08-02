import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../models/post_model.dart';
import '../services/explore_post_service.dart';

class ExplorePostsPage extends StatefulWidget {
  const ExplorePostsPage({super.key});

  @override
  State<ExplorePostsPage> createState() => _ExplorePostsPageState();
}

class _ExplorePostsPageState extends State<ExplorePostsPage>
    with AutomaticKeepAliveClientMixin {
  final ExplorePostService _postService = ExplorePostService();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  PostCategory _selectedCategory = PostCategory.all;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialPosts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadInitialPosts() async {
    await _postService.loadPosts(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      category: _selectedCategory,
      refresh: true,
    );
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _loadMorePosts() async {
    await _postService.loadMorePosts(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      category: _selectedCategory,
    );
    if (mounted) setState(() {});
  }

  Future<void> _refreshPosts() async {
    await _postService.loadPosts(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      category: _selectedCategory,
      refresh: true,
    );
    if (mounted) setState(() {});
  }

  void _onCategoryChanged(PostCategory category) {
    setState(() => _selectedCategory = category);
    _loadInitialPosts();
  }

  Timer? _debounceTimer;
  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadInitialPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: !_isInitialized 
          ? _buildLoadingSkeleton()
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with Search and Filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _debounceSearch();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search posts, events, users...',
                        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: PostCategory.values.map((category) {
                        final isSelected = category == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_getCategoryDisplayName(category)),
                            selected: isSelected,
                            onSelected: (selected) => _onCategoryChanged(category),
                            backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
                            selectedColor: colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // Instagram-style Posts Grid
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshPosts,
                color: colorScheme.primary,
                child: _buildModernPostsGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(PostCategory category) {
    switch (category) {
      case PostCategory.all:
        return 'All';
      case PostCategory.tech:
        return 'Tech';
      case PostCategory.music:
        return 'Music';
      case PostCategory.sports:
        return 'Sports';
      case PostCategory.food:
        return 'Food';
      case PostCategory.art:
        return 'Art';
      case PostCategory.business:
        return 'Business';
      case PostCategory.education:
        return 'Education';
      case PostCategory.entertainment:
        return 'Entertainment';
      case PostCategory.lifestyle:
        return 'Lifestyle';
    }
  }

  Widget _buildModernPostsGrid() {
    if (_postService.posts.isEmpty && !_postService.isLoading) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            itemBuilder: (context, index) {
              final post = _postService.posts[index];
              
              return _buildModernPostCard(post, index);
            },
            childCount: _postService.posts.length,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
        ),
        if (_postService.isLoading) 
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildModernPostCard(ExplorePost post, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      key: ValueKey(post.id),
      onTap: () {
        print('🔍 Explore: Tapping post ${post.id}');
        // Keep the existing navigation functionality
        _handleComment(post.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: _getAspectRatio(index),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        [colorScheme.primaryContainer, colorScheme.primary.withOpacity(0.7)],
                        [colorScheme.secondaryContainer, colorScheme.secondary.withOpacity(0.7)],
                        [colorScheme.tertiaryContainer, colorScheme.tertiary.withOpacity(0.7)],
                      ][index % 3],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: post.imageUrls.isNotEmpty
                      ? Image.network(
                          post.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.image_not_supported,
                              color: colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.image,
                          color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                          size: 32,
                        ),
                ),
              ),
            ),
            // Post Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: post.userAvatarUrl.isNotEmpty 
                            ? NetworkImage(post.userAvatarUrl) 
                            : null,
                        child: post.userAvatarUrl.isEmpty
                            ? Text(
                                post.userDisplayName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post.userDisplayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (post.isUserVerified)
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Post content
                  Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Engagement stats
                  Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: post.isLiked ? colorScheme.error : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentsCount}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (post.isBookmarked)
                        Icon(
                          Icons.bookmark,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getAspectRatio(int index) {
    // Instagram-style varied aspect ratios
    const aspectRatios = [1.2, 0.8, 1.0, 1.5, 0.9, 1.1];
    return aspectRatios[index % aspectRatios.length];
  }

  Widget _buildLoadingSkeleton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header Loading Skeleton
            _buildHeaderLoadingSkeleton(),
            // Content Loading Skeleton
            Expanded(
              child: _buildContentLoadingSkeleton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderLoadingSkeleton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar Skeleton
          _buildShimmerContainer(
            height: 48,
            borderRadius: 12,
          ),
          const SizedBox(height: 16),
          // Filter Chips Skeleton
          Row(
            children: List.generate(4, (index) => Padding(
              padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
              child: _buildShimmerContainer(
                width: 60 + (index * 10),
                height: 32,
                borderRadius: 16,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildContentLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Create masonry-like loading grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  children: [
                    _buildPostSkeletonCard(height: 250),
                    const SizedBox(height: 12),
                    _buildPostSkeletonCard(height: 180),
                    const SizedBox(height: 12),
                    _buildPostSkeletonCard(height: 220),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right column
              Expanded(
                child: Column(
                  children: [
                    _buildPostSkeletonCard(height: 200),
                    const SizedBox(height: 12),
                    _buildPostSkeletonCard(height: 260),
                    const SizedBox(height: 12),
                    _buildPostSkeletonCard(height: 190),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostSkeletonCard({required double height}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image skeleton
          Expanded(
            flex: 3,
            child: _buildShimmerContainer(
              borderRadius: 16,
            ),
          ),
          // Content skeleton
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info skeleton
                  Row(
                    children: [
                      _buildShimmerContainer(
                        width: 24,
                        height: 24,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 8),
                      _buildShimmerContainer(
                        width: 80,
                        height: 14,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Content lines skeleton
                  _buildShimmerContainer(
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 4),
                  _buildShimmerContainer(
                    width: double.infinity * 0.7,
                    height: 14,
                    borderRadius: 4,
                  ),
                  const Spacer(),
                  // Action buttons skeleton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildShimmerContainer(
                            width: 40,
                            height: 20,
                            borderRadius: 10,
                          ),
                          const SizedBox(width: 12),
                          _buildShimmerContainer(
                            width: 40,
                            height: 20,
                            borderRadius: 10,
                          ),
                        ],
                      ),
                      _buildShimmerContainer(
                        width: 20,
                        height: 20,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer({
    double? width,
    double? height,
    double borderRadius = 8,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              colors: [
                colorScheme.surfaceVariant.withOpacity(0.3),
                colorScheme.surfaceVariant.withOpacity(0.1),
                colorScheme.surfaceVariant.withOpacity(0.3),
              ],
              stops: [
                (value - 0.3).clamp(0.0, 1.0),
                value,
                (value + 0.3).clamp(0.0, 1.0),
              ],
              begin: const Alignment(-1.0, 0.0),
              end: const Alignment(1.0, 0.0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No posts found',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleComment(String postId) async {
    // Navigate to post detail with comments
    print('🎯 Post tapped! Post ID: $postId');
    print('🚀 Navigating to: /explore/post/$postId');
    try {
      context.push('/explore/post/$postId');
      print('✅ Navigation call successful');
    } catch (e) {
      print('❌ Navigation failed: $e');
    }
  }
}
