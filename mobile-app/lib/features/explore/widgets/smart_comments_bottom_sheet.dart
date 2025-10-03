import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/smart_bottom_sheet_service.dart';
import '../services/explore_post_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Enhanced comment bottom sheet that preloads data automatically
class SmartCommentsBottomSheet {
  static final ExplorePostService _postService = ExplorePostService();

  /// Show comments with automatic preloading
  static Future<void> show({
    required BuildContext context,
    required String postId,
    required VoidCallback? onCommentAdded,
  }) async {
    final smartService = SmartBottomSheetService();

    await smartService.showBottomSheetWithData(
      context: context,
      cacheKey: 'comments_$postId',
      dataLoader: () => _loadCommentsData(postId),
      builder: (context, data, isLoading) => _CommentsContent(
        postId: postId,
        data: data,
        isLoading: isLoading,
        onCommentAdded: onCommentAdded,
      ),
    );
  }

  /// Show comments with draggable sheet
  static Widget buildDraggableComments({
    required String postId,
    required VoidCallback? onCommentAdded,
    double initialChildSize = 0.7,
    double minChildSize = 0.5,
    double maxChildSize = 0.9,
  }) {
    final smartService = SmartBottomSheetService();

    return smartService.buildDraggableSheetWithData(
      cacheKey: 'comments_$postId',
      dataLoader: () => _loadCommentsData(postId),
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      builder: (context, scrollController, data, isLoading) =>
          _DraggableCommentsContent(
        scrollController: scrollController,
        postId: postId,
        data: data,
        isLoading: isLoading,
        onCommentAdded: onCommentAdded,
      ),
    );
  }

  /// Load comments data
  static Future<Map<String, dynamic>> _loadCommentsData(String postId) async {
    try {
      print('🔄 [SMART_COMMENTS] Loading comments for post: $postId');

      final comments = await _postService.getComments(postId);

      // Process comments to remove optimistic updates
      final processedComments = comments
          .where((comment) => comment['is_optimistic'] != true)
          .toList();

      print('✅ [SMART_COMMENTS] Loaded ${processedComments.length} comments');

      return {
        'comments': processedComments,
        'count': processedComments.length,
        'postId': postId,
        'loadedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ [SMART_COMMENTS] Failed to load comments: $e');
      rethrow;
    }
  }

  /// Clear comments cache for a post
  static void clearCache(String postId) {
    SmartBottomSheetService().clearCache('comments_$postId');
  }
}

/// Comments content for modal bottom sheet
class _CommentsContent extends StatefulWidget {
  final String postId;
  final dynamic data;
  final bool isLoading;
  final VoidCallback? onCommentAdded;

  const _CommentsContent({
    required this.postId,
    required this.data,
    required this.isLoading,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsContent> createState() => _CommentsContentState();
}

class _CommentsContentState extends State<_CommentsContent> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _comments = [];
  bool _isSubmitting = false;

  // Reply state
  Map<String, dynamic>? _replyingToComment;
  String _placeholderText = "Write a comment...";

  @override
  void initState() {
    super.initState();
    _updateComments();
    _commentController.addListener(() {
      setState(() {}); // Update UI when comment text changes
    });
  }

  @override
  void didUpdateWidget(_CommentsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _updateComments();
    }
  }

  void _updateComments() {
    if (widget.data != null && widget.data['comments'] != null) {
      final newComments =
          List<Map<String, dynamic>>.from(widget.data['comments']);

      // Debug: Print loaded comments structure
      print('🔍 [UPDATE_COMMENTS] Loading ${newComments.length} comments');
      for (int i = 0; i < newComments.length && i < 2; i++) {
        final comment = newComments[i];
        final replies = comment['replies'] as List<dynamic>? ?? [];
        print(
            '🔍 [UPDATE_COMMENTS] Comment $i: user_name="${comment['user_name']}", replies=${replies.length}');
        if (replies.isNotEmpty) {
          final firstReply = replies[0] as Map<String, dynamic>;
          print(
              '🔍 [UPDATE_COMMENTS] First reply: user_name="${firstReply['user_name']}"');
        }
      }

      setState(() {
        _comments = newComments;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final content = _commentController.text.trim();
      final parentCommentId =
          _replyingToComment?['comment_id'] ?? _replyingToComment?['id'];

      // Get current user data from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      // Use current user data with better fallback names that won't be "Anonymous"
      String userName, userDisplayName, username;
      Map<String, dynamic> userObject;

      if (currentUser != null && authProvider.isAuthenticated) {
        userName = currentUser.fullName.isNotEmpty
            ? currentUser.fullName
            : '${currentUser.firstName} ${currentUser.lastName}'.trim();
        userDisplayName = userName;
        username =
            currentUser.firstName.isNotEmpty ? currentUser.firstName : userName;
        userObject = {
          'id': currentUser.id,
          'full_name': userName,
          'name': userName,
          'avatar_url': currentUser.profileImageUrl,
        };
      } else {
        // Fallback for unauthenticated users - use a more descriptive name than "Anonymous"
        userName = 'You';
        userDisplayName = 'You';
        username = 'You';
        userObject = {
          'id': 'guest_user',
          'full_name': 'You',
          'name': 'You',
          'avatar_url': null,
        };
      }

      // Add optimistic comment/reply
      final optimisticItem = {
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'comment_id': DateTime.now().millisecondsSinceEpoch,
        'content': content,
        'comment_text': content,
        'user_name': userName,
        'user_display_name': userDisplayName,
        'username': username,
        'user_id': userObject['id'],
        'created_at': DateTime.now().toIso8601String(),
        'like_count': 0,
        'likes_count': 0,
        'is_liked': false,
        'is_optimistic': true,
        'parent_comment_id': parentCommentId,
        'replies': [],
        'replies_count': 0,
        'user': userObject,
      };

      setState(() {
        if (parentCommentId != null) {
          // Add as reply to existing comment
          final parentIndex = _comments.indexWhere((c) =>
              (c['comment_id'] ?? c['id']).toString() ==
              parentCommentId.toString());

          if (parentIndex != -1) {
            if (_comments[parentIndex]['replies'] == null) {
              _comments[parentIndex]['replies'] = [];
            }
            _comments[parentIndex]['replies'].add(optimisticItem);
            _comments[parentIndex]['replies_count'] =
                (_comments[parentIndex]['replies_count'] ?? 0) + 1;
          }
        } else {
          // Add as new top-level comment
          _comments.insert(0, optimisticItem);
        }
      });

      _commentController.clear();
      _cancelReply(); // Exit reply mode

      // Post to server
      final result = await SmartCommentsBottomSheet._postService
          .addComment(widget.postId, content, parentCommentId: parentCommentId);

      if (result != null) {
        print('✅ [SMART_COMMENTS] Comment/reply posted successfully');

        // Update optimistic comment with real server data
        setState(() {
          if (parentCommentId != null) {
            // Update reply with real data
            final parentIndex = _comments.indexWhere((c) =>
                (c['comment_id'] ?? c['id']).toString() ==
                parentCommentId.toString());

            if (parentIndex != -1 &&
                _comments[parentIndex]['replies'] != null) {
              final replyIndex = _comments[parentIndex]['replies']
                  .indexWhere((reply) => reply['is_optimistic'] == true);
              if (replyIndex != -1) {
                // Replace optimistic reply with real data
                _comments[parentIndex]['replies'][replyIndex] = {
                  ...result,
                  'parent_comment_id': parentCommentId,
                  'replies': [],
                  'replies_count': 0,
                };
              }
            }
          } else {
            // Update top-level comment with real data
            final optimisticIndex =
                _comments.indexWhere((c) => c['is_optimistic'] == true);
            if (optimisticIndex != -1) {
              _comments[optimisticIndex] = {
                ...result,
                'replies': [],
                'replies_count': 0,
              };
            }
          }
        });

        // Don't clear cache immediately - keep the updated comments in memory
        widget.onCommentAdded?.call();
      } else {
        // Remove optimistic item on failure
        setState(() {
          if (parentCommentId != null) {
            final parentIndex = _comments.indexWhere((c) =>
                (c['comment_id'] ?? c['id']).toString() ==
                parentCommentId.toString());
            if (parentIndex != -1) {
              _comments[parentIndex]['replies']?.removeLast();
              _comments[parentIndex]['replies_count'] =
                  (_comments[parentIndex]['replies_count'] ?? 1) - 1;
            }
          } else {
            _comments.removeAt(0);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to post. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ [SMART_COMMENTS] Failed to post comment: $e');

      // Remove optimistic comment on error
      setState(() {
        _comments.removeWhere((c) => c['is_optimistic'] == true);
      });

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post comment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Cancel reply mode
  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
      _placeholderText = "Write a comment...";
    });
  }

  /// Build comment with its replies displayed inline (Facebook style)
  Widget _buildCommentWithReplies(Map<String, dynamic> comment) {
    final replies = comment['replies'] as List<dynamic>? ?? [];

    // Debug: Check if this comment has replies and what the structure is
    if (replies.isNotEmpty) {
      print(
          '🔍 [COMMENTS] Comment ${comment['comment_id']} has ${replies.length} replies');
      for (int i = 0; i < replies.length; i++) {
        final reply = replies[i] as Map<String, dynamic>;
        print(
            '🔍 [REPLIES] Reply $i: user_name="${reply['user_name']}", parent_id="${reply['parent_comment_id']}"');
      }
    }

    return Column(
      children: [
        // Main comment
        _buildCommentItem(comment, isParent: true),

        // Replies displayed inline
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48.0),
            child: Column(
              children: replies.map<Widget>((reply) {
                return _buildCommentItem(reply as Map<String, dynamic>,
                    isReply: true);
              }).toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.headlineSmall?.color,
                  ),
                ),
                const Spacer(),
                if (widget.isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.primaryColor),
                    ),
                  )
                else
                  Text(
                    '${_comments.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),

          // Comment input - Professional style
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // User avatar for input
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: isDarkMode ? Colors.grey[400] : theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[200]!,
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: _placeholderText,
                          hintStyle: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.5),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _postComment(),
                        enabled: !_isSubmitting,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Cancel reply button (only show when replying)
                  if (_replyingToComment != null)
                    GestureDetector(
                      onTap: _cancelReply,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  if (_replyingToComment != null) const SizedBox(width: 8),
                  // Send button
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _commentController.text.trim().isEmpty ||
                              _isSubmitting
                          ? (isDarkMode ? Colors.grey[700] : Colors.grey[300])
                          : theme.primaryColor,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(17),
                        onTap: _isSubmitting ||
                                _commentController.text.trim().isEmpty
                            ? null
                            : _postComment,
                        child: _isSubmitting
                            ? SizedBox(
                                width: 34,
                                height: 34,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDarkMode
                                          ? Colors.grey[400]!
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: _commentController.text.trim().isEmpty
                                    ? (isDarkMode
                                        ? Colors.grey[500]
                                        : Colors.grey[600])
                                    : Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Comments list
          Expanded(
            child: widget.isLoading && _comments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      ),
                    ),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No comments yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to comment!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return _buildCommentWithReplies(comment);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Helper method to extract comment content from various possible field names
  String _getCommentContent(Map<String, dynamic> comment) {
    // Try different possible field names for comment content
    // Backend uses 'comment_text', but frontend was looking for 'content'
    final possibleFields = [
      'comment_text',
      'content',
      'text',
      'message',
      'comment',
      'body'
    ];

    for (final field in possibleFields) {
      final value = comment[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return 'No content available';
  }

  /// Helper method to extract user name from various possible field names
  String _getUserName(Map<String, dynamic> comment) {
    // Debug: Print comment structure for troubleshooting
    final commentId = comment['comment_id'] ?? comment['id'];
    print(
        '🔍 [USERNAME] Processing comment $commentId: ${comment.keys.toList()}');

    // Backend uses 'user_display_name' or 'user_name'
    final possibleFields = [
      'user_display_name',
      'user_name',
      'username',
      'name',
      'full_name'
    ];

    for (final field in possibleFields) {
      final value = comment[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        print('🔍 [USERNAME] Found username in field "$field": $value');
        return value.toString();
      }
    }

    // Check nested user object
    final user = comment['user'];
    if (user != null && user is Map<String, dynamic>) {
      print('🔍 [USERNAME] Checking nested user object: ${user.keys.toList()}');
      final userFields = ['full_name', 'name', 'display_name'];
      for (final field in userFields) {
        final value = user[field];
        if (value != null && value.toString().trim().isNotEmpty) {
          print('🔍 [USERNAME] Found username in user.$field: $value');
          return value.toString();
        }
      }
    }

    print('🔍 [USERNAME] No username found, returning Anonymous');
    return 'Anonymous';
  }

  /// Build user avatar with proper theming
  Widget _buildUserAvatar(Map<String, dynamic> comment, bool isOptimistic,
      bool isDarkMode, ThemeData theme) {
    final userData = comment['user'];
    final avatarUrl = userData?['avatar_url'] ?? userData?['profile_picture'];

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOptimistic
            ? (isDarkMode ? Colors.grey[700] : Colors.grey[300])
            : (isDarkMode ? Colors.grey[600] : Colors.grey[200]),
        border: Border.all(
          color: isDarkMode ? Colors.grey[500]! : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: avatarUrl != null && avatarUrl.toString().isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl.toString(),
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultAvatar(isOptimistic, isDarkMode, theme),
              ),
            )
          : _buildDefaultAvatar(isOptimistic, isDarkMode, theme),
    );
  }

  /// Build default avatar icon
  Widget _buildDefaultAvatar(
      bool isOptimistic, bool isDarkMode, ThemeData theme) {
    return Icon(
      Icons.person,
      size: 20,
      color: isOptimistic
          ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
          : (isDarkMode ? Colors.grey[300] : theme.primaryColor),
    );
  }

  /// Get time ago string
  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'now';

    try {
      final DateTime commentTime = DateTime.parse(createdAt.toString());
      final Duration difference = DateTime.now().difference(commentTime);

      if (difference.inMinutes < 1) return 'now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m';
      if (difference.inHours < 24) return '${difference.inHours}h';
      if (difference.inDays < 7) return '${difference.inDays}d';
      return '${(difference.inDays / 7).floor()}w';
    } catch (e) {
      return 'now';
    }
  }

  /// Toggle comment like
  Future<void> _toggleCommentLike(Map<String, dynamic> comment) async {
    try {
      final commentId = comment['comment_id'];
      final isCurrentlyLiked = comment['is_liked'] == true;

      // Optimistic update
      setState(() {
        comment['is_liked'] = !isCurrentlyLiked;
        comment['like_count'] =
            (comment['like_count'] ?? 0) + (isCurrentlyLiked ? -1 : 1);
      });

      // Call API
      if (isCurrentlyLiked) {
        await SmartCommentsBottomSheet._postService
            .unlikeComment(commentId.toString());
      } else {
        await SmartCommentsBottomSheet._postService
            .likeComment(commentId.toString());
      }

      print(
          '✅ [SMART_COMMENTS] Comment ${isCurrentlyLiked ? 'unliked' : 'liked'} successfully');
    } catch (e) {
      print('❌ [SMART_COMMENTS] Failed to toggle comment like: $e');

      // Revert optimistic update on error
      setState(() {
        final isCurrentlyLiked = comment['is_liked'] == true;
        comment['is_liked'] = !isCurrentlyLiked;
        comment['like_count'] =
            (comment['like_count'] ?? 0) + (isCurrentlyLiked ? -1 : 1);
      });
    }
  }

  /// Show reply dialog
  void _showReplyDialog(Map<String, dynamic> comment) {
    final userName = _getUserName(comment);

    setState(() {
      _replyingToComment = comment;
      _placeholderText = "Reply to $userName...";
    });

    // Focus the input field
    FocusScope.of(context).requestFocus(_focusNode);
  }

  /// Show replies
  void _showReplies(Map<String, dynamic> comment) {
    final replies = comment['replies'] as List<dynamic>? ?? [];
    final userName = _getUserName(comment);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Replies to $userName',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Parent comment
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCommentItem(comment, isParent: true),
              ),
              const Divider(),
              // Replies list
              Expanded(
                child: replies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No replies yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to reply!',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: replies.length,
                        itemBuilder: (context, index) {
                          final reply = replies[index] as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(left: 24, bottom: 8),
                            child: _buildCommentItem(reply, isReply: true),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment,
      {bool isParent = false, bool isReply = false}) {
    final isOptimistic = comment['is_optimistic'] == true;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isLiked = comment['is_liked'] == true;
    final likeCount = comment['like_count'] ?? 0;
    final repliesCount = comment['replies_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle comment tap (could expand for replies)
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Avatar
                _buildUserAvatar(comment, isOptimistic, isDarkMode, theme),

                const SizedBox(width: 12),

                // Comment Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Comment Bubble
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[800]?.withOpacity(0.6)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Name
                            Text(
                              _getUserName(comment),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Comment Text
                            Text(
                              _getCommentContent(comment),
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.3,
                                color: isOptimistic
                                    ? theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.6)
                                    : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Action Row (Like, Reply, Time)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Row(
                          children: [
                            // Time ago
                            Text(
                              _getTimeAgo(comment['created_at']),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Like Button with Animation
                            GestureDetector(
                              onTap: isOptimistic
                                  ? null
                                  : () => _toggleCommentLike(comment),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedScale(
                                      scale: isLiked ? 1.1 : 1.0,
                                      duration:
                                          const Duration(milliseconds: 150),
                                      child: Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 16,
                                        color: isLiked
                                            ? Colors.red[600]
                                            : theme.textTheme.bodyMedium?.color
                                                ?.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Like',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isLiked
                                            ? Colors.red[600]
                                            : theme.textTheme.bodyMedium?.color
                                                ?.withOpacity(0.6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (likeCount > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '($likeCount)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme
                                              .textTheme.bodyMedium?.color
                                              ?.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Reply Button (hide for replies to avoid infinite nesting)
                            if (!isReply)
                              GestureDetector(
                                onTap: isOptimistic
                                    ? null
                                    : () => _showReplyDialog(comment),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 14,
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Reply',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .textTheme.bodyMedium?.color
                                              ?.withOpacity(0.6),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Show replies count if any (only for top-level comments)
                            if (repliesCount > 0 && !isReply) ...[
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () => _showReplies(comment),
                                child: Text(
                                  '$repliesCount ${repliesCount == 1 ? 'reply' : 'replies'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],

                            // Optimistic indicator
                            if (isOptimistic) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: isDarkMode
                                    ? Colors.orange[300]
                                    : Colors.orange[600],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draggable comments content
class _DraggableCommentsContent extends StatelessWidget {
  final ScrollController scrollController;
  final String postId;
  final dynamic data;
  final bool isLoading;
  final VoidCallback? onCommentAdded;

  const _DraggableCommentsContent({
    required this.scrollController,
    required this.postId,
    required this.data,
    required this.isLoading,
    required this.onCommentAdded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _CommentsContent(
        postId: postId,
        data: data,
        isLoading: isLoading,
        onCommentAdded: onCommentAdded,
      ),
    );
  }
}
