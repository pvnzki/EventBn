import 'package:flutter/material.dart';
import '../../../core/services/smart_bottom_sheet_service.dart';

/// Enhanced event picker that preloads events automatically
class SmartEventPicker {
  /// Show event picker with automatic preloading
  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required Future<List<Map<String, dynamic>>> Function() eventLoader,
    String? selectedEventId,
  }) async {
    final smartService = SmartBottomSheetService();

    return await smartService.showBottomSheetWithData<Map<String, dynamic>>(
      context: context,
      cacheKey: 'available_events',
      dataLoader: () => _loadEventsData(eventLoader),
      builder: (context, data, isLoading) => _EventPickerContent(
        data: data,
        isLoading: isLoading,
        selectedEventId: selectedEventId,
      ),
    );
  }

  /// Preload events in background
  static Future<void> preloadEvents(
      Future<List<Map<String, dynamic>>> Function() eventLoader) async {
    final smartService = SmartBottomSheetService();
    await smartService.preloadData(
      cacheKey: 'available_events',
      dataLoader: () => _loadEventsData(eventLoader),
    );
  }

  /// Load events data
  static Future<Map<String, dynamic>> _loadEventsData(
    Future<List<Map<String, dynamic>>> Function() eventLoader,
  ) async {
    try {
      print('🔄 [SMART_EVENT_PICKER] Loading events...');

      final events = await eventLoader();

      print('✅ [SMART_EVENT_PICKER] Loaded ${events.length} events');

      return {
        'events': events,
        'count': events.length,
        'loadedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ [SMART_EVENT_PICKER] Failed to load events: $e');
      rethrow;
    }
  }

  /// Clear events cache
  static void clearCache() {
    SmartBottomSheetService().clearCache('available_events');
  }
}

/// Event picker content
class _EventPickerContent extends StatefulWidget {
  final dynamic data;
  final bool isLoading;
  final String? selectedEventId;

  const _EventPickerContent({
    required this.data,
    required this.isLoading,
    required this.selectedEventId,
  });

  @override
  State<_EventPickerContent> createState() => _EventPickerContentState();
}

class _EventPickerContentState extends State<_EventPickerContent> {
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _filteredEvents = [];
  final TextEditingController _searchController = TextEditingController();
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.selectedEventId;
    _updateEvents();
    _searchController.addListener(_filterEvents);
  }

  @override
  void didUpdateWidget(_EventPickerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _updateEvents();
    }
  }

  void _updateEvents() {
    if (widget.data != null && widget.data['events'] != null) {
      setState(() {
        _events = List<Map<String, dynamic>>.from(widget.data['events']);
        _filteredEvents = List.from(_events);
      });
    }
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredEvents = List.from(_events);
      } else {
        _filteredEvents = _events.where((event) {
          final name = (event['name'] ?? '').toString().toLowerCase();
          final description =
              (event['description'] ?? '').toString().toLowerCase();
          return name.contains(query) || description.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Select Event',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.headlineSmall?.color,
                  ),
                ),
                const Spacer(),
                if (widget.isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.primaryColor),
                    ),
                  )
                else
                  Text(
                    '${_filteredEvents.length} events',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: theme.iconTheme.color),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),

          // Search bar
          if (!widget.isLoading && _events.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.iconTheme.color?.withOpacity(0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                ),
              ),
            ),

          // Clear selection option
          if (_selectedEventId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop({
                    'id': null,
                    'name': null,
                    'action': 'clear',
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.red[900]?.withOpacity(0.2)
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.red[700]! : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.clear,
                          color:
                              isDarkMode ? Colors.red[400] : Colors.red[600]),
                      const SizedBox(width: 12),
                      Text(
                        'Clear event selection',
                        style: TextStyle(
                          color: isDarkMode ? Colors.red[400] : Colors.red[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Events list
          Expanded(
            child: widget.isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                theme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading events...',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _events.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 48,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No events available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create an event first to select it for your post.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.4),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredEvents.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No events found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search terms.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = _filteredEvents[index];
                              return _buildEventItem(event);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final eventId = event['id']?.toString();
    final isSelected = eventId == _selectedEventId;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop({
            'id': eventId,
            'name': event['name'],
            'action': 'select',
            'event': event,
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withOpacity(0.1)
                : (isDarkMode ? Colors.grey[800] : Colors.grey[50]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : (isDarkMode ? Colors.grey[600]! : Colors.grey[200]!),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Event icon/image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primaryColor.withOpacity(0.2)
                      : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event,
                  color: isSelected
                      ? theme.primaryColor
                      : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['name'] ?? 'Unnamed Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.primaryColor
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    if (event['description'] != null &&
                        event['description'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          event['description'].toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? theme.primaryColor.withOpacity(0.8)
                                : theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (event['date'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          event['date'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? theme.primaryColor.withOpacity(0.7)
                                : theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
