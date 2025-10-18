import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../models/post_model.dart';
import '../services/explore_post_service.dart';
import '../widgets/post_shimmer_loading.dart';

class ExplorePostsPage extends StatefulWidget {
  const ExplorePostsPage({super.key});

  @override
  State<ExplorePostsPage> createState() => _ExplorePostsPageState();
}

class _ExplorePostsPageState extends State<ExplorePostsPage>
    with AutomaticKeepAliveClientMixin {
  final ExplorePostService _postService = ExplorePostService();
  final PageController _pageController = PageController();

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
      refresh: true,
    );
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _loadMorePosts() async {
    await _postService.loadMorePosts();
    if (mounted) setState(() {});
  }

  Future<void> _refreshPosts() async {
    await _postService.loadPosts(
      refresh: true,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            _buildAppBar(),
            const Expanded(
              child: GridPostShimmerLoading(itemCount: 12),
            ),
          ],
        ),
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshPosts,
                color: colorScheme.primary,
                child: _buildVerticalFeed(),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4, // Reduced from 8
        left: 20,
        right: 20,
        bottom: 8, // Reduced from 16
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Explore',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
              fontSize: 22, // Reduced from 24
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalFeed() {
    if (_postService.posts.isEmpty && !_postService.isLoading) {
      return _buildEmptyState();
    }

    final posts = _postService.posts.toList();
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // More aggressive preloading - load when 800px from bottom
        if (scrollInfo is ScrollEndNotification &&
            scrollInfo.metrics.extentAfter < 800 &&
            _postService.hasMoreData &&
            !_postService.isLoading) {
          _loadMorePosts();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        // Add scroll caching for better performance
        cacheExtent: 1000,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(3, 0, 3, 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < posts.length) {
                    return _buildOptimizedInstagramTile(posts[index]);
                  } else if (_postService.isLoading &&
                      index < posts.length + 6) {
                    return _buildLoadingTile();
                  }
                  return null;
                },
                childCount: posts.length + (_postService.isLoading ? 6 : 0),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                childAspectRatio: 1.0,
              ),
            ),
          ),
          // Show loading indicator at bottom when loading more
          if (_postService.isLoading && posts.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading more posts...',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Show "no more posts" indicator when reached end
          if (!_postService.hasMoreData && posts.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    '🎉 You\'ve seen all posts!',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptimizedInstagramTile(ExplorePost post) {
    // Debug video content
    if (post.videoUrls.isNotEmpty) {
      print('🎬 [Tile] Post ${post.id} has videos:');
      print('  - videoUrls: ${post.videoUrls}');
      print('  - videoThumbnails: ${post.videoThumbnails}');
      print('  - imageUrls: ${post.imageUrls}');

      // Check and fix HTTP URLs
      if (post.videoThumbnails.isNotEmpty) {
        final originalUrl = post.videoThumbnails.first;
        final fixedUrl = originalUrl.replaceFirst('http://', 'https://');
        if (originalUrl != fixedUrl) {
          print('🔧 [Tile] Fixed HTTP to HTTPS: $originalUrl -> $fixedUrl');
        }
      }
    } else if (post.imageUrls.isEmpty) {
      print('⚠️ [Tile] Post ${post.id} has no media:');
      print('  - videoUrls: ${post.videoUrls}');
      print('  - imageUrls: ${post.imageUrls}');
    }

    return GestureDetector(
      onTap: () {
        print('🔍 Explore: Tapping post ${post.id}');
        context.push('/explore/igtv/${post.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Optimized image loading with better caching - prioritize video thumbnails for video posts
            (post.videoUrls.isNotEmpty && post.videoThumbnails.isNotEmpty)
                ? Image.network(
                    // Fix HTTP to HTTPS for Cloudinary URLs
                    post.videoThumbnails.first
                        .replaceFirst('http://', 'https://'),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print(
                          '❌ Video thumbnail failed to load: ${post.videoThumbnails.first}');
                      print('❌ Error details: $error');
                      print('❌ Stack trace: $stackTrace');

                      // Check if URL is HTTP vs HTTPS
                      if (post.videoThumbnails.first.startsWith('http://')) {
                        print(
                            '⚠️ POTENTIAL ISSUE: Thumbnail URL uses HTTP instead of HTTPS');
                      }

                      // For video posts, show video thumbnail placeholder instead of trying images
                      return Container(
                        color: Colors.black87,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const Center(
                              child: Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'VIDEO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : post.imageUrls.isNotEmpty
                    ? Image.network(
                        post.imageUrls.first,
                        fit: BoxFit.cover,
                        // Add better caching and loading
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[400],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[900],
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const Center(
                              child: Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'VIDEO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            // Overlay for video posts or multiple images
            if (post.imageUrls.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.collections,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),

            // Video indicator for video posts
            if (post.videoUrls.isNotEmpty)
              const Positioned(
                top: 8,
                left: 8,
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 20,
                ),
              ),

            // Bottom engagement overlay
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatCount(post.likesCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingTile() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[500]! : Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
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
