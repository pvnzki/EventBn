import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../providers/event_provider.dart';
import '../models/event_model.dart';
import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Event> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  bool _imagesPreloaded = false;

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
  final List<String> _locationOptions = [
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

  final List<String> _bannerImages = [
    'assets/images/manobhawa banner.jpg',
    'assets/images/alokana banner.png',
    'assets/images/parinamaya banner.png',
  ];

  @override
  void initState() {
    super.initState();
    print('HomeScreen initialized - fetching real events from API');
    print('Banner images loaded: ${_bannerImages.length} total');
    for (int i = 0; i < _bannerImages.length; i++) {
      print('Banner $i: ${_bannerImages[i]}');
    }

    // Load user data
    _loadUserData();

    // Add focus listener to trigger rebuilds for search bar styling
    _searchFocusNode.addListener(() {
      setState(() {});
    });

    // Preload banner images for faster rendering
    _preloadBannerImages();

    // Start auto-scrolling banner
    _startBannerAutoScroll();

    // Fetch events when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEvents().then((_) {
        // Preload pricing for the first few events after events are loaded
        _preloadEventPricing();
      });
    });
  }

  // Preload banner images to improve performance
  Future<void> _preloadBannerImages() async {
    for (String imagePath in _bannerImages) {
      try {
        await precacheImage(AssetImage(imagePath), context);
        print('Preloaded banner image: $imagePath');
      } catch (e) {
        print('Error preloading banner image $imagePath: $e');
      }
    }
    if (mounted) {
      setState(() {
        _imagesPreloaded = true;
      });
      print('All banner images preloaded successfully');
    }
  }

  // Load user data for greeting
  Future<void> _loadUserData() async {
    try {
      final authService = AuthService();
      final userData = await authService.getCurrentUser();
      if (userData != null && mounted) {
        setState(() {
          _userName =
              userData.firstName.isNotEmpty ? userData.firstName : 'User';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'All',
      'icon': Icons.grid_view_rounded,
      'color': 0xFF1A1A1A,
      'isSelected': true
    },
    {
      'name': 'Concerts',
      'icon': Icons.music_note_rounded,
      'color': 0xFF6366F1,
      'isSelected': false
    },
    {
      'name': 'Sports',
      'icon': Icons.sports_soccer_rounded,
      'color': 0xFF10B981,
      'isSelected': false
    },
    {
      'name': 'Food',
      'icon': Icons.restaurant_rounded,
      'color': 0xFFF59E0B,
      'isSelected': false
    },
    {
      'name': 'Art',
      'icon': Icons.palette_rounded,
      'color': 0xFFEF4444,
      'isSelected': false
    },
    {
      'name': 'Business',
      'icon': Icons.business_rounded,
      'color': 0xFF8B5CF6,
      'isSelected': false
    },
  ];

  @override
  void dispose() {
    _bannerController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % _bannerImages.length;
        print(
            'Banner auto-scroll: moving to index $_currentBannerIndex of ${_bannerImages.length} total banners');
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

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
    setState(() {
      _isSearching = true;
    });

    try {
      final eventProvider = context.read<EventProvider>();
      final results = await eventProvider.searchEvents(query);

      // Apply category filtering to search results as well
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

  // Check if any advanced filters are active
  bool _hasActiveFilters() {
    return _selectedDateRange != null ||
        _selectedPriceRange != null ||
        _selectedLocation != 'All';
  }

  // Show the filter modal
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => _buildFilterModal(setState),
      ),
    );
  }

  // Clear all filters
  void _clearAllFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedPriceRange = null;
      _selectedLocation = 'All';
    });

    // Show feedback when filters are cleared
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All filters cleared'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Apply filters
  void _applyFilters() {
    Navigator.pop(context);
    // If there's an active search, re-perform it with filters
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    } else {
      // Just refresh the UI to show filtered events
      setState(() {});
    }

    // Show feedback message when filters are applied
    final filterCount = _getActiveFilterCount();
    if (filterCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Applied $filterCount filter${filterCount > 1 ? 's' : ''}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Get count of active filters for better UX feedback
  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedDateRange != null) count++;
    if (_selectedPriceRange != null) count++;
    if (_selectedLocation != 'All') count++;
    return count;
  }

  // Select date range
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  // Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get filtered events based on all active filters
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

      // Price range filter (using cached prices if available)
      if (_selectedPriceRange != null) {
        final cachedPrice = _eventPriceCache[event.id];
        if (cachedPrice != null) {
          if (cachedPrice < _selectedPriceRange!.start ||
              cachedPrice > _selectedPriceRange!.end) {
            return false;
          }
        }
        // If no cached price, we can't filter by price for this event
        // so we include it to avoid filtering out events with unknown prices
      }

      return true;
    }).toList();
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 56,
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surface.withOpacity(0.8)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _searchFocusNode.hasFocus
                ? theme.primaryColor.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.2),
            width: _searchFocusNode.hasFocus ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : theme.colorScheme.onSurface.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            if (_searchFocusNode.hasFocus)
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!_searchFocusNode.hasFocus) {
                _searchFocusNode.requestFocus();
              }
            },
            borderRadius: BorderRadius.circular(28),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              cursorColor: theme.primaryColor,
              cursorRadius: const Radius.circular(2),
              cursorWidth: 2,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'Search for events',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.search_rounded,
                      color: _searchFocusNode.hasFocus
                          ? theme.primaryColor
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      size: 24,
                    ),
                  ),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Filter button
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showFilterModal,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _hasActiveFilters()
                                  ? theme.primaryColor.withOpacity(0.2)
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: _hasActiveFilters()
                                  ? theme.primaryColor
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Clear button (only shown when there's text)
                    if (_searchController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _clearSearch,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                filled: false,
                isDense: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isSearching) {
      return Column(
        children: [
          SizedBox(
              height: MediaQuery.of(context).size.height *
                  0.3), // Center the loading
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
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 120), // Add bottom padding for floating nav
        ],
      );
    }

    if (_searchResults.isEmpty) {
      return Column(
        children: [
          SizedBox(
              height:
                  MediaQuery.of(context).size.height * 0.2), // Dynamic spacing
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
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching with different keywords',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 120), // Add bottom padding for floating nav
        ],
      );
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
                'Search Results (${_searchResults.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (_selectedCategory != 'All') ...[
                const SizedBox(height: 4),
                Text(
                  'Filtered by: $_selectedCategory',
                  style: TextStyle(
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
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final event = _searchResults[index];
            return GestureDetector(
              onTap: () => context.push('/events/${event.id}'),
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
                      spreadRadius: 0,
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
                                  image: CachedNetworkImageProvider(
                                      event.imageUrl),
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
          },
        ),
        const SizedBox(height: 120), // Add bottom padding for floating nav
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _bannerImages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          width: _currentBannerIndex == index ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentBannerIndex == index
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            boxShadow: _currentBannerIndex == index
                ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContentWithoutSearchBar() {
    return Column(
      children: [
        _buildPromotionalBanner(),
        const SizedBox(height: 8), // Increased gap between banner and indicator
        _buildPageIndicators(),
        const SizedBox(height: 16), // Keep user's preferred spacing
        _buildCategories(),
        const SizedBox(height: 32),
        _buildEventGrid(),
        const SizedBox(
            height:
                16), // Reduced since we're adding proper padding in the main scroll view
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          color: theme.scaffoldBackgroundColor,
          child: SafeArea(
            child: _searchController.text.isNotEmpty
                ? Column(
                    children: [
                      // Fixed header and search bar
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      // Expanded search results to fill remaining space
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildSearchResults(),
                              // Add bottom padding for search results too
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).padding.bottom +
                                          kBottomNavigationBarHeight +
                                          16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildSearchBar(),
                        const SizedBox(height: 24),
                        _buildMainContentWithoutSearchBar(),
                        // Add bottom padding to account for bottom navigation bar
                        SizedBox(
                            height: MediaQuery.of(context).padding.bottom +
                                kBottomNavigationBarHeight +
                                16),
                      ],
                    ),
                  ),
          ),
        ),

        // Floating Mini Game Button with Shimmer Effect
        const Positioned(
          right: 16,
          bottom: 80,
          child: ShimmerGameButton(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          // Header Logo with greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                SizedBox(
                  height: 30,
                  child: Image.asset(
                    isDark
                        ? 'assets/images/White Header logo.png'
                        : 'assets/images/Black header logo.png',
                    height: 30,
                    width: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'EventBn',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      );
                    },
                  ),
                ),
                // Greeting text
                if (_userName != null) ...[
                  const SizedBox(height: 9),
                  Text(
                    '    Hi, $_userName👋',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Notification icon (kept modern style)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Stack(
      children: [
        // Ambient background effect removed to fix Android APK crash in dark mode
        // Main banner content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 180,
            child: Stack(
              children: [
                // PageView for multiple banner containers with smooth transitions
                PageView.builder(
                  controller: _bannerController,
                  onPageChanged: (index) {
                    print('PageView changed to index: $index');
                    setState(() {
                      _currentBannerIndex = index;
                    });
                  },
                  itemCount: _bannerImages.length,
                  itemBuilder: (context, index) {
                    print(
                        'Building banner item at index: $index, image: ${_bannerImages[index]}');
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: Container(
                        key: ValueKey(index),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: _imagesPreloaded
                                ? Image.asset(
                                    _bannerImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      print(
                                          'Error loading banner image ${_bannerImages[index]}: $error');
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.7),
                                              Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.9),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .image_not_supported_outlined,
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                size: 40,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Banner ${index + 1}',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.3),
                                          Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.5),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white.withOpacity(0.8),
                                        ),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventGrid() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        if (eventProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (eventProvider.error != null) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unable to connect to server.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          Text(
                            'Please check your connection and try again.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        eventProvider.fetchEvents().then((_) {
                          _preloadEventPricing();
                        });
                      },
                      child:
                          const Text('Retry', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Apply category filtering
        final filteredEvents = _getFilteredEvents(eventProvider.events);

        if (filteredEvents.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedCategory == 'All' && !_hasActiveFilters()
                        ? 'No events found'
                        : _hasActiveFilters()
                            ? 'No events match your filters'
                            : 'No $_selectedCategory events found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasActiveFilters()
                        ? 'Try adjusting your filters to see more events'
                        : 'Try checking back later for new events',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedCategory != 'All' || _hasActiveFilters()) ...[
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Reset to "All" category
                          for (var cat in _categories) {
                            cat['isSelected'] = cat['name'] == 'All';
                          }
                          _selectedCategory = 'All';
                          // Clear all filters
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Show All Events'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio:
                  0.65, // Made taller to accommodate the new design
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final event = filteredEvents[index];
              return _buildEventCard(event);
            },
          ),
        );
      },
    );
  }

  // Preload pricing for first few events to improve user experience
  void _preloadEventPricing() {
    final events = context.read<EventProvider>().events;
    // Preload pricing for the first 6 events (what's typically visible)
    final eventsToPreload = events.take(6);

    for (final event in eventsToPreload) {
      _fetchEventPricing(event.id);
    }
  }

  // Fetch pricing information for an event from seatmap API
  Future<void> _fetchEventPricing(String eventId) async {
    if (_loadingPrices.contains(eventId) ||
        _eventPriceCache.containsKey(eventId)) {
      return; // Already loading or cached
    }

    _loadingPrices.add(eventId);

    try {
      final authService = AuthService();
      final token = await authService.getStoredToken();
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
            // Find the lowest price from seat data
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
              if (mounted) {
                setState(() {});
              }
            }
          }
        }
      }
    } catch (e) {
      // Silently handle errors - pricing is not critical for the list view
      print('Could not fetch pricing for event $eventId: $e');
    } finally {
      _loadingPrices.remove(eventId);
    }
  }

  String _getEventPriceText(Event event) {
    // Check if we have cached pricing data
    final cachedPrice = _eventPriceCache[event.id];
    if (cachedPrice != null && cachedPrice > 0) {
      return 'LKR ${cachedPrice.toStringAsFixed(0)}';
    }

    // Use the cheapestPrice getter from Event model as fallback
    final price = event.cheapestPrice;
    if (price > 0) {
      return 'LKR ${price.toStringAsFixed(0)}';
    }

    // Fetch pricing data in the background if not already loading
    if (!_loadingPrices.contains(event.id) &&
        !_eventPriceCache.containsKey(event.id)) {
      _fetchEventPricing(event.id);
    }

    // Smart fallback pricing based on event category and capacity
    return _getEstimatedPrice(event);
  }

  // Provide estimated pricing based on event characteristics
  String _getEstimatedPrice(Event event) {
    // Analyze event category and capacity to provide realistic price estimates
    final category = event.category.toLowerCase();
    final capacity = event.totalCapacity;

    // Base prices by category
    int basePrice = 500; // Default base price

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

    // Adjust for capacity (premium events typically have higher capacity)
    if (capacity > 5000) {
      basePrice = (basePrice * 1.5).round();
    } else if (capacity < 100) {
      basePrice = (basePrice * 1.3).round(); // Exclusive events
    }

    return 'From LKR $basePrice';
  }

  Widget _buildEventCard(Event event) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background image covering full card
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  image: event.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(event.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: event.imageUrl.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.event_rounded,
                          size: 60,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      )
                    : null,
              ),
              // Gradient overlay for better text visibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
              // Content overlay
              Column(
                children: [
                  // Top section with price and favorite
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getEventPriceText(event),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Favorite icon
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              // Handle favorite action
                            },
                            icon: const Icon(
                              Icons.favorite_border,
                              size: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Bottom section with blurred background and text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Event title and rating
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '4.8',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Location
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.address.isNotEmpty
                                    ? event.address
                                    : event.venue,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Event details - Single row with flexible spacing
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildEventDetailWhite(
                                Icons.people,
                                '${(event.id.hashCode % 200 + 50)}',
                              ),
                              const SizedBox(width: 8),
                              _buildEventDetailWhite(
                                Icons.access_time,
                                '${event.startDateTime.hour}:${event.startDateTime.minute.toString().padLeft(2, '0')}',
                              ),
                              if (event.category.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                _buildEventDetailWhite(
                                  Icons.category,
                                  event.category,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Page indicators at the bottom center of image area
              Positioned(
                bottom: 100, // Adjusted position to avoid text overlap
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == 0
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetailWhite(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.white70,
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFilterModal(StateSetter setModalState) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Events',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Filter options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range filter
                  _buildFilterSection(
                    'Date Range',
                    _buildDateRangeFilter(theme, setModalState),
                  ),
                  const SizedBox(height: 24),
                  // Location filter
                  _buildFilterSection(
                    'Location',
                    _buildLocationFilter(theme, setModalState),
                  ),
                  const SizedBox(height: 24),
                  // Price range filter
                  _buildFilterSection(
                    'Price Range (LKR)',
                    _buildPriceRangeFilter(theme, setModalState),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildDateRangeFilter(ThemeData theme, [StateSetter? setModalState]) {
    return InkWell(
      onTap: _selectDateRange,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDateRange != null
                    ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                    : 'Select date range',
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedDateRange != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            if (_selectedDateRange != null)
              InkWell(
                onTap: () {
                  // Update the main widget state
                  setState(() {
                    _selectedDateRange = null;
                  });
                  // Also update the modal state if available
                  if (setModalState != null) {
                    setModalState(() {
                      _selectedDateRange = null;
                    });
                  }
                },
                child: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationFilter(ThemeData theme, [StateSetter? setModalState]) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _locationOptions.map((location) {
        final isSelected = _selectedLocation == location;
        return InkWell(
          onTap: () {
            // Update the main widget state
            setState(() {
              _selectedLocation = location;
            });
            // Also update the modal state if available
            if (setModalState != null) {
              setModalState(() {
                _selectedLocation = location;
              });
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              location,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeFilter(ThemeData theme, [StateSetter? setModalState]) {
    return Column(
      children: [
        if (_selectedPriceRange != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LKR ${_selectedPriceRange!.start.round()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'LKR ${_selectedPriceRange!.end.round()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        RangeSlider(
          values: _selectedPriceRange ?? RangeValues(_minPrice, _maxPrice),
          min: _minPrice,
          max: _maxPrice,
          divisions: 20,
          labels: _selectedPriceRange != null
              ? RangeLabels(
                  'LKR ${_selectedPriceRange!.start.round()}',
                  'LKR ${_selectedPriceRange!.end.round()}',
                )
              : null,
          onChanged: (RangeValues values) {
            // Update the main widget state
            setState(() {
              _selectedPriceRange = values;
            });
            // Also update the modal state if available
            if (setModalState != null) {
              setModalState(() {
                _selectedPriceRange = values;
              });
            }
          },
        ),
        if (_selectedPriceRange != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Update the main widget state
              setState(() {
                _selectedPriceRange = null;
              });
              // Also update the modal state if available
              if (setModalState != null) {
                setModalState(() {
                  _selectedPriceRange = null;
                });
              }
            },
            child: Text(
              'Clear Price Filter',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategories() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category['isSelected'] ?? false;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    // Reset all selections
                    for (var cat in _categories) {
                      cat['isSelected'] = false;
                    }
                    // Select current category
                    _categories[index]['isSelected'] = true;
                    // Update selected category for filtering
                    _selectedCategory = category['name'];
                  });

                  // If there's an active search, re-perform it with the new category filter
                  if (_searchController.text.isNotEmpty) {
                    _performSearch(_searchController.text);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.surface
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ShimmerGameButton extends StatefulWidget {
  const ShimmerGameButton({super.key});

  @override
  State<ShimmerGameButton> createState() => _ShimmerGameButtonState();
}

class _ShimmerGameButtonState extends State<ShimmerGameButton>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Shimmer animation for the overlay effect
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Pulse animation for size changes
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go('/games/spinning-wheel');
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_shimmerAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 70,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(98),
              ),
              child: Stack(
                children: [
                  // Base image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(98),
                    child: Transform.scale(
                      scale: 1.35,
                      child: Image.asset(
                        'assets/icons/Offers_Green.png',
                        fit: BoxFit.cover,
                        width: 90,
                        height: 90,
                      ),
                    ),
                  ),
                  // Shimmer overlay - now fits exactly to the button
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [
                            _shimmerAnimation.value - 0.3,
                            _shimmerAnimation.value,
                            _shimmerAnimation.value + 0.3,
                          ],
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
