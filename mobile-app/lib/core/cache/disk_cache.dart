import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../../features/explore/models/post_model.dart';

/// High-performance disk cache for persistent storage across app sessions
class DiskCache {
  static const String _cacheDir = 'post_cache';
  static const String _metadataFile = 'cache_metadata.json';
  static const Duration _defaultMaxAge = Duration(hours: 24);

  Directory? _cacheDirectory;
  Map<String, dynamic> _metadata = {};
  bool _initialized = false;

  /// Initialize the disk cache
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDocDir.path}/$_cacheDir');

      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }

      await _loadMetadata();
      await _cleanExpiredCache();

      _initialized = true;
      print('💾 [DISK_CACHE] Initialized successfully');
    } catch (e) {
      print('❌ [DISK_CACHE] Initialization failed: $e');
    }
  }

  /// Save posts to disk with compression
  Future<void> savePostsToDisk(List<ExplorePost> posts, String cacheKey) async {
    if (!_initialized || posts.isEmpty) return;

    try {
      final file = File('${_cacheDirectory!.path}/$cacheKey.json');
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'posts': posts.map((post) => post.toJson()).toList(),
        'count': posts.length,
      };

      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);

      // Update metadata
      _metadata[cacheKey] = {
        'timestamp': DateTime.now().toIso8601String(),
        'size': jsonString.length,
        'count': posts.length,
      };

      await _saveMetadata();
      print('💾 [DISK_CACHE] Saved ${posts.length} posts for key: $cacheKey');
    } catch (e) {
      print('❌ [DISK_CACHE] Save failed: $e');
    }
  }

  /// Get posts from disk cache
  Future<List<ExplorePost>> getPostsFromDisk({
    String? cacheKey,
    Duration maxAge = _defaultMaxAge,
  }) async {
    if (!_initialized) return [];

    try {
      if (cacheKey != null) {
        return await _getPostsForKey(cacheKey, maxAge);
      } else {
        return await _getAllCachedPosts(maxAge);
      }
    } catch (e) {
      print('❌ [DISK_CACHE] Get failed: $e');
      return [];
    }
  }

  /// Get posts for specific cache key
  Future<List<ExplorePost>> _getPostsForKey(
      String cacheKey, Duration maxAge) async {
    final file = File('${_cacheDirectory!.path}/$cacheKey.json');

    if (!await file.exists()) return [];

    // Check if file is too old
    final metadata = _metadata[cacheKey];
    if (metadata != null) {
      final timestamp = DateTime.parse(metadata['timestamp']);
      if (DateTime.now().difference(timestamp) > maxAge) {
        await _deleteCache(cacheKey);
        return [];
      }
    }

    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString);

    final List<dynamic> postsJson = data['posts'] ?? [];
    return postsJson.map((json) => ExplorePost.fromJson(json)).toList();
  }

  /// Get all cached posts (for app startup)
  Future<List<ExplorePost>> _getAllCachedPosts(Duration maxAge) async {
    final allPosts = <ExplorePost>[];

    for (final entry in _metadata.entries) {
      final timestamp = DateTime.parse(entry.value['timestamp']);
      if (DateTime.now().difference(timestamp) <= maxAge) {
        final posts = await _getPostsForKey(entry.key, maxAge);
        allPosts.addAll(posts);
      }
    }

    return allPosts;
  }

  /// Delete specific cache entry
  Future<void> _deleteCache(String cacheKey) async {
    final file = File('${_cacheDirectory!.path}/$cacheKey.json');
    if (await file.exists()) {
      await file.delete();
    }
    _metadata.remove(cacheKey);
    await _saveMetadata();
  }

  /// Clean expired cache entries
  Future<void> _cleanExpiredCache() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _metadata.entries) {
      final timestamp = DateTime.parse(entry.value['timestamp']);
      if (now.difference(timestamp) > _defaultMaxAge) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await _deleteCache(key);
    }

    if (expiredKeys.isNotEmpty) {
      print('💾 [DISK_CACHE] Cleaned ${expiredKeys.length} expired entries');
    }
  }

  /// Load metadata from disk
  Future<void> _loadMetadata() async {
    final file = File('${_cacheDirectory!.path}/$_metadataFile');

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        _metadata = jsonDecode(jsonString);
      } catch (e) {
        print('⚠️ [DISK_CACHE] Failed to load metadata: $e');
        _metadata = {};
      }
    }
  }

  /// Save metadata to disk
  Future<void> _saveMetadata() async {
    try {
      final file = File('${_cacheDirectory!.path}/$_metadataFile');
      await file.writeAsString(jsonEncode(_metadata));
    } catch (e) {
      print('⚠️ [DISK_CACHE] Failed to save metadata: $e');
    }
  }

  /// Generate cache key from request parameters
  String generateCacheKey(Map<String, dynamic> params) {
    final content = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return sha256.convert(utf8.encode(content)).toString().substring(0, 16);
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    if (!_initialized) return {};

    int totalSize = 0;
    int totalFiles = 0;

    try {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          final stat = await file.stat();
          totalSize += stat.size;
          totalFiles++;
        }
      }
    } catch (e) {
      print('⚠️ [DISK_CACHE] Stats calculation failed: $e');
    }

    return {
      'totalFiles': totalFiles,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
      'metadata': _metadata,
    };
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    if (!_initialized) return;

    try {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
      _metadata.clear();
      print('💾 [DISK_CACHE] Cleared all cache');
    } catch (e) {
      print('❌ [DISK_CACHE] Clear all failed: $e');
    }
  }
}
