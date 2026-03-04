import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/app_colors.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'popular_event_card.dart';

class PopularConcertSection extends StatelessWidget {
  /// Callback to get price text for an event.
  final String Function(Event event) getPriceText;

  /// Currently-selected home-screen category (e.g. 'All', 'Concerts').
  final String selectedCategory;

  const PopularConcertSection({
    super.key,
    required this.getPriceText,
    this.selectedCategory = 'All',
  });

  /// Returns a user-friendly section title based on [selectedCategory].
  String _sectionTitle(bool hasFilteredEvents) {
    if (selectedCategory == 'All') return 'Popular Events';
    // Strip trailing 's' for nicer label ("Concerts" → "Concert")
    final label = selectedCategory.endsWith('s')
        ? selectedCategory.substring(0, selectedCategory.length - 1)
        : selectedCategory;
    return 'Popular $label';
  }

  /// Filters events by [selectedCategory]. When 'All', returns everything.
  List<Event> _filterByCategory(List<Event> events) {
    if (selectedCategory == 'All') return events;
    final sel = selectedCategory.toLowerCase();
    return events.where((e) {
      final cat = (e.category ?? '').toLowerCase();
      switch (sel) {
        case 'concerts':
          return cat.contains('music') ||
              cat.contains('concert') ||
              cat.contains('entertainment');
        case 'sports':
          return cat.contains('sport') ||
              cat.contains('football') ||
              cat.contains('cricket') ||
              cat.contains('game');
        case 'food':
          return cat.contains('food') ||
              cat.contains('culinary') ||
              cat.contains('dining') ||
              cat.contains('restaurant');
        case 'art':
          return cat.contains('art') ||
              cat.contains('exhibition') ||
              cat.contains('gallery') ||
              cat.contains('creative');
        case 'business':
          return cat.contains('business') ||
              cat.contains('conference') ||
              cat.contains('workshop') ||
              cat.contains('seminar') ||
              cat.contains('professional');
        default:
          return cat.contains(sel);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        if (eventProvider.isLoading || eventProvider.error != null) {
          return const SizedBox.shrink();
        }

        // Filter by selected category, then take top 8
        final displayEvents =
            _filterByCategory(eventProvider.events).take(8).toList();

        if (displayEvents.isEmpty) return const SizedBox.shrink();

        final title = _sectionTitle(displayEvents.isNotEmpty);
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        // Build "See all" route with the right filter
        final filterParam = selectedCategory == 'All'
            ? ''
            : '&filter=${Uri.encodeComponent(selectedCategory)}';
        final seeAllRoute =
            '/all-events?title=${Uri.encodeComponent(title)}$filterParam';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      context.push(seeAllRoute);
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
            SizedBox(
              height: 265,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                addAutomaticKeepAlives: false,
                cacheExtent: 500,
                itemCount: displayEvents.length,
                itemBuilder: (context, index) {
                  final event = displayEvents[index];
                  return RepaintBoundary(
                    child: PopularEventCard(
                      event: event,
                      isDark: isDark,
                      getPriceText: getPriceText,
                      width: 225,
                      rightMargin: 16,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

