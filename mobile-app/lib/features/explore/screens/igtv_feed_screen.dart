import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../services/explore_post_service.dart';

class IGTVFeedScreen extends StatefulWidget {
  final String postId;

  const IGTVFeedScreen({
    super.key,
    required this.postId,
  });

  @override
  State<IGTVFeedScreen> createState() => _IGTVFeedScreenState();
}

class _IGTVFeedScreenState extends State<IGTVFeedScreen>
    with TickerProviderStateMixin {
  final ExplorePostService _postService = ExplorePostService();
  final PageController _pageController = PageController();
  List<ExplorePost> _posts = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  late AnimationController _animationController;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  // Bottom sheet for comments
  final TextEditingController _commentController = TextEditingController();
  
  // Comments management
  List<Map<String, dynamic>> _comments = [];
  bool _commentsLoading = false;
  
  // Track user interaction states
  final Map<String, bool> _userHasCommented = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Check backend connectivity first
    _checkBackendConnectivity();
    _loadPosts();
    
    // Set status bar to transparent for full screen experience
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _checkBackendConnectivity() async {
    try {
      print('🔍 [DEBUG] IGTV: Checking backend connectivity...');
      
      // Try to reach the health endpoint
      final response = await http.get(
        Uri.parse('http://localhost:3002/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('✅ [DEBUG] IGTV: Backend is reachable');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connected to backend services'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('⚠️ [DEBUG] IGTV: Backend returned status ${response.statusCode}');
        // _showBackendError('Backend service returned error status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [DEBUG] IGTV: Backend connection failed: $e');
      // _showBackendError('Failed to connect to backend services: ${e.toString().contains('Connection') ? 'Service not running' : e.toString()}');
    }
  }

  void _showBackendError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('❌ Backend Connection Issue', 
                style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(message),
              const SizedBox(height: 8),
              const Text('• Comments and likes may not persist to database', 
                style: TextStyle(fontSize: 12)),
              const Text('• To fix: Start backend services from terminal', 
                style: TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _checkBackendConnectivity,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    _animationController.dispose();
    _likeAnimationController.dispose();
    // Restore status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      await _postService.loadPosts(refresh: true);
      final posts = _postService.posts.toList();

      // Find the index of the selected post
      int initialIndex = posts.indexWhere((post) => post.id == widget.postId);
      if (initialIndex == -1) initialIndex = 0;

      setState(() {
        _posts = posts;
        _currentIndex = initialIndex;
        _isLoading = false;
      });

      // Jump to the selected post
      if (_posts.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.animateToPage(
            initialIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Load more posts when near the end
    if (index >= _posts.length - 3) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    await _postService.loadPosts(refresh: false);
    setState(() {
      _posts = _postService.posts.toList();
    });
  }

  Future<void> _loadComments(String postId) async {
    setState(() {
      _commentsLoading = true;
    });

    try {
      print('� [DEBUG] IGTV: Loading comments for post $postId from database...');
      final comments = await _postService.getComments(postId);
      
      print('📊 [DEBUG] IGTV: Received ${comments.length} comments from API');
      if (comments.isNotEmpty) {
        print('📊 [DEBUG] IGTV: Sample comment structure: ${comments.first}');
      }
      
      setState(() {
        // Filter out optimistic updates (temporary comments)
        _comments = comments.where((comment) => comment['is_optimistic'] != true).toList();
        _commentsLoading = false;
        
        // Check if current user has commented on this post
        const currentUserId = 'current_user'; // This should come from auth service
        _userHasCommented[postId] = comments.any((comment) => 
            comment['user_id']?.toString() == currentUserId);
      });
      
      print('✅ [DEBUG] IGTV: Successfully loaded ${_comments.length} real comments from database');
      print('👤 [DEBUG] IGTV: User has commented: ${_userHasCommented[postId]}');
      
      // Show success feedback if comments were loaded
      if (mounted && comments.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_download, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('📥 Loaded ${comments.length} comments from database'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      
    } catch (e) {
      print('❌ [ERROR] IGTV: Failed to load comments from database: $e');
      setState(() {
        _comments = [];
        _commentsLoading = false;
      });
      
      // Show detailed error message to user
      final isConnectionError = e.toString().toLowerCase().contains('connection') || 
                                e.toString().toLowerCase().contains('socket') ||
                                e.toString().toLowerCase().contains('network');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('❌ Failed to load comments', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(isConnectionError 
                    ? 'Cannot connect to backend (service not running)'
                    : 'Database error: ${e.toString()}'),
                if (isConnectionError) ...[
                  const SizedBox(height: 4),
                  const Text('• Comments will only show temporarily until backend starts', 
                    style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadComments(postId),
            ),
          ),
        );
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _currentIndex >= _posts.length) return;

    final commentContent = _commentController.text.trim();
    final currentPost = _posts[_currentIndex];
    
    print('📝 [DEBUG] IGTV: Starting comment post process...');
    print('📝 [DEBUG] IGTV: Post ID: ${currentPost.id}');
    print('📝 [DEBUG] IGTV: Comment content: "$commentContent"');
    print('📝 [DEBUG] IGTV: Current comments count: ${currentPost.commentsCount}');
    
    // Clear the input immediately for better UX
    _commentController.clear();
    FocusScope.of(context).unfocus();
    
    // Optimistic UI update - immediately add comment and update count
    final tempCommentId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      // Mark that user has commented on this post
      _userHasCommented[currentPost.id] = true;
      
      // Update post comment count
      _posts[_currentIndex] = currentPost.copyWith(
        commentsCount: currentPost.commentsCount + 1,
      );
      
      // Add optimistic comment to the list (will appear at top since we reverse)
      _comments.insert(0, {
        'comment_id': tempCommentId,
        'comment_text': commentContent,
        'user_display_name': 'You', // Current user
        'user_id': 'current_user',
        'created_at': DateTime.now().toIso8601String(),
        'is_liked': false,
        'likes_count': 0,
        'is_optimistic': true, // Flag to identify optimistic updates
      });
    });
    
    print('✅ [DEBUG] IGTV: Optimistic UI updated - comments count: ${_posts[_currentIndex].commentsCount}');
    
    try {
      print('🌐 [DEBUG] IGTV: Making API call to post comment...');
      final result = await _postService.addComment(currentPost.id, commentContent);
      
      if (result != null) {
        print('✅ [DEBUG] IGTV: Comment API call successful!');
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('✅ Comment posted to database!'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload comments to get the real data from server and replace optimistic comment
        print('🔄 [DEBUG] IGTV: Reloading comments from server...');
        await _loadComments(currentPost.id);
        
      } else {
        throw Exception('API returned null result');
      }
      
    } catch (e) {
      print('❌ [ERROR] IGTV: Failed to post comment to database: $e');
      
      // Revert optimistic updates on error
      setState(() {
        _userHasCommented[currentPost.id] = false;
        _posts[_currentIndex] = currentPost.copyWith(
          commentsCount: currentPost.commentsCount, // Revert back to original count
        );
        
        // Remove the optimistic comment
        _comments.removeWhere((comment) => comment['comment_id'] == tempCommentId);
      });
      
      print('🔄 [DEBUG] IGTV: Optimistic UI reverted due to API failure');
      
      // Show detailed error message
      final isConnectionError = e.toString().toLowerCase().contains('connection') || 
                                e.toString().toLowerCase().contains('socket') ||
                                e.toString().toLowerCase().contains('network');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('❌ Failed to save comment', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(isConnectionError 
                    ? 'Cannot connect to backend service (not running)'
                    : 'Database error: ${e.toString().length > 100 ? '${e.toString().substring(0, 100)}...' : e.toString()}'),
                if (isConnectionError) ...[
                  const SizedBox(height: 4),
                  const Text('• Start backend services to enable database persistence', 
                    style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _commentController.text = commentContent;
              },
            ),
          ),
        );
      }
      
      // Restore the comment text on error
      _commentController.text = commentContent;
    }
  }

  Future<void> _toggleLike() async {
    if (_currentIndex >= _posts.length) return;
    
    final currentPost = _posts[_currentIndex];
    print('❤️ [DEBUG] IGTV: Toggling like for post ${currentPost.id}');
    
    // Trigger like animation
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });
    
    // Optimistic UI update - immediately toggle the like state and update count
    setState(() {
      final wasLiked = currentPost.isLiked;
      _posts[_currentIndex] = currentPost.copyWith(
        isLiked: !wasLiked, // Toggle like state
        likesCount: wasLiked ? currentPost.likesCount - 1 : currentPost.likesCount + 1, // Update count
      );
    });
    
    try {
      // Call the real API to toggle like
      await _postService.toggleLike(currentPost.id);
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentPost.isLiked ? 'Liked!' : 'Unliked!'),
          duration: const Duration(milliseconds: 500),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('❌ [ERROR] IGTV: Failed to toggle like: $e');
      
      // Revert optimistic update on error
      setState(() {
        final currentLikedState = _posts[_currentIndex].isLiked;
        _posts[_currentIndex] = _posts[_currentIndex].copyWith(
          isLiked: !currentLikedState, // Revert like state
          likesCount: currentLikedState ? _posts[_currentIndex].likesCount - 1 : _posts[_currentIndex].likesCount + 1, // Revert count
        );
      });
      
      // Show detailed error message
      final errorMessage = e.toString().contains('Connection') 
          ? 'Cannot connect to server. Please check if services are running.'
          : 'Failed to update like: ${e.toString()}';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _toggleLike(),
          ),
        ),
      );
    }
  }

  void _showCommentsSheet() {
    if (_currentIndex >= _posts.length) return;
    
    final currentPost = _posts[_currentIndex];
    _loadComments(currentPost.id);
    _animationController.forward();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCommentsSheet(),
    ).then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'No posts available',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main PageView for posts
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              return _buildPostPage(_posts[index]);
            },
          ),

          // Top app bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // Right side actions
          Positioned(
            right: 16,
            bottom: 200,
            child: _buildActionButtons(),
          ),

          // Bottom user info and content
          Positioned(
            left: 16,
            right: 80,
            bottom: 100,
            child: _buildBottomContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          const Text(
            'Posts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostPage(ExplorePost post) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image/video
          if (post.imageUrls.isNotEmpty)
            Image.network(
              post.imageUrls.first,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[900],
                child: const Center(
                  child:
                      Icon(Icons.broken_image, color: Colors.white, size: 64),
                ),
              ),
            )
          else
            Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.image, color: Colors.white, size: 64),
              ),
            ),

          // Gradient overlays for better text visibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final currentPost = _posts[_currentIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button with animation
        GestureDetector(
          onTap: _toggleLike,
          child: AnimatedBuilder(
            animation: _likeAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _likeAnimation.value,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: currentPost.isLiked ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ] : null,
                      ),
                      child: Icon(
                        currentPost.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: currentPost.isLiked ? Colors.red : Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCount(currentPost.likesCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Comment button with colored state
        GestureDetector(
          onTap: _showCommentsSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: (_userHasCommented[currentPost.id] == true) ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    _userHasCommented[currentPost.id] == true 
                        ? Icons.chat_bubble 
                        : Icons.chat_bubble_outline,
                    color: _userHasCommented[currentPost.id] == true 
                        ? Colors.blue 
                        : Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCount(currentPost.commentsCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Share button
        GestureDetector(
          onTap: () {
            // Handle share
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share functionality coming soon!'),
                backgroundColor: Colors.black87,
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Column(
            children: [
              Icon(
                Icons.share_outlined,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(height: 4),
              Text(
                'Share',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Bookmark button
        GestureDetector(
          onTap: () {
            // Handle bookmark
          },
          child: const Column(
            children: [
              Icon(
                Icons.bookmark_border,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomContent() {
    final currentPost = _posts[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // User info
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  currentPost.userDisplayName.isNotEmpty
                      ? currentPost.userDisplayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentPost.userDisplayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '2 hours ago', // In real app, format the actual timestamp
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Follow button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Follow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Post content
        Text(
          currentPost.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // Hashtags or tags
        if (currentPost.content.contains('#'))
          Wrap(
            children: _extractHashtags(currentPost.content)
                .map((tag) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildCommentsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Comments header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_comments.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Comment input at the top
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue[100],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.blue,
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
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _postComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _postComment,
                      icon: const Icon(Icons.send, color: Colors.blue),
                    ),
                  ],
                ),
              ),

              // Comments list
              Expanded(
                child: _commentsLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _comments.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No comments yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Be the first to comment!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              // Show latest comments first by reversing the index
                              final reversedIndex = _comments.length - 1 - index;
                              return _buildCommentItem(_comments[reversedIndex]);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    // Extract comment data safely
    final userId = comment['user_id']?.toString() ?? '';
    final userName = comment['user_display_name']?.toString() ?? 
                    comment['user_name']?.toString() ?? 
                    'User $userId';
    final commentText = comment['comment_text']?.toString() ?? 
                       comment['content']?.toString() ?? 
                       'No comment text';
    final createdAt = comment['created_at']?.toString() ?? '';
    final commentId = comment['comment_id']?.toString() ?? comment['id']?.toString() ?? '';
    final isLiked = comment['is_liked'] == true;
    final likesCount = comment['likes_count'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  commentText,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatCommentTime(createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (likesCount > 0) ...[
                      Text(
                        '$likesCount ${likesCount == 1 ? 'like' : 'likes'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Text(
                      'Reply',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: commentId.isNotEmpty ? () => _toggleCommentLike(commentId) : null,
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: isLiked ? Colors.red : Colors.grey[600],
            ),
          ),
        ],
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

  String _formatCommentTime(String createdAt) {
    if (createdAt.isEmpty) return 'now';
    
    try {
      final DateTime commentTime = DateTime.parse(createdAt);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(commentTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return 'now';
    }
  }

  Future<void> _toggleCommentLike(String commentId) async {
    try {
      print('❤️ [DEBUG] IGTV: Toggling comment like for comment $commentId');
      await _postService.toggleCommentLike(commentId);
      
      // Reload comments to get updated like status
      if (_currentIndex < _posts.length) {
        await _loadComments(_posts[_currentIndex].id);
      }
    } catch (e) {
      print('❌ [ERROR] IGTV: Failed to toggle comment like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update comment like: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<String> _extractHashtags(String content) {
    final regex = RegExp(r'#\w+');
    final matches = regex.allMatches(content);
    return matches.map((match) => match.group(0)!).toList();
  }
}
