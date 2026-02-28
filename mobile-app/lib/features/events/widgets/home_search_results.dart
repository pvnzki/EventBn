import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/event_model.dart';
import '../../auth/providers/auth_provider.dart';

class HomeSearchResults extends StatelessWidget {
  final bool isSearching;
  final List<Event> searchResults;
  final String selectedCategory;

  const HomeSearchResults({
    super.key,
    required this.isSearching,
    required this.searchResults,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isSearching) {
      return _SearchingIndicator(theme: theme);
    }

    if (searchResults.isEmpty) {
      return _EmptyResults(theme: theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search Results (${searchResults.length})',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (selectedCategory != 'All') ...[
                const SizedBox(height: 4),
                Text(
                  'Filtered by: $selectedCategory',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            final event = searchResults[index];
            return _SearchResultCard(event: event, isDark: isDark);
          },
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Searching indicator
// ---------------------------------------------------------------------------
class _SearchingIndicator extends StatelessWidget {
  final ThemeData theme;
  const _SearchingIndicator({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: theme.primaryColor,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Searching events...',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty results
// ---------------------------------------------------------------------------
class _EmptyResults extends StatelessWidget {
  final ThemeData theme;
  const _EmptyResults({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No events found',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search result card
// ---------------------------------------------------------------------------
class _SearchResultCard extends StatelessWidget {
  final Event event;
  final bool isDark;

  const _SearchResultCard({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.isGuestMode) {
          context.push('/guest/events/${event.id}');
        } else {
          context.push('/events/${event.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : theme.colorScheme.onSurface.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: event.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(event.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: event.imageUrl.isEmpty
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : null,
                ),
                child: event.imageUrl.isEmpty
                    ? Icon(
                        Icons.event_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.venue,
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (event.category.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.category,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 12,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
