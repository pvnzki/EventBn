import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle, HapticFeedback;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../common_widgets/custom_button.dart';
import '../services/seat_lock_service.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String eventId;
  final String ticketType;
  final int initialCount;
  const SeatSelectionScreen(
      {super.key,
      required this.eventId,
      required this.ticketType,
      this.initialCount = 1});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen>
    with TickerProviderStateMixin {
  Set<int> selectedSeats = {};
  List<Map<String, dynamic>> seatMap = [];
  bool isLoading = true;
  String eventName = '';
  String eventDate = '';
  String venueLayout = 'theater'; // theater, concert, conference, custom
  Map<String, dynamic> layoutConfig = {};
  
  // Seat locking service
  final SeatLockService _seatLockService = SeatLockService();
  Map<String, bool> lockedSeats = {}; // Track locked seats
  
  // Global session timer (starts when first seat is selected)
  Timer? _sessionTimer;
  int _sessionTimeLeft = 0; // in seconds
  bool _sessionActive = false;
  
  // Global selection timer
  Timer? _selectionTimer;
  int _timeRemaining = 0; // seconds
  bool _hasSelectedSeats = false;
  
  // Zoom and pan controllers
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  static const double _minScale = 0.8;
  static const double _maxScale = 3.0;
  
  // Animation controller for selected seats pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    
    _loadSeatMap();
    _loadEventDetails();
    _loadEventLocks(); // Load initially locked seats
    _startLockPolling(); // Start polling for lock updates
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pulseController.dispose();
    _sessionTimer?.cancel();
    _selectionTimer?.cancel();
    _seatLockService.stopPollingEventLocks(widget.eventId);
    super.dispose();
  }

  // Start the 5-minute session timer when first seat is selected
  void _startSessionTimer() {
    if (_sessionActive) return; // Already started
    
    _sessionActive = true;
    _sessionTimeLeft = 5 * 60; // 5 minutes in seconds
    
    _sessionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _sessionTimeLeft--;
        });
        
        if (_sessionTimeLeft <= 0) {
          _expireSession();
        }
      } else {
        timer.cancel();
      }
    });
  }

  // Expire the session - release all locks and refresh
  void _expireSession() {
    _sessionTimer?.cancel();
    
    // Release all selected seat locks
    for (int seatId in selectedSeats) {
      _seatLockService.releaseSeatLock(eventId: widget.eventId, seatId: seatId.toString());
    }
    
    // Clear state and refresh page
    setState(() {
      selectedSeats.clear();
      lockedSeats.clear();
      _sessionActive = false;
      _sessionTimeLeft = 0;
    });
    
    // Show expiration message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selection time expired. Please select your seats again.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Extend session timer during payment
  void _extendSessionTimer() {
    if (_sessionActive) {
      setState(() {
        _sessionTimeLeft = 10 * 60; // Extend to 10 minutes during payment
      });
    }
  }

  // Stop the session timer when no seats are selected
  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    setState(() {
      _sessionActive = false;
      _sessionTimeLeft = 0;
    });
  }

  Future<void> _loadSeatMap() async {
    try {
      final String baseUrl = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/${widget.eventId}/seatmap'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 Seat Map Response: $data');
        
        if (data['success'] == true && data['data'] != null) {
          final seatMapData = data['data'];
          print('🔍 Seat Map Data: $seatMapData');
          print('🔍 hasCustomSeating: ${seatMapData['hasCustomSeating']}');
          
          // Check if this event has custom seating
          if (seatMapData['hasCustomSeating'] == false) {
            print('🎯 No custom seating - navigating to ticket type selection');
            // Navigate to ticket type selection screen
            setState(() {
              isLoading = false; // Stop loading before navigation
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('🚀 Attempting navigation to ticket-type-selection');
              context.pushReplacement('/ticket-type-selection', extra: {
                'eventId': widget.eventId,
                'ticketType': widget.ticketType,
                'initialCount': widget.initialCount,
              });
            });
            return; // This will properly exit the function
          }
          
          print('🎯 Custom seating found - showing seat grid');
          setState(() {
            seatMap = List<Map<String, dynamic>>.from(seatMapData['seats']);
            venueLayout = seatMapData['layout'] ?? 'theater';
            layoutConfig = seatMapData['layoutConfig'] ?? {};
            
            // Transform flat seat data into venue-shaped layout
            _transformSeatMapForVenue();
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load seat map');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error loading seat map: $e');
      // Fallback to local JSON if API fails
      final String jsonString = await rootBundle.loadString('assets/seat_map.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        seatMap = jsonData.cast<Map<String, dynamic>>();
        venueLayout = 'theater'; // Default layout
        _transformSeatMapForVenue();
        isLoading = false;
      });
    }
  }

  // Transform flat seat data into venue-like layout
  void _transformSeatMapForVenue() {
    if (seatMap.isEmpty) return;
    
    // Add positioning data if not present
    for (int i = 0; i < seatMap.length; i++) {
      var seat = seatMap[i];
      
      // Extract row and column from label if not present
      if (!seat.containsKey('row') || !seat.containsKey('column')) {
        String label = seat['label'] ?? '';
        String row = '';
        int column = 0;
        
        // Parse label like "A1", "B12", etc.
        if (label.isNotEmpty) {
          RegExp regExp = RegExp(r'^([A-Z]+)(\d+)$');
          Match? match = regExp.firstMatch(label);
          if (match != null) {
            row = match.group(1) ?? '';
            column = int.tryParse(match.group(2) ?? '0') ?? 0;
          }
        }
        
        seat['row'] = row;
        seat['column'] = column;
        seat['section'] = _determineSectionFromPosition(row, column);
      }
    }
    
    // Sort seats by row and column for proper layout
    seatMap.sort((a, b) {
      String rowA = a['row'] ?? '';
      String rowB = b['row'] ?? '';
      int columnA = a['column'] ?? 0;
      int columnB = b['column'] ?? 0;
      
      int rowComparison = rowA.compareTo(rowB);
      if (rowComparison != 0) return rowComparison;
      return columnA.compareTo(columnB);
    });
  }

  String _determineSectionFromPosition(String row, int column) {
    // Logic to determine section based on venue layout
    switch (venueLayout) {
      case 'theater':
        if (row.compareTo('D') <= 0) return 'front';
        if (row.compareTo('H') <= 0) return 'middle';
        return 'back';
      case 'concert':
        if (column <= 10) return 'left';
        if (column <= 20) return 'center';
        return 'right';
      case 'conference':
        return 'general';
      default:
        return 'general';
    }
  }

  Future<void> _loadEventDetails() async {
    try {
      final String baseUrl = AppConfig.baseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/${widget.eventId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final event = data['data'];
          setState(() {
            eventName = event['title'] ?? 'Event';
            // Format the start_time to a readable date
            if (event['start_time'] != null) {
              final DateTime startTime = DateTime.parse(event['start_time']);
              eventDate = '${startTime.day}/${startTime.month}/${startTime.year} ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
            } else {
              eventDate = 'Date TBA';
            }
          });
        }
      }
    } catch (e) {
      print('Error loading event details: $e');
      // Use defaults if API fails
      setState(() {
        eventName = 'Event';
        eventDate = 'Date TBA';
      });
    }
  }

  void _toggleSeat(int seatId) async {
    // Check if we're deselecting
    if (selectedSeats.contains(seatId)) {
      setState(() {
        selectedSeats.remove(seatId);
      });
      
      // Release the lock
      await _seatLockService.releaseSeatLock(
        eventId: widget.eventId,
        seatId: seatId.toString(),
      );
      
      // Stop session timer if no seats selected
      if (selectedSeats.isEmpty) {
        _stopSessionTimer();
      }
      
      HapticFeedback.lightImpact();
      return;
    }
    
    // Check if seat is locked by another user
    if (lockedSeats[seatId.toString()] == true) {
      _showSeatLockedDialog();
      return;
    }
    
    // Try to lock and select the seat
    final lockResult = await _seatLockService.lockSeat(
      eventId: widget.eventId,
      seatId: seatId.toString(),
    );
    
    if (lockResult['success'] == true) {
      setState(() {
        selectedSeats.add(seatId);
      });
      
      // Start session timer on first seat selection
      if (selectedSeats.length == 1) {
        _startSessionTimer();
      }
      
      HapticFeedback.mediumImpact();
    } else {
      // Show error dialog
      _showSeatLockFailedDialog(lockResult['message'] ?? 'Failed to select seat');
      
      // Update locked seats if this seat is now locked
      if (lockResult['isLocked'] == true) {
        setState(() {
          lockedSeats[seatId.toString()] = true;
        });
      }
    }
  }

  /// Load initially locked seats from the server
  Future<void> _loadEventLocks() async {
    try {
      final result = await _seatLockService.getEventLockedSeats(
        eventId: widget.eventId,
      );
      
      if (result['success'] == true) {
        final List<dynamic> locks = result['lockedSeats'] ?? [];
        final Map<String, bool> newLockedSeats = {};
        
        for (final lock in locks) {
          newLockedSeats[lock['seatId']] = true;
        }
        
        if (mounted) {
          setState(() {
            lockedSeats = newLockedSeats;
          });
        }
      }
    } catch (e) {
      print('Error loading event locks: $e');
    }
  }

  /// Start polling for lock updates
  void _startLockPolling() {
    _seatLockService.startPollingEventLocks(
      eventId: widget.eventId,
      interval: const Duration(seconds: 15), // Poll every 15 seconds
    );
    
    // Listen to lock updates
    _seatLockService.getLockUpdateStream(widget.eventId)?.listen((update) {
      if (!mounted) return;
      
      switch (update['action']) {
        case 'poll_update':
          _handlePollUpdate(update['lockedSeats'] ?? []);
          break;
        case 'locked':
          _handleSeatLocked(update['seatId']);
          break;
        case 'released':
          _handleSeatReleased(update['seatId']);
          break;
      }
    });
  }

  /// Handle poll update with latest locked seats
  void _handlePollUpdate(List<dynamic> lockedSeatsList) {
    final Map<String, bool> newLockedSeats = {};
    
    for (final lock in lockedSeatsList) {
      newLockedSeats[lock['seatId']] = true;
    }
    
    setState(() {
      lockedSeats = newLockedSeats;
    });
  }

  /// Handle seat locked event
  void _handleSeatLocked(String seatId) {
    setState(() {
      lockedSeats[seatId] = true;
    });
  }

  /// Handle seat released event
  void _handleSeatReleased(String seatId) {
    setState(() {
      lockedSeats.remove(seatId);
    });
  }

  /// Show dialog when seat is locked by another user
  void _showSeatLockedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seat Unavailable'),
        content: const Text(
          'This seat is currently being selected by another user. Please choose a different seat or try again in a moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show dialog when seat lock fails
  void _showSeatLockFailedDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Select Seat'),
        content: Text(message.replaceAll('lock', 'select').replaceAll('Lock', 'Selection')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Format time in seconds to MM:SS format
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading seat map...',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Compact App Bar
          _buildCompactAppBar(theme),
          
          // Compact Event Info Header
          _buildCompactEventHeader(theme),
          
          // Global Session Timer (appears when seats are selected)
          if (_sessionActive) _buildSessionTimer(theme),
          
          // Full Screen Seat Map Section
          Expanded(
            child: _buildFullScreenSeatMap(theme),
          ),
          
          // Bottom Section with Selection Summary
          _buildBottomSection(theme),
        ],
      ),
    );
  }

  Widget _buildCompactAppBar(ThemeData theme) {
    return SafeArea(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                'Choose Your Seats',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Selection counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selectedSeats.isNotEmpty 
                    ? theme.primaryColor 
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                '${selectedSeats.length}',
                style: TextStyle(
                  color: selectedSeats.isNotEmpty 
                      ? theme.colorScheme.onPrimary 
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactEventHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event_seat_rounded,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventName.isEmpty ? 'Loading...' : eventName,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  eventDate.isEmpty ? 'Date TBA' : eventDate,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTimer(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Selection expires in:',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _formatTime(_sessionTimeLeft),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenSeatMap(ThemeData theme) {
    if (seatMap.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_seat_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No seats available',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Compact controls bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.brightness == Brightness.dark 
              ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
              : theme.primaryColor.withOpacity(0.05),
          child: Row(
            children: [
              // Zoom controls
              _buildCompactZoomControls(theme),
            ],
          ),
        ),
        
        // Full screen seat map
        Expanded(
          child: Container(
            width: double.infinity,
            color: theme.colorScheme.surface,
            child: Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  boundaryMargin: const EdgeInsets.all(10),
                  onInteractionUpdate: (details) {
                    setState(() {
                      _currentScale = _transformationController.value.getMaxScaleOnAxis();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: _buildVenueLayout(theme),
                  ),
                ),
                
                // Floating zoom indicator
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: theme.brightness == Brightness.dark 
                          ? Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                              width: 0.5,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${(_currentScale * 100).toInt()}%',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark 
                            ? theme.colorScheme.primary
                            : theme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // Mini-map for large venues when zoomed in
                if (seatMap.length > 100 && _currentScale > 1.5)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: _buildMiniMap(theme),
                  ),
                
                // Floating legend
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: _buildFloatingLegend(theme),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactZoomControls(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactZoomButton(
          icon: Icons.zoom_out_rounded,
          onTap: () => _zoomOut(),
          theme: theme,
        ),
        const SizedBox(width: 4),
        _buildCompactZoomButton(
          icon: Icons.zoom_in_rounded,
          onTap: () => _zoomIn(),
          theme: theme,
        ),
        const SizedBox(width: 4),
        _buildCompactZoomButton(
          icon: Icons.center_focus_strong_rounded,
          onTap: () => _resetZoom(),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildCompactZoomButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark 
              ? theme.colorScheme.surfaceVariant.withOpacity(0.8)
              : theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.brightness == Brightness.dark 
                ? theme.colorScheme.outline.withOpacity(0.5)
                : theme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          color: theme.brightness == Brightness.dark 
              ? theme.colorScheme.primary
              : theme.primaryColor,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildFloatingLegend(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: theme.brightness == Brightness.dark 
            ? Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
                width: 0.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactLegendItem(
            color: theme.brightness == Brightness.dark 
                ? theme.colorScheme.surfaceVariant
                : theme.colorScheme.surface,
            label: 'Available',
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildCompactLegendItem(
            color: Colors.orange.withOpacity(0.9),
            label: 'Selected',
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildCompactLegendItem(
            color: Colors.amber.withOpacity(0.8),
            label: 'Locked',
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildCompactLegendItem(
            color: theme.colorScheme.tertiary.withOpacity(0.8),
            label: 'VIP',
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildCompactLegendItem(
            color: theme.colorScheme.error.withOpacity(0.8),
            label: 'Booked',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLegendItem({
    required Color color,
    required String label,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Helper methods for zoom functionality

  Widget _buildVenueLayout(ThemeData theme) {
    switch (venueLayout) {
      case 'theater':
        return _buildTheaterLayout(theme);
      case 'concert':
        return _buildConcertLayout(theme);
      case 'conference':
        return _buildConferenceLayout(theme);
      default:
        return _buildDefaultGridLayout(theme);
    }
  }

  Widget _buildTheaterLayout(ThemeData theme) {
    // Group seats by rows
    Map<String, List<Map<String, dynamic>>> rowGroups = {};
    for (var seat in seatMap) {
      String row = seat['row'] ?? '';
      if (!rowGroups.containsKey(row)) {
        rowGroups[row] = [];
      }
      rowGroups[row]!.add(seat);
    }

    // Calculate global seat size based on the longest row
    double screenWidth = MediaQuery.of(context).size.width;
    int maxSeatsInRow = rowGroups.values
        .map((seats) => seats.length)
        .reduce((a, b) => a > b ? a : b);
    
    double availableWidth = screenWidth - 30; // Account for reduced row labels (15+15) and padding
    int aisleCount = (maxSeatsInRow / 4).floor();
    double totalAisleSpace = aisleCount * 6; // Reduced aisle space
    double totalRegularSpacing = (maxSeatsInRow - aisleCount - 1) * 0.5; // Reduced spacing
    
    double calculatedSize = (availableWidth - totalAisleSpace - totalRegularSpacing) / maxSeatsInRow;
    double globalSeatSize = calculatedSize.clamp(4.0, 30.0); // Reduced minimum

    // Sort rows alphabetically
    var sortedRows = rowGroups.keys.toList()..sort();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Stage area
          Container(
            width: double.infinity,
            height: 30,
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  theme.primaryColor.withOpacity(0.3),
                  theme.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                'STAGE',
                style: TextStyle(
                  color: theme.brightness == Brightness.dark 
                      ? theme.colorScheme.primary
                      : theme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          
          // Seating area with proper constraints
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 16, // Reduced padding
            ),
            child: Column(
              children: sortedRows.map((row) {
                var rowSeats = rowGroups[row]!;
                rowSeats.sort((a, b) => (a['column'] ?? 0).compareTo(b['column'] ?? 0));
                
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 1), // Reduced margin
                  child: Row(
                    children: [
                      // Row label (left)
                      SizedBox(
                        width: 15, // Reduced width
                        child: Text(
                          row,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 9, // Smaller font
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      // Seats in row with fixed layout to prevent wrapping
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _buildRowSeatsWithAisles(rowSeats, theme, globalSeatSize),
                          ),
                        ),
                      ),
                      
                      // Row label (right)
                      SizedBox(
                        width: 15, // Reduced width
                        child: Text(
                          row,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 9, // Smaller font
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcertLayout(ThemeData theme) {
    // Group seats by sections (left, center, right)
    Map<String, List<Map<String, dynamic>>> sectionGroups = {};
    for (var seat in seatMap) {
      String section = seat['section'] ?? 'center';
      if (!sectionGroups.containsKey(section)) {
        sectionGroups[section] = [];
      }
      sectionGroups[section]!.add(seat);
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Stage area (wider for concerts)
          Container(
            width: double.infinity,
            height: 40,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor.withOpacity(0.2),
                  theme.primaryColor.withOpacity(0.4),
                  theme.primaryColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'CONCERT STAGE',
                style: TextStyle(
                  color: theme.brightness == Brightness.dark 
                      ? theme.colorScheme.primary
                      : theme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          
          // Seating sections with flexible layout
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 16, // Reduced padding
            ),
            child: Column(
              children: [
                if (sectionGroups['center'] != null)
                  _buildFlexibleSection('CENTER', sectionGroups['center']!, theme),
                
                const SizedBox(height: 15),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left section
                    if (sectionGroups['left'] != null)
                      Expanded(child: _buildFlexibleSection('LEFT', sectionGroups['left']!, theme)),
                    
                    if (sectionGroups['left'] != null && sectionGroups['right'] != null)
                      const SizedBox(width: 15),
                    
                    // Right section
                    if (sectionGroups['right'] != null)
                      Expanded(child: _buildFlexibleSection('RIGHT', sectionGroups['right']!, theme)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConferenceLayout(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Presentation area
          Container(
            width: double.infinity,
            height: 50,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                'PRESENTATION SCREEN',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          
          // Conference style seating (rows of tables)
          _buildDefaultGridLayout(theme),
        ],
      ),
    );
  }

  Widget _buildDefaultGridLayout(ThemeData theme) {
    // Calculate responsive grid based on screen width and actual seat count
    double screenWidth = MediaQuery.of(context).size.width;
    int totalSeats = seatMap.length;
    
    // Dynamically determine columns based on seat count
    int calculatedCrossAxisCount;
    if (totalSeats <= 50) {
      calculatedCrossAxisCount = (screenWidth / 35).floor().clamp(6, 10);
    } else if (totalSeats <= 100) {
      calculatedCrossAxisCount = (screenWidth / 30).floor().clamp(8, 12);
    } else {
      calculatedCrossAxisCount = (screenWidth / 25).floor().clamp(10, 16);
    }
    
    return Padding(
      padding: const EdgeInsets.all(4.0), // Reduced padding
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: calculatedCrossAxisCount,
          mainAxisSpacing: 0.5, // Extremely minimal spacing
          crossAxisSpacing: 0.5, // Extremely minimal spacing
          childAspectRatio: 1,
        ),
        itemCount: seatMap.length,
        itemBuilder: (context, index) {
          var seat = seatMap[index];
          // Calculate seat size to fit the grid perfectly
          double availableWidth = screenWidth - 8; // Minimal padding
          double calculatedSize = (availableWidth / calculatedCrossAxisCount) - 1; // Minimal spacing
          double seatSize = calculatedSize.clamp(4.0, 30.0); // Much more aggressive scaling
          return _buildCompactVenueSeat(seat, theme, seatSize);
        },
      ),
    );
  }

  Widget _buildFlexibleSection(String sectionName, List<Map<String, dynamic>> seats, ThemeData theme) {
    // Group by rows within section
    Map<String, List<Map<String, dynamic>>> rowGroups = {};
    for (var seat in seats) {
      String row = seat['row'] ?? '';
      if (!rowGroups.containsKey(row)) {
        rowGroups[row] = [];
      }
      rowGroups[row]!.add(seat);
    }

    var sortedRows = rowGroups.keys.toList()..sort();

    // Calculate seat size based on screen width and maximum seats in any row
    double screenWidth = MediaQuery.of(context).size.width;
    int maxSeatsInRow = rowGroups.values
        .map((seats) => seats.length)
        .reduce((a, b) => a > b ? a : b);
    
    // Reserve space for padding and spacing - be more aggressive with size reduction
    double availableWidth = screenWidth - 32; // Reduced padding
    double spacing = 0.5; // Even smaller spacing
    double totalSpacing = (maxSeatsInRow - 1) * spacing;
    
    // Much more aggressive scaling - allow extremely small seats for large seat maps
    double calculatedSize = (availableWidth - totalSpacing) / maxSeatsInRow;
    double seatSize = calculatedSize.clamp(4.0, 35.0); // Reduced minimum from 8.0 to 4.0

    return Column(
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            sectionName,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ),
        
        // Rows in section with fixed layout to prevent wrapping
        ...sortedRows.map((row) {
          var rowSeats = rowGroups[row]!;
          rowSeats.sort((a, b) => (a['column'] ?? 0).compareTo(b['column'] ?? 0));
          
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 0.5), // Reduced margin
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < rowSeats.length; i++) ...[
                  _buildCompactVenueSeat(rowSeats[i], theme, seatSize),
                  if (i < rowSeats.length - 1) SizedBox(width: spacing),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }



  List<Widget> _buildRowSeatsWithAisles(List<Map<String, dynamic>> rowSeats, ThemeData theme, [double? preCalculatedSize]) {
    List<Widget> widgets = [];
    
    double seatSize;
    if (preCalculatedSize != null) {
      seatSize = preCalculatedSize;
    } else {
      // Fallback calculation if no pre-calculated size provided
      double screenWidth = MediaQuery.of(context).size.width;
      double availableWidth = screenWidth - 30; // Account for reduced row labels and padding
      int totalSeats = rowSeats.length;
      int aisleCount = (totalSeats / 4).floor();
      double totalAisleSpace = aisleCount * 6; // Reduced aisle space
      
      // Much more aggressive scaling for theater layout
      double calculatedSize = (availableWidth - totalAisleSpace) / totalSeats;
      seatSize = calculatedSize.clamp(4.0, 30.0); // Reduced minimum
    }
    
    for (int i = 0; i < rowSeats.length; i++) {
      var seat = rowSeats[i];
      widgets.add(_buildCompactVenueSeat(seat, theme, seatSize));
      
      // Add aisle spacing every 4 seats (configurable)
      int aisleSpacing = layoutConfig['aisleSpacing'] ?? 4;
      if ((i + 1) % aisleSpacing == 0 && i < rowSeats.length - 1) {
        widgets.add(SizedBox(width: 6)); // Further reduced aisle gap
      } else if (i < rowSeats.length - 1) {
        widgets.add(SizedBox(width: 0.5)); // Extremely minimal regular spacing
      }
    }
    
    return widgets;
  }

  Widget _buildCompactVenueSeat(Map<String, dynamic> seat, ThemeData theme, double seatSize) {
    final seatLabel = seat['label'] as String;
    final seatId = seat['id'] as int;
    final isAvailable = seat['available'] as bool;
    final isSelected = selectedSeats.contains(seatId);
    final ticketType = seat['ticketType'] as String;
    final isLocked = lockedSeats[seatId.toString()] == true;
    
    // Calculate font size based on seat size - better scaling for very small seats
    final double fontSize = (seatSize * 0.5).clamp(3.0, 10.0); // Even smaller minimum font for tiny seats
    
    Color seatColor;
    Color textColor;
    IconData? seatIcon;
    
    if (!isAvailable) {
      // Seat is permanently booked (payment completed) - RED
      seatColor = theme.colorScheme.error.withOpacity(0.8);
      textColor = theme.colorScheme.onError;
      seatIcon = Icons.close_rounded;
    } else if (isLocked && !isSelected) {
      // Seat temporarily locked by another user - YELLOW/AMBER
      seatColor = Colors.amber.withOpacity(0.8);
      textColor = Colors.black87;
      seatIcon = Icons.schedule_rounded; // Clock icon to show temporary
    } else if (isSelected) {
      // Selected by current user - ORANGE (locked behind the scenes)
      seatColor = Colors.orange.withOpacity(0.9);
      textColor = Colors.white;
      seatIcon = Icons.check_rounded;
    } else if (ticketType == 'VIP' || ticketType == 'Premium') {
      seatColor = theme.colorScheme.tertiary.withOpacity(0.8);
      textColor = theme.colorScheme.onTertiary;
    } else {
      // For available seats, use a more visible color in dark mode
      final isDarkMode = theme.brightness == Brightness.dark;
      seatColor = isDarkMode 
          ? theme.colorScheme.surfaceVariant
          : theme.colorScheme.surface;
      textColor = isDarkMode 
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.onSurface;
    }
    
    return GestureDetector(
      onTap: (isAvailable && !isLocked) || isSelected ? () => _toggleSeat(seatId) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: seatSize,
        height: seatSize,
        margin: EdgeInsets.all(seatSize < 8 ? 0.1 : (seatSize < 12 ? 0.25 : 0.5)), // Extremely small margin for tiny seats
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(seatSize < 10 ? 1 : (seatSize < 15 ? 2 : (seatSize < 20 ? 3 : 6))), // Progressive border radius
          border: Border.all(
            color: isSelected 
                ? theme.primaryColor 
                : (theme.brightness == Brightness.dark 
                    ? theme.colorScheme.outline.withOpacity(0.4)
                    : theme.colorScheme.outline.withOpacity(0.2)),
            width: seatSize < 8 ? 0.25 : (seatSize < 12 ? 0.5 : (isSelected ? 1.5 : 0.5)), // Very thin borders for tiny seats
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isSelected ? _pulseAnimation.value : 1.0,
              child: Stack(
                children: [
                  Center(
                    child: seatIcon != null
                        ? Icon(
                            seatIcon,
                            color: textColor,
                            size: fontSize,
                          )
                        : Text(
                            seatLabel.length > 2 ? seatLabel.substring(1) : seatLabel, // Show number part for compact view
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: fontSize,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _zoomIn() {
    final double newScale = (_currentScale * 1.2).clamp(_minScale, _maxScale);
    _animateToScale(newScale);
  }

  void _zoomOut() {
    final double newScale = (_currentScale / 1.2).clamp(_minScale, _maxScale);
    _animateToScale(newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
    });
  }

  void _animateToScale(double scale) {
    final Matrix4 matrix = Matrix4.identity()..scale(scale);
    _transformationController.value = matrix;
    setState(() {
      _currentScale = scale;
    });
  }

  int _calculateCrossAxisCount() {
    // Dynamic cross axis count based on seat map size
    if (seatMap.length <= 64) {
      return 8; // 8x8 grid
    } else if (seatMap.length <= 144) {
      return 12; // 12x12 grid
    } else if (seatMap.length <= 256) {
      return 16; // 16x16 grid
    } else {
      return 20; // 20+ columns for very large venues
    }
  }



  Widget _buildBottomSection(ThemeData theme) {
    final canProceed = selectedSeats.isNotEmpty;
    final totalPrice = selectedSeats.fold<double>(0.0, (sum, seatId) {
      final seat = seatMap.firstWhere(
        (s) => s['id'] == seatId,
        orElse: () => {'price': 0.0},
      );
      return sum + (seat['price']?.toDouble() ?? 0.0);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selection Summary
            if (selectedSeats.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_seat_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedSeats.length} seat${selectedSeats.length > 1 ? 's' : ''} selected',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            selectedSeats.map((id) {
                              final seat = seatMap.firstWhere(
                                (s) => s['id'] == id,
                                orElse: () => {'label': 'Unknown'},
                              );
                              return seat['label'];
                            }).join(', '),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'LKR ${totalPrice.toInt()}',
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark 
                            ? theme.colorScheme.primary
                            : theme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Continue Button
            CustomButton(
              text: canProceed 
                  ? 'Continue to Booking' 
                  : 'Select seats to continue',
              onPressed: canProceed ? () {
                // Extend session timer for payment process
                _extendSessionTimer();
                
                // Get selected seat data with full details
                List<Map<String, dynamic>> selectedSeatData = [];
                for (int seatId in selectedSeats) {
                  final seatData = seatMap.firstWhere(
                    (seat) => seat['id'] == seatId,
                    orElse: () => <String, dynamic>{},
                  );
                  if (seatData.isNotEmpty) {
                    selectedSeatData.add(seatData);
                  }
                }
                
                // Navigate to user details page using new booking flow
                context.pushNamed(
                  'user-details',
                  pathParameters: {'eventId': widget.eventId},
                  extra: {
                    'eventId': widget.eventId,
                    'eventName': eventName,
                    'eventDate': eventDate,
                    'ticketType': widget.ticketType,
                    'seatCount': selectedSeats.length, // Use actual selected count
                    'selectedSeats': selectedSeats.map((id) => id.toString()).toList(),
                    'selectedSeatData': selectedSeatData,
                  },
                );
              } : null,
              backgroundColor: canProceed ? theme.primaryColor : null,
              height: 56,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMap(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Mini seat map overview
          Padding(
            padding: const EdgeInsets.all(4),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _calculateCrossAxisCount(),
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
              ),
              itemCount: seatMap.length,
              itemBuilder: (context, index) {
                final seat = seatMap[index];
                final isSelected = selectedSeats.contains(seat['id']);
                final isAvailable = seat['available'] as bool;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primaryColor
                        : isAvailable
                            ? (theme.brightness == Brightness.dark 
                                ? theme.colorScheme.surfaceVariant
                                : theme.colorScheme.onSurface.withOpacity(0.3))
                            : theme.colorScheme.error.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              },
            ),
          ),
          
          // Close button
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _resetZoom(),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
