import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../explore/models/post_model.dart';
import '../../explore/services/explore_post_service.dart';
import '../../explore/widgets/explore_post_card.dart';
import '../../explore/widgets/post_shimmer_loading.dart';

class ProfilePostsFeedScreen extends StatefulWidget {
  final String userId;
  final String? username;

  const ProfilePostsFeedScreen({
    super.key,
    required this.userId,
    this.username,
  });

  @override
  State<ProfilePostsFeedScreen> createState() => _ProfilePostsFeedScreenState();
}

class _ProfilePostsFeedScreenState extends State<ProfilePostsFeedScreen> {
  final ExplorePostService _postService = ExplorePostService();
  final ScrollController _scrollController = ScrollController();
  List<ExplorePost> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _posts.clear();
    });

    try {
      final response = await _postService.getExplorePostsForUser(
        userId: widget.userId,
        page: _currentPage,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _posts = response;
          _hasMore = response.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading posts: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final response = await _postService.getExplorePostsForUser(
        userId: widget.userId,
        page: _currentPage + 1,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _posts.addAll(response);
          _currentPage++;
          _hasMore = response.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more posts: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back,
            color: colorScheme.onSurface,
          ),
        ),
        title: Text(
          widget.username != null ? "${widget.username}'s Posts" : "Posts",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (_isLoading && _posts.isEmpty) {
              return ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) => const PostShimmerLoading(),
              );
            }

            if (_posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Posts Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.userId == authProvider.user?.id
                          ? 'Share your first moment!'
                          : 'This user hasn\'t shared anything yet.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: _posts.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _posts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return ExplorePostCard(
                  post: _posts[index],
                  onLike: () async {
                    try {
                      final currentPost = _posts[index];
                      if (currentPost.isLiked) {
                        await _postService.unlikePost(currentPost.id);
                      } else {
                        await _postService.likePost(currentPost.id);
                      }
                      // Refresh the post in the list
                      final updatedPost = await _postService.getPostById(currentPost.id);
                      if (updatedPost != null) {
                        setState(() {
                          _posts[index] = updatedPost;
                        });
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                  onComment: () {
                    context.push('/posts/${_posts[index].id}/comments');
                  },
                  onShare: () {
                    // Implement share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share feature coming soon!')),
                    );
                  },
                  onBookmark: () async {
                    // Implement bookmark functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bookmark feature coming soon!')),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}