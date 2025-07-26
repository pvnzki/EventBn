import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _showFilters = false;

  // Filter options
  String _selectedCategory = 'All';
  String _selectedLocation = 'All';
  String _selectedDateRange = 'All';
  String _selectedPriceRange = 'All';

  final List<String> _categories = [
    'All',
    'Music',
    'Sports',
    'Food',
    'Comedy',
    'Art',
    'Business',
    'Technology'
  ];
  final List<String> _locations = [
    'All',
    'Manhattan',
    'Brooklyn',
    'Queens',
    'Bronx',
    'Staten Island'
  ];
  final List<String> _dateRanges = [
    'All',
    'Today',
    'Tomorrow',
    'This Week',
    'This Month'
  ];
  final List<String> _priceRanges = [
    'All',
    'Free',
    '\$0-\$25',
    '\$25-\$50',
    '\$50+'
  ];

  final List<String> _recentSearches = [
    'Music concert',
    'Food festival',
    'Comedy show',
    'Art exhibition',
    'Sports event',
  ];

  final List<String> _popularSearches = [
    'Jazz night',
    'Basketball game',
    'Wine tasting',
    'Stand-up comedy',
    'Rock concert',
    'Food truck festival',
    'Art gallery opening',
    'Tech conference',
  ];

  final List<Map<String, dynamic>> _searchResults = [
    {
      'id': '1',
      'title': 'International Band Music Concert',
      'date': 'Wed, Dec 18 • 6:00 PM',
      'location': 'Times Square NYC, Manhattan',
      'price': 25.0,
      'category': 'Music',
      'image':
          'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=300&h=180&fit=crop',
      'rating': 4.8,
      'attendees': 1245,
    },
    {
      'id': '2',
      'title': 'Summer Music Festival',
      'date': 'Sat, Dec 21 • 8:00 PM',
      'location': 'Central Park, NYC',
      'price': 45.0,
      'category': 'Music',
      'image':
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=180&fit=crop',
      'rating': 4.9,
      'attendees': 2840,
    },
    {
      'id': '3',
      'title': 'Jazz Night Live',
      'date': 'Sun, Dec 22 • 7:30 PM',
      'location': 'Blue Note, Manhattan',
      'price': 35.0,
      'category': 'Music',
      'image':
          'https://images.unsplash.com/photo-1511735111819-9a3f7709049c?w=300&h=180&fit=crop',
      'rating': 4.7,
      'attendees': 567,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus search bar when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      // Add to recent searches if not already there
      if (!_recentSearches.contains(query.trim())) {
        setState(() {
          _recentSearches.insert(0, query.trim());
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }
    }
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedLocation = 'All';
      _selectedDateRange = 'All';
      _selectedPriceRange = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Search Events',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSearchBar(theme, isDark),
            ),
            const SizedBox(height: 16),
            _buildFilterBar(theme, isDark),
            if (_showFilters) _buildFiltersPanel(theme, isDark),
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildSearchSuggestions()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? theme.dividerColor.withOpacity(0.3) : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'Search events...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Icon(Icons.clear, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        border: Border(
          bottom: BorderSide(color: isDark ? theme.dividerColor.withOpacity(0.2) : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _showFilters
                    ? theme.primaryColor
                    : (isDark ? theme.cardColor : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _showFilters
                      ? theme.primaryColor
                      : (isDark ? theme.dividerColor.withOpacity(0.3) : Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    size: 16,
                    color: _showFilters ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Filters',
                    style: TextStyle(
                      color: _showFilters ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (_hasActiveFilters())
            GestureDetector(
              onTap: _clearFilters,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.red.withOpacity(0.3) : Colors.red.shade200),
                ),
                child: const Text(
                  'Clear filters',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          const Spacer(),
          if (_searchQuery.isNotEmpty)
            Text(
              '${_searchResults.length} results',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != 'All' ||
        _selectedLocation != 'All' ||
        _selectedDateRange != 'All' ||
        _selectedPriceRange != 'All';
  }

  Widget _buildFiltersPanel(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: isDark ? theme.dividerColor.withOpacity(0.2) : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection('Category', _categories, _selectedCategory, (value) { setState(() => _selectedCategory = value); }, theme, isDark),
          const SizedBox(height: 16),
          _buildFilterSection('Location', _locations, _selectedLocation, (value) { setState(() => _selectedLocation = value); }, theme, isDark),
          const SizedBox(height: 16),
          _buildFilterSection('Date', _dateRanges, _selectedDateRange, (value) { setState(() => _selectedDateRange = value); }, theme, isDark),
          const SizedBox(height: 16),
          _buildFilterSection('Price', _priceRanges, _selectedPriceRange, (value) { setState(() => _selectedPriceRange = value); }, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, String selected, Function(String) onChanged, ThemeData theme, bool isDark) {
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : (isDark ? theme.cardColor : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.primaryColor
                        : (isDark ? theme.dividerColor.withOpacity(0.3) : Colors.grey.shade300),
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...(_recentSearches.map(
                (search) => _buildSearchSuggestionItem(search, Icons.history))),
            const SizedBox(height: 24),
          ],
          const Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...(_popularSearches.map((search) =>
              _buildSearchSuggestionItem(search, Icons.trending_up))),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestionItem(String text, IconData icon) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _onSearchChanged(text);
        _onSearchSubmitted(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.north_west, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final event = _searchResults[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildNoResults() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        print('Search result event tapped: ${event['id']} - ${event['title']}');
        context.push('/event/${event['id']}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                event['image'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event['date'],
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event['location'],
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event['category'],
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${event['price'].toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
