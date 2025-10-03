import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/post_model.dart';
import 'feed_video_player.dart'; // Import our custom video player

class ExplorePostCard extends StatefulWidget {
  final ExplorePost post;
  final int crossAxisCellCount;
  final int mainAxisCellCount;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;

  const ExplorePostCard({
    super.key,
    required this.post,
    this.crossAxisCellCount = 1,
    this.mainAxisCellCount = 2,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
  });

  @override
  State<ExplorePostCard> createState() => _ExplorePostCardState();
}

class _ExplorePostCardState extends State<ExplorePostCard>
    with TickerProviderStateMixin {
  bool _isImageLoaded = false;
  double _swipeOffset = 0.0;

  // Animation controllers for premium bookmark effects
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize bookmark animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Start subtle animations
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        print('👆 GestureDetector onTap triggered for post ${widget.post.id}');
        _onPostTap();
      },
      onPanUpdate: (details) {
        // Only track horizontal swipes (left swipe for event)
        if (details.delta.dx < 0) {
          setState(() {
            _swipeOffset += details.delta.dx;
            // Limit the swipe offset to prevent over-swiping
            _swipeOffset = _swipeOffset.clamp(-100.0, 0.0);
          });
        }
      },
      onPanEnd: (details) {
        // If swiped left more than 50 pixels and has event, navigate to event
        if (_swipeOffset < -50 && _hasEvent()) {
          _onGoToEventWithAnimation();
        }

        // Reset swipe offset
        setState(() {
          _swipeOffset = 0.0;
        });
      },
      child: Transform.translate(
        offset: Offset(_swipeOffset, 0),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main post content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUserHeader(),
                  _buildContent(),
                  // Remove the large event connection from here
                  _buildEngagementBar(),
                ],
              ),
              // Event bookmark at top right
              if (widget.post.relatedEventId != null)
                _buildEventBookmark()
              else if (widget.post.id == "1")
                _buildDemoEventBookmark(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Hero(
            tag: 'user_avatar_${widget.post.userId}',
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.post.userAvatarUrl),
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        print('👤 Navigating to user profile: ${widget.post.userId}');
                        context.push('/user/${widget.post.userId}');
                      },
                      child: Text(
                        widget.post.userDisplayName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (widget.post.isUserVerified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                Text(
                  widget.post.timeAgo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (widget.post.isSponsored)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Sponsored',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 10,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            iconSize: 16,
            onPressed: () => _showPostOptions(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.post.content.isNotEmpty) _buildTextContent(),
        if (widget.post.imageUrls.isNotEmpty) _buildImages(),
        if (widget.post.videoUrls.isNotEmpty) _buildVideos(), // Added video support
        _buildPostType(),
      ],
    );
  }

  Widget _buildTextContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        widget.post.content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          height: 1.4,
        ),
        maxLines: widget.mainAxisCellCount > 2 ? 6 : 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildImages() {
    if (widget.post.imageUrls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: widget.post.imageUrls.length == 1
          ? _buildSingleImage()
          : _buildMultipleImages(),
    );
  }

  Widget _buildSingleImage() {
    // Calculate appropriate height based on cell count for varying aspect ratios
    final imageHeight = widget.mainAxisCellCount == 1
        ? 100.0
        : widget.mainAxisCellCount == 2
            ? 140.0
            : 180.0;

    return SizedBox(
      height: imageHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.post.imageUrls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _isImageLoaded = true);
              });
              return AnimatedOpacity(
                opacity: _isImageLoaded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: child,
              );
            }
            return Container(
              height: imageHeight,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: imageHeight,
              color: Theme.of(context).colorScheme.errorContainer,
              child: Icon(
                Icons.broken_image,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMultipleImages() {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.post.imageUrls.first,
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.post.imageUrls[1],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                if (widget.post.imageUrls.length > 2) ...[
                  const SizedBox(height: 4),
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.post.imageUrls[2],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        if (widget.post.imageUrls.length > 3)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '+${widget.post.imageUrls.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideos() {
    if (widget.post.videoUrls.isEmpty) return const SizedBox.shrink();

    print('🎬 [PostCard] Building videos section. Video count: ${widget.post.videoUrls.length}');
    print('🎬 [PostCard] Video URLs: ${widget.post.videoUrls}');
    print('🎬 [PostCard] Video thumbnails: ${widget.post.videoThumbnails}');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: widget.post.videoUrls.length == 1
          ? _buildSingleVideo(widget.post.videoUrls.first)
          : _buildMultipleVideos(),
    );
  }

  Widget _buildSingleVideo(String videoUrl) {
    print('🎬 [PostCard] Building single video for URL: $videoUrl');
    return FeedVideoPlayer(
      videoUrl: videoUrl,
      autoPlay: false, // Don't autoplay in feed to save bandwidth
      showControls: true, // Show controls so users can play
      aspectRatio: 16/9, // Set consistent aspect ratio
    );
  }

  Widget _buildMultipleVideos() {
    return Container(
      height: 200,
      child: Row(
        children: [
          // First video (larger)
          Expanded(
            flex: 2,
            child: _buildVideoThumbnail(widget.post.videoUrls.first),
          ),
          const SizedBox(width: 4),
          // Other videos (smaller)
          Expanded(
            child: Column(
              children: [
                if (widget.post.videoUrls.length > 1)
                  Expanded(
                    child: _buildVideoThumbnail(widget.post.videoUrls[1]),
                  ),
                if (widget.post.videoUrls.length > 2) ...[
                  const SizedBox(height: 4),
                  Expanded(
                    child: Stack(
                      children: [
                        _buildVideoThumbnail(widget.post.videoUrls[2]),
                        if (widget.post.videoUrls.length > 3)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '+${widget.post.videoUrls.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnail(String videoUrl) {
    // Try to get thumbnail from videoThumbnails array if available
    String? thumbnailUrl;
    if (widget.post.videoThumbnails.isNotEmpty) {
      // Find corresponding thumbnail for this video URL
      final videoIndex = widget.post.videoUrls.indexOf(videoUrl);
      if (videoIndex >= 0 && videoIndex < widget.post.videoThumbnails.length) {
        thumbnailUrl = widget.post.videoThumbnails[videoIndex];
      }
    }
    
    return GestureDetector(
      onTap: () => _openVideoPlayer(videoUrl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black87,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Show thumbnail if available, otherwise show placeholder
              if (thumbnailUrl != null)
                Image.network(
                  thumbnailUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black87,
                      child: const Icon(
                        Icons.video_library_outlined,
                        color: Colors.white70,
                        size: 24,
                      ),
                    );
                  },
                )
              else
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black87,
                  child: const Icon(
                    Icons.video_library_outlined,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              // Play button overlay
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVideoPlayer(String videoUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Container(
            width: double.infinity,
            height: 300,
            child: FeedVideoPlayer(
              videoUrl: videoUrl,
              autoPlay: true,
              showControls: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostType() {
    final theme = Theme.of(context);

    Color badgeColor;
    IconData badgeIcon;

    switch (widget.post.postType) {
      case PostType.eventInterest:
        badgeColor = Colors.orange;
        badgeIcon = Icons.favorite;
        break;
      case PostType.eventReview:
        badgeColor = Colors.blue;
        badgeIcon = Icons.star;
        break;
      case PostType.eventMoment:
        badgeColor = Colors.green;
        badgeIcon = Icons.camera_alt;
        break;
      case PostType.eventPromotion:
        badgeColor = Colors.purple;
        badgeIcon = Icons.campaign;
        break;
      case PostType.eventQuestion:
        badgeColor = Colors.amber;
        badgeIcon = Icons.help;
        break;
      case PostType.eventMemory:
        badgeColor = Colors.pink;
        badgeIcon = Icons.photo_album;
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badgeIcon,
              size: 12,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
            Text(
              widget.post.postTypeDisplayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBookmark() {
    return Positioned(
      top: 120,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: GestureDetector(
              onTap: () => _onGoToEventWithAnimation(),
              child: Container(
                width: 95,
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                  ),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF84cc16), // lime-500
                      Color(0xFF65a30d), // lime-600
                      Color(0xFF4d7c0f), // lime-700
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF84cc16).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(-4, 3),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(-2, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Shimmer effect overlay
                    AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              bottomLeft: Radius.circular(28),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                  begin: Alignment(
                                      -1.0 + _shimmerAnimation.value, -0.5),
                                  end: Alignment(
                                      1.0 + _shimmerAnimation.value, 0.5),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Main content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.event,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Flexible(
                            child: Text(
                              widget.post.relatedEventName
                                      ?.split(' ')
                                      .take(2)
                                      .join('\n') ??
                                  'Event',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDemoEventBookmark() {
    return Positioned(
      top: 120,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                            '🎪 Demo: Premium Event bookmark! Create posts with events to see real connections.'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF84cc16),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              child: Container(
                width: 95,
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                  ),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFfbbf24), // amber-400
                      Color(0xFFf59e0b), // amber-500
                      Color(0xFFd97706), // amber-600
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFfbbf24).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(-4, 3),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(-2, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Shimmer effect overlay
                    AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              bottomLeft: Radius.circular(28),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                  begin: Alignment(
                                      -1.0 + _shimmerAnimation.value, -0.5),
                                  end: Alignment(
                                      1.0 + _shimmerAnimation.value, 0.5),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Main content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Flexible(
                            child: Text(
                              'Demo\nEvent',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventConnection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onGoToEvent(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF32CD32).withOpacity(0.1),
                  const Color(0xFF228B22).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF32CD32).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: widget.post.relatedEventImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.post.relatedEventImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.event,
                          color: Color(0xFF32CD32),
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.relatedEventName ?? 'Related Event',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (widget.post.relatedEventLocation != null)
                        Text(
                          widget.post.relatedEventLocation!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.post.relatedEventDate != null)
                        Text(
                          _formatEventDate(widget.post.relatedEventDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF32CD32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Go to Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Demo event connection for testing the UI when no real events are linked
  Widget _buildDemoEventConnection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '🎪 Demo: Go to Event functionality works! Create a post with an event to see real connections.'),
                backgroundColor: Color(0xFF32CD32),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B6B).withOpacity(0.1),
                  const Color(0xFFFF4757).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Color(0xFFFF6B6B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Event Connection',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF6B6B),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Demo Location • Demo Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Demo Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  void _onGoToEvent() {
    if (widget.post.relatedEventId != null) {
      print('🎫 Navigating to event: ${widget.post.relatedEventId}');
      context.push('/events/${widget.post.relatedEventId}');
    }
  }

  bool _hasEvent() {
    return widget.post.relatedEventId != null || widget.post.id == "1";
  }

  void _onGoToEventWithAnimation() {
    if (widget.post.relatedEventId != null) {
      print(
          '🎫 [ANIMATION] Navigating to event with slide: ${widget.post.relatedEventId}');

      // Add a small scale animation to the bookmark
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        // Create a subtle feedback animation
        HapticFeedback.lightImpact();
      }

      // Navigate with custom slide transition
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            // Import the event details screen when available
            // For now, we'll use context.push as fallback
            context.push('/events/${widget.post.relatedEventId}');
            return Container(); // Placeholder
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0); // Slide from right
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  Widget _buildEngagementBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildEngagementButton(
            icon: widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
            count: widget.post.likesCount,
            color:
                widget.post.isLiked ? Colors.red : colorScheme.onSurfaceVariant,
            onTap: widget.onLike,
          ),
          const SizedBox(width: 16),
          _buildEngagementButton(
            icon: Icons.mode_comment_outlined,
            count: widget.post.commentsCount,
            color: colorScheme.onSurfaceVariant,
            onTap: widget.onComment,
          ),
          const SizedBox(width: 16),
          _buildEngagementButton(
            icon: Icons.share_outlined,
            count: widget.post.sharesCount,
            color: colorScheme.onSurfaceVariant,
            onTap: widget.onShare,
          ),
          const Spacer(),
          // Optimized "Go to Event" button for better space efficiency
          widget.post.relatedEventId != null
              ? GestureDetector(
                  onTap: _onGoToEventWithAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, // Reduced from 8
                      vertical: 3,   // Reduced from 4
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10), // Reduced from 12
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event,
                          size: 14, // Reduced from 16
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 3), // Reduced from 4
                        Text(
                          'Event', // Shortened from 'Go to Event'
                          style: TextStyle(
                            fontSize: 11, // Reduced from 12
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    widget.post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: widget.post.isBookmarked
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  iconSize: 18,
                  onPressed: widget.onBookmark,
                ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            _formatCount(count),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  void _onPostTap() {
    // Navigate to post detail screen
    print('🎯 Post tapped! Post ID: ${widget.post.id}');
    print('🚀 Navigating to: /explore/post/${widget.post.id}');
    try {
      context.push('/explore/post/${widget.post.id}');
      print('✅ Navigation call successful');
    } catch (e) {
      print('❌ Navigation failed: $e');
    }
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(
              bottom: 90), // Account for bottom nav height + padding
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show "Go to Event" option if post has related event, otherwise show bookmark
              widget.post.relatedEventId != null
                  ? ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Go to Event'),
                      onTap: () {
                        Navigator.pop(context);
                        _onGoToEventWithAnimation();
                      },
                    )
                  : ListTile(
                      leading: const Icon(Icons.bookmark_border),
                      title: const Text('Save Post'),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onBookmark?.call();
                      },
                    ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onShare?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
