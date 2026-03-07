import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/event_model.dart';
import '../../auth/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Reusable blurred-bottom event card (poster image + blur overlay details).
//
//  Used by:
//    • PopularConcertSection  (horizontal scroll, fixed 225 width)
//    • AllEventsScreen         (vertical list, full width)
//
//  Set [width] to constrain the card width (horizontal list) or leave null for
//  full-width (vertical list).  [height] defaults to 265.
// ═══════════════════════════════════════════════════════════════════════════════

class PopularEventCard extends StatelessWidget {
  final Event event;
  final bool isDark;
  final String Function(Event event) getPriceText;

  /// Card width.  `null` → full width (uses parent constraints).
  final double? width;

  /// Card height.
  final double height;

  /// Horizontal margin to the right (used when in a horizontal list).
  final double rightMargin;

  /// Bottom margin (used when in a vertical list).
  final double bottomMargin;

  const PopularEventCard({
    super.key,
    required this.event,
    required this.isDark,
    required this.getPriceText,
    this.width,
    this.height = 265,
    this.rightMargin = 0,
    this.bottomMargin = 0,
  });

  // Cached static gradient — avoids allocating new objects on every build.
  static const _bottomGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Colors.transparent,
      Color(0x26000000), // black 15%
      Color(0xD9000000), // black 85%
    ],
    stops: [0.0, 0.35, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(right: rightMargin, bottom: bottomMargin),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Full poster background
              Positioned.fill(
                child: event.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: event.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? AppColors.bg01 : Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _ImagePlaceholder(isDark: isDark),
                      )
                    : _ImagePlaceholder(isDark: isDark),
              ),

              // Gradient overlay from bottom for readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: _bottomGradient,
                  ),
                ),
              ),

              // Bottom content area — lightweight semi-transparent overlay
              // instead of BackdropFilter (which is extremely GPU-expensive
              // and was causing frame drops during scrolling/banner animation).
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xBB000000) // black ~73% — frosted glass on dark poster
                          : const Color(0xF0FFFFFF), // white ~94% — light frosted glass
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          // Event title
                          Text(
                            event.title,
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Location
                          Row(
                            children: [
                              Image.asset(
                                'assets/icons/event card/location.png',
                                width: 12,
                                height: 12,
                                color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  event.venue.isNotEmpty
                                      ? event.venue
                                      : event.address,
                                  style: TextStyle(
                                    fontFamily: kFontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Date & time
                          Row(
                            children: [
                              Image.asset(
                                'assets/icons/event card/date-time.png',
                                width: 12,
                                height: 12,
                                color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _formatDate(event.startDateTime),
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Price + availability
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                getPriceText(event),
                                style: const TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                'Tickets available',
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Tap overlay for instant visual feedback
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final authProvider = context.read<AuthProvider>();
                      if (authProvider.isGuestMode) {
                        context.push('/guest/events/${event.id}');
                      } else {
                        context.push('/events/${event.id}');
                      }
                    },
                    splashColor: AppColors.primary.withOpacity(0.08),
                    highlightColor: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ─── Placeholder shown when image is missing / errors ─────────────────────
class _ImagePlaceholder extends StatelessWidget {
  final bool isDark;
  const _ImagePlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.bg01 : Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.event_rounded,
          size: 40,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }
}
