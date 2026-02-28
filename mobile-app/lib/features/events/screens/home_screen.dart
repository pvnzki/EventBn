import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../providers/event_provider.dart';
import '../models/event_model.dart';
import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

// Widget imports
import '../widgets/home_search_bar.dart';
import '../widgets/promotional_banner.dart';
import '../widgets/home_categories.dart';
import '../widgets/popular_concert_section.dart';
import '../widgets/home_event_grid.dart';
import '../widgets/home_filter_modal.dart';
import '../widgets/home_search_results.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final PageController _bannerController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Event> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  bool _imagesPreloaded = false;

  // Reuse a single AuthService instance instead of creating new ones per call
  final AuthService _authService = AuthService();

  // Price caching for events
  final Map<String, double> _eventPriceCache = {};
  final Set<String> _loadingPrices = {};

  // Category filtering
  String _selectedCategory = 'All';

  // Advanced search filters
  DateTimeRange? _selectedDateRange;
  RangeValues? _selectedPriceRange;
  String _selectedLocation = 'All';

  // Available filter options
  final List<String> _locationOptions = const [
    'All',
    'Colombo',
    'Kandy',
    'Galle',
    'Jaffna',
    'Other'
  ];
  final double _minPrice = 0;
  final double _maxPrice = 10000;

  // User data
  String? _userName;

  static const List<String> _bannerImages = [
    'assets/images/manobhawa banner.jpg',
    'assets/images/alokana banner.png',
    'assets/images/parinamaya banner.png',
  ];

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'All',
      'icon': Icons.grid_view_rounded,
      'iconPath': null,
      'isSelected': true
    },
    {
      'name': 'Concerts',
      'icon': Icons.music_note_rounded,
      'iconPath': 'assets/icons/categories/concert.png',
      'isSelected': false
    },
    {
      'name': 'Sports',
      'icon': Icons.sports_soccer_rounded,
      'iconPath': 'assets/icons/categories/sport.png',
      'isSelected': false
    },
    {
      'name': 'Food',
      'icon': Icons.restaurant_rounded,
      'iconPath': 'assets/icons/categories/food.png',
      'isSelected': false
    },
    {
      'name': 'Art',
      'icon': Icons.palette_rounded,
      'iconPath': 'assets/icons/categories/art festival.png',
      'isSelected': false
    },
    {
      'name': 'Business',
      'icon': Icons.business_rounded,
      'iconPath': null,
      'isSelected': false
    },
  ];

  // Keep this page alive when switching bottom-nav tabs
  @override
  bool get wantKeepAlive => true;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  // ValueNotifier for banner index – avoids full setState on page swipe
  final ValueNotifier<int> _bannerIndexNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // NOTE: removed _searchFocusNode.addListener(setState) – the TextField
    // already handles its own focus decoration; no need to rebuild the tree.
    _preloadBannerImages();
    _startBannerAutoScroll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEvents().then((_) {
        _preloadEventPricing();
      });
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _bannerIndexNotifier.dispose();
    _debounceTimer?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Banner helpers
  // ---------------------------------------------------------------------------

  Future<void> _preloadBannerImages() async {
    for (String imagePath in _bannerImages) {
      try {
        await precacheImage(AssetImage(imagePath), context);
      } catch (e) {
        debugPrint('Error preloading banner image $imagePath: $e');
      }
    }
    if (mounted) setState(() => _imagesPreloaded = true);
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % _bannerImages.length;
        _bannerIndexNotifier.value = _currentBannerIndex;
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // User data
  // ---------------------------------------------------------------------------

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getCurrentUser();
      if (userData != null && mounted) {
        setState(() {
          _userName =
              userData.firstName.isNotEmpty ? userData.firstName : 'User';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

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
      final filteredResults = _getFilteredEvents(results);
      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      log('Search error: $e');
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  bool _hasActiveFilters() {
    return _selectedDateRange != null ||
        _selectedPriceRange != null ||
        _selectedLocation != 'All';
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedDateRange != null) count++;
    if (_selectedPriceRange != null) count++;
    if (_selectedLocation != 'All') count++;
    return count;
  }

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All filters cleared'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          onApply: () {
            Navigator.pop(context);
            if (_searchController.text.isNotEmpty) {
              _performSearch(_searchController.text);
            } else {
              setState(() {});
            }
            final filterCount = _getActiveFilterCount();
            if (filterCount > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Applied $filterCount filter${filterCount > 1 ? 's' : ''}'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
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

  // ---------------------------------------------------------------------------
  // Event filtering
  // ---------------------------------------------------------------------------

  List<Event> _getFilteredEvents(List<Event> events) {
    return events.where((event) {
      // Category filter
      if (_selectedCategory != 'All') {
        final eventCategory = event.category.toLowerCase();
        final selectedCategory = _selectedCategory.toLowerCase();

        bool categoryMatch = false;
        switch (selectedCategory) {
          case 'concerts':
            categoryMatch = eventCategory.contains('music') ||
                eventCategory.contains('concert') ||
                eventCategory.contains('entertainment');
            break;
          case 'sports':
            categoryMatch = eventCategory.contains('sport') ||
                eventCategory.contains('football') ||
                eventCategory.contains('cricket') ||
                eventCategory.contains('game');
            break;
          case 'food':
            categoryMatch = eventCategory.contains('food') ||
                eventCategory.contains('culinary') ||
                eventCategory.contains('dining') ||
                eventCategory.contains('restaurant');
            break;
          case 'art':
            categoryMatch = eventCategory.contains('art') ||
                eventCategory.contains('exhibition') ||
                eventCategory.contains('gallery') ||
                eventCategory.contains('creative');
            break;
          case 'business':
            categoryMatch = eventCategory.contains('business') ||
                eventCategory.contains('conference') ||
                eventCategory.contains('workshop') ||
                eventCategory.contains('seminar') ||
                eventCategory.contains('professional');
            break;
          default:
            categoryMatch = eventCategory.contains(selectedCategory);
        }
        if (!categoryMatch) return false;
      }

      // Date range filter
      if (_selectedDateRange != null) {
        final eventDate = event.startDateTime;
        if (eventDate.isBefore(_selectedDateRange!.start) ||
            eventDate.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }

      // Location filter
      if (_selectedLocation != 'All') {
        final eventVenue = event.venue.toLowerCase();
        final eventAddress = event.address.toLowerCase();
        final selectedLocation = _selectedLocation.toLowerCase();
        if (!eventVenue.contains(selectedLocation) &&
            !eventAddress.contains(selectedLocation)) {
          return false;
        }
      }

      // Price range filter
      if (_selectedPriceRange != null) {
        final cachedPrice = _eventPriceCache[event.id];
        if (cachedPrice != null) {
          if (cachedPrice < _selectedPriceRange!.start ||
              cachedPrice > _selectedPriceRange!.end) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Pricing
  // ---------------------------------------------------------------------------

  void _preloadEventPricing() {
    final events = context.read<EventProvider>().events;
    for (final event in events.take(6)) {
      _fetchEventPricing(event.id);
    }
  }

  Future<void> _fetchEventPricing(String eventId) async {
    if (_loadingPrices.contains(eventId) ||
        _eventPriceCache.containsKey(eventId)) {
      return;
    }

    _loadingPrices.add(eventId);

    try {
      final token = await _authService.getStoredToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final url = '${AppConfig.baseUrl}/api/events/$eventId/seatmap';
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final seatMapData = data['data']['seats'] as List?;
          if (seatMapData != null && seatMapData.isNotEmpty) {
            double? lowestPrice;
            for (var seat in seatMapData) {
              if (seat['price'] != null) {
                final price = (seat['price'] as num).toDouble();
                if (lowestPrice == null || price < lowestPrice) {
                  lowestPrice = price;
                }
              }
            }
            if (lowestPrice != null && lowestPrice > 0) {
              _eventPriceCache[eventId] = lowestPrice;
              if (mounted) setState(() {});
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Could not fetch pricing for event $eventId: $e');
    } finally {
      _loadingPrices.remove(eventId);
    }
  }

  String _getEventPriceText(Event event) {
    final cachedPrice = _eventPriceCache[event.id];
    if (cachedPrice != null && cachedPrice > 0) {
      return 'LKR ${cachedPrice.toStringAsFixed(0)}';
    }

    final price = event.cheapestPrice;
    if (price > 0) {
      return 'LKR ${price.toStringAsFixed(0)}';
    }

    if (!_loadingPrices.contains(event.id) &&
        !_eventPriceCache.containsKey(event.id)) {
      _fetchEventPricing(event.id);
    }

    return _getEstimatedPrice(event);
  }

  String _getEstimatedPrice(Event event) {
    final category = event.category.toLowerCase();
    final capacity = event.totalCapacity;

    int basePrice = 500;
    switch (category) {
      case 'music':
      case 'concert':
        basePrice = capacity > 2000 ? 1500 : 1000;
        break;
      case 'tech':
      case 'conference':
      case 'summit':
        basePrice = capacity > 500 ? 2500 : 1500;
        break;
      case 'art':
      case 'gallery':
        basePrice = 800;
        break;
      case 'food':
      case 'wine':
        basePrice = 1200;
        break;
      case 'sports':
        basePrice = capacity > 1000 ? 2000 : 1000;
        break;
      default:
        basePrice = 500;
    }

    if (capacity > 5000) {
      basePrice = (basePrice * 1.5).round();
    } else if (capacity < 100) {
      basePrice = (basePrice * 1.3).round();
    }

    return 'From LKR $basePrice';
  }

  // ---------------------------------------------------------------------------
  // Category tap
  // ---------------------------------------------------------------------------

  void _onCategoryTap(int index) {
    setState(() {
      for (var cat in _categories) {
        cat['isSelected'] = false;
      }
      _categories[index]['isSelected'] = true;
      _selectedCategory = _categories[index]['name'];
    });

    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  // ---------------------------------------------------------------------------
  // Reset all filters & category
  // ---------------------------------------------------------------------------

  void _resetAllFilters() {
    setState(() {
      for (var cat in _categories) {
        cat['isSelected'] = cat['name'] == 'All';
      }
      _selectedCategory = 'All';
      _selectedDateRange = null;
      _selectedPriceRange = null;
      _selectedLocation = 'All';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filters and category reset'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: _searchController.text.isNotEmpty
            ? Column(
                children: [
                  const SizedBox(height: 16),
                  HomeSearchBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    onClear: _clearSearch,
                    onFilterTap: _showFilterModal,
                    hasActiveFilters: _hasActiveFilters(),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: HomeSearchResults(
                        isSearching: _isSearching,
                        searchResults: _searchResults,
                        selectedCategory: _selectedCategory,
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    HomeSearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      onClear: _clearSearch,
                      onFilterTap: _showFilterModal,
                      hasActiveFilters: _hasActiveFilters(),
                    ),
                    const SizedBox(height: 20),

                    // --- Promotional Banner (RepaintBoundary isolates
                    //     the PageView from rest of the tree) ---
                    RepaintBoundary(
                      child: PromotionalBanner(
                        controller: _bannerController,
                        bannerImages: _bannerImages,
                        imagesPreloaded: _imagesPreloaded,
                        onPageChanged: (index) {
                          _currentBannerIndex = index;
                          _bannerIndexNotifier.value = index;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Dot indicators – only this tiny widget rebuilds
                    //     when the page changes, not the whole screen ---
                    ValueListenableBuilder<int>(
                      valueListenable: _bannerIndexNotifier,
                      builder: (_, currentIndex, __) {
                        return BannerPageIndicators(
                          count: _bannerImages.length,
                          currentIndex: currentIndex,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    HomeCategories(
                      categories: _categories,
                      onCategoryTap: _onCategoryTap,
                    ),
                    const SizedBox(height: 24),

                    // --- Popular Concert Section (contains BackdropFilter
                    //     cards — isolate repaint) ---
                    RepaintBoundary(
                      child: PopularConcertSection(
                        getPriceText: _getEventPriceText,
                        selectedCategory: _selectedCategory,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Event grid ---
                    RepaintBoundary(
                      child: HomeEventGrid(
                        filterEvents: (events) => events,
                        selectedCategory: 'All',
                        hasActiveFilters: _hasActiveFilters(),
                        onResetFilters: _resetAllFilters,
                        onRetry: () {
                          context
                              .read<EventProvider>()
                              .fetchEvents()
                              .then((_) => _preloadEventPricing());
                        },
                        getPriceText: _getEventPriceText,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }
}
