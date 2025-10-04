import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../../../core/config/app_config.dart';

class ExplorePostService {
  static final ExplorePostService _instance = ExplorePostService._internal();
  factory ExplorePostService() => _instance;
  ExplorePostService._internal();

  // Use post-service URL (different port from main API)
  // Note: Use 10.0.2.2 for Android emulator, localhost for iOS simulator/real device
  static String get _postServiceUrl => AppConfig.postServiceUrl;
  final List<ExplorePost> _posts = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;

  List<ExplorePost> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;

  // Get auth token from shared preferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(AppConfig.tokenKey);

    // If no token exists and we're in debug mode, try to get a test token
    if (token == null) {
      print('🔑 [DEBUG] No auth token found, attempting to get test token...');
      token = await _getTestToken();
      if (token != null) {
        // Store the test token for future use
        await prefs.setString(AppConfig.tokenKey, token);
        print('🔑 [DEBUG] Test token obtained and stored');
      }
    }

    return token;
  }

  // Get a test token from the backend (development only)
  Future<String?> _getTestToken() async {
    try {
      final response = await http.get(
        Uri.parse('$_postServiceUrl/api/debug/test-token'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      print(
          '🔑 [DEBUG] Test token response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          print('🔑 [DEBUG] Test token obtained successfully');
          return data['token'];
        }
      }
    } catch (error) {
      print('🔑 [DEBUG] Failed to get test token: $error');
    }

    return null;
  }

  // Create headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> loadPosts({
    String? searchQuery,
    PostCategory? category,
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      if (refresh) {
        _currentPage = 1;
        _hasMoreData = true;
        _posts.clear();
      }

      final headers = await _getHeaders();
      final queryParams = {
        'page': _currentPage.toString(),
        'limit': '20',
        if (searchQuery?.isNotEmpty == true) 'search': searchQuery!,
        if (category != null && category != PostCategory.all)
          'category': category.name,
      };

      final uri = Uri.parse('$_postServiceUrl/api/posts/explore').replace(
        queryParameters: queryParams,
      );

      print('🌐 [DEBUG] Making request to: $uri');
      print('📤 [DEBUG] Request headers: $headers');
      print('🔑 [DEBUG] Post service URL: $_postServiceUrl');

      // Test basic connectivity first with improved error handling
      try {
        print(
            '🔍 [DEBUG] Testing connectivity to $_postServiceUrl/api/health...');
        final healthResponse = await http.get(
          Uri.parse('$_postServiceUrl/api/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 8), onTimeout: () {
          throw Exception(
              'Health check timeout after 8 seconds - backend service may not be running');
        });
        print('🏥 [DEBUG] Health check status: ${healthResponse.statusCode}');
        print('🏥 [DEBUG] Health check response: ${healthResponse.body}');

        // Also test the test endpoint
        print(
            '🧪 [DEBUG] Testing connectivity to $_postServiceUrl/api/test...');
        final testResponse = await http.get(
          Uri.parse('$_postServiceUrl/api/test'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 8), onTimeout: () {
          throw Exception(
              'Test endpoint timeout after 8 seconds - backend service may not be running');
        });
        print('🧪 [DEBUG] Test endpoint status: ${testResponse.statusCode}');
        print('🧪 [DEBUG] Test endpoint response: ${testResponse.body}');
      } catch (connectivityError) {
        print('❌ [DEBUG] Connectivity test failed: $connectivityError');
        print('❌ [DEBUG] Backend URL: $_postServiceUrl');
        print(
            '❌ [DEBUG] If using emulator, ensure backend is running on host machine');
        print(
            '❌ [DEBUG] If using physical device, check WiFi and IP configuration');
        throw Exception(
            'Backend connection failed: ${connectivityError.toString()}. Check if backend services are running.');
      }

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Posts API request timeout after 15 seconds');
      });

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> postsJson = data['posts'] ?? [];

        // Debug: Log video-related data from backend
        print('🎬 [DEBUG] Backend response contains ${postsJson.length} posts');
        for (int i = 0; i < postsJson.length && i < 5; i++) {
          final post = postsJson[i];
          print('🎬 [DEBUG] Post ${i + 1} (ID: ${post['id']}) video data:');
          print('  - videoUrls: ${post['videoUrls']}');
          print('  - videoThumbnails: ${post['videoThumbnails']}');
          print('  - videos: ${post['videos']}');
          print('  - imageUrls: ${post['imageUrls']}');
          print('  - all keys: ${post.keys.toList()}');
        }

        final newPosts =
            postsJson.map((json) => ExplorePost.fromJson(json)).toList();

        // Debug: Log parsed video data
        print('🎬 [DEBUG] Parsed posts video data:');
        for (int i = 0; i < newPosts.length && i < 5; i++) {
          final post = newPosts[i];
          print('🎬 [DEBUG] Parsed post ${i + 1} (ID: ${post.id}):');
          print('  - videoUrls: ${post.videoUrls}');
          print('  - videoThumbnails: ${post.videoThumbnails}');
          if (post.videoUrls.isNotEmpty) {
            print('  🎥 This post has ${post.videoUrls.length} videos');
          }
          if (post.imageUrls.isNotEmpty) {
            print('  🖼️ This post has ${post.imageUrls.length} images');
          }
        }

        if (refresh) {
          _posts.clear();
        }

        // Filter out duplicates by checking existing post IDs
        final existingIds = _posts.map((post) => post.id).toSet();
        final uniqueNewPosts =
            newPosts.where((post) => !existingIds.contains(post.id)).toList();

        _posts.addAll(uniqueNewPosts);

        print(
            '🔄 [DEBUG] Added ${uniqueNewPosts.length} unique posts (${newPosts.length - uniqueNewPosts.length} duplicates filtered)');

        // Check if we have more data
        final pagination = data['pagination'];
        if (pagination != null) {
          _hasMoreData = pagination['page'] < pagination['totalPages'];
        } else {
          _hasMoreData = newPosts.length >= 20;
        }
      } else {
        // Handle API error - fall back to empty list for now
        print('Failed to load posts: ${data['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error loading posts: $e');
      // Handle network error - could show error state
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadMorePosts({
    String? searchQuery,
    PostCategory? category,
  }) async {
    if (_isLoading || !_hasMoreData) return;

    _isLoading = true;
    _currentPage++;

    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': _currentPage.toString(),
        'limit': '20',
        if (searchQuery?.isNotEmpty == true) 'search': searchQuery!,
        if (category != null && category != PostCategory.all)
          'category': category.name,
      };

      final uri = Uri.parse('$_postServiceUrl/api/posts/explore').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> postsJson = data['posts'] ?? [];
        final newPosts =
            postsJson.map((json) => ExplorePost.fromJson(json)).toList();

        // Filter out duplicates for loadMorePosts as well
        final existingIds = _posts.map((post) => post.id).toSet();
        final uniqueNewPosts =
            newPosts.where((post) => !existingIds.contains(post.id)).toList();

        _posts.addAll(uniqueNewPosts);

        print(
            '➕ [DEBUG] Load more: Added ${uniqueNewPosts.length} unique posts (${newPosts.length - uniqueNewPosts.length} duplicates filtered)');

        // Check if we have more data
        final pagination = data['pagination'];
        if (pagination != null) {
          _hasMoreData = pagination['page'] < pagination['totalPages'];
        } else {
          _hasMoreData = newPosts.length >= 20;
        }
      } else {
        // Handle API error
        _currentPage--; // Revert page increment on error
        print('Failed to load more posts: ${data['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _currentPage--; // Revert page increment on error
      print('Error loading more posts: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      print('❤️ [DEBUG] Toggling like for post: $postId');
      final headers = await _getHeaders();
      final uri = Uri.parse('$_postServiceUrl/api/posts/$postId/like');
      print('❤️ [DEBUG] Like URL: $uri');
      print('❤️ [DEBUG] Like headers: $headers');

      final response = await http
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      print(
          '❤️ [DEBUG] Like toggle response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Update local state
        final index = _posts.indexWhere((post) => post.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = post.copyWith(
            isLiked: data['liked'] ?? !post.isLiked,
            likesCount: data['likesCount'] ??
                (post.isLiked ? post.likesCount - 1 : post.likesCount + 1),
          );
          print(
              '✅ Updated post $postId: liked=${_posts[index].isLiked}, likes=${_posts[index].likesCount}');
        }
      } else {
        print('❌ Failed to toggle like: ${data['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('💥 Error toggling like: $e');
    }
  }

  Future<void> toggleBookmark(String postId) async {
    // For now, just update locally since bookmark API is not implemented
    // This can be implemented when bookmark service is added
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(
        isBookmarked: !post.isBookmarked,
      );
    }
  }

  // Add comment to a post
  Future<Map<String, dynamic>?> addComment(String postId, String content,
      {int? parentCommentId}) async {
    try {
      print('💬 [DEBUG] Adding comment to post: $postId');
      print('💬 [DEBUG] Comment content: $content');
      print('💬 [DEBUG] Parent comment ID: $parentCommentId');
      final headers = await _getHeaders();
      final uri = Uri.parse('$_postServiceUrl/api/posts/$postId/comments');
      final body = jsonEncode({
        'content': content,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      });
      print('💬 [DEBUG] Comment URL: $uri');
      print('💬 [DEBUG] Comment headers: $headers');
      print('💬 [DEBUG] Comment body: $body');

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      print(
          '� [DEBUG] Add comment response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        // Update local post comment count
        final index = _posts.indexWhere((post) => post.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = post.copyWith(
            commentsCount: post.commentsCount + 1,
          );
          print(
              '✅ Added comment to post $postId, new count: ${_posts[index].commentsCount}');
        }
        return data['data']['comment'];
      } else {
        print('❌ Failed to add comment: ${data['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      print('💥 Error adding comment: $e');
      return null;
    }
  }

  // Get comments for a post
  Future<List<Map<String, dynamic>>> getComments(String postId,
      {int page = 1, int limit = 20}) async {
    try {
      print('📖 [DEBUG] Getting comments for post: $postId');
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri =
          Uri.parse('$_postServiceUrl/api/posts/$postId/comments').replace(
        queryParameters: queryParams,
      );
      print('📖 [DEBUG] Get comments URL: $uri');
      print('📖 [DEBUG] Get comments headers: $headers');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      print(
          '� [DEBUG] Get comments response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> commentsJson = data['data']['comments'] ?? [];
        return commentsJson.cast<Map<String, dynamic>>();
      } else {
        print(
            '❌ Failed to get comments: ${data['message'] ?? 'Unknown error'}');
        return [];
      }
    } catch (e) {
      print('💥 Error getting comments: $e');
      return [];
    }
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_postServiceUrl/api/comments/$commentId'),
        headers: headers,
      );

      print(
          '🔧 Delete comment response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Comment $commentId deleted successfully');
        return true;
      } else {
        print(
            '❌ Failed to delete comment: ${data['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('💥 Error deleting comment: $e');
      return false;
    }
  }

  // Like a comment
  Future<bool> likeComment(String commentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_postServiceUrl/api/comments/$commentId/like'),
        headers: headers,
      );

      print(
          '💖 Like comment response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Comment $commentId liked successfully');
        return true;
      } else {
        print(
            '❌ Failed to like comment: ${data['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('💥 Error liking comment: $e');
      return false;
    }
  }

  // Unlike a comment
  Future<bool> unlikeComment(String commentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_postServiceUrl/api/comments/$commentId/like'),
        headers: headers,
      );

      print(
          '💔 Unlike comment response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Comment $commentId unliked successfully');
        return true;
      } else {
        print(
            '❌ Failed to unlike comment: ${data['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('💥 Error unliking comment: $e');
      return false;
    }
  }

  // Toggle like on a comment
  Future<void> toggleCommentLike(String commentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_postServiceUrl/api/comments/$commentId/like'),
        headers: headers,
      );

      print(
          '🔧 Comment like toggle response: ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final isLiked = data['data']['isLiked'] ?? false;
        print('✅ Comment $commentId like toggled: $isLiked');
      } else {
        print(
            '❌ Failed to toggle comment like: ${data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('💥 Error toggling comment like: $e');
    }
  }

  // Create a new post with multipart upload support
  Future<bool> createPost({
    required String content,
    List<String>? imagePaths,
    List<String>? videoPaths, // Added video support
    String? eventId,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ No auth token available');
        return false;
      }

      print('🚀 Creating post with URL: $_postServiceUrl/api/posts');
      print('📝 Content: $content');
      print('🖼️ Images: ${imagePaths?.length ?? 0}');
      print('🎥 Videos: ${videoPaths?.length ?? 0}'); // Added video logging
      print('🎫 Event ID: $eventId');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_postServiceUrl/api/posts'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['content'] = content;
      if (eventId != null && eventId.isNotEmpty) {
        request.fields['eventId'] = eventId;
      }

      // Add image files if provided
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (int i = 0; i < imagePaths.length; i++) {
          final file = File(imagePaths[i]);
          if (await file.exists()) {
            // Determine the file extension and content type
            final extension = file.path.split('.').last.toLowerCase();
            String contentType = 'image/jpeg'; // Default
            String filename = 'image_$i.jpg'; // Default

            switch (extension) {
              case 'jpg':
              case 'jpeg':
                contentType = 'image/jpeg';
                filename = 'image_$i.jpg';
                break;
              case 'png':
                contentType = 'image/png';
                filename = 'image_$i.png';
                break;
              case 'gif':
                contentType = 'image/gif';
                filename = 'image_$i.gif';
                break;
              case 'webp':
                contentType = 'image/webp';
                filename = 'image_$i.webp';
                break;
              default:
                // Try to detect from file path or default to jpeg
                contentType = 'image/jpeg';
                filename = 'image_$i.jpg';
            }

            final multipartFile = await http.MultipartFile.fromPath(
              'images', // Backend expects 'images' field name
              file.path,
              filename: filename,
              contentType: MediaType.parse(contentType),
            );
            request.files.add(multipartFile);
            print('📎 Added image ${i + 1}: ${file.path} ($contentType)');
          }
        }
      }

      // Add video files if provided
      if (videoPaths != null && videoPaths.isNotEmpty) {
        for (int i = 0; i < videoPaths.length; i++) {
          final file = File(videoPaths[i]);
          if (await file.exists()) {
            // Determine the file extension and content type for videos
            final extension = file.path.split('.').last.toLowerCase();
            String contentType = 'video/mp4'; // Default
            String filename = 'video_$i.mp4'; // Default

            switch (extension) {
              case 'mp4':
                contentType = 'video/mp4';
                filename = 'video_$i.mp4';
                break;
              case 'mov':
                contentType = 'video/quicktime';
                filename = 'video_$i.mov';
                break;
              case 'avi':
                contentType = 'video/x-msvideo';
                filename = 'video_$i.avi';
                break;
              case 'webm':
                contentType = 'video/webm';
                filename = 'video_$i.webm';
                break;
              case 'mkv':
                contentType = 'video/x-matroska';
                filename = 'video_$i.mkv';
                break;
              default:
                // Default to mp4
                contentType = 'video/mp4';
                filename = 'video_$i.mp4';
            }

            final multipartFile = await http.MultipartFile.fromPath(
              'videos', // Backend expects 'videos' field name
              file.path,
              filename: filename,
              contentType: MediaType.parse(contentType),
            );
            request.files.add(multipartFile);
            print('📎 Added video ${i + 1}: ${file.path} ($contentType)');
          }
        }
      }

      print('📤 Sending multipart request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        // Refresh posts list to include the new post
        await loadPosts(refresh: true);
        print('✅ Post created successfully and list refreshed');
        return true;
      } else {
        print('❌ Failed to create post: ${data['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('💥 Error creating post: $e');
      return false;
    }
  }

  // Get posts for a specific user
  Future<List<ExplorePost>> getExplorePostsForUser({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('$_postServiceUrl/api/posts/explore').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'userId': userId,
        },
      );

      print('🔍 [USER_POSTS] Fetching posts for user $userId (page: $page, limit: $limit)');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['posts'] is List) {
          final postsList = data['posts'] as List;
          final posts = postsList.map((json) => ExplorePost.fromJson(json)).toList();
          print('✅ [USER_POSTS] Fetched ${posts.length} posts for user $userId');
          return posts;
        }
      }

      print('❌ [USER_POSTS] Failed to fetch posts for user $userId: ${response.statusCode}');
      return [];
    } catch (e) {
      print('💥 [USER_POSTS] Error fetching posts for user $userId: $e');
      return [];
    }
  }

  // Get a single post by ID
  Future<ExplorePost?> getPostById(String postId) async {
    try {
      final token = await _getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_postServiceUrl/api/posts/$postId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['post'] != null) {
          print('✅ [GET_POST] Fetched post $postId');
          return ExplorePost.fromJson(data['post']);
        }
      }

      print('❌ [GET_POST] Failed to fetch post $postId: ${response.statusCode}');
      return null;
    } catch (e) {
      print('💥 [GET_POST] Error fetching post $postId: $e');
      return null;
    }
  }

  // Like a post
  Future<bool> likePost(String postId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [LIKE_POST] No auth token available');
        return false;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('$_postServiceUrl/api/posts/$postId/like'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ [LIKE_POST] Liked post $postId');
          return true;
        }
      }

      print('❌ [LIKE_POST] Failed to like post $postId: ${response.statusCode}');
      return false;
    } catch (e) {
      print('💥 [LIKE_POST] Error liking post $postId: $e');
      return false;
    }
  }

  // Unlike a post
  Future<bool> unlikePost(String postId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [UNLIKE_POST] No auth token available');
        return false;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.delete(
        Uri.parse('$_postServiceUrl/api/posts/$postId/like'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ [UNLIKE_POST] Unliked post $postId');
          return true;
        }
      }

      print('❌ [UNLIKE_POST] Failed to unlike post $postId: ${response.statusCode}');
      return false;
    } catch (e) {
      print('💥 [UNLIKE_POST] Error unliking post $postId: $e');
      return false;
    }
  }
}
