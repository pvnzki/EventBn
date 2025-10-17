import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
// Added for video support
import 'dart:io';
import '../services/explore_post_service.dart';
import '../widgets/smart_event_picker.dart';
import '../../events/services/event_service.dart';
import '../../events/models/event_model.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  final List<File> _selectedVideos = []; // Added for video support
  bool _isLoading = false;
  double _uploadProgress = 0.0; // Added for progress tracking
  String _uploadStatus = ''; // Added for status messages
  final ImagePicker _picker = ImagePicker();

  // Event selection state
  String? _selectedEventId;
  String? _selectedEventName;
  List<Event> _availableEvents = [];
  final EventService _eventService = EventService();

  // User data state
  User? _currentUser;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      print('🔍 [CreatePost] Loading current user...');
      final user = await _authService.getCurrentUser();
      print(
          '🔍 [CreatePost] User loaded: ${user?.firstName} ${user?.lastName}');
      setState(() {
        _currentUser = user;
      });

      if (user == null) {
        print('⚠️ [CreatePost] User is null - backend might not be running');
        print('🔧 [CreatePost] Creating fallback user for testing');
        // Create a fallback user for testing when backend is not available
        setState(() {
          _currentUser = User(
            id: '1001',
            firstName: 'Test',
            lastName: 'User',
            email: 'test@example.com',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });
      }
    } catch (e) {
      print('❌ [CreatePost] Error loading current user: $e');
      print('🔧 [CreatePost] Creating fallback user for testing');
      // Set a fallback user for UI testing
      setState(() {
        _currentUser = User(
          id: '1001',
          firstName: 'Test',
          lastName: 'User',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    // Check if we've reached the maximum number of images
    const maxImages = 10;
    if (_selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum $maxImages images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        // Calculate how many more images we can add
        final remainingSlots = maxImages - _selectedImages.length;
        final imagesToAdd = images.take(remainingSlots).toList();

        setState(() {
          _selectedImages.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
        });

        // Show warning if we had to limit the selection
        if (images.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Only added ${imagesToAdd.length} images (max $maxImages total)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    // Check if we've reached the maximum number of images
    const maxImages = 10;
    if (_selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum $maxImages images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Video picking methods
  Future<void> _pickVideo() async {
    const maxVideos = 5; // Limit videos for performance
    if (_selectedVideos.length >= maxVideos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 videos allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // 5 minute limit
      );

      if (video != null) {
        setState(() {
          _selectedVideos.add(File(video.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
      );
    }
  }

  Future<void> _recordVideo() async {
    const maxVideos = 5;
    if (_selectedVideos.length >= maxVideos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 videos allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        setState(() {
          _selectedVideos.add(File(video.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording video: $e')),
      );
    }
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
  }

  bool _canPost() {
    return _contentController.text.trim().isNotEmpty ||
        _selectedImages.isNotEmpty ||
        _selectedVideos.isNotEmpty; // Updated to include videos
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _eventService.getAllEvents();
      setState(() {
        _availableEvents = events;
      });
    } catch (e) {
      print('Error loading events: $e');
      // Don't show error to user, just continue without events
    }
  }

  void _showEventPicker() async {
    // Preload events in background before showing picker
    SmartEventPicker.preloadEvents(() => _loadEventsForPicker());

    final result = await SmartEventPicker.show(
      context: context,
      eventLoader: () => _loadEventsForPicker(),
      selectedEventId: _selectedEventId,
    );

    if (result != null) {
      if (result['action'] == 'clear') {
        _clearSelectedEvent();
      } else if (result['action'] == 'select') {
        setState(() {
          _selectedEventId = result['id'];
          _selectedEventName = result['name'];
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadEventsForPicker() async {
    try {
      await _loadEvents(); // Load events using existing method
      return _availableEvents
          .map((event) => {
                'id': event.id,
                'name': event.title, // Use title instead of name
                'description': event.description,
                'date': event.startDateTime
                    .toString(), // Use startDateTime instead of startDate
              })
          .toList();
    } catch (e) {
      print('❌ [CREATE_POST] Failed to load events for picker: $e');
      return [];
    }
  }

  void _clearSelectedEvent() {
    setState(() {
      _selectedEventId = null;
      _selectedEventName = null;
    });
  }

  Widget _buildEventPickerModal() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
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
                  'Link to Event',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Events list
          Expanded(
            child: _availableEvents.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading events...'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _availableEvents.length,
                    itemBuilder: (context, index) {
                      final event = _availableEvents[index];
                      final isSelected = _selectedEventId == event.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              _selectedEventId = event.id;
                              _selectedEventName = event.title;
                            });
                            Navigator.pop(context);
                          },
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: event.imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(event.imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: event.imageUrl.isEmpty
                                  ? (isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.grey[300])
                                  : null,
                            ),
                            child: event.imageUrl.isEmpty
                                ? Icon(Icons.event,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600])
                                : null,
                          ),
                          title: Text(
                            event.title,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Text(
                            '${event.venue} • ${_formatEventDate(event.startDateTime)}',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF32CD32))
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  Future<void> _createPost() async {
    final content = _contentController.text.trim();

    // Validation - updated to include videos
    if (content.isEmpty && _selectedImages.isEmpty && _selectedVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some content, images, or videos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Additional validation for content length
    if (content.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post content is too long (max 2000 characters)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      final postService = ExplorePostService();

      // Convert selected images to paths
      List<String>? imagePaths;
      if (_selectedImages.isNotEmpty) {
        imagePaths = _selectedImages.map((file) => file.path).toList();
        setState(() {
          _uploadStatus = 'Processing ${imagePaths!.length} image(s)...';
          _uploadProgress = 0.2;
        });
      }

      // Convert selected videos to paths
      List<String>? videoPaths;
      if (_selectedVideos.isNotEmpty) {
        videoPaths = _selectedVideos.map((file) => file.path).toList();
        setState(() {
          _uploadStatus =
              'Processing ${videoPaths!.length} video(s)... This may take a moment.';
          _uploadProgress = 0.4;
        });
      }

      print(
          '🚀 Creating post with ${imagePaths?.length ?? 0} images and ${videoPaths?.length ?? 0} videos');

      setState(() {
        _uploadStatus = 'Uploading to server...';
        _uploadProgress = 0.7;
      });

      final success = await postService.createPost(
        content: content,
        imagePaths: imagePaths,
        videoPaths: videoPaths, // Added video paths
        eventId: _selectedEventId, // Pass the selected event ID
      );

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Finalizing...';
      });

      if (mounted) {
        if (success) {
          // Clear form - updated to include videos
          _contentController.clear();
          _selectedImages.clear();
          _selectedVideos.clear(); // Clear videos too
          _selectedEventId = null;
          _selectedEventName = null;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Post created successfully!'),
              backgroundColor: Color(0xFF32CD32),
              duration: Duration(seconds: 2),
            ),
          );
          context.pop(true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to create post. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        print('💥 Error in _createPost: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💥 Network error: Please check your connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color:
                  theme.appBarTheme.foregroundColor ?? theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'New Post',
          style: TextStyle(
            color: theme.appBarTheme.titleTextStyle?.color ??
                theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: TextButton(
              onPressed: _isLoading ? null : _createPost,
              style: TextButton.styleFrom(
                backgroundColor: _canPost() && !_isLoading
                    ? const Color(0xFF32CD32)
                    : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Share',
                      style: TextStyle(
                        color: _canPost() && !_isLoading
                            ? Colors.white
                            : (isDarkMode ? Colors.grey[400] : Colors.grey),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _buildProfileSection(),

                  // Content Input
                  _buildContentInput(),

                  // Event Selection
                  _buildEventSection(),

                  // Media Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildMediaSection(),
                  ),

                  // Image Preview
                  if (_selectedImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildImagePreview(),
                    ),

                  // Progress Bar for Upload
                  if (_isLoading) _buildUploadProgress(),

                  const SizedBox(height: 80), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              border: Border.all(
                  color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                  width: 1),
              image: _currentUser?.profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_currentUser!.profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _currentUser?.profileImageUrl == null
                ? Icon(
                    Icons.person,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Username only (removed location section)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser != null
                      ? (_currentUser!.firstName.isNotEmpty &&
                              _currentUser!.lastName.isNotEmpty
                          ? '${_currentUser!.firstName} ${_currentUser!.lastName}'
                          : _currentUser!.firstName.isNotEmpty
                              ? _currentUser!.firstName
                              : 'User')
                      : 'Guest User', // Better fallback when user data isn't available
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),

          // Privacy Settings
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.public,
                  size: 16,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                const SizedBox(width: 4),
                Text(
                  'Public',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        maxLength: 2000,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'What\'s happening?',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            fontSize: 18,
          ),
          border: InputBorder.none,
          counterText: '', // Hide character counter
        ),
        style: TextStyle(
          fontSize: 18,
          height: 1.4,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildEventSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _showEventPicker,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: _selectedEventId != null
                        ? const Color(0xFF32CD32)
                        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedEventId != null && _selectedEventName != null
                          ? 'Event: $_selectedEventName'
                          : 'Link to an event (optional)',
                      style: TextStyle(
                        color: _selectedEventId != null
                            ? theme.textTheme.bodyLarge?.color
                            : (isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                        fontSize: 14,
                        fontWeight: _selectedEventId != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (_selectedEventId != null)
                    GestureDetector(
                      onTap: _clearSelectedEvent,
                      child: Icon(
                        Icons.close,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 18,
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      children: [
        // First row - Photos
        Row(
          children: [
            Expanded(
              child: _buildMediaButton(
                icon: Icons.photo_library_outlined,
                label: 'Photos',
                color: Colors.blue,
                onTap: _pickImages,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMediaButton(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                color: Colors.green,
                onTap: _takePhoto,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - Videos
        Row(
          children: [
            Expanded(
              child: _buildMediaButton(
                icon: Icons.videocam_outlined,
                label: 'Video Gallery',
                color: Colors.purple,
                onTap: _pickVideo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMediaButton(
                icon: Icons.video_call_outlined,
                label: 'Record Video',
                color: Colors.orange,
                onTap: _recordVideo,
              ),
            ),
          ],
        ),
        // Image selection status
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.photo_library, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_selectedImages.length} photo${_selectedImages.length == 1 ? '' : 's'} selected',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedImages.length}/10',
                  style: TextStyle(
                    color: _selectedImages.length >= 10
                        ? Colors.red
                        : Colors.blue[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        // Video selection status
        if (_selectedVideos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.videocam, color: Colors.purple[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_selectedVideos.length} video${_selectedVideos.length == 1 ? '' : 's'} selected',
                  style: TextStyle(
                    color: Colors.purple[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedVideos.length}/5',
                  style: TextStyle(
                    color: _selectedVideos.length >= 5
                        ? Colors.red
                        : Colors.purple[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImages[index],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    if (index == 0 && _selectedImages.length > 1)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _uploadStatus,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.blue[100],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            '${(_uploadProgress * 100).toInt()}% complete',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
