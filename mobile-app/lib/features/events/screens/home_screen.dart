import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import 'dart:async';
import 'dart:ui';

import '../providers/event_provider.dart';
import '../models/event_model.dart';

import '../widgets/mini_game_overlay.dart';

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
      context.read<EventProvider>().fetchEvents();
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

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded, 'color': 0xFF1A1A1A, 'isSelected': true},
    {'name': 'Concerts', 'icon': Icons.music_note_rounded, 'color': 0xFF6366F1, 'isSelected': false},
    {'name': 'Sports', 'icon': Icons.sports_soccer_rounded, 'color': 0xFF10B981, 'isSelected': false},
    {'name': 'Food', 'icon': Icons.restaurant_rounded, 'color': 0xFFF59E0B, 'isSelected': false},
    {'name': 'Art', 'icon': Icons.palette_rounded, 'color': 0xFFEF4444, 'isSelected': false},
    {'name': 'Business', 'icon': Icons.business_rounded, 'color': 0xFF8B5CF6, 'isSelected': false},
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
        print('Banner auto-scroll: moving to index $_currentBannerIndex of ${_bannerImages.length} total banners');
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
      setState(() {
        _searchResults = results;
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
                suffixIcon: _searchController.text.isNotEmpty
                    ? Container(
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
                      )
                    : null,
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.3), // Center the loading
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.2), // Dynamic spacing
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
          child: Text(
            'Search Results (${_searchResults.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
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
        const SizedBox(height: 2), // Keep user's preferred spacing
        _buildCategories(),
        const SizedBox(height: 32),
        _buildEventGrid(),
        const SizedBox(height: 16), // Reduced since we're adding proper padding in the main scroll view
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
                              SizedBox(height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16),
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
                        SizedBox(height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16),
                      ],
                    ),
                  ),
          ),
        ),
        const MiniGameOverlay(),
      ],
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Header Logo - Theme aware (restored from original)
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
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
          ),
          const Spacer(),
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
        // Ambient background effect with smooth transitions - spread around all sides (dark mode only)
        if (_imagesPreloaded && Theme.of(context).brightness == Brightness.dark)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1200),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Container(
              key: ValueKey(_currentBannerIndex),
              child: Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8), // Slightly inset
                  child: Transform.translate(
                    offset: const Offset(0, -10), // Extend upward
                    child: Container(
                      height: 180, // Increased height to extend on all sides
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5), // Slightly less rounded for broader effect
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55), // Increased blur for broader spread
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(_bannerImages[_currentBannerIndex]),
                                fit: BoxFit.cover,
                                onError: (error, stackTrace) {
                                  print('Error loading banner background image: $error');
                                },
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  radius: 1.6, // Larger radius for broader spread
                                  colors: [
                                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
                                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
                                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                                  ],
                                  stops: const [0.0, 0.4, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
                    print('Building banner item at index: $index, image: ${_bannerImages[index]}');
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
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: _imagesPreloaded
                                ? Image.asset(
                                    _bannerImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading banner image ${_bannerImages[index]}: $error');
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Theme.of(context).primaryColor.withOpacity(0.7),
                                              Theme.of(context).primaryColor.withOpacity(0.9),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image_not_supported_outlined,
                                                color: Colors.white.withOpacity(0.8),
                                                size: 40,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Banner ${index + 1}',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
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
                                          Theme.of(context).primaryColor.withOpacity(0.3),
                                          Theme.of(context).primaryColor.withOpacity(0.5),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
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
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
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
                      onPressed: () => eventProvider.fetchEvents(),
                      child: const Text('Retry', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        if (eventProvider.events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text('No events found'),
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
              childAspectRatio: 0.65, // Made taller to accommodate the new design
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: eventProvider.events.length,
            itemBuilder: (context, index) {
              final event = eventProvider.events[index];
              return _buildEventCard(event);
            },
          ),
        );
      },
    );
  }

  String _getEventPriceText(Event event) {
    // Check if event has ticket types with pricing
    if (event.ticketTypes.isNotEmpty) {
      final lowestPrice = event.ticketTypes.map((t) => t.price).reduce((a, b) => a < b ? a : b);
      if (lowestPrice > 0) {
        return 'From LKR ${lowestPrice.toStringAsFixed(0)}';
      }
    }
    return 'Free Event';
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '4.8',
                                    style: const TextStyle(
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
                                event.address.isNotEmpty ? event.address : event.venue,
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
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
