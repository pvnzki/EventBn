import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/theme/design_tokens.dart';
import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';
import '../widgets/popular_event_card.dart';
import '../widgets/home_categories.dart';

class AllEventsScreen extends StatefulWidget {
  final String screenTitle;
  final String initialFilter;

  const AllEventsScreen({
    super.key,
    this.screenTitle = 'All Events',
    this.initialFilter = 'All',
  });

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  late String _selectedFilter;

  // Same category list as the home screen — includes icons.
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded, 'iconPath': null, 'isSelected': true},
    {'name': 'Concerts', 'icon': Icons.music_note_rounded, 'iconPath': 'assets/icons/categories/concert.png', 'isSelected': false},
    {'name': 'Sports', 'icon': Icons.sports_soccer_rounded, 'iconPath': 'assets/icons/categories/sport.png', 'isSelected': false},
    {'name': 'Food', 'icon': Icons.restaurant_rounded, 'iconPath': 'assets/icons/categories/food.png', 'isSelected': false},
    {'name': 'Art', 'icon': Icons.palette_rounded, 'iconPath': 'assets/icons/categories/art festival.png', 'isSelected': false},
    {'name': 'Business', 'icon': Icons.business_rounded, 'iconPath': null, 'isSelected': false},
  ];

  // Price caching
  final Map<String, double> _priceCache = {};
  final Set<String> _loadingPrices = {};

  @override
  void initState() {
    super.initState();
    // Normalise initial filter coming from the route (e.g. "Concert" → "Concerts")
    _selectedFilter = _normaliseFilter(widget.initialFilter);
    // Mark initial chip as selected
    _syncChipSelection();
  }

  /// Map singular/variant filter names to the chip labels used here.
  String _normaliseFilter(String raw) {
    final lower = raw.toLowerCase();
    for (final c in _categories) {
      final name = c['name'] as String;
      if (name.toLowerCase() == lower) return name;
      if (name.toLowerCase().startsWith(lower)) return name;
    }
    return 'All';
  }

  void _syncChipSelection() {
    for (var c in _categories) {
      c['isSelected'] = c['name'] == _selectedFilter;
    }
  }

  void _onCategoryTap(int index) {
    setState(() {
      _selectedFilter = _categories[index]['name'];
      _syncChipSelection();
    });
  }

  // ── Category filtering — same logic as PopularConcertSection ────────────
  List<Event> _filteredEvents(List<Event> events) {
    if (_selectedFilter == 'All') return events;
    final sel = _selectedFilter.toLowerCase();
    return events.where((event) {
      final cat = (event.category ?? '').toLowerCase();
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

  // ── Price fetching ──────────────────────────────────────────────────────
  Future<void> _fetchEventPrice(Event event) async {
    if (_priceCache.containsKey(event.id) ||
        _loadingPrices.contains(event.id)) return;

    _loadingPrices.add(event.id);
    try {
      final authService = AuthService();
      final token = await authService.getStoredToken();
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

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<EventProvider>(
          builder: (context, eventProvider, child) {
            final events = _filteredEvents(eventProvider.events);
            return Column(
              children: [
                _buildTopBar(context),
                const SizedBox(height: 16),
                HomeCategories(
                  categories: _categories,
                  onCategoryTap: _onCategoryTap,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: events.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            return PopularEventCard(
                              event: events[index],
                              isDark: isDark,
                              getPriceText: _getPriceText,
                              height: 265,
                              bottomMargin: 16,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 16, top: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Text(
            widget.screenTitle,
            style: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }


  // ── Empty state ─────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy,
              size: 64, color: AppColors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No Events Found',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try selecting a different category',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              color: AppColors.grey200,
            ),
          ),
        ],
      ),
    );
  }
}
