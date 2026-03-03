import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../providers/event_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/design_tokens.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/event_details_skeleton_loading.dart';
import '../../../common_widgets/app_bottom_sheet.dart';
import '../../explore/services/explore_post_service.dart';
import '../../explore/models/post_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Event Details Screen — Figma node 2131:21654
//
//  Upgraded layout with card-style sections:
//    1. Hero (video / photo) with frosted-glass back / love / share buttons
//    2. Date+Time / Price row
//    3. Organizer card with rating
//    4. "Detail concert" card (about with read-more)
//    5. Posts card (horizontal scroll, dummy data for now)
//    6. Map card
//    7. Fixed "Book Now" button at bottom
//
//  Header video/photo implementation kept from existing codebase.
// ═══════════════════════════════════════════════════════════════════════════════

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  final bool isGuestMode;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.isGuestMode = false,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool isVideoExpanded = false;
  // Video player
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _userPausedVideo = false;

  // Attendees
  List<dynamic> attendees = [];
  bool _attendeesLoading = true;
  final EventService _eventService = EventService();

  // State variables
  bool isAboutExpanded = false;
  bool _isLiked = false;

  // Collapse tracking for title in pinned header (ValueNotifier avoids full rebuild)
  final ValueNotifier<bool> _isCollapsedNotifier = ValueNotifier(false);

  // Scroll controller for reliable video pause/play & collapse detection
  final ScrollController _scrollController = ScrollController();
  double? _collapseThreshold;

  // Seat map cache
  bool? _hasCustomSeating;
  bool _seatMapLoaded = false;
  List<dynamic> _seatMapData = [];

  // Posts pagination
  final ExplorePostService _postService = ExplorePostService();
  List<ExplorePost> _eventPosts = [];
  bool _postsLoading = true;
  bool _hasMorePosts = true;
  int _postPage = 1;
  bool _postsLoadingMore = false;
  final ScrollController _postsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _postsScrollController.addListener(_onPostsScroll);
    Future.microtask(() {
      Provider.of<EventProvider>(context, listen: false)
          .fetchEventById(widget.eventId);
      _fetchAttendees();
      _loadSeatMapInfo();
      _fetchEventPosts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Video controller lifecycle — driven by provider changes, not build()
    final event = Provider.of<EventProvider>(context).currentEvent;
    // Guard: only initialise the video when the provider holds the event
    // that THIS screen requested.  Without this check a stale event left
    // over from the previous screen would briefly start its video.
    if (event != null && event.id.toString() != widget.eventId) return;
    _ensureVideoController(event);
  }

  @override
  void deactivate() {
    // Immediately silence & pause video when this route is popped / replaced.
    // deactivate() fires before dispose(), preventing audio bleed into the
    // next screen while the old widget tree is still tearing down.
    if (_videoController != null) {
      _videoController!.setVolume(0);
      _videoController!.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _postsScrollController.removeListener(_onPostsScroll);
    _postsScrollController.dispose();
    _isCollapsedNotifier.dispose();
    // Volume already silenced in deactivate(); safe to dispose now.
    _videoController?.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Scroll handler — video pause/play + collapse detection
  // ══════════════════════════════════════════════════════════════════════════

  void _onScroll() {
    final pixels = _scrollController.position.pixels;

    // Collapse threshold: hero fully collapsed
    _collapseThreshold ??=
        326 - kToolbarHeight - MediaQuery.of(context).padding.top;
    final collapsed = pixels >= _collapseThreshold!;
    if (collapsed != _isCollapsedNotifier.value) {
      _isCollapsedNotifier.value = collapsed;
    }

    // Video auto-pause when scrolled past hero area
    if (_videoController != null && _videoInitialized) {
      if (pixels > 250) {
        if (_videoController!.value.isPlaying) {
          _videoController?.pause();
        }
      } else if (!_videoController!.value.isPlaying && !_userPausedVideo) {
        _videoController?.play();
      }
    }

    // Collapse fullscreen video overlay on any scroll
    if (isVideoExpanded && pixels > 10) {
      setState(() => isVideoExpanded = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Data loading
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadSeatMapInfo() async {
    try {
      final url = '${AppConfig.baseUrl}/api/events/${widget.eventId}/seatmap';
      final authService = AuthService();
      final token = await authService.getStoredToken();

      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final seatMapData = responseData['data'];

        setState(() {
          _hasCustomSeating = seatMapData['hasCustomSeating'] == true;
          _seatMapData = seatMapData['seats'] ?? [];
          _seatMapLoaded = true;
        });
      } else {
        setState(() => _seatMapLoaded = true);
      }
    } catch (e) {
      setState(() => _seatMapLoaded = true);
    }
  }

  Future<void> _fetchAttendees() async {
    try {
      final response = await _eventService.getEventAttendees(widget.eventId);
      if (mounted) {
        setState(() {
          attendees = response;
          _attendeesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          attendees = [
            {'id': '1', 'avatar': 'https://i.pravatar.cc/100?img=1'},
            {'id': '2', 'avatar': 'https://i.pravatar.cc/100?img=2'},
            {'id': '3', 'avatar': 'https://i.pravatar.cc/100?img=3'},
            {'id': '4', 'avatar': 'https://i.pravatar.cc/100?img=4'},
            {'id': '5', 'avatar': 'https://i.pravatar.cc/100?img=5'},
          ];
          _attendeesLoading = false;
        });
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Posts fetching (paginated, 3 per call)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _fetchEventPosts({bool loadMore = false}) async {
    if (!loadMore && _postsLoading == false && _eventPosts.isNotEmpty) return;
    if (loadMore && (_postsLoadingMore || !_hasMorePosts)) return;

    if (loadMore) {
      setState(() => _postsLoadingMore = true);
      _postPage++;
    }

    try {
      final result = await _postService.getPostsForEvent(
        eventId: widget.eventId,
        page: _postPage,
        limit: 3,
      );

      if (mounted) {
        final newPosts = result['posts'] as List<ExplorePost>;
        setState(() {
          if (loadMore) {
            // Filter duplicates
            final existingIds = _eventPosts.map((p) => p.id).toSet();
            _eventPosts.addAll(
              newPosts.where((p) => !existingIds.contains(p.id)),
            );
          } else {
            _eventPosts = newPosts;
          }
          _hasMorePosts = result['hasMore'] as bool;
          _postsLoading = false;
          _postsLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postsLoading = false;
          _postsLoadingMore = false;
        });
      }
    }
  }

  void _onPostsScroll() {
    if (!_postsScrollController.hasClients) return;
    final maxScroll = _postsScrollController.position.maxScrollExtent;
    final currentScroll = _postsScrollController.position.pixels;
    // Trigger load more when near the end (within 100px)
    if (currentScroll >= maxScroll - 100) {
      _fetchEventPosts(loadMore: true);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Helpers
  // ══════════════════════════════════════════════════════════════════════════

  ImageProvider? _getAttendeeAvatarImage(int index) {
    try {
      if (attendees.isEmpty || index >= attendees.length || index < 0) {
        return null;
      }
      final attendee = attendees[index];
      if (attendee == null) return null;

      String? avatarUrl;
      if (attendee is Map) {
        avatarUrl = attendee['avatar'] ??
            attendee['profilePicture'] ??
            attendee['userAvatarUrl'] ??
            attendee['profile_picture'];
      }

      if (avatarUrl != null &&
          avatarUrl.isNotEmpty &&
          Uri.tryParse(avatarUrl) != null) {
        return NetworkImage(avatarUrl);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  double? _getLowestPriceFromSeatMap() {
    if (_seatMapData.isEmpty) return null;
    try {
      List<double> prices = [];
      for (var seat in _seatMapData) {
        if (seat['price'] != null) {
          prices.add((seat['price'] as num).toDouble());
        }
      }
      if (prices.isEmpty) return null;
      return prices.reduce((a, b) => a < b ? a : b);
    } catch (e) {
      return null;
    }
  }

  String _formatDateLong(DateTime date) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  String _getPriceText(Event event) {
    final lowestPrice = _getLowestPriceFromSeatMap();
    if (lowestPrice != null) {
      return 'LKR ${lowestPrice.toStringAsFixed(0)}';
    }
    if (event.ticketTypes.isNotEmpty) {
      final ticketPrice = event.ticketTypes
          .map((t) => t.price)
          .reduce((a, b) => a < b ? a : b);
      return 'LKR ${ticketPrice.toStringAsFixed(0)}';
    }
    return 'Free';
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Share bottom sheet
  // ══════════════════════════════════════════════════════════════════════════

  void _showShareSheet(Event event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context: context,
      builder: (_) {
        final shareText =
            'Check out "${event.title}" on EventBn!\n'
            '📍 ${event.venue.isNotEmpty ? event.venue : 'TBA'}\n'
            '📅 ${_formatDate(event.startDateTime)}\n\n'
            '${event.description.length > 120 ? '${event.description.substring(0, 120)}...' : event.description}';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Event',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 20),
            _ShareOptionTile(
              icon: Icons.copy_rounded,
              label: 'Copy link',
              isDark: isDark,
              onTap: () {
                Clipboard.setData(ClipboardData(text: shareText));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard'),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),
            _ShareOptionTile(
              icon: Icons.share_rounded,
              label: 'Share via...',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Share.share(shareText);
              },
            ),
            _ShareOptionTile(
              icon: Icons.message_rounded,
              label: 'Send as message',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Share.share(shareText);
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Attendees bottom sheet
  // ══════════════════════════════════════════════════════════════════════════

  void _showAttendeesSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context: context,
      builder: (_) => _AttendeeSheetContent(
        eventId: widget.eventId,
        attendees: attendees,
        isLoading: _attendeesLoading,
        isDark: isDark,
        getAvatarImage: _getAttendeeAvatarImage,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Video controller lifecycle
  // ══════════════════════════════════════════════════════════════════════════

  void _ensureVideoController(Event? event) {
    if (event != null && event.videoUrl.isNotEmpty) {
      if (_videoController == null ||
          _videoController!.dataSource != event.videoUrl) {
        _videoController?.dispose();
        _videoInitialized = false;
        final controller = event.videoUrl.startsWith('http')
            ? VideoPlayerController.networkUrl(Uri.parse(event.videoUrl))
            : VideoPlayerController.asset(event.videoUrl);
        _videoController = controller;
        controller
          ..setLooping(true)
          ..initialize().then((_) {
            // Only proceed if this controller is still the active one
            if (mounted && _videoController == controller) {
              setState(() {
                _videoInitialized = true;
                controller.play();
                _userPausedVideo = false;
              });
            }
          });
      }
    } else if (_videoController != null) {
      _videoController?.dispose();
      _videoController = null;
      _videoInitialized = false;
      _userPausedVideo = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Build
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final eventProvider = Provider.of<EventProvider>(context);
    final event = eventProvider.currentEvent;
    final isLoading = eventProvider.isLoading;
    final errorMessage = eventProvider.error;

    // ── Loading / error guards ────────────────────────────────────────────
    if (isLoading) {
      return const EventDetailsSkeletonLoading();
    }
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.background : AppColors.bgLight,
        body: Center(
          child: Text('Error: $errorMessage',
              style: TextStyle(
                  color: isDark
                      ? AppColors.white
                      : AppColors.textPrimaryLight)),
        ),
      );
    }
    if (event == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.background : AppColors.bgLight,
        body: Center(
          child: Text('Event not found',
              style: TextStyle(
                  color: isDark
                      ? AppColors.white
                      : AppColors.textPrimaryLight)),
        ),
      );
    }

    // ── Main scaffold ─────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.bgLight,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  _buildHeroSection(context, isDark, event),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                              _buildSchedulePrice(isDark, event),
                          const SizedBox(height: 20),
                          _buildOrganizerCard(isDark, event),
                          const SizedBox(height: 20),
                          _buildDetailCard(isDark, event),
                          const SizedBox(height: 20),
                          _buildPostsCard(isDark),
                          const SizedBox(height: 20),
                          _buildMapCard(isDark, event),
                              const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Fullscreen video overlay ──────────────────────────────
              if (isVideoExpanded &&
                  event.videoUrl.isNotEmpty &&
                  _videoController != null &&
                  _videoInitialized)
                _buildFullscreenVideo(),

              // ── Fixed bottom button ───────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomBar(isDark, event),
              ),
            ],
          ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HERO SECTION — SliverAppBar with video / photo
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroSection(BuildContext context, bool isDark, Event event) {
    return SliverAppBar(
      expandedHeight: 326,
      pinned: true,
      backgroundColor: isDark ? AppColors.background : AppColors.bgLight,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: ValueListenableBuilder<bool>(
        valueListenable: _isCollapsedNotifier,
        builder: (_, isCollapsed, child) => AnimatedOpacity(
          opacity: isCollapsed ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _MarqueeText(
            text: event.title,
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ),
      centerTitle: true,
      leading: ValueListenableBuilder<bool>(
        valueListenable: _isCollapsedNotifier,
        builder: (_, isCollapsed, child) => IgnorePointer(
          ignoring: !isCollapsed,
          child: AnimatedOpacity(
            opacity: isCollapsed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: child,
          ),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? AppColors.white : AppColors.textPrimaryLight,
              size: 18),
          onPressed: () {
            if (_videoController != null &&
                _videoController!.value.isPlaying) {
              _videoController?.pause();
            }
            context.pop();
          },
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ── Image / Video ────────────────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (event.videoUrl.isNotEmpty &&
                    _videoController != null &&
                    _videoInitialized) {
                  setState(() => isVideoExpanded = true);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: event.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        color: isDark
                            ? AppColors.surface
                            : Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(
                        color: isDark
                            ? AppColors.surface
                            : Colors.grey[200],
                        child: const Icon(Icons.image_not_supported,
                            size: 48)),
                  ),
                  if (_videoInitialized && _videoController != null)
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Top bar: back + love + share ─────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FrostedCircleButton(
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                    onTap: () {
                      if (_videoController != null &&
                          _videoController!.value.isPlaying) {
                        _videoController?.pause();
                      }
                      context.pop();
                    },
                  ),
                  Row(
                    children: [
                      _FrostedCircleButton(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            _isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(_isLiked),
                            size: 20,
                            color: _isLiked
                                ? AppColors.primary
                                : Colors.white,
                          ),
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isLiked = !_isLiked);
                        },
                      ),
                      const SizedBox(width: 10),
                      _FrostedCircleButton(
                        child: const Icon(Icons.share_outlined,
                            color: Colors.white, size: 18),
                        onTap: () => _showShareSheet(event),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Bottom overlays (title, category, avatars) ───────────
            Positioned(
              bottom: 30,
              left: 16,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image counter badge
                  _buildImageCounterBadge(event),
                  const SizedBox(height: 8),
                  // Event title — Spotify-style marquee for long titles
                  _MarqueeText(
                    text: event.title,
                    style: const TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            color: Colors.black,
                            offset: Offset(0, 2),
                            blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Category + attendees row
                  Row(
                    children: [
                      // Category pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Text(
                          event.category,
                          style: const TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1B1B1B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Single large touch target for attendees
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showAttendeesSheet(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                _buildAttendeeAvatars(),
                                const SizedBox(width: 6),
                                Text(
                                  _attendeesLoading
                                      ? ''
                                      : '+${attendees.length > 10 ? 10 : attendees.length} More',
                                  style: const TextStyle(
                                    fontFamily: kFontFamily,
                                    fontSize: 10,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios,
                                    color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Video controls (sound + play) ────────────────────────
            if (event.videoUrl.isNotEmpty &&
                _videoController != null &&
                _videoInitialized)
              Positioned(
                bottom: 24,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sound button
                    _buildVideoControlButton(
                      size: 32,
                      child: Image.asset(
                        _videoController!.value.volume > 0
                            ? 'assets/icons/event-details/sound.png'
                            : 'assets/icons/event-details/no sound.png',
                        width: 12,
                        height: 12,
                        color: Colors.white,
                      ),
                      onTap: () {
                        if (_videoController!.value.volume > 0) {
                          _videoController?.setVolume(0);
                        } else {
                          _videoController?.setVolume(1);
                        }
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    // Play/pause button
                    _buildVideoControlButton(
                      size: 42,
                      child: Image.asset(
                        _videoController!.value.isPlaying
                            ? 'assets/icons/event-details/pause.png'
                            : 'assets/icons/event-details/play.png',
                        width: 22,
                        height: 22,
                        color: Colors.white,
                      ),
                      onTap: () {
                        if (_videoController!.value.isPlaying) {
                          _videoController?.pause();
                          _userPausedVideo = true;
                        } else {
                          _videoController?.play();
                          _userPausedVideo = false;
                        }
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),


            // ── Bottom sheet transition ──────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.background : AppColors.bgLight,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF393939)
                          : Colors.grey.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCounterBadge(Event event) {
    // Count available media (main image + other images)
    int imageCount = 1; // main image always present
    if (event.otherImagesUrl.isNotEmpty) {
      // otherImagesUrl is a comma-separated string
      final otherImages = event.otherImagesUrl
          .split(',')
          .where((url) => url.trim().isNotEmpty)
          .toList();
      imageCount += otherImages.length;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        '1/$imageCount',
        style: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 10,
          color: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildVideoControlButton({
    required double size,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }

  // ── Attendee avatars (stacked circles) ─────────────────────────────────
  Widget _buildAttendeeAvatars() {
    if (_attendeesLoading || attendees.isEmpty) {
      return const SizedBox.shrink();
    }
    final displayCount = attendees.length > 4 ? 4 : attendees.length;
    return SizedBox(
      width: displayCount * 14.0 + 7,
      height: 21,
      child: Stack(
        children: List.generate(displayCount, (index) {
          return Positioned(
            left: index * 14.0,
            child: Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 9,
                backgroundColor: Colors.grey[400],
                backgroundImage: _getAttendeeAvatarImage(index),
                child: _getAttendeeAvatarImage(index) == null
                    ? Icon(Icons.person,
                        size: 10, color: Colors.grey[600])
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SCHEDULE + PRICE ROW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSchedulePrice(bool isDark, Event event) {
    final priceStr = _getPriceText(event);
    final isFree = priceStr == 'Free';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: date & location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date row
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/event card/date-time.png',
                      width: 18,
                      height: 18,
                      color: isDark
                          ? AppColors.grey200
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDateLong(event.startDateTime),
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.grey200
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location row
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/event card/location.png',
                      width: 18,
                      height: 18,
                      color: isDark
                          ? AppColors.grey200
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.venue.isNotEmpty
                            ? event.venue
                            : event.address,
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.grey200
                              : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isFree)
                Text(
                  'From',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: isDark
                        ? AppColors.grey200
                        : AppColors.textSecondaryLight,
                  ),
                ),
              Text(
                isFree ? 'Free' : priceStr,
                style: const TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ORGANIZER CARD
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildOrganizerCard(bool isDark, Event event) {
    final orgLogoUrl = (event.organization != null &&
            event.organization!['logo_url'] != null &&
            event.organization!['logo_url'].toString().isNotEmpty)
        ? event.organization!['logo_url'].toString()
        : 'https://i.pravatar.cc/100?u=${event.organizationId}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Avatar
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: orgLogoUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  width: 48,
                  height: 48,
                  color: isDark ? AppColors.bg01 : Colors.grey[200]),
              errorWidget: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: isDark ? AppColors.bg01 : Colors.grey[200],
                child: const Icon(Icons.person, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.organizerName,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: isDark
                        ? AppColors.white
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Organizer',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF8C9097)
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Rating
          Text(
            '4.8',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  isDark ? AppColors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(width: 7),
          Image.asset(
            'assets/icons/event-details/icons8-star-96.png',
            width: 19,
            height: 19,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DETAIL CONCERT CARD (about + read more)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDetailCard(bool isDark, Event event) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/event-details/more-details.png',
                width: 14,
                height: 14,
                color: isDark ? AppColors.white : AppColors.textPrimaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Detail concert',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color:
                      isDark ? AppColors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isAboutExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: isDark
                        ? AppColors.grey200
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(
                      () => isAboutExpanded = !isAboutExpanded),
                  child: const Text(
                    'read more',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: isDark
                        ? AppColors.grey200
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(
                      () => isAboutExpanded = !isAboutExpanded),
                  child: const Text(
                    'show less',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  POSTS CARD (horizontal scroll, paginated — 3 per call)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPostsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/event-details/gallery.png',
                width: 18,
                height: 18,
                color: isDark ? AppColors.white : AppColors.textPrimaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Posts',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: isDark ? AppColors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 189,
            child: _postsLoading
                ? _buildPostsShimmer(isDark)
                : _eventPosts.isEmpty
                    ? _buildNoPostsPlaceholder(isDark)
                    : ListView.separated(
                        controller: _postsScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount:
                            _eventPosts.length + (_hasMorePosts ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          // Loading indicator at the end
                          if (index == _eventPosts.length) {
                            return _buildPostLoadingTile(isDark);
                          }
                          return _buildPostTile(
                              _eventPosts[index], isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTile(ExplorePost post, bool isDark) {
    // Determine thumbnail: prefer first image, then video thumbnail, else icon
    final hasImage = post.imageUrls.isNotEmpty;
    final hasVideoThumb = post.videoThumbnails.isNotEmpty;
    final hasVideo = post.videoUrls.isNotEmpty;
    final thumbUrl = hasImage
        ? post.imageUrls.first
        : hasVideoThumb
            ? post.videoThumbnails.first
            : null;

    return GestureDetector(
      onTap: () {
        context.push('/explore/post/${post.id}');
      },
      child: Container(
        width: 125,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: thumbUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: thumbUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: isDark
                          ? const Color(0xFF252525)
                          : Colors.grey[200],
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _buildPostIconPlaceholder(
                        isDark, hasVideo),
                  ),
                  // Play icon overlay for videos
                  if (hasVideo && !hasImage)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  // Bottom gradient with content preview
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Text(
                        post.content.isNotEmpty
                            ? post.content
                            : post.userDisplayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _buildPostIconPlaceholder(isDark, hasVideo),
      ),
    );
  }

  Widget _buildPostIconPlaceholder(bool isDark, bool isVideo) {
    return Container(
      color: isDark ? const Color(0xFF252525) : Colors.grey[100],
      child: Center(
        child: Icon(
          isVideo ? Icons.play_circle_outline : Icons.image_outlined,
          size: 36,
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildPostLoadingTile(bool isDark) {
    return Container(
      width: 125,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsShimmer(bool isDark) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: 125,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoPostsPlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 40,
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'No posts yet',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 12,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MAP CARD
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMapCard(bool isDark, Event event) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/event-details/map.png',
                width: 14,
                height: 14,
                color: isDark ? AppColors.white : AppColors.textPrimaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Map',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color:
                      isDark ? AppColors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Map placeholder
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  color: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.grey[200],
                  child: isDark
                      ? CustomPaint(
                          painter: _DarkMapPainter(),
                          size: const Size(double.infinity, 180),
                        )
                      : CustomPaint(
                          painter: _LightMapPainter(),
                          size: const Size(double.infinity, 180),
                        ),
                ),
              ),
              // Location pin
              Positioned.fill(
                child: Center(
                  child: Image.asset(
                    'assets/icons/event-details/icons8-location-80.png',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            ],
          ),
          if (event.address.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Image.asset(
                  'assets/icons/event card/location.png',
                  width: 18,
                  height: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.address,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.grey200
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FULLSCREEN VIDEO OVERLAY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFullscreenVideo() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Column(
                children: [
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.primary,
                      backgroundColor: Colors.white24,
                      bufferedColor: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildVideoControlButton(
                        size: 48,
                        child: Icon(
                          _videoController!.value.volume > 0
                              ? Icons.volume_up
                              : Icons.volume_off,
                          color: Colors.white,
                          size: 28,
                        ),
                        onTap: () {
                          if (_videoController!.value.volume > 0) {
                            _videoController?.setVolume(0);
                          } else {
                            _videoController?.setVolume(1);
                          }
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 32),
                      _buildVideoControlButton(
                        size: 56,
                        child: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                        onTap: () {
                          if (_videoController!.value.isPlaying) {
                            _videoController?.pause();
                            _userPausedVideo = true;
                          } else {
                            _videoController?.play();
                            _userPausedVideo = false;
                          }
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 32,
              right: 24,
              child: _buildVideoControlButton(
                size: 40,
                child: const Icon(Icons.close,
                    color: Colors.white, size: 24),
                onTap: () => setState(() => isVideoExpanded = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BOTTOM BAR — "Book Now" button
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomBar(bool isDark, Event event) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg01 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => _handleBookEvent(event),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.dark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBookEvent(Event event) async {
    // Guest mode → login prompt
    if (widget.isGuestMode) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text(
              'Please login or create an account to book tickets.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/onboarding');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController?.pause();
    }

    // Wait for seat map info
    if (!_seatMapLoaded) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator()),
      );
      while (!_seatMapLoaded) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (mounted) Navigator.of(context).pop();
    }

    if (_hasCustomSeating == true) {
      if (mounted) {
        context.pushNamed('booking-seat-selection',
            pathParameters: {'eventId': widget.eventId});
      }
    } else {
      if (mounted) {
        context.pushReplacement('/ticket-type-selection', extra: {
          'eventId': widget.eventId,
          'eventName': event.title,
          'eventDate': event.startDateTime.toString(),
          'venue': event.venue,
          'ticketType': 'General',
          'initialCount': 1,
        });
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Frosted-glass circular button (hero overlay)
// ═══════════════════════════════════════════════════════════════════════════════

class _FrostedCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _FrostedCircleButton(
      {required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.24),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Share option tile (used in share bottom sheet)
// ═══════════════════════════════════════════════════════════════════════════════

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.white : AppColors.textPrimaryLight,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Map painters (stylised dark / light placeholders)
// ═══════════════════════════════════════════════════════════════════════════════

class _DarkMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Draw "road" lines to simulate a dark map
    paint
      ..color = const Color(0xFF2A2A3E)
      ..strokeWidth = 1.5;

    // Horizontal roads
    canvas.drawLine(Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.3), paint);
    canvas.drawLine(Offset(0, size.height * 0.6),
        Offset(size.width, size.height * 0.6), paint);
    canvas.drawLine(Offset(0, size.height * 0.85),
        Offset(size.width, size.height * 0.85), paint);

    // Vertical roads
    canvas.drawLine(Offset(size.width * 0.25, 0),
        Offset(size.width * 0.25, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.75, 0),
        Offset(size.width * 0.75, size.height), paint);

    // Diagonal
    paint.color = const Color(0xFF353550);
    canvas.drawLine(Offset(0, size.height),
        Offset(size.width * 0.6, 0), paint);
    canvas.drawLine(Offset(size.width * 0.4, size.height),
        Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Spotify-style marquee text — scrolls left when text overflows
//  Uses AnimationController (GPU-composited) instead of ScrollController
//  async loops to avoid jank with video playback.
// ═══════════════════════════════════════════════════════════════════════════════

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animController;
  bool _needsScroll = false;
  double _maxExtent = 0;
  bool _checkedOnce = false;

  // Animation phases: pause → forward → pause → reverse → repeat
  static const _pauseDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _animController.stop();
      _animController.removeListener(_onAnimTick);
      _animController.reset();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _checkedOnce = false;
      _needsScroll = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
    }
  }

  void _checkOverflow() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0 && !_checkedOnce) {
      _checkedOnce = true;
      setState(() => _needsScroll = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients || !mounted) return;
        _maxExtent = _scrollController.position.maxScrollExtent;
        _kickOffAnimation();
      });
    } else if (maxScroll <= 0) {
      if (_needsScroll) setState(() => _needsScroll = false);
    }
  }

  void _kickOffAnimation() {
    if (!mounted || !_needsScroll || _maxExtent <= 0) return;

    // ~30px/s forward, ~50px/s reverse — feels smooth like Spotify
    final forwardMs = (_maxExtent * 33).toInt().clamp(500, 30000);
    final reverseMs = (_maxExtent * 20).toInt().clamp(300, 15000);
    final totalMs = forwardMs + reverseMs + (_pauseDuration.inMilliseconds * 2);

    // Forward occupies [pause..pause+forward] then pause then reverse
    final fwdStart = _pauseDuration.inMilliseconds / totalMs;
    final fwdEnd = fwdStart + forwardMs / totalMs;
    final revStart = fwdEnd + _pauseDuration.inMilliseconds / totalMs;
    // revEnd = 1.0

    _animController.stop();
    _animController.reset();
    _animController.duration = Duration(milliseconds: totalMs);

    // Remove old listeners before adding a new one
    _animController.removeListener(_onAnimTick);

    // Capture phase boundaries for the listener closure
    _fwdStart = fwdStart;
    _fwdEnd = fwdEnd;
    _revStart = revStart;

    _animController.addListener(_onAnimTick);
    _animController.repeat();
  }

  // Phase boundaries (set before each animation cycle)
  double _fwdStart = 0;
  double _fwdEnd = 0;
  double _revStart = 0;

  void _onAnimTick() {
    if (!_scrollController.hasClients || !mounted) return;
    final t = _animController.value;
    double scrollOffset;
    if (t < _fwdStart) {
      scrollOffset = 0;
    } else if (t < _fwdEnd) {
      final frac = (t - _fwdStart) / (_fwdEnd - _fwdStart);
      scrollOffset = frac * _maxExtent;
    } else if (t < _revStart) {
      scrollOffset = _maxExtent;
    } else {
      final frac = (t - _revStart) / (1.0 - _revStart);
      // easeOut curve for reverse
      final curved = 1.0 - (1.0 - frac) * (1.0 - frac);
      scrollOffset = _maxExtent * (1.0 - curved);
    }
    _scrollController.jumpTo(scrollOffset.clamp(0, _maxExtent));
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (widget.style.fontSize ?? 20) * (widget.style.height ?? 1.4),
      child: ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            colors: _needsScroll
                ? [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ]
                : [Colors.white, Colors.white],
            stops: _needsScroll ? [0.0, 0.03, 0.92, 1.0] : [0.0, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              Text(
                widget.text,
                style: widget.style,
                maxLines: 1,
                softWrap: false,
              ),
              if (_needsScroll) ...[
                const SizedBox(width: 30),
                Text(
                  widget.text,
                  style: widget.style,
                  maxLines: 1,
                  softWrap: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Attendee list bottom sheet content
// ═══════════════════════════════════════════════════════════════════════════════

class _AttendeeSheetContent extends StatelessWidget {
  final String eventId;
  final List<dynamic> attendees;
  final bool isLoading;
  final bool isDark;
  final ImageProvider? Function(int index) getAvatarImage;

  const _AttendeeSheetContent({
    required this.eventId,
    required this.attendees,
    required this.isLoading,
    required this.isDark,
    required this.getAvatarImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Event Attendees',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.textPrimaryLight,
              ),
            ),
            const Spacer(),
            if (!isLoading)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${attendees.length} Going',
                  style: const TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (attendees.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.people_outline,
                      size: 48,
                      color: isDark
                          ? AppColors.grey200
                          : AppColors.textTertiaryLight),
                  const SizedBox(height: 12),
                  Text(
                    'No attendees yet',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 14,
                      color: isDark
                          ? AppColors.grey200
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to join this event!',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF8C9097)
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: attendees.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey.withValues(alpha: 0.12),
              ),
              itemBuilder: (context, index) {
                final attendee = attendees[index];
                final name = attendee is Map
                    ? (attendee['username'] ??
                        attendee['name'] ??
                        'Unknown User')
                    : 'Unknown User';
                final avatar = getAvatarImage(index);

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            isDark ? AppColors.surface : Colors.grey[200],
                        backgroundImage: avatar,
                        child: avatar == null
                            ? Icon(Icons.person,
                                size: 20,
                                color: isDark
                                    ? AppColors.grey200
                                    : Colors.grey[500])
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name.toString(),
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.white
                                : AppColors.textPrimaryLight,
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
}

class _LightMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    paint
      ..color = Colors.grey.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.3), paint);
    canvas.drawLine(Offset(0, size.height * 0.6),
        Offset(size.width, size.height * 0.6), paint);
    canvas.drawLine(Offset(0, size.height * 0.85),
        Offset(size.width, size.height * 0.85), paint);

    canvas.drawLine(Offset(size.width * 0.25, 0),
        Offset(size.width * 0.25, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.75, 0),
        Offset(size.width * 0.75, size.height), paint);

    paint.color = Colors.grey.withValues(alpha: 0.15);
    canvas.drawLine(Offset(0, size.height),
        Offset(size.width * 0.6, 0), paint);
    canvas.drawLine(Offset(size.width * 0.4, size.height),
        Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
