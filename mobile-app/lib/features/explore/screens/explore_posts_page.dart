import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../common_widgets/app_colors.dart';
import '../models/post_model.dart';
import '../services/explore_post_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Explore screen — Vertical social-media feed
// Matches Figma node 40000070:4428
// ─────────────────────────────────────────────────────────────────────────────

class ExplorePostsPage extends StatefulWidget {
  const ExplorePostsPage({super.key});

  @override
  State<ExplorePostsPage> createState() => _ExplorePostsPageState();
}

class _ExplorePostsPageState extends State<ExplorePostsPage>
    with AutomaticKeepAliveClientMixin {
  final ExplorePostService _postService = ExplorePostService();
  bool _isInitialized = false;

  // Track liked state locally per post id
  final Set<String> _likedPosts = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
  }

  Future<void> _loadInitialPosts() async {
    await _postService.loadPosts(refresh: true);
    if (mounted) {
      // Seed initial liked state from service
      for (final p in _postService.posts) {
        if (p.isLiked) _likedPosts.add(p.id);
      }
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _loadMorePosts() async {
    await _postService.loadMorePosts();
    if (mounted) setState(() {});
  }

  Future<void> _refreshPosts() async {
    await _postService.loadPosts(refresh: true);
    if (mounted) setState(() {});
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Safe-area + title
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 22,
              bottom: 14,
            ),
            child: Text(
              'Explore',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.dark,
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Feed
          Expanded(
            child: !_isInitialized
                ? _buildShimmerFeed(isDark)
                : RefreshIndicator(
                    onRefresh: _refreshPosts,
                    color: AppColors.primary,
                    child: _buildFeed(isDark),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Feed list ──────────────────────────────────────────────────────────────
  Widget _buildFeed(bool isDark) {
    final posts = _postService.posts;

    if (posts.isEmpty && !_postService.isLoading) {
      return _buildEmptyState(isDark);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (info) {
        if (info is ScrollEndNotification &&
            info.metrics.extentAfter < 800 &&
            _postService.hasMoreData &&
            !_postService.isLoading) {
          _loadMorePosts();
        }
        return false;
      },
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: posts.length + (_postService.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= posts.length) return _buildLoadingIndicator();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _ExplorePostCard(
              post: posts[index],
              isDark: isDark,
              isLiked: _likedPosts.contains(posts[index].id),
              onLikeToggle: () => _toggleLike(posts[index]),
              onGoToEvent: () => _navigateToEvent(posts[index]),
              onTap: () => context.push('/explore/igtv/${posts[index].id}'),
            ),
          );
        },
      ),
    );
  }

  void _toggleLike(ExplorePost post) {
    setState(() {
      if (_likedPosts.contains(post.id)) {
        _likedPosts.remove(post.id);
      } else {
        _likedPosts.add(post.id);
      }
    });
  }

  void _navigateToEvent(ExplorePost post) {
    if (post.relatedEventId != null) {
      context.push('/events/${post.relatedEventId}');
    }
  }

  // ── Loading / shimmer ──────────────────────────────────────────────────────
  Widget _buildShimmerFeed(bool isDark) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Shimmer.fromColors(
          baseColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300]!,
          highlightColor:
              isDark ? const Color(0xFF3A3A3A) : Colors.grey[100]!,
          child: Container(
            height: 295,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off_rounded,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single post card — matches Figma "Post 1" node (40000074:4441)
// ─────────────────────────────────────────────────────────────────────────────
class _ExplorePostCard extends StatefulWidget {
  final ExplorePost post;
  final bool isDark;
  final bool isLiked;
  final VoidCallback onLikeToggle;
  final VoidCallback onGoToEvent;
  final VoidCallback onTap;

  const _ExplorePostCard({
    required this.post,
    required this.isDark,
    required this.isLiked,
    required this.onLikeToggle,
    required this.onGoToEvent,
    required this.onTap,
  });

  @override
  State<_ExplorePostCard> createState() => _ExplorePostCardState();
}

class _ExplorePostCardState extends State<_ExplorePostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  // Convenience getters to avoid `widget.` everywhere
  ExplorePost get post => widget.post;
  bool get isDark => widget.isDark;
  bool get isLiked => widget.isLiked;
  VoidCallback get onLikeToggle => widget.onLikeToggle;
  VoidCallback get onGoToEvent => widget.onGoToEvent;
  VoidCallback get onTap => widget.onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? const Color(0xFF181818).withValues(alpha: 0.3)
        : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF252525)
        : Colors.grey.shade200;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) { _scaleCtrl.reverse(); onTap(); },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area with overlays ─────────────────────────────
            _buildImageArea(context),
            // ── Text area below image ────────────────────────────────
            _buildTextArea(),
          ],
        ),
      ),
      ),
    );
  }

  // ── Image area ─────────────────────────────────────────────────────────────
  Widget _buildImageArea(BuildContext context) {
    // Pick best image URL
    final imageUrl = post.imageUrls.isNotEmpty
        ? post.imageUrls.first
        : (post.videoThumbnails.isNotEmpty
            ? post.videoThumbnails.first.replaceFirst('http://', 'https://')
            : '');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Event image ──────────────────────────────────────────
            if (imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                ),
                errorWidget: (_, __, ___) => Container(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey, size: 40),
                ),
              )
            else
              Container(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey, size: 40),
              ),

            // ── Subtle top gradient for organizer + menu visibility ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Subtle bottom gradient for engagement icons + pill ───
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Organizer info (top-left) ────────────────────────────
            Positioned(
              top: 10,
              left: 12,
              child: _buildOrganizerBadge(),
            ),

            // ── Three-dot menu (top-right) ───────────────────────────
            Positioned(
              top: 4,
              right: 4,
              child: _buildMenuButton(context),
            ),

            // ── "Go to Event" pill (bottom-left) ─────────────────────
            Positioned(
              bottom: 10,
              left: 8,
              child: _buildGoToEventPill(),
            ),

            // ── Comment + Like icons (bottom-right) ──────────────────
            Positioned(
              bottom: 8,
              right: 8,
              child: _buildEngagementIcons(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Organizer badge ────────────────────────────────────────────────────────
  Widget _buildOrganizerBadge() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
          ),
          child: ClipOval(
            child: post.userAvatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: post.userAvatarUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey[700],
                      child: const Icon(Icons.person,
                          size: 16, color: Colors.white54),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[700],
                      child: const Icon(Icons.person,
                          size: 16, color: Colors.white54),
                    ),
                  )
                : Container(
                    color: Colors.grey[700],
                    child: Center(
                      child: Text(
                        post.userDisplayName.isNotEmpty
                            ? post.userDisplayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        // Name + "Organizer"
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.userDisplayName,
              style: const TextStyle(
                fontFamily: kFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFCFCFD),
                shadows: [
                  Shadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const Text(
              'Organizer',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8C9097),
                shadows: [
                  Shadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Three-dot menu ─────────────────────────────────────────────────────────
  Widget _buildMenuButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showPostMenu(context),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF181818).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF181818) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _menuTile(Icons.share_outlined, 'Share', () {
              Navigator.pop(context);
            }),
            _menuTile(Icons.bookmark_border_rounded, 'Save Post', () {
              Navigator.pop(context);
            }),
            _menuTile(Icons.flag_outlined, 'Report', () {
              Navigator.pop(context);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon,
          color: isDark ? Colors.white70 : Colors.black87, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  // ── "Go to Event" pill button ──────────────────────────────────────────────
  Widget _buildGoToEventPill() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onGoToEvent,
      child: Container(
        height: 38,
        padding: const EdgeInsets.only(left: 4, right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // EventBn logo
            SizedBox(
              width: 28,
              height: 28,
              child: Image.asset(
                'assets/images/New Eventbn Logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Go to Event',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Comment + Like engagement icons ────────────────────────────────────────
  Widget _buildEngagementIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Comment icon + superscript count
        _buildIconWithCount(
          onTap: () {}, // TODO: open comments
          icon: Image.asset(
            'assets/icons/explore/comment.png',
            width: 28,
            height: 28,
            color: Colors.white,
          ),
          count: post.commentsCount,
          color: Colors.white,
        ),
        const SizedBox(width: 14),
        // Like (heart) icon + superscript count
        _buildIconWithCount(
          onTap: onLikeToggle,
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            size: 28,
            color: isLiked ? Colors.redAccent : Colors.white,
          ),
          count: isLiked ? post.likesCount + 1 : post.likesCount,
          color: Colors.white,
        ),
      ],
    );
  }

  /// Icon with a small superscript count at top-right. Fixed layout so the
  /// container never shifts.
  Widget _buildIconWithCount({
    required VoidCallback onTap,
    required Widget icon,
    required int count,
    required Color color,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Icon centred at bottom-left area
            Positioned(
              left: 0,
              bottom: 0,
              child: icon,
            ),
            // Superscript count pinned at top-right
            if (count > 0)
              Positioned(
                right: -2,
                bottom: 0,
                child: Text(
                  _formatCount(count),
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                    height: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Text area below the image ──────────────────────────────────────────────
  Widget _buildTextArea() {
    final nameColor = isDark ? const Color(0xFFFCFCFD) : AppColors.dark;
    final bodyColor = isDark ? const Color(0xFF8C9097) : Colors.grey[600]!;
    final hashtagColor =
        isDark ? const Color(0xFFA3A7AC) : Colors.blueGrey[600]!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author name
          Text(
            post.userDisplayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: nameColor,
            ),
          ),
          const SizedBox(height: 4),
          // Post content with hashtags
          _buildRichContent(bodyColor, hashtagColor),
        ],
      ),
    );
  }

  Widget _buildRichContent(Color bodyColor, Color hashtagColor) {
    final content = post.content;
    const maxLen = 120;
    final truncated = content.length > maxLen;
    final displayText = truncated ? content.substring(0, maxLen) : content;

    // Split content into normal text and hashtags
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(#\w+)');
    int lastEnd = 0;
    for (final match in regex.allMatches(displayText)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: displayText.substring(lastEnd, match.start),
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: bodyColor,
            height: 1.35,
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: hashtagColor,
          height: 1.35,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < displayText.length) {
      spans.add(TextSpan(
        text: displayText.substring(lastEnd),
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: bodyColor,
          height: 1.35,
        ),
      ));
    }
    if (truncated) {
      spans.add(TextSpan(
        text: ' ...More',
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: bodyColor,
          height: 1.35,
        ),
      ));
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
