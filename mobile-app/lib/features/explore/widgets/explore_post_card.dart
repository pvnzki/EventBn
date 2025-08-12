import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/post_model.dart';

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

class _ExplorePostCardState extends State<ExplorePostCard> {
  bool _isImageLoaded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        print('👆 GestureDetector onTap triggered for post ${widget.post.id}');
        _onPostTap();
      },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUserHeader(),
            _buildContent(),
            if (widget.post.relatedEventId != null) _buildEventConnection(),
            _buildEngagementBar(),
          ],
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
                    Text(
                      widget.post.userDisplayName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
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

  Widget _buildEventConnection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          if (widget.post.relatedEventImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                widget.post.relatedEventImage!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.relatedEventName ?? '',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.post.relatedEventLocation != null)
                  Text(
                    widget.post.relatedEventLocation!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
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
          IconButton(
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
              ListTile(
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
