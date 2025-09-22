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
    return prefs.getString(AppConfig.tokenKey);
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

      print('🌐 Making request to: $uri');
      print('📤 Request headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> postsJson = data['posts'] ?? [];
        final newPosts =
            postsJson.map((json) => ExplorePost.fromJson(json)).toList();

        if (refresh) {
          _posts.clear();
        }
        _posts.addAll(newPosts);

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

        _posts.addAll(newPosts);

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
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_postServiceUrl/posts/$postId/like'),
        headers: headers,
      );

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
        }
      } else {
        print('Failed to toggle like: ${data['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error toggling like: $e');
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

  // Create a new post with multipart upload support
  Future<bool> createPost({
    required String content,
    List<String>? imagePaths,
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
}
