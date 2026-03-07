import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/design_tokens.dart';
import '../../events/models/event_model.dart';
import '../../events/services/event_service.dart';
import '../services/user_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ORGANIZER PROFILE SCREEN
//
// Reuses the Account Screen's cover-photo → gradient → avatar layout.
// No settings, no edit/share buttons.  Shows organizer info, stats,
// bio, and a list of their events.
// ─────────────────────────────────────────────────────────────────────────────

class OrganizerProfileScreen extends StatefulWidget {
  final String organizerId;

  /// Optional pre-populated data from the event's `organization` map
  /// so the screen can render instantly while the API call completes.
  final Map<String, dynamic>? initialOrgData;

  const OrganizerProfileScreen({
    super.key,
    required this.organizerId,
    this.initialOrgData,
  });

  @override
  State<OrganizerProfileScreen> createState() => _OrganizerProfileScreenState();
}

class _OrganizerProfileScreenState extends State<OrganizerProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final EventService _eventService = EventService();
  final UserService _userService = UserService();

  Map<String, dynamic>? _orgData;
  List<Event> _organizerEvents = [];
  bool _isLoadingProfile = true;
  bool _isLoadingEvents = true;

  // ── Convenience getters ──────────────────────────────────────────────
  String get _name =>
      _orgData?['name'] ?? _orgData?['firstName'] ?? 'Unknown Organizer';
  String? get _avatarUrl =>
      _orgData?['avatar'] ??
      _orgData?['avatar_url'] ??
      _orgData?['logo_url'];
  String? get _coverUrl =>
      _orgData?['cover_image'] ??
      _orgData?['cover_image_url'] ??
      _orgData?['coverImage'];
  String? get _bio =>
      _orgData?['bio'] ?? _orgData?['description'];
  String? get _location =>
      _orgData?['location'] ?? _orgData?['city'];
  String? get _website =>
      _orgData?['website'] ?? _orgData?['websiteUrl'];
  bool get _isVerified => _orgData?['isVerified'] ?? true;
  int get _followersCount =>
      int.tryParse(_orgData?['followers']?.toString() ?? '') ?? 0;
  int get _followingCount =>
      int.tryParse(_orgData?['following']?.toString() ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Use initial data for instant render, then fetch fresh data
    if (widget.initialOrgData != null) {
      _orgData = widget.initialOrgData;
      _isLoadingProfile = false;
    }

    _loadProfile();
    _loadOrganizerEvents();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Fetch organizer profile ───────────────────────────────────────────
  Future<void> _loadProfile() async {
    try {
      final fetched = await _userService.getUserById(widget.organizerId);
      if (fetched != null && mounted) {
        setState(() {
          _orgData = {
            ...?_orgData,          // keep initial data as fallback
            ...fetched,            // override with fresh API data
            'name': fetched['name'] ??
                fetched['firstName'] ??
                _orgData?['name'] ??
                'Unknown Organizer',
            'avatar': fetched['avatar'] ??
                fetched['avatarUrl'] ??
                _orgData?['avatar'] ??
                _orgData?['logo_url'],
            'cover_image': fetched['coverImage'] ??
                fetched['cover_image'] ??
                _orgData?['cover_image'],
            'bio': fetched['bio'] ??
                fetched['description'] ??
                _orgData?['bio'],
            'location': fetched['location'] ??
                fetched['city'] ??
                _orgData?['location'],
            'website': fetched['website'] ??
                fetched['websiteUrl'] ??
                _orgData?['website'],
            'isVerified': fetched['isVerified'] ?? true,
            'followers': fetched['followers'] ?? 0,
            'following': fetched['following'] ?? 0,
          };
          _isLoadingProfile = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('❌ [OrganizerProfile] Error loading profile: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // ── Fetch organizer events ────────────────────────────────────────────
  Future<void> _loadOrganizerEvents() async {
    try {
      final allEvents = await _eventService.getAllEvents();
      final matched = allEvents.where((event) {
        if (event.organizationId == widget.organizerId) return true;
        if (event.organization != null) {
          final org = event.organization!;
          if (org['creator_id']?.toString() == widget.organizerId ||
              org['user_id']?.toString() == widget.organizerId ||
              org['organization_id']?.toString() == widget.organizerId) {
            return true;
          }
          // Hash-based match for generated IDs
          if (widget.organizerId.length > 8 &&
              RegExp(r'^\d+$').hasMatch(widget.organizerId) &&
              org['name'] != null) {
            return org['name'].toString().hashCode.abs().toString() ==
                widget.organizerId;
          }
        }
        return false;
      }).toList();

      if (mounted) {
        setState(() {
          _organizerEvents = matched;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [OrganizerProfile] Error loading events: $e');
      if (mounted) {
        setState(() {
          _organizerEvents = [];
          _isLoadingEvents = false;
        });
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // ── Cover photo background ──
            _buildCoverBackground(isDark),

            // ── Scrollable content ──
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 280),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Gradient fade
                      Positioned(
                        top: -120,
                        left: 0,
                        right: 0,
                        height: 120,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                bgColor.withValues(alpha: 0),
                                bgColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Solid bg container
                      Container(
                        width: double.infinity,
                        color: bgColor,
                        child: Transform.translate(
                          offset: const Offset(0, -200),
                          child: Column(
                            children: [
                              _buildAvatar(isDark, bgColor),
                              _buildOrgInfo(isDark),
                              const SizedBox(height: 20),
                              _buildStats(isDark),
                              if (_bio != null && _bio!.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _buildBioCard(isDark),
                              ],
                              if (_location != null || _website != null) ...[
                                const SizedBox(height: 16),
                                _buildDetailsCard(isDark),
                              ],
                              const SizedBox(height: 24),
                              _buildEventsSection(isDark),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Back button ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cover photo (same style as Account Screen) ────────────────────────
  Widget _buildCoverBackground(bool isDark) {
    const coverHeight = 320.0;

    return SizedBox(
      height: coverHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _coverUrl != null && _coverUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: _coverUrl!,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 150),
                  placeholder: (_, __) => Container(
                    color: isDark
                        ? const Color(0xFF252525)
                        : const Color(0xFFE0E0E0),
                  ),
                  errorWidget: (_, __, ___) => _coverPlaceholder(isDark),
                )
              : _coverPlaceholder(isDark),
        ],
      ),
    );
  }

  Widget _coverPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)]
              : [const Color(0xFFE0E0E0), const Color(0xFFC0C0C0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // ── Avatar (same ring + circle style as Account Screen) ───────────────
  Widget _buildAvatar(bool isDark, Color bgColor) {
    const avatarRadius = 48.0;

    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: bgColor, width: 4),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor:
                  isDark ? const Color(0xFF252525) : const Color(0xFFE0E0E0),
              backgroundImage:
                  _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(_avatarUrl!)
                      : null,
              child: _avatarUrl == null || _avatarUrl!.isEmpty
                  ? Text(
                      _initials,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        fontFamily: kFontFamily,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String get _initials {
    final parts = _name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _name.isNotEmpty ? _name[0].toUpperCase() : '?';
  }

  // ── Name + Organizer badge ────────────────────────────────────────────
  Widget _buildOrgInfo(bool isDark) {
    final nameColor = isDark ? AppColors.white : AppColors.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Name row with verified icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: nameColor,
                  ),
                ),
              ),
              if (_isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified,
                    color: AppColors.primary, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Organizer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Organizer',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row (Events · Followers · Following) ────────────────────────
  Widget _buildStats(bool isDark) {
    final numColor = isDark ? AppColors.white : AppColors.dark;
    final labelColor = isDark ? AppColors.grey : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statColumn(
              _isLoadingEvents ? '–' : '${_organizerEvents.length}',
              'Events',
              numColor,
              labelColor,
            ),
            Container(width: 1, height: 32, color: isDark ? AppColors.divider : const Color(0xFFE8E9EA)),
            _statColumn(
              _formatCount(_followersCount),
              'Followers',
              numColor,
              labelColor,
            ),
            Container(width: 1, height: 32, color: isDark ? AppColors.divider : const Color(0xFFE8E9EA)),
            _statColumn(
              _formatCount(_followingCount),
              'Following',
              numColor,
              labelColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(
      String value, String label, Color numColor, Color labelColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: numColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  // ── Bio card ──────────────────────────────────────────────────────────
  Widget _buildBioCard(bool isDark) {
    final textColor = isDark ? AppColors.grey : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _bio!,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Details card (location, website) ──────────────────────────────────
  Widget _buildDetailsCard(bool isDark) {
    final iconColor = isDark ? AppColors.grey300 : AppColors.textSecondaryLight;
    final textColor = isDark ? AppColors.white : AppColors.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (_location != null && _location!.isNotEmpty)
              _detailRow(
                Icons.location_on_outlined,
                _location!,
                iconColor,
                textColor,
              ),
            if (_location != null &&
                _location!.isNotEmpty &&
                _website != null &&
                _website!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.divider
                      : const Color(0xFFE8E9EA),
                ),
              ),
            if (_website != null && _website!.isNotEmpty)
              _detailRow(
                Icons.link_rounded,
                _website!,
                iconColor,
                AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
      IconData icon, String text, Color iconColor, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  // ── Events section ────────────────────────────────────────────────────
  Widget _buildEventsSection(bool isDark) {
    final headerColor = isDark ? AppColors.white : AppColors.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Events',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: headerColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingEvents)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_organizerEvents.isEmpty)
          _buildEmptyEvents(isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _organizerEvents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildEventTile(_organizerEvents[index], isDark),
          ),
      ],
    );
  }

  Widget _buildEmptyEvents(bool isDark) {
    final color = isDark ? AppColors.grey : AppColors.textSecondaryLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              'No events yet',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(Event event, bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
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
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: event.imageUrl,
                width: 100,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 100,
                  height: 90,
                  color: isDark
                      ? const Color(0xFF252525)
                      : const Color(0xFFE0E0E0),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 100,
                  height: 90,
                  color: isDark
                      ? const Color(0xFF252525)
                      : const Color(0xFFE0E0E0),
                  child: const Icon(Icons.image_outlined,
                      size: 28, color: AppColors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.white
                            : AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 12,
                            color: isDark
                                ? AppColors.grey
                                : AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(event.startDateTime),
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 12,
                            color: isDark
                                ? AppColors.grey
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12,
                            color: isDark
                                ? AppColors.grey
                                : AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.venue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.grey
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Chevron
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.grey : AppColors.textSecondaryLight,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
