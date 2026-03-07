import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/theme/design_tokens.dart';
import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';
import '../widgets/popular_event_card.dart';
import '../widgets/home_search_results.dart';
import '../widgets/home_filter_modal.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Search Screen — Figma node 2131:17888
//
//  Full-page search experience with:
//    • Search bar + filter button at top
//    • Category grid (3 columns × 2 rows)
//    • Popular events horizontal scroll
//    • Live search results when user types
// ═══════════════════════════════════════════════════════════════════════════════

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final AuthService _authService = AuthService();

  List<Event> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  // Price caching
  final Map<String, double> _priceCache = {};
  final Set<String> _loadingPrices = {};

  // Filter state
  DateTimeRange? _selectedDateRange;
  RangeValues? _selectedPriceRange;
  String _selectedLocation = 'All';
  final List<String> _locationOptions = const [
    'All',
    'Colombo',
    'Kandy',
    'Galle',
    'Jaffna',
    'Other',
  ];
  final double _minPrice = 0;
  final double _maxPrice = 10000;

  // Categories matching Figma design
  static const List<_CategoryItem> _categories = [
    _CategoryItem(
      name: 'Concert',
      filterKey: 'Concerts',
      iconPath: 'assets/icons/categories/concert.png',
      fallbackIcon: Icons.music_note_rounded,
    ),
    _CategoryItem(
      name: 'Sport',
      filterKey: 'Sports',
      iconPath: 'assets/icons/categories/sport.png',
      fallbackIcon: Icons.sports_soccer_rounded,
    ),
    _CategoryItem(
      name: 'Theater',
      filterKey: 'Theater',
      iconPath: 'assets/icons/categories/theater.png',
      fallbackIcon: Icons.theater_comedy_rounded,
    ),
    _CategoryItem(
      name: 'Film',
      filterKey: 'Film',
      iconPath: 'assets/icons/categories/film.png',
      fallbackIcon: Icons.movie_rounded,
    ),
    _CategoryItem(
      name: 'Fashion Show',
      filterKey: 'Fashion',
      iconPath: 'assets/icons/categories/fashion show.png',
      fallbackIcon: Icons.checkroom_rounded,
    ),
    _CategoryItem(
      name: 'Arts Festival',
      filterKey: 'Art',
      iconPath: 'assets/icons/categories/art festival.png',
      fallbackIcon: Icons.palette_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
    // Rebuild when focus changes so the border updates
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ── Search logic ──────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final eventProvider = context.read<EventProvider>();
      final results = await eventProvider.searchEvents(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      log('Search error: $e');
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  // ── Price fetching ────────────────────────────────────────────────────────

  Future<void> _fetchEventPrice(Event event) async {
    if (_priceCache.containsKey(event.id) ||
        _loadingPrices.contains(event.id)) return;

    _loadingPrices.add(event.id);
    try {
      final token = await _authService.getStoredToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final url = '${AppConfig.baseUrl}/api/events/${event.id}/seatmap';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final seats = data['data']['seats'] as List?;
          if (seats != null && seats.isNotEmpty) {
            double? lowest;
            for (var s in seats) {
              if (s['price'] != null) {
                final p = (s['price'] as num).toDouble();
                if (lowest == null || p < lowest) lowest = p;
              }
            }
            if (lowest != null && lowest > 0 && mounted) {
              setState(() => _priceCache[event.id] = lowest!);
            }
          }
        }
      }
    } catch (e) {
      log('Price fetch error for ${event.id}: $e');
    } finally {
      _loadingPrices.remove(event.id);
    }
  }

  String _getPriceText(Event event) {
    if (_priceCache.containsKey(event.id)) {
      final price = _priceCache[event.id]!;
      if (price == 0) return 'Free';
      return 'LKR ${price.toStringAsFixed(0)}';
    }
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
    _fetchEventPrice(event);
    return '...';
  }

  // ── Filter modal ───────────────────────────────────────────────────────

  bool get _hasActiveFilters =>
      _selectedDateRange != null ||
      _selectedPriceRange != null ||
      _selectedLocation != 'All';

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => HomeFilterModal(
          selectedDateRange: _selectedDateRange,
          selectedPriceRange: _selectedPriceRange,
          selectedLocation: _selectedLocation,
          locationOptions: _locationOptions,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          setModalState: setModalState,
          onClearAll: () {
            setState(() {
              _selectedDateRange = null;
              _selectedPriceRange = null;
              _selectedLocation = 'All';
            });
            setModalState(() {});
          },
          onApply: () {
            Navigator.pop(context);
            if (_searchController.text.isNotEmpty) {
              _performSearch(_searchController.text);
            }
            setState(() {});
          },
          onSelectDateRange: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: _selectedDateRange,
            );
            if (picked != null) {
              setState(() => _selectedDateRange = picked);
              setModalState(() {});
            }
          },
          onDateRangeChanged: (value) {
            setState(() => _selectedDateRange = value);
            setModalState(() {});
          },
          onPriceRangeChanged: (value) {
            setState(() => _selectedPriceRange = value);
            setModalState(() {});
          },
          onLocationChanged: (value) {
            setState(() => _selectedLocation = value);
            setModalState(() {});
          },
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColors.bgLight;
    final hasQuery = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // ── Search bar + filter button ──
            _buildSearchBar(isDark),
            const SizedBox(height: 24),
            // ── Content: search results or default browse ──
            Expanded(
              child: hasQuery
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: HomeSearchResults(
                        isSearching: _isSearching,
                        searchResults: _searchResults,
                        selectedCategory: 'All',
                        searchQuery: _searchController.text,
                        getPriceText: _getPriceText,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategorySection(isDark),
                          const SizedBox(height: 24),
                          _buildPopularConcertSection(isDark),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(bool isDark) {
    final inputBg = isDark ? AppColors.surface : Colors.grey[100]!;
    final filterBg = isDark ? AppColors.bg01 : Colors.grey[200]!;
    final iconColor = isDark ? AppColors.grey200 : Colors.grey[500]!;
    final hintColor = isDark ? AppColors.grey200 : Colors.grey[500]!;
    final textColor = isDark ? AppColors.white : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Search input field
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                cursorColor: AppColors.primary,
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search event',
                  hintStyle: TextStyle(
                    fontFamily: kFontFamily,
                    color: hintColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/icons/search.png',
                      width: 24,
                      height: 24,
                      color: iconColor,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: Icon(
                            Icons.close_rounded,
                            color: iconColor,
                            size: 20,
                          ),
                        )
                      : null,
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.25)
                          : Colors.black.withOpacity(0.15),
                      width: 1.0,
                    ),
                  ),
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter button (separate, per Figma)
          GestureDetector(
            onTap: _showFilterModal,
            child: Container(
              width: 47,
              height: 44,
              decoration: BoxDecoration(
                color: _hasActiveFilters
                    ? AppColors.primary.withOpacity(0.15)
                    : filterBg,
                borderRadius: BorderRadius.circular(12),
                border: _hasActiveFilters
                    ? Border.all(color: AppColors.primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Icon(
                  Icons.tune_rounded,
                  color: _hasActiveFilters ? AppColors.primary : iconColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category section ──────────────────────────────────────────────────────

  Widget _buildCategorySection(bool isDark) {
    final headerColor = isDark ? AppColors.white : AppColors.textPrimaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: headerColor,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to all events with no filter
                  context.push(
                      '/all-events?title=${Uri.encodeComponent("All Events")}');
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 3-column grid of category cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 12.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * 2) / 3; // 3 columns
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _categories.map((cat) {
                  return _buildCategoryCard(cat, cardWidth, isDark);
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
      _CategoryItem category, double width, bool isDark) {
    final cardBg = isDark ? AppColors.surface : Colors.white;
    final iconColor = isDark ? AppColors.white : AppColors.textPrimaryLight;
    final labelColor = isDark ? AppColors.white : AppColors.textPrimaryLight;

    return GestureDetector(
      onTap: () {
        context.push(
          '/all-events?title=${Uri.encodeComponent(category.name)}&filter=${Uri.encodeComponent(category.filterKey)}',
        );
      },
      child: Container(
        width: width,
        height: 61,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              category.iconPath,
              width: 24,
              height: 24,
              color: iconColor,
              errorBuilder: (_, __, ___) => Icon(
                category.fallbackIcon,
                size: 24,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.name,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Popular Concert section ───────────────────────────────────────────────

  Widget _buildPopularConcertSection(bool isDark) {
    final headerColor = isDark ? AppColors.white : AppColors.textPrimaryLight;

    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        if (eventProvider.isLoading || eventProvider.error != null) {
          return const SizedBox.shrink();
        }

        final events = eventProvider.events.take(8).toList();
        if (events.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular Concert',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: headerColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push(
                        '/all-events?title=${Uri.encodeComponent("Popular Concert")}',
                      );
                    },
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Horizontal scroll of event cards
            SizedBox(
              height: 265,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                addAutomaticKeepAlives: false,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return RepaintBoundary(
                    child: PopularEventCard(
                      event: events[index],
                      isDark: isDark,
                      getPriceText: _getPriceText,
                      width: 225,
                      rightMargin: 12,
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

// ── Data class for category items ───────────────────────────────────────────

class _CategoryItem {
  final String name;
  final String filterKey;
  final String iconPath;
  final IconData fallbackIcon;

  const _CategoryItem({
    required this.name,
    required this.filterKey,
    required this.iconPath,
    required this.fallbackIcon,
  });
}
