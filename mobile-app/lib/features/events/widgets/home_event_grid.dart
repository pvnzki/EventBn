import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/app_colors.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// "Event this Month" vertical list section — matches the Figma design with
/// square image on the left and event details on the right.
class HomeEventGrid extends StatelessWidget {
  final List<Event> Function(List<Event> events) filterEvents;
  final String selectedCategory;
  final bool hasActiveFilters;
  final VoidCallback onResetFilters;
  final VoidCallback onRetry;
  final String Function(Event event) getPriceText;

  const HomeEventGrid({
    super.key,
    required this.filterEvents,
    required this.selectedCategory,
    required this.hasActiveFilters,
    required this.onResetFilters,
    required this.onRetry,
    required this.getPriceText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        if (eventProvider.isLoading) {
          return const SizedBox.shrink();
        }

        if (eventProvider.error != null) {
          return _ErrorState(onRetry: onRetry);
        }

        final filteredEvents = filterEvents(eventProvider.events);

        if (filteredEvents.isEmpty) {
          return _EmptyState(
            selectedCategory: selectedCategory,
            hasActiveFilters: hasActiveFilters,
            onReset: onResetFilters,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Event this Month',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      context.push('/all-events?title=Event%20this%20Month');
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'See all',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Event list – shrinkWrap is necessary here because the grid
            // lives inside a Column (not a CustomScrollView). We still let
            // ListView.builder build items lazily.
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              addAutomaticKeepAlives: false,
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                // RepaintBoundary isolates each card so one card
                // animating/updating doesn't repaint its siblings.
                return RepaintBoundary(
                  child: _EventListItem(
                    event: event,
                    isDark: isDark,
                    getPriceText: getPriceText,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Event list item — Square image + details
// ---------------------------------------------------------------------------
class _EventListItem extends StatelessWidget {
  final Event event;
  final bool isDark;
  final String Function(Event event) getPriceText;

  const _EventListItem({
    required this.event,
    required this.isDark,
    required this.getPriceText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final authProvider = context.read<AuthProvider>();
            if (authProvider.isGuestMode) {
              context.push('/guest/events/${event.id}');
            } else {
              context.push('/events/${event.id}');
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            height: 104,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Event image — flush with card edges (top, bottom, left)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.card),
                  bottomLeft: Radius.circular(AppRadius.card),
                ),
                child: SizedBox(
                  width: 104,
                  child: event.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: event.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark
                                ? AppColors.bg01
                                : Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDark
                                ? AppColors.bg01
                                : Colors.grey[200],
                            child: Icon(
                              Icons.event_rounded,
                              size: 32,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.3),
                            ),
                          ),
                        )
                      : Container(
                          color: isDark
                              ? AppColors.bg01
                              : Colors.grey[200],
                          child: Icon(
                            Icons.event_rounded,
                            size: 32,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Event details — padded on the right side only
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  // Title + location (flexible top section)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title — shows up to 2 lines
                      Text(
                        event.title,
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Location + Date row
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/event card/location.png',
                            width: 13,
                            height: 13,
                            color: isDark
                                ? AppColors.grey300
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              event.venue.isNotEmpty ? event.venue : event.address,
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? AppColors.grey300
                                    : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Image.asset(
                            'assets/icons/event card/date-time.png',
                            width: 13,
                            height: 13,
                            color: isDark
                                ? AppColors.grey300
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(event.startDateTime),
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? AppColors.grey300
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Price + Tickets available — pinned to bottom
                  Row(
                    children: [
                      Text(
                        getPriceText(event),
                        style: const TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tickets available',
                        style: const TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 12,
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
          ],
        ),
        ),
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

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to connect to server.',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                Text(
                  'Please check your connection and try again.',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(fontFamily: kFontFamily, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final String selectedCategory;
  final bool hasActiveFilters;
  final VoidCallback onReset;

  const _EmptyState({
    required this.selectedCategory,
    required this.hasActiveFilters,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              selectedCategory == 'All' && !hasActiveFilters
                  ? 'No events found'
                  : hasActiveFilters
                      ? 'No events match your filters'
                      : 'No $selectedCategory events found',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveFilters
                  ? 'Try adjusting your filters to see more events'
                  : 'Try checking back later for new events',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            if (selectedCategory != 'All' || hasActiveFilters)
              ElevatedButton(
                onPressed: onReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Show All Events',
                    style: TextStyle(fontFamily: kFontFamily)),
              ),
          ],
        ),
      ),
    );
  }
}
