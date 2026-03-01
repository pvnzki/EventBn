import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../providers/event_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/design_tokens.dart';
import '../../auth/services/auth_service.dart';

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

  // Seat map cache
  bool? _hasCustomSeating;
  bool _seatMapLoaded = false;
  List<dynamic> _seatMapData = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<EventProvider>(context, listen: false)
          .fetchEventById(widget.eventId);
      _fetchAttendees();
      _loadSeatMapInfo();
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
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

    // ── Video controller setup ────────────────────────────────────────────
    if (event != null && event.videoUrl.isNotEmpty) {
      if (_videoController == null ||
          _videoController!.dataSource != event.videoUrl) {
        _videoController?.dispose();
        _videoController = event.videoUrl.startsWith('http')
            ? VideoPlayerController.networkUrl(Uri.parse(event.videoUrl))
            : VideoPlayerController.asset(event.videoUrl);
        _videoController!
          ..setLooping(true)
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _videoInitialized = true;
                _videoController?.play();
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

    // ── Loading / error guards ────────────────────────────────────────────
    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.background : AppColors.bgLight,
        body: const Center(child: CircularProgressIndicator()),
      );
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
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (isVideoExpanded && notification.metrics.pixels > 10) {
              setState(() => isVideoExpanded = false);
            }
            if (_videoController != null && _videoInitialized) {
              if (notification.metrics.pixels > 250) {
                if (_videoController!.value.isPlaying) {
                  _videoController?.pause();
                }
              } else if (!_videoController!.value.isPlaying &&
                  !_userPausedVideo) {
                _videoController?.play();
              }
            }
            return false;
          },
          child: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  _buildHeroSection(context, isDark, event),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rounded transition that scrolls with content
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.background : AppColors.bgLight,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
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
                        Padding(
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
                      ],
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
                  if (_videoInitialized &&
                      _videoController != null &&
                      (_videoController!.value.isPlaying || isVideoExpanded))
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
                        child: Image.asset(
                          'assets/icons/event-details/love.png',
                          width: 20,
                          height: 20,
                          color: Colors.white,
                        ),
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      _FrostedCircleButton(
                        child: const Icon(Icons.share_outlined,
                            color: Colors.white, size: 18),
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Bottom overlays (title, category, avatars) ───────────
            Positioned(
              bottom: 24,
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
                      // Attendee avatars
                      _buildAttendeeAvatars(),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => context
                            .push('/event/${widget.eventId}/attendees'),
                        child: Text(
                          _attendeesLoading
                              ? ''
                              : '+${attendees.length > 10 ? 10 : attendees.length} More',
                          style: const TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 10,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Arrow icon
                      GestureDetector(
                        onTap: () => context
                            .push('/event/${widget.eventId}/attendees'),
                        child: const Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 14),
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
  //  POSTS CARD (horizontal scroll, dummy for now)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPostsCard(bool isDark) {
    // Dummy posts data — replace with actual post-service fetch later
    final dummyPosts = [
      {'label': '#Video/Photo 01', 'image': null},
      {'label': '#Video/Photo 02', 'image': null},
      {'label': '#Video/Photo 03', 'image': null},
      {'label': '#Video/Photo 04', 'image': null},
    ];

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
          Text(
            'Posts',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color:
                  isDark ? AppColors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 189,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: dummyPosts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final post = dummyPosts[index];
                return Container(
                  width: 125,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252525)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['label'] as String,
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const Spacer(),
                      // Placeholder icon for post content
                      Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 36,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                );
              },
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
      _scrollController.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
    }
  }

  void _checkOverflow() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      setState(() {
        _needsScroll = true;
        _maxExtent = maxScroll;
      });
      _startAnimation();
    } else {
      setState(() => _needsScroll = false);
    }
  }

  void _startAnimation() async {
    if (!mounted || !_needsScroll) return;

    // Speed: ~30px/s  →  feels smooth like Spotify
    final forwardDuration =
        Duration(milliseconds: (_maxExtent * 33).toInt());
    final reverseDuration =
        Duration(milliseconds: (_maxExtent * 20).toInt());

    while (mounted && _needsScroll) {
      // Pause at start
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_scrollController.hasClients) return;

      // Scroll to end
      await _scrollController.animateTo(
        _maxExtent,
        duration: forwardDuration,
        curve: Curves.linear,
      );
      if (!mounted) return;

      // Pause at end
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_scrollController.hasClients) return;

      // Scroll back to start (faster)
      await _scrollController.animateTo(
        0,
        duration: reverseDuration,
        curve: Curves.easeOut,
      );
    }
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
        // Fade edges when scrolling
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
          child: Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
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
