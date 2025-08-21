import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../models/post_model.dart';
import '../services/explore_post_service.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with AutomaticKeepAliveClientMixin {
  final ExplorePostService _postService = ExplorePostService();
  final PageController _pageController = PageController();

  String _searchQuery = '';
  PostCategory _selectedCategory = PostCategory.all;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: _buildLoadingSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: GestureDetector(
        onPanUpdate: (details) {
          // Force all scroll gestures to be horizontal page changes
          final delta = details.delta;
          
          // Convert both vertical and horizontal movements to page navigation
          if (delta.dy.abs() > 5 || delta.dx.abs() > 5) {
            if (delta.dy < -10 || delta.dx > 10) {
              // Swipe up or right - next page
              if (_pageController.hasClients) {
                final currentPage = _pageController.page?.round() ?? 0;
                final maxPages = (_postService.posts.length / 4).ceil();
                if (currentPage < maxPages - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            } else if (delta.dy > 10 || delta.dx < -10) {
              // Swipe down or left - previous page
              if (_pageController.hasClients) {
                final currentPage = _pageController.page?.round() ?? 0;
                if (currentPage > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            }
          }
        },
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchAndFilters(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshPosts,
                color: colorScheme.primary,
                child: _buildHorizontalFeed(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4, // minimal top
        left: 16,
        right: 16,
        bottom: 0,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Explore',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // minimal vertical
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _debounceSearch();
              },
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search posts, events, users...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Category Filter
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PostCategory.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = PostCategory.values[index];
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () => _onCategoryChanged(category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      category.toString().split('.').last.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalFeed() {
    if (_postService.posts.isEmpty && !_postService.isLoading) {
      return _buildEmptyState();
    }

    final posts = _postService.posts.toList();
    const int postsPerPage = 6; // 3 rows x 2 columns
    return ScrollConfiguration(
      behavior: _NoScrollGlowBehavior(),
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          // Load more when near end
          if (index >= posts.length ~/ postsPerPage - 2) {
            _loadMorePosts();
          }
        },
        itemCount: (posts.length / postsPerPage).ceil() + (_postService.isLoading ? 1 : 0),
        itemBuilder: (context, pageIndex) {
          if (pageIndex >= (posts.length / postsPerPage).ceil()) {
            return _buildLoadingPage(postsPerPage);
          }
          return _buildPostsGrid(posts, pageIndex, postsPerPage);
        },
      ),
    );
  }

  Widget _buildPostsGrid(List posts, int pageIndex, int postsPerPage) {
    final startIndex = pageIndex * postsPerPage;
    final endIndex = (startIndex + postsPerPage).clamp(0, posts.length).toInt();
    final pagePosts = posts.sublist(startIndex, endIndex);
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 2,
        bottom: MediaQuery.of(context).padding.bottom + 8, // minimal bottom
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(postsPerPage, (index) {
          if (index < pagePosts.length) {
            return _buildTileCard(pagePosts[index], startIndex + index);
          } else {
            return _buildEmptyTile();
          }
        }),
      ),
    );
  }

  Widget _buildTileCard(post, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: () {
            print('🔍 Explore: Tapping post ${post.id}');
            context.push('/explore/post/${post.id}');
          },
          child: Stack(
            children: [
              // Background Image
              SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: post.imageUrls.isNotEmpty
                    ? Image.network(
                        post.imageUrls.first,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.errorContainer,
                                colorScheme.errorContainer.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: colorScheme.onErrorContainer,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primaryContainer,
                              colorScheme.secondaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_rounded,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                            size: 32,
                          ),
                        ),
                      ),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Content Overlay
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top - Author info
                    Row(
                      children: [
                        Container(
                          height: 24,
                          width: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              post.userDisplayName.isNotEmpty 
                                  ? post.userDisplayName[0].toUpperCase() 
                                  : "?",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            post.userDisplayName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Bottom - Content and engagement
                    Text(
                      post.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTileEngagementButton(
                          Icons.favorite_rounded,
                          post.likesCount,
                          Colors.red.shade400,
                        ),
                        const SizedBox(width: 12),
                        _buildTileEngagementButton(
                          Icons.chat_bubble_rounded,
                          post.commentsCount,
                          Colors.blue.shade400,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bookmark_border_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tap effect
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    splashColor: Colors.white.withOpacity(0.1),
                    highlightColor: Colors.white.withOpacity(0.05),
                    onTap: () {
                      print('🔍 Explore: Tapping post ${post.id}');
                      context.push('/explore/post/${post.id}');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTileEngagementButton(IconData icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          count > 999 ? '${(count / 1000).toStringAsFixed(1)}K' : count.toString(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTile() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.add_rounded,
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildLoadingPage(int postsPerPage) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 2,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(postsPerPage, (index) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )),
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                count > 999 ? '${(count / 1000).toStringAsFixed(1)}K' : count.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = screenWidth * 0.72;
    final cardHeight = screenHeight * 0.65;

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: const EdgeInsets.only(right: 12, bottom: 8, top: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        _buildAppBar(),
        _buildSearchAndFilters(),
        Expanded(
          child: _buildLoadingPage(6),
        ),
      ],
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
            Icons.explore_off_rounded,
            size: 72,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'No posts found',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom scroll behavior to remove scroll glow effect
class _NoScrollGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}