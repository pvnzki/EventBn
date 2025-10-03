import 'dart:async';
import '../cache/memory_cache.dart';
import '../cache/disk_cache.dart';

/// Advanced comment optimization service with virtualization,
/// incremental loading, and smart caching
class CommentOptimizationService {
  static final CommentOptimizationService _instance = CommentOptimizationService._internal();
  factory CommentOptimizationService() => _instance;
  CommentOptimizationService._internal();

  // Cache instances
  late final MemoryCache<String, List<Comment>> _commentCache;
  late final DiskCache _diskCache;

  // Configuration
  static const int _commentsPerPage = 20;
  static const int _preloadThreshold = 5; // Load more when 5 items from bottom
  static const Duration _cacheExpiry = Duration(minutes: 30);

  // State management
  final Map<String, CommentLoadingState> _loadingStates = {};
  final Map<String, StreamController<List<Comment>>> _commentStreams = {};

  /// Initialize the comment service
  Future<void> initialize() async {
    _commentCache = MemoryCache<String, List<Comment>>(
      maxSize: 200, // Cache 200 comment pages
      defaultTtl: _cacheExpiry,
    );
    
    _diskCache = DiskCache();
    await _diskCache.initialize();
  }

  /// Get comments stream for a post with virtualization
  Stream<List<Comment>> getCommentsStream(String postId) {
    if (!_commentStreams.containsKey(postId)) {
      _commentStreams[postId] = StreamController<List<Comment>>.broadcast();
      _initializeCommentLoading(postId);
    }
    
    return _commentStreams[postId]!.stream;
  }

  /// Initialize comment loading for a post
  Future<void> _initializeCommentLoading(String postId) async {
    if (_loadingStates.containsKey(postId)) return;

    _loadingStates[postId] = CommentLoadingState(
      postId: postId,
      currentPage: 0,
      hasMoreComments: true,
      isLoading: false,
      comments: [],
    );

    // Load initial comments
    await _loadComments(postId, reload: true);
  }

  /// Load comments for a post with pagination
  Future<void> _loadComments(String postId, {bool reload = false}) async {
    final state = _loadingStates[postId];
    if (state == null || state.isLoading) return;

    if (reload) {
      state.reset();
    }

    if (!state.hasMoreComments) return;

    state.isLoading = true;

    try {
      // Check cache first
      final cacheKey = '${postId}_page_${state.currentPage}';
      List<Comment>? cachedComments = _commentCache.get(cacheKey);

      if (cachedComments == null) {
        // Load from disk cache
        cachedComments = await _loadCommentsFromDisk(cacheKey);
      }

      if (cachedComments == null) {
        // Load from network
        cachedComments = await _loadCommentsFromNetwork(postId, state.currentPage);
        
        // Cache the results
        _commentCache.put(cacheKey, cachedComments);
        await _saveCommentsToDisk(cacheKey, cachedComments);
      }

      // Update state
      if (reload) {
        state.comments = cachedComments;
      } else {
        state.comments.addAll(cachedComments);
      }

      state.currentPage++;
      state.hasMoreComments = cachedComments.length >= _commentsPerPage;

      // Notify listeners
      _commentStreams[postId]?.add(List.from(state.comments));

    } catch (e) {
      print('❌ [COMMENT_SERVICE] Error loading comments for $postId: $e');
    } finally {
      state.isLoading = false;
    }
  }

  /// Load more comments when user scrolls near bottom
  Future<void> loadMoreComments(String postId) async {
    await _loadComments(postId);
  }

  /// Refresh comments for a post
  Future<void> refreshComments(String postId) async {
    // Clear caches for this post
    _clearPostCache(postId);
    
    // Reload comments
    await _loadComments(postId, reload: true);
  }

  /// Add a new comment with optimistic updates
  Future<bool> addComment(String postId, String content, String userId) async {
    try {
      // Create optimistic comment
      final optimisticComment = Comment(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        postId: postId,
        userId: userId,
        content: content,
        createdAt: DateTime.now(),
        isOptimistic: true,
        likesCount: 0,
        isLiked: false,
      );

      // Add to current state immediately
      final state = _loadingStates[postId];
      if (state != null) {
        state.comments.insert(0, optimisticComment);
        _commentStreams[postId]?.add(List.from(state.comments));
      }

      // Send to server
      final serverComment = await _addCommentToServer(postId, content, userId);
      
      // Replace optimistic comment with server response
      if (state != null) {
        final index = state.comments.indexWhere((c) => c.id == optimisticComment.id);
        if (index != -1) {
          state.comments[index] = serverComment;
          _commentStreams[postId]?.add(List.from(state.comments));
        }
      }

      // Invalidate cache to ensure fresh data on next load
      _clearPostCache(postId);

      return true;
    } catch (e) {
      print('❌ [COMMENT_SERVICE] Error adding comment: $e');
      
      // Remove optimistic comment on error
      final state = _loadingStates[postId];
      if (state != null) {
        state.comments.removeWhere((c) => c.isOptimistic);
        _commentStreams[postId]?.add(List.from(state.comments));
      }
      
      return false;
    }
  }

  /// Toggle like on a comment with optimistic updates
  Future<bool> toggleCommentLike(String postId, String commentId) async {
    try {
      final state = _loadingStates[postId];
      if (state == null) return false;

      // Find comment and update optimistically
      final commentIndex = state.comments.indexWhere((c) => c.id == commentId);
      if (commentIndex == -1) return false;

      final comment = state.comments[commentIndex];
      final wasLiked = comment.isLiked;
      
      // Optimistic update
      state.comments[commentIndex] = comment.copyWith(
        isLiked: !wasLiked,
        likesCount: wasLiked ? comment.likesCount - 1 : comment.likesCount + 1,
      );
      
      _commentStreams[postId]?.add(List.from(state.comments));

      // Send to server
      final success = await _toggleCommentLikeOnServer(commentId, !wasLiked);
      
      if (!success) {
        // Revert on failure
        state.comments[commentIndex] = comment;
        _commentStreams[postId]?.add(List.from(state.comments));
      }

      return success;
    } catch (e) {
      print('❌ [COMMENT_SERVICE] Error toggling comment like: $e');
      return false;
    }
  }

  /// Delete a comment with optimistic updates
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final state = _loadingStates[postId];
      if (state == null) return false;

      // Find comment
      final commentIndex = state.comments.indexWhere((c) => c.id == commentId);
      if (commentIndex == -1) return false;

      final deletedComment = state.comments[commentIndex];
      
      // Optimistic removal
      state.comments.removeAt(commentIndex);
      _commentStreams[postId]?.add(List.from(state.comments));

      // Send to server
      final success = await _deleteCommentOnServer(commentId);
      
      if (!success) {
        // Revert on failure
        state.comments.insert(commentIndex, deletedComment);
        _commentStreams[postId]?.add(List.from(state.comments));
      }

      return success;
    } catch (e) {
      print('❌ [COMMENT_SERVICE] Error deleting comment: $e');
      return false;
    }
  }

  /// Check if more comments should be loaded based on scroll position
  bool shouldLoadMore(String postId, int visibleIndex) {
    final state = _loadingStates[postId];
    if (state == null || state.isLoading || !state.hasMoreComments) {
      return false;
    }

    return (state.comments.length - visibleIndex) <= _preloadThreshold;
  }

  /// Preload comments for multiple posts
  Future<void> preloadComments(List<String> postIds) async {
    for (final postId in postIds) {
      if (!_loadingStates.containsKey(postId)) {
        unawaited(_initializeCommentLoading(postId));
      }
    }
  }

  /// Load comments from network (mock implementation)
  Future<List<Comment>> _loadCommentsFromNetwork(String postId, int page) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock data - replace with actual API call
    final comments = <Comment>[];
    final startIndex = page * _commentsPerPage;
    
    for (int i = 0; i < _commentsPerPage; i++) {
      comments.add(Comment(
        id: 'comment_${postId}_${startIndex + i}',
        postId: postId,
        userId: 'user_${(startIndex + i) % 10}',
        content: 'This is comment ${startIndex + i} for post $postId',
        createdAt: DateTime.now().subtract(Duration(hours: i)),
        isOptimistic: false,
        likesCount: (startIndex + i) % 20,
        isLiked: (startIndex + i) % 3 == 0,
      ));
    }
    
    return comments;
  }

  /// Add comment to server (mock implementation)
  Future<Comment> _addCommentToServer(String postId, String content, String userId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    return Comment(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: userId,
      content: content,
      createdAt: DateTime.now(),
      isOptimistic: false,
      likesCount: 0,
      isLiked: false,
    );
  }

  /// Toggle comment like on server (mock implementation)
  Future<bool> _toggleCommentLikeOnServer(String commentId, bool isLiked) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true; // Success
  }

  /// Delete comment on server (mock implementation)
  Future<bool> _deleteCommentOnServer(String commentId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true; // Success
  }

  /// Load comments from disk cache
  Future<List<Comment>?> _loadCommentsFromDisk(String cacheKey) async {
    try {
      // Use the custom cache key approach for comments
      final commentCacheKey = 'comments_$cacheKey';
      final cacheData = await _diskCache.getPostsFromDisk(cacheKey: commentCacheKey);
      
      // Convert posts to comments if data exists
      if (cacheData.isNotEmpty) {
        // This is a simplified approach - in real implementation,
        // you'd store comments in a separate format
        return [];
      }
    } catch (e) {
      print('⚠️ [COMMENT_SERVICE] Error loading from disk cache: $e');
    }
    return null;
  }

  /// Save comments to disk cache
  Future<void> _saveCommentsToDisk(String cacheKey, List<Comment> comments) async {
    try {
      // For now, we'll skip disk caching of comments as the DiskCache
      // is designed for posts. In a real implementation, you'd extend
      // DiskCache to support generic data or create a separate CommentDiskCache
      print('💭 [COMMENT_SERVICE] Skipping disk cache for comments (not implemented)');
    } catch (e) {
      print('⚠️ [COMMENT_SERVICE] Error saving to disk cache: $e');
    }
  }

  /// Clear cache for a specific post
  void _clearPostCache(String postId) {
    // Clear memory cache entries for this post
    // Since we can't iterate over keys, we'll clear specific known keys
    for (int page = 0; page < 10; page++) { // Clear up to 10 pages
      final cacheKey = '${postId}_page_$page';
      _commentCache.remove(cacheKey);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memory_cache_size': _commentCache.size,
      'memory_cache_stats': _commentCache.getStats(),
      'active_streams': _commentStreams.length,
      'loading_states': _loadingStates.length,
    };
  }

  /// Dispose resources
  void dispose() {
    for (final controller in _commentStreams.values) {
      controller.close();
    }
    _commentStreams.clear();
    _loadingStates.clear();
    _commentCache.clear();
  }
}

/// Comment loading state management
class CommentLoadingState {
  final String postId;
  int currentPage;
  bool hasMoreComments;
  bool isLoading;
  List<Comment> comments;

  CommentLoadingState({
    required this.postId,
    required this.currentPage,
    required this.hasMoreComments,
    required this.isLoading,
    required this.comments,
  });

  void reset() {
    currentPage = 0;
    hasMoreComments = true;
    isLoading = false;
    comments.clear();
  }
}

/// Comment model
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final bool isOptimistic;
  final int likesCount;
  final bool isLiked;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.isOptimistic,
    required this.likesCount,
    required this.isLiked,
  });

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? content,
    DateTime? createdAt,
    bool? isOptimistic,
    int? likesCount,
    bool? isLiked,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isOptimistic': isOptimistic,
      'likesCount': likesCount,
      'isLiked': isLiked,
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      isOptimistic: json['isOptimistic'] ?? false,
      likesCount: json['likesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}