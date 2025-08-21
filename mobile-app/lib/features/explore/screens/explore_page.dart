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
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: colorScheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(),
            _buildSearchSection(),
            _buildCategoryFilter(),
            _buildPostsGrid(),
            if (_postService.isLoading) _buildLoadingIndicator(),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 60,
      floating: true,
      pinned: false,
      backgroundColor: colorScheme.surface.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        title: Text(
          'Explore',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _debounceSearch();
            },
            decoration: InputDecoration(
              hintText: 'Search posts, events, users...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      sliver: SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: PostCategory.values.map((category) {
              final isSelected = category == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category.toString().split('.').last),
                  selected: isSelected,
                  onSelected: (selected) => _onCategoryChanged(category),
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.purple.shade100,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.purple.shade700
                        : Colors.grey.shade700,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (_postService.posts.isEmpty && !_postService.isLoading) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        itemBuilder: (context, index) {
          final post = _postService.posts[index];

          return GestureDetector(
            key: ValueKey(post.id),
            onTap: () {
              print('🔍 Explore: Tapping post ${post.id}');
              context.push('/explore/post/${post.id}');
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // Post Image
                    AspectRatio(
                      aspectRatio: index % 2 == 0 ? 1.0 : 0.8,
                      child: post.imageUrls.isNotEmpty
                          ? Image.network(
                              post.imageUrls.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey.shade300,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey.shade600,
                                  size: 32,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.image,
                                color: Colors.white.withOpacity(0.7),
                                size: 32,
                              ),
                            ),
                    ),
                    // Caption overlay (top)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Text(
                          post.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Author info & engagement (bottom)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: Colors.purple.shade100,
                              child: Text(
                                post.userDisplayName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                post.userDisplayName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(0, 1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.likesCount}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        offset: Offset(0, 1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.commentsCount}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        offset: Offset(0, 1),
                                        blurRadius: 4,
                                      ),
                                    ],
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
          );
        },
        childCount: _postService.posts.length,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            itemBuilder: (context, index) {
              return Container(
                height: index % 3 == 0 ? 200 : 150,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            childCount: 6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
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
}
