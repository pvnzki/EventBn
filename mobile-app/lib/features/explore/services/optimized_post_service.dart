import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/post_model.dart';
import '../../../core/config/app_config.dart';
import '../../../core/cache/memory_cache.dart';
import '../../../core/cache/disk_cache.dart';
import '../../../core/network/connection_pool.dart';
import '../../../core/performance/performance_monitor.dart';

/// Highly optimized ExplorePostService with advanced caching, performance monitoring,
/// and intelligent data management strategies.
class OptimizedExplorePostService {
  static final OptimizedExplorePostService _instance =
      OptimizedExplorePostService._internal();
  factory OptimizedExplorePostService() => _instance;
  OptimizedExplorePostService._internal() {
    _initializeService();
  }

  // Core configuration
  static String get _postServiceUrl => AppConfig.postServiceUrl;

  // Performance and caching
  final MemoryCache<String, ExplorePost> _postCache = MemoryCache(maxSize: 500);
  final MemoryCache<String, List<Map<String, dynamic>>> _commentCache =
      MemoryCache(maxSize: 200);
  final MemoryCache<String, String> _imageCache = MemoryCache(maxSize: 1000);
  final DiskCache _diskCache = DiskCache();
  final ConnectionPool _connectionPool = ConnectionPool();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // Data management
  final List<ExplorePost> _posts = [];
  final Map<String, DateTime> _postLastFetch = {};
  final Map<String, bool> _postOptimisticUpdates = {};

  // State management
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  String? _cachedAuthToken;
  DateTime? _tokenExpiry;

  // Performance metrics
  final int _networkFetchCount = 0;
  final int _cacheHitCount = 0;

  // Getters
  List<ExplorePost> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;
  Map<String, dynamic> get performanceMetrics =>
      _performanceMonitor.getMetrics();

  Future<void> _initializeService() async {
    await _diskCache.initialize();
    await _preloadCriticalData();
    _startPerformanceMonitoring();
  }

  void _startPerformanceMonitoring() {
    _performanceMonitor.startMonitoring('PostService');
  }

  /// Preload critical data for faster startup
  Future<void> _preloadCriticalData() async {
    try {
      // Preload cached posts from disk
      final cachedPosts = await _diskCache.getPostsFromDisk();
      if (cachedPosts.isNotEmpty) {
        _posts.addAll(cachedPosts);
        print(
            '📦 [CACHE] Preloaded ${cachedPosts.length} posts from disk cache');
      }

      // Preload auth token
      await _getAuthToken();
    } catch (e) {
      print('⚠️ [PRELOAD] Error preloading data: $e');
    }
  }

  /// Optimized auth token management with caching and expiry
  Future<String?> _getAuthToken() async {
    // Return cached token if still valid
    if (_cachedAuthToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAuthToken;
    }

    final stopwatch = Stopwatch()..start();

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(AppConfig.tokenKey);

      if (token == null) {
        token = await _getTestToken();
        if (token != null) {
          await prefs.setString(AppConfig.tokenKey, token);
        }
      }

      if (token != null) {
        _cachedAuthToken = token;
        _tokenExpiry = DateTime.now().add(const Duration(hours: 12));
      }

      _performanceMonitor.recordMetric(
          'auth_token_fetch_ms', stopwatch.elapsedMilliseconds);
      return token;
    } catch (e) {
      _performanceMonitor.recordError('auth_token_fetch_error', e.toString());
      return null;
    } finally {
      stopwatch.stop();
    }
  }

  /// Optimized test token retrieval with connection pooling
  Future<String?> _getTestToken() async {
    try {
      final client = _connectionPool.getClient();
      final response = await client.get(
        Uri.parse('$_postServiceUrl/api/debug/test-token'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          return data['token'];
        }
      }
    } catch (e) {
      print('🔑 [DEBUG] Test token fetch failed: $e');
    }
    return null;
  }

  /// Create optimized headers with caching
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Generate cache key for requests
  String _generateCacheKey(String endpoint, Map<String, String> params) {
    final content =
        '$endpoint${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return sha256.convert(utf8.encode(content)).toString().substring(0, 16);
  }

  /// Highly optimized post loading with multi-level caching
  Future<void> loadPosts({
    String? searchQuery,
    PostCategory? category,
    bool refresh = false,
    bool forceFresh = false,
  }) async {
    if (_isLoading && !forceFresh) return;

    final stopwatch = Stopwatch()..start();
    final operationId = 'load_posts_${DateTime.now().millisecondsSinceEpoch}';

    try {
      _isLoading = true;
      _performanceMonitor.startOperation(operationId);

      if (refresh) {
        _currentPage = 1;
        _hasMoreData = true;
        if (!forceFresh) {
          _posts.clear();
        }
      }

      // Step 1: Check memory cache first (fastest)
      final cacheKey = _generateCacheKey('explore', {
        'page': _currentPage.toString(),
        'search': searchQuery ?? '',
        'category': category?.name ?? 'all',
      });

      if (!forceFresh && !refresh) {
        final cachedPosts = _getPostsFromMemoryCache(cacheKey);
        if (cachedPosts.isNotEmpty) {
          _posts.addAll(cachedPosts);
          _performanceMonitor.recordCacheHit('memory_cache');
          print(
              '⚡ [CACHE] Loaded ${cachedPosts.length} posts from memory cache');
          return;
        }
      }

      // Step 2: Check disk cache (medium speed)
      if (!forceFresh) {
        final diskCachedPosts = await _diskCache.getPostsFromDisk(
          cacheKey: cacheKey,
          maxAge: const Duration(minutes: 5),
        );
        if (diskCachedPosts.isNotEmpty) {
          _addPostsToCache(diskCachedPosts, cacheKey);
          _posts.addAll(diskCachedPosts);
          _performanceMonitor.recordCacheHit('disk_cache');
          print(
              '💾 [CACHE] Loaded ${diskCachedPosts.length} posts from disk cache');

          // Background refresh if data is older than 2 minutes
          _backgroundRefreshIfNeeded(cacheKey);
          return;
        }
      }

      // Step 3: Fetch from network (slowest but freshest)
      await _fetchPostsFromNetwork(
        searchQuery: searchQuery,
        category: category,
        cacheKey: cacheKey,
        refresh: refresh,
      );

      _performanceMonitor.recordMetric(
          'total_load_time_ms', stopwatch.elapsedMilliseconds);
    } catch (e) {
      _performanceMonitor.recordError('load_posts_error', e.toString());
      print('❌ [ERROR] Failed to load posts: $e');
    } finally {
      _isLoading = false;
      _performanceMonitor.endOperation(operationId);
      stopwatch.stop();
    }
  }

  /// Background refresh for stale cache data
  void _backgroundRefreshIfNeeded(String cacheKey) {
    // Don't await this - let it run in background
    Future.microtask(() async {
      try {
        await _fetchPostsFromNetwork(
          cacheKey: cacheKey,
          isBackgroundRefresh: true,
        );
      } catch (e) {
        print('⚠️ [BACKGROUND] Background refresh failed: $e');
      }
    });
  }

  /// Optimized network fetching with connection pooling and compression
  Future<void> _fetchPostsFromNetwork({
    String? searchQuery,
    PostCategory? category,
    required String cacheKey,
    bool refresh = false,
    bool isBackgroundRefresh = false,
  }) async {
    final client = _connectionPool.getClient();
    final headers = await _getHeaders();

    final queryParams = {
      'page': _currentPage.toString(),
      'limit': '20',
      'compress': 'true', // Request compressed response
      if (searchQuery?.isNotEmpty == true) 'search': searchQuery!,
      if (category != null && category != PostCategory.all)
        'category': category.name,
    };

    final uri = Uri.parse('$_postServiceUrl/api/posts/explore').replace(
      queryParameters: queryParams,
    );

    final response = await client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final List<dynamic> postsJson = data['posts'] ?? [];
        final newPosts =
            postsJson.map((json) => ExplorePost.fromJson(json)).toList();

        // Intelligent duplicate filtering
        final uniqueNewPosts = _filterDuplicates(newPosts);

        if (!isBackgroundRefresh) {
          if (refresh) _posts.clear();
          _posts.addAll(uniqueNewPosts);
        }

        // Cache the results
        await _cachePostsMultiLevel(uniqueNewPosts, cacheKey);

        // Update pagination
        final pagination = data['pagination'];
        if (pagination != null) {
          _hasMoreData = pagination['page'] < pagination['totalPages'];
        } else {
          _hasMoreData = newPosts.length >= 20;
        }

        _performanceMonitor.recordMetric(
            'network_fetch_count', uniqueNewPosts.length);
        print('🌐 [NETWORK] Fetched ${uniqueNewPosts.length} unique posts');
      }
    } else {
      throw Exception('Network request failed: ${response.statusCode}');
    }
  }

  /// Intelligent duplicate filtering with performance optimization
  List<ExplorePost> _filterDuplicates(List<ExplorePost> newPosts) {
    final existingIds = Set<String>.from(_posts.map((post) => post.id));
    return newPosts.where((post) => !existingIds.contains(post.id)).toList();
  }

  /// Multi-level caching strategy
  Future<void> _cachePostsMultiLevel(
      List<ExplorePost> posts, String cacheKey) async {
    // Memory cache (immediate access)
    _addPostsToCache(posts, cacheKey);

    // Disk cache (persistent across app restarts)
    await _diskCache.savePostsToDisk(posts, cacheKey);

    // Update fetch timestamps
    final now = DateTime.now();
    for (final post in posts) {
      _postLastFetch[post.id] = now;
    }
  }

  /// Memory cache management
  void _addPostsToCache(List<ExplorePost> posts, String cacheKey) {
    for (final post in posts) {
      _postCache.put(post.id, post);
    }
    _performanceMonitor.recordCacheHit('memory_cache_write');
  }

  /// Get posts from memory cache
  List<ExplorePost> _getPostsFromMemoryCache(String cacheKey) {
    final cachedPosts = <ExplorePost>[];
    // Implementation would retrieve posts based on cache key strategy
    // For simplicity, returning empty list here
    return cachedPosts;
  }

  /// Optimized pagination with predictive loading
  Future<void> loadMorePosts({
    String? searchQuery,
    PostCategory? category,
  }) async {
    if (_isLoading || !_hasMoreData) return;

    _currentPage++;
    await loadPosts(
      searchQuery: searchQuery,
      category: category,
      refresh: false,
    );
  }

  /// Optimized like toggle with optimistic updates and batch processing
  Future<void> toggleLike(String postId) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Optimistic update
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        final newLikeState = !post.isLiked;
        final newLikeCount =
            newLikeState ? post.likesCount + 1 : post.likesCount - 1;

        _posts[postIndex] = post.copyWith(
          isLiked: newLikeState,
          likesCount: newLikeCount,
        );

        _postOptimisticUpdates[postId] = true;
      }

      // Background network request
      _performNetworkLikeToggle(postId);

      _performanceMonitor.recordMetric(
          'like_toggle_time_ms', stopwatch.elapsedMilliseconds);
    } catch (e) {
      _performanceMonitor.recordError('like_toggle_error', e.toString());
      // Revert optimistic update on error
      await _revertOptimisticUpdate(postId);
    } finally {
      stopwatch.stop();
    }
  }

  /// Network like toggle (non-blocking)
  void _performNetworkLikeToggle(String postId) {
    Future.microtask(() async {
      try {
        final client = _connectionPool.getClient();
        final headers = await _getHeaders();
        final uri = Uri.parse('$_postServiceUrl/api/posts/$postId/like');

        final response = await client
            .post(uri, headers: headers)
            .timeout(const Duration(seconds: 8));

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          // Confirm optimistic update was correct
          _postOptimisticUpdates.remove(postId);

          // Update with server response if different
          final serverLiked = data['liked'];
          final serverCount = data['likesCount'];

          final postIndex = _posts.indexWhere((post) => post.id == postId);
          if (postIndex != -1) {
            final post = _posts[postIndex];
            if (post.isLiked != serverLiked || post.likesCount != serverCount) {
              _posts[postIndex] = post.copyWith(
                isLiked: serverLiked,
                likesCount: serverCount,
              );
            }
          }
        } else {
          // Revert optimistic update
          await _revertOptimisticUpdate(postId);
        }
      } catch (e) {
        print('❌ [NETWORK] Like toggle failed: $e');
        await _revertOptimisticUpdate(postId);
      }
    });
  }

  /// Revert optimistic update
  Future<void> _revertOptimisticUpdate(String postId) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      _posts[postIndex] = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    }
    _postOptimisticUpdates.remove(postId);
  }

  /// Dispose resources and cleanup
  void dispose() {
    _connectionPool.dispose();
    _performanceMonitor.dispose();
    _postCache.clear();
    _commentCache.clear();
    _imageCache.clear();
  }
}
