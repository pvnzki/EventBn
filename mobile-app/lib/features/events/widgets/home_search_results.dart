import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/event_model.dart';
import 'popular_event_card.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  HomeSearchResults — Figma nodes 2131:18057 (empty) & 2131:18212 (found)
//
//  Two states:
//    • Empty  → "Oops not Event!" illustration + query-specific subtitle
//    • Found  → Query header label + vertical list of full-width event cards
//  Both theme-aware (light / dark).
// ═══════════════════════════════════════════════════════════════════════════════

class HomeSearchResults extends StatelessWidget {
  final bool isSearching;
  final List<Event> searchResults;
  final String selectedCategory;

  /// The raw search query text — shown in empty-state subtitle and header.
  final String searchQuery;

  /// Callback from parent (SearchScreen) that returns a price label for an
  /// event, e.g. "LKR 2500" or "Free" or "...".
  final String Function(Event)? getPriceText;

  const HomeSearchResults({
    super.key,
    required this.isSearching,
    required this.searchResults,
    required this.selectedCategory,
    this.searchQuery = '',
    this.getPriceText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isSearching) {
      return _SearchingIndicator(isDark: isDark);
    }

    if (searchResults.isEmpty) {
      return _EmptyResults(isDark: isDark, query: searchQuery);
    }

    return _FoundResults(
      isDark: isDark,
      query: searchQuery,
      results: searchResults,
      getPriceText: getPriceText,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Searching indicator
// ═══════════════════════════════════════════════════════════════════════════════

class _SearchingIndicator extends StatelessWidget {
  final bool isDark;
  const _SearchingIndicator({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Searching events...',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.grey200 : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Empty results — Figma node 2131:18057
//
//  Centered illustration (88×88), title "Oops not Event!",
//  subtitle 'Not event for "[query]", Maybe try another!'
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyResults extends StatelessWidget {
  final bool isDark;
  final String query;
  const _EmptyResults({required this.isDark, required this.query});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.white : AppColors.textPrimaryLight;
    final subtitleColor = isDark ? AppColors.grey200 : AppColors.textSecondaryLight;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              // 88×88 illustration
              Image.asset(
                'assets/images/oops! no event.png',
                width: 88,
                height: 88,
                errorBuilder: (_, __, ___) => Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surface
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 44,
                    color: isDark ? AppColors.grey200 : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Title
              SizedBox(
                width: 343,
                child: Text(
                  'Oops not Event!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle with query
              SizedBox(
                width: 325,
                child: Text(
                  query.isNotEmpty
                      ? 'Not event for "$query", Maybe try another!'
                      : 'No events found. Maybe try another search!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Found results — Figma node 2131:18212
//
//  Query header label + vertical list of full-width event cards.
//  Card layout: poster image (170px) → title → location → date → price row
// ═══════════════════════════════════════════════════════════════════════════════

class _FoundResults extends StatelessWidget {
  final bool isDark;
  final String query;
  final List<Event> results;
  final String Function(Event)? getPriceText;

  const _FoundResults({
    required this.isDark,
    required this.query,
    required this.results,
    this.getPriceText,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor = isDark ? AppColors.white : AppColors.textPrimaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Query header label ──
        if (query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              query,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: headerColor,
                height: 1.2,
              ),
            ),
          ),
        // ── Event cards (reuse PopularEventCard — same as AllEventsScreen) ──
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return PopularEventCard(
              event: results[index],
              isDark: isDark,
              getPriceText: getPriceText ?? _fallbackPriceText,
              height: 265,
              bottomMargin: 16,
            );
          },
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  /// Fallback price resolver when parent doesn't supply [getPriceText].
  static String _fallbackPriceText(Event event) {
    if (event.ticketTypes.isNotEmpty) {
      double minPrice = double.infinity;
      for (var t in event.ticketTypes) {
        final map = t.toJson();
        final p = map['price'];
        if (p != null) {
          final price =
              (p is num) ? p.toDouble() : double.tryParse(p.toString()) ?? 0;
          if (price < minPrice) minPrice = price;
        }
      }
      if (minPrice != double.infinity) {
        if (minPrice == 0) return 'Free';
        return 'LKR ${minPrice.toStringAsFixed(0)}';
      }
    }
    return '...';
  }
}
