import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/post_model.dart';
import '../services/explore_post_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() {
    print('🏭 Creating PostDetailScreen state for postId: ${postId}');
    return _PostDetailScreenState();
  }
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ExplorePostService _postService = ExplorePostService();
  ExplorePost? _post;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🎬 PostDetailScreen initState called for postId: ${widget.postId}');
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      print('🔍 Loading post with ID: ${widget.postId}');
      // Load posts and find the specific post
      await _postService.loadPosts(refresh: true);
      print('📚 Posts loaded. Total count: ${_postService.posts.length}');
      print(
          '📋 Available post IDs: ${_postService.posts.map((p) => p.id).toList()}');

      final post = _postService.posts.firstWhere(
        (p) => p.id == widget.postId,
        orElse: () => throw Exception('Post not found'),
      );

      print(
          '✅ Post found: ${post.userDisplayName} - ${post.content.substring(0, 50)}...');
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
        ),
        body: _buildLoadingSkeleton(),
      );
    }

    if (_post == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Post not found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPostHeader(),
                _buildPostContent(),
                _buildPostImage(),
                _buildEngagementSection(),
                _buildGoToEventButton(),
                _buildCommentsSection(),
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      backgroundColor: colorScheme.surface.withOpacity(0.9),
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: colorScheme.onSurface),
          onPressed: () => _handleShare(),
        ),
        IconButton(
          icon: Icon(
            _post!.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
            color: _post!.isBookmarked
                ? colorScheme.primary
                : colorScheme.onSurface,
          ),
          onPressed: () => _handleBookmark(),
        ),
      ],
    );
  }

  Widget _buildPostHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          print('🔍 PostDetail: Tapping user profile ${_post!.userId}');
          // Navigate to user profile
          context.push('/user/${_post!.userId}');
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              child: _post!.userAvatarUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        _post!.userAvatarUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 48,
                            height: 48,
                            child: _buildShimmerBox(48, 48, 24),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _post!.userDisplayName[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _post!.userDisplayName[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _post!.userDisplayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_post!.isUserVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '@${_post!.userId} • ${_getTimeAgo(_post!.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPostTypeColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getPostTypeText(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _getPostTypeColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _post!.content,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
          ),
          if (_post!.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _post!.tags.map((hashtag) {
                return Text(
                  '#$hashtag',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    if (_post!.imageUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _post!.imageUrls.first,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildShimmerBox(double.infinity, double.infinity, 16),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image, size: 48),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEngagementSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildEngagementButton(
            icon: _post!.isLiked ? Icons.favorite : Icons.favorite_outline,
            count: _post!.likesCount,
            color: _post!.isLiked ? Colors.red : colorScheme.onSurfaceVariant,
            onTap: _handleLike,
          ),
          const SizedBox(width: 24),
          _buildEngagementButton(
            icon: Icons.chat_bubble_outline,
            count: _post!.commentsCount,
            color: colorScheme.onSurfaceVariant,
            onTap: () => _scrollToComments(),
          ),
          const SizedBox(width: 24),
          _buildEngagementButton(
            icon: Icons.share_outlined,
            count: _post!.sharesCount,
            color: colorScheme.onSurfaceVariant,
            onTap: _handleShare,
          ),
          const Spacer(),
          Text(
            '${_post!.likesCount + _post!.commentsCount + _post!.sharesCount} engagement',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              _formatCount(count),
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoToEventButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _navigateToEvent(),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shadowColor: colorScheme.primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 20),
            const SizedBox(width: 8),
            Text(
              'Go to Event',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Comments (${_post!.commentsCount})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Mock comments for demonstration
          ...List.generate(3, (index) => _buildCommentItem(index)),
        ],
      ),
    );
  }

  Widget _buildCommentItem(int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final comments = [
      {
        'user': 'Alice Johnson',
        'userId': 'alice_001',
        'comment': 'This looks amazing! Can\'t wait to attend.',
        'time': '2h'
      },
      {
        'user': 'Bob Smith',
        'userId': 'bob_002',
        'comment': 'Thanks for sharing! This event is going to be epic.',
        'time': '4h'
      },
      {
        'user': 'Carol Davis',
        'userId': 'carol_003',
        'comment': 'Love the energy in this post! 🔥',
        'time': '6h'
      },
    ];

    if (index >= comments.length) return const SizedBox.shrink();

    final comment = comments[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          print('🔍 PostDetail: Tapping comment user profile ${comment['userId']}');
          // Navigate to user profile
          context.push('/user/${comment['userId']}');
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Text(
                comment['user']![0],
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment['user']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        comment['time']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment['comment']!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _postComment(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _postComment,
            icon: Icon(
              Icons.send,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToComments() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToEvent() {
    // Navigate to the specific event page
    if (_post!.relatedEventId != null) {
      print('🎯 Navigating to event: ${_post!.relatedEventId}');
      print('🚀 Route: /event/${_post!.relatedEventId}');
      try {
        context.push('/event/${_post!.relatedEventId}');
        print('✅ Event navigation successful');
      } catch (e) {
        print('❌ Event navigation failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to navigate to event: $e'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No related event found for this post'),
        ),
      );
    }
  }

  Future<void> _handleLike() async {
    await _postService.toggleLike(_post!.id);
    setState(() {
      _post = _post!.copyWith(
        isLiked: !_post!.isLiked,
        likesCount:
            _post!.isLiked ? _post!.likesCount - 1 : _post!.likesCount + 1,
      );
    });
  }

  Future<void> _handleShare() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  Future<void> _handleBookmark() async {
    await _postService.toggleBookmark(_post!.id);
    setState(() {
      _post = _post!.copyWith(isBookmarked: !_post!.isBookmarked);
    });
  }

  void _postComment() {
    if (_commentController.text.trim().isEmpty) return;

    // Here you would typically send the comment to your backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment posted!')),
    );

    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  Color _getPostTypeColor() {
    switch (_post!.postType) {
      case PostType.eventInterest:
        return Colors.blue;
      case PostType.eventReview:
        return Colors.green;
      case PostType.eventMoment:
        return Colors.purple;
      case PostType.eventPromotion:
        return Colors.orange;
      case PostType.eventQuestion:
        return Colors.indigo;
      case PostType.eventMemory:
        return Colors.pink;
    }
  }

  String _getPostTypeText() {
    switch (_post!.postType) {
      case PostType.eventInterest:
        return 'Interest';
      case PostType.eventReview:
        return 'Review';
      case PostType.eventMoment:
        return 'Moment';
      case PostType.eventPromotion:
        return 'Promotion';
      case PostType.eventQuestion:
        return 'Question';
      case PostType.eventMemory:
        return 'Memory';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  Widget _buildLoadingSkeleton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header skeleton
          Row(
            children: [
              _buildShimmerBox(48, 48, 24), // Avatar
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(120, 20, 8), // Username
                    const SizedBox(height: 4),
                    _buildShimmerBox(80, 14, 6), // Time and ID
                  ],
                ),
              ),
              _buildShimmerBox(60, 24, 12), // Post type badge
            ],
          ),
          const SizedBox(height: 16),
          
          // Post content skeleton
          _buildShimmerBox(double.infinity, 16, 8), // Content line 1
          const SizedBox(height: 8),
          _buildShimmerBox(double.infinity, 16, 8), // Content line 2
          const SizedBox(height: 8),
          _buildShimmerBox(200, 16, 8), // Content line 3 (shorter)
          const SizedBox(height: 16),
          
          // Image skeleton
          _buildShimmerBox(double.infinity, 300, 12),
          const SizedBox(height: 16),
          
          // Engagement bar skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEngagementButtonSkeleton(),
              _buildEngagementButtonSkeleton(),
              _buildEngagementButtonSkeleton(),
            ],
          ),
          const SizedBox(height: 16),
          
          // Related event skeleton (if applicable)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildShimmerBox(60, 60, 8), // Event image
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(150, 16, 8), // Event name
                      const SizedBox(height: 4),
                      _buildShimmerBox(100, 14, 6), // Event date
                      const SizedBox(height: 4),
                      _buildShimmerBox(120, 14, 6), // Event location
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Comments header skeleton
          _buildShimmerBox(100, 18, 8),
          const SizedBox(height: 16),
          
          // Comment skeleton items
          ...List.generate(3, (index) => _buildCommentSkeleton()),
          
          // Comment input skeleton
          const SizedBox(height: 16),
          Row(
            children: [
              _buildShimmerBox(32, 32, 16), // User avatar
              const SizedBox(width: 12),
              Expanded(
                child: _buildShimmerBox(double.infinity, 40, 20), // Input field
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(double width, double height, double borderRadius) {
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

  Widget _buildEngagementButtonSkeleton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildShimmerBox(20, 20, 4), // Icon
        const SizedBox(width: 4),
        _buildShimmerBox(30, 16, 4), // Count
      ],
    );
  }

  Widget _buildCommentSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(32, 32, 16), // Avatar
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildShimmerBox(80, 16, 8), // Username
                    const SizedBox(width: 8),
                    _buildShimmerBox(30, 12, 6), // Time
                  ],
                ),
                const SizedBox(height: 4),
                _buildShimmerBox(double.infinity, 14, 6), // Comment line 1
                const SizedBox(height: 4),
                _buildShimmerBox(150, 14, 6), // Comment line 2
              ],
            ),
          ),
        ],
      ),
    );
  }
}
