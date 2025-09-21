import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/explore_post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    // Check if we've reached the maximum number of images
    const maxImages = 5;
    if (_selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
    const maxImages = 5;
    if (_selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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

  Future<void> _createPost() async {
    final content = _contentController.text.trim();

    // Validation
    if (content.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some content or images'),
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
    });

    try {
      final postService = ExplorePostService();

      // Convert selected images to paths
      List<String>? imagePaths;
      if (_selectedImages.isNotEmpty) {
        imagePaths = _selectedImages.map((file) => file.path).toList();
      }

      print('🚀 Creating post with ${imagePaths?.length ?? 0} images');

      final success = await postService.createPost(
        content: content,
        imagePaths: imagePaths,
        // TODO: Add event selection functionality
        eventId: null,
      );

      if (mounted) {
        if (success) {
          // Clear form
          _contentController.clear();
          _selectedImages.clear();

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
          SnackBar(
            content: Text('💥 Network error: Please check your connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: theme.iconTheme.color,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Post',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Post',
                    style: const TextStyle(
                      color: Color(0xFF32CD32), // Lime Green
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content Input
            _buildContentInput(),
            const SizedBox(height: 20),

            // Image Selection
            _buildImageSection(),
            const SizedBox(height: 20),

            // Image Preview
            if (_selectedImages.isNotEmpty) _buildImagePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentInput() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s on your mind?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          maxLines: 5,
          maxLength: 2000,
          onChanged: (value) {
            // Trigger rebuild to update character counter color
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'Share your thoughts, experiences, or memories...',
            hintStyle: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF32CD32), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: TextStyle(
              color: _contentController.text.length > 1800
                  ? Colors.orange
                  : _contentController.text.length > 1950
                      ? Colors.red
                      : theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            Text(
              '${_selectedImages.length}/5',
              style: TextStyle(
                fontSize: 14,
                color: _selectedImages.length >= 5
                    ? Colors.red
                    : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildImageButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: _pickImages,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImageButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: _takePhoto,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF32CD32), // Lime Green
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Images (${_selectedImages.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _selectedImages.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImages[index],
                    width: double.infinity,
                    height: double.infinity,
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
                        color: Colors.red,
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
              ],
            );
          },
        ),
      ],
    );
  }
}
