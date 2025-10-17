import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../common_widgets/custom_notification.dart';
import '../../auth/services/auth_service.dart';
import 'payment_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String eventId;
  final String ticketType;
  final int initialCount;

  const SeatSelectionScreen({
    super.key,
    required this.eventId,
    required this.ticketType,
    required this.initialCount,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen>
    with TickerProviderStateMixin {
  List<dynamic> seatMap = [];
  List<String> selectedSeats = [];
  List<String> lockedSeats = [];
  Set<String> unlockedByUser =
      {}; // Track seats explicitly unlocked by this user
  bool isLoading = true;
  String eventName = '';
  String eventDate = '';

  // Session management
  bool _sessionActive = false;
  int _sessionTimeLeft = 0;
  Timer? _sessionTimer;

  // Seat lock timer management
  Timer? _seatLockTimer;

  // Animation controllers
  late AnimationController _selectionAnimation;
  late AnimationController _pulseAnimation;

  // Zoom controls
  final TransformationController _transformationController =
      TransformationController();
  bool _showZoomControls = false;
  Timer? _controlsTimer;
  double _currentScale = 1.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 3.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchSeatMap();
    _fetchLockedSeats();
    _startLockedSeatsRefreshTimer();
  }

  void _initializeAnimations() {
    _selectionAnimation = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // Release all selected seats before disposing
    _releaseAllSeatsOnDispose();

    _sessionTimer?.cancel();
    _seatLockTimer?.cancel();
    _controlsTimer?.cancel();
    _lockedSeatsRefreshTimer?.cancel();
    _stopLockedSeatsRefreshTimer();
    _selectionAnimation.dispose();
    _pulseAnimation.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _releaseAllSeatsOnDispose() async {
    if (selectedSeats.isNotEmpty) {
      print('🔄 Releasing ${selectedSeats.length} seats on page dispose');
      final seatsToRelease = List<String>.from(selectedSeats);
      for (String seatId in seatsToRelease) {
        try {
          await _releaseSeatLock(seatId);
          print('✅ Released seat $seatId on dispose');
        } catch (e) {
          print('❌ Failed to release seat $seatId on dispose: $e');
        }
      }
    }
  }

  Future<void> _fetchSeatMap() async {
    try {
      print('🎫 Fetching seat map for event: ${widget.eventId}');
      final url = '${AppConfig.baseUrl}/api/events/${widget.eventId}/seatmap';

      // Get authentication token
      final authService = AuthService();
      final token = await authService.getStoredToken();

      final headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('🔑 Using auth token for seat map request');
      } else {
        print('⚠️ No auth token available for seat map request');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'];

        setState(() {
          seatMap = data['seats'] ?? [];
          eventName = data['event_name'] ?? 'Event';
          eventDate = data['event_date'] ?? '';
          isLoading = false;
        });

        print('✅ Seat map loaded. Total seats: ${seatMap.length}');
        print('🔍 Sample seat data: ${seatMap.take(3).toList()}');
        print(
            '🎯 Seat statuses found: ${seatMap.map((s) => s['status']).toSet().toList()}');
        print(
            '🎯 Seat availability found: ${seatMap.map((s) => s['available']).toSet().toList()}');
        print(
            '🎯 Seat booked flags found: ${seatMap.map((s) => s['booked']).toSet().toList()}');
        print(
            '🔴 Unavailable seats: ${seatMap.where((s) => s['available'] == false || s['booked'] == true || s['status'] == 'booked' || s['status'] == 'occupied').map((s) => '${s['label'] ?? s['id']}').toList()}');
        print(
            '🟢 Available seats: ${seatMap.where((s) => (s['available'] == true || (s['available'] == null && s['booked'] != true)) && s['status'] != 'booked' && s['status'] != 'occupied').length}');

        if (seatMap.isNotEmpty) {
          // Fetch currently locked seats and start session
          await _fetchLockedSeats();
          _startSession();
          _startLockedSeatsRefreshTimer();
        }
      } else {
        print('❌ Failed to load seat map. Status: ${response.statusCode}');
        // Fallback to demo data for testing
        _loadDemoSeatMap();
      }
    } catch (e) {
      print('❌ Error fetching seat map: $e');
      // Fallback to demo data for testing
      _loadDemoSeatMap();
    }
  }

  // ========== SEAT LOCKING API METHODS ==========

  Future<bool> _lockSeat(String seatId) async {
    try {
      print('🔒 API: Locking seat $seatId');

      // Import auth service at the top: import '../../../features/auth/services/auth_service.dart';
      final authService = AuthService();
      final token = await authService.getStoredToken();

      if (token == null) {
        print('❌ No auth token available for seat locking');
        return false;
      }

      final url =
          '${AppConfig.baseUrl}/api/seat-locks/events/${widget.eventId}/seats/$seatId/lock';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API: Seat $seatId locked successfully');
        return data['success'] == true;
      } else if (response.statusCode == 409) {
        // Seat already locked by another user
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Seat is temporarily locked';
        print('🔒 API: Seat $seatId already locked - $message');
        throw Exception(message);
      } else {
        print(
            '❌ API: Failed to lock seat $seatId. Status: ${response.statusCode}');
        print('Response: ${response.body}');
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Failed to lock seat';
        throw Exception(message);
      }
    } catch (e) {
      print('❌ API: Error locking seat $seatId: $e');
      return false;
    }
  }

  Future<bool> _unlockSeat(String seatId) async {
    try {
      print('🔓 API: Unlocking seat $seatId');

      final authService = AuthService();
      final token = await authService.getStoredToken();

      if (token == null) {
        print('❌ No auth token available for seat unlocking');
        return false;
      }

      final url =
          '${AppConfig.baseUrl}/api/seat-locks/events/${widget.eventId}/seats/$seatId/lock';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API: Seat $seatId unlocked successfully');
        return data['success'] == true;
      } else {
        print(
            '❌ API: Failed to unlock seat $seatId. Status: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ API: Error unlocking seat $seatId: $e');
      return false;
    }
  }

  Future<bool> _extendSeatLocks(List<String> seatIds) async {
    try {
      print('⏰ API: Extending locks for seats: $seatIds');

      final authService = AuthService();
      final token = await authService.getStoredToken();

      if (token == null) {
        print('❌ No auth token available for extending seat locks');
        return false;
      }

      final url = '${AppConfig.baseUrl}/api/seat-locks/extend';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'seatIds': seatIds,
          'eventId': widget.eventId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API: Seat locks extended successfully for payment duration');
        return data['success'] == true;
      } else {
        print(
            '❌ API: Failed to extend seat locks. Status: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ API: Error extending seat locks: $e');
      return false;
    }
  }

  // Wrapper methods for individual seat operations
  Future<bool> _releaseSeatLock(String seatId) async {
    return await _unlockSeat(seatId);
  }

  // ========== PAYMENT SEAT LOCKING ==========

  Future<bool> _lockAllSelectedSeatsForPayment() async {
    if (selectedSeats.isEmpty) {
      print('⚠️ No seats selected to lock for payment');
      return false;
    }

    print(
        '🔒 Locking ${selectedSeats.length} seats for payment: $selectedSeats');
    bool allSuccess = true;
    List<String> failedSeats = [];

    for (String seatId in selectedSeats) {
      try {
        // First lock the seat with regular duration
        final lockSuccess = await _lockSeat(seatId);
        if (lockSuccess) {
          // Then extend it to payment duration (15 minutes)
          final extendSuccess = await _extendSeatLocks([seatId]);
          if (extendSuccess) {
            print('✅ Locked and extended seat $seatId for payment (15 min)');
          } else {
            print('⚠️ Locked seat $seatId but failed to extend for payment');
            // Still count as success since seat is locked
          }
        } else {
          print('❌ Failed to lock seat $seatId for payment');
          allSuccess = false;
          failedSeats.add(seatId);
        }
      } catch (e) {
        print('❌ Error locking seat $seatId for payment: $e');
        allSuccess = false;
        failedSeats.add(seatId);
      }
    }

    if (allSuccess) {
      setState(() {
        lockedSeats.addAll(selectedSeats);
      });
      _startPaymentTimer(); // Start 15-minute payment timer
      print('✅ All selected seats locked for payment');
    } else {
      _showSnackBar(
          'Failed to lock seats: ${failedSeats.join(", ")}', Colors.red);
      print('❌ Failed to lock some seats for payment: $failedSeats');
    }

    return allSuccess;
  }

  void _startPaymentTimer() {
    _sessionTimer?.cancel();

    setState(() {
      _sessionTimeLeft = 900; // 15 minutes for payment
      _sessionActive = true;
    });

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sessionTimeLeft--;
      });

      if (_sessionTimeLeft <= 0) {
        _paymentTimeExpired();
        timer.cancel();
      }
    });

    print('⏰ Started 15-minute payment timer');
  }

  void _paymentTimeExpired() async {
    print('🕒 Payment time expired, releasing all locked seats');

    // Release all locked seats
    final seatsToRelease = List<String>.from(selectedSeats);
    for (String seatId in seatsToRelease) {
      try {
        await _releaseSeatLock(seatId);
        print('✅ Released expired payment lock for seat $seatId');
      } catch (e) {
        print('❌ Failed to release expired payment lock for seat $seatId: $e');
      }
    }

    setState(() {
      selectedSeats.clear();
      lockedSeats.clear();
      unlockedByUser.clear();
      _sessionActive = false;
      _sessionTimeLeft = 0;
    });

    _showSnackBar(
        'Payment time expired. Please select seats again.', Colors.orange);
  }

  // ========== LOCKED SEATS FETCHING ==========

  Future<void> _fetchLockedSeats() async {
    try {
      print('🔍 Fetching currently locked seats for event: ${widget.eventId}');
      final url =
          '${AppConfig.baseUrl}/api/seat-locks/events/${widget.eventId}/locks';

      // Get authentication token
      final authService = AuthService();
      final token = await authService.getStoredToken();

      final headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('🔑 Using auth token for locked seats request');
      } else {
        print('⚠️ No auth token available for locked seats request');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 API Response: ${response.body}');
        if (data['success'] == true) {
          final List<dynamic> lockedSeatsData = data['locks'] ?? [];

          // Debug: Log what the API returned
          final allLockedSeats =
              lockedSeatsData.map((seat) => seat['seatId'].toString()).toList();
          print('🔍 API returned locked seats: $allLockedSeats');

          setState(() {
            lockedSeats = lockedSeatsData
                .map((seat) => seat['seatId'].toString())
                .where((seatId) => !selectedSeats
                    .contains(seatId)) // Don't include our own selections
                .where((seatId) => !unlockedByUser.contains(
                    seatId)) // Don't include seats we explicitly unlocked
                .toList();
          });

          print(
              '🔒 Final locked seats for display: $lockedSeats (filtered from ${allLockedSeats.length} API seats)');
          if (unlockedByUser.isNotEmpty) {
            print('🚫 Seats unlocked by this user (excluded): $unlockedByUser');
          }
        } else {
          print('❌ API returned success: false');
        }
      } else {
        print('❌ Failed to fetch locked seats. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching locked seats: $e');
    }
  }

  Timer? _lockedSeatsRefreshTimer;

  void _startLockedSeatsRefreshTimer() {
    _lockedSeatsRefreshTimer?.cancel();
    _lockedSeatsRefreshTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        _fetchLockedSeats();
      }
    });
  }

  void _stopLockedSeatsRefreshTimer() {
    _lockedSeatsRefreshTimer?.cancel();
    _lockedSeatsRefreshTimer = null;
  }

  void _loadDemoSeatMap() {
    print('🎭 Loading demo seat map for testing');
    setState(() {
      // Create a demo seat map for testing
      seatMap = List.generate(50, (index) {
        final row = index ~/ 10;
        final col = index % 10;
        String status = 'available';

        // Make some seats booked/occupied for testing - more variety
        if (index == 5 ||
            index == 15 ||
            index == 25 ||
            index == 35 ||
            index == 45) {
          status = 'booked';
        } else if (index == 8 || index == 18 || index == 28) {
          status = 'occupied';
        } else if (index == 12 || index == 22) {
          status = 'reserved';
        }

        return {
          'id': 'seat-$index',
          'label': '${String.fromCharCode(65 + row)}${col + 1}',
          'row': row,
          'col': col,
          'price': row == 0
              ? 2500.0
              : (row == 1 ? 2000.0 : 1500.0), // Premium front rows
          'tier': row == 0 ? 'premium' : (row == 1 ? 'vip' : 'economy'),
          'status': status,
        };
      });
      eventName = 'Demo Event';
      eventDate = '2025-01-15';
      isLoading = false;
    });

    print('✅ Demo seat map loaded. Total seats: ${seatMap.length}');
    print(
        '🔍 Demo seat statuses: ${seatMap.map((s) => s['status']).toSet().toList()}');
    print(
        '🎯 Sample booked seats: ${seatMap.where((s) => s['status'] != 'available').map((s) => '${s['label']}(${s['status']})').toList()}');
    _startSession();
  }

  void _startSession() {
    if (seatMap.isEmpty) return;

    setState(() {
      _sessionActive = true;
      _sessionTimeLeft = 300; // 5 minutes for seat selection
    });

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sessionTimeLeft--;
      });

      if (_sessionTimeLeft <= 0) {
        _sessionExpired();
        timer.cancel();
      }
    });
  }

  void _sessionExpired() {
    setState(() {
      selectedSeats.clear();
      lockedSeats.clear();
      unlockedByUser.clear();
      _sessionActive = false;
      _sessionTimeLeft = 0;
    });

    _showSnackBar('Selection time expired. Please select seats again.', null);
  }

  void _showSnackBar(String message, Color? backgroundColor) {
    // Determine notification type based on color
    NotificationType type;
    if (backgroundColor == Colors.red) {
      type = NotificationType.error;
    } else if (backgroundColor == Colors.orange) {
      type = NotificationType.warning;
    } else {
      type = NotificationType.info;
    }

    CustomNotification.show(
      context,
      message: message,
      type: type,
    );
  }

  String _getSeatLabel(String seatId) {
    final seat = seatMap.firstWhere((s) => s['id'].toString() == seatId,
        orElse: () => <String, dynamic>{});
    return seat['label'] ?? seatId;
  }

  Future<void> _toggleSeat(String seatId) async {
    final seat = seatMap.firstWhere((s) => s['id'].toString() == seatId,
        orElse: () => <String, dynamic>{});
    final seatStatus =
        (seat['status']?.toString() ?? 'available').toLowerCase();
    final isAvailableFromBackend = seat['available'] == true ||
        (seat['available'] == null && seat['booked'] != true);
    final isBookedExplicitly = seat['booked'] == true;

    // Check if seat is locked by another user
    if (lockedSeats.contains(seatId) && !selectedSeats.contains(seatId)) {
      HapticFeedback.heavyImpact();
      _showSnackBar('This seat is currently being selected by another user',
          Colors.orange);
      print('🔒 Seat $seatId is locked by another user');
      return;
    }

    // Check if seat is available - handle all possible backend formats
    bool isSeatAvailable;
    if (seat.containsKey('available') || seat.containsKey('booked')) {
      // Backend format: available: true/false OR booked: true/false
      isSeatAvailable = isAvailableFromBackend && !isBookedExplicitly;
    } else {
      // Demo/alternative format: status field
      isSeatAvailable = !(seatStatus == 'occupied' ||
          seatStatus == 'booked' ||
          seatStatus == 'unavailable' ||
          seatStatus == 'reserved');
    }

    if (seat.isEmpty || !isSeatAvailable) {
      HapticFeedback.heavyImpact();
      String statusInfo;
      if (seat.containsKey('available') || seat.containsKey('booked')) {
        statusInfo =
            'Available: ${seat['available']}, Booked: ${seat['booked']}';
      } else {
        statusInfo = 'Status: $seatStatus';
      }
      _showSnackBar(
          'This seat is not available for booking ($statusInfo)', Colors.red);
      print('❌ Seat $seatId is not available - $statusInfo');
      return;
    }

    // Enhanced haptic feedback
    HapticFeedback.mediumImpact();

    if (selectedSeats.contains(seatId)) {
      // Deselect seat (no unlocking needed since not locked until payment)
      setState(() {
        selectedSeats.remove(seatId);
        lockedSeats.remove(seatId);
        unlockedByUser.add(seatId); // Track that this user deselected this seat
      });

      // Visual feedback for deselection
      _showSnackBar('Seat ${_getSeatLabel(seatId)} deselected', Colors.orange);
      print('✅ Seat $seatId deselected (was not locked)');
    } else {
      // Select seat (no locking until payment)
      setState(() {
        selectedSeats.add(seatId);
        unlockedByUser
            .remove(seatId); // Remove from unlocked list if re-selecting
      });

      // Enhanced selection animation
      _selectionAnimation.reset();
      _selectionAnimation.forward().then((_) {
        _selectionAnimation.reverse();
      });

      // Visual feedback for selection
      _showSnackBar('Seat ${_getSeatLabel(seatId)} selected', Colors.green);

      // Start session if this is the first seat selected
      if (!_sessionActive) {
        _startSession();
      }

      print('✅ Seat $seatId selected (not locked until payment)');
    }
  }

  void _onInteractionStart(ScaleStartDetails details) {
    _showZoomControls = true;
    _resetControlsTimer();
    setState(() {});
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    _currentScale = _transformationController.value.getMaxScaleOnAxis();
    _resetControlsTimer();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showZoomControls = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading venue layout...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(theme),
            if (_sessionActive) _buildSessionTimer(theme),
            Expanded(
              child: _buildSeatMapContainer(theme),
            ),
            _buildBottomSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: colorScheme.onSurface,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Your Seats',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (eventName.isNotEmpty)
                  Text(
                    eventName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _selectionAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: selectedSeats.isNotEmpty
                    ? _selectionAnimation.value + 1.0
                    : 1.0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedSeats.isNotEmpty
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${selectedSeats.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selectedSeats.isNotEmpty
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTimer(ThemeData theme) {
    final minutes = _sessionTimeLeft ~/ 60;
    final seconds = _sessionTimeLeft % 60;
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _sessionTimeLeft < 300
            ? Colors.orange.withValues(alpha: 0.1)
            : colorScheme.primaryContainer.withValues(alpha: 0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: _sessionTimeLeft < 300 ? Colors.orange : colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Time remaining: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  _sessionTimeLeft < 300 ? Colors.orange : colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatMapContainer(ThemeData theme) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: _minScale,
            maxScale: _maxScale,
            boundaryMargin: const EdgeInsets.all(50),
            constrained: false,
            onInteractionStart: _onInteractionStart,
            onInteractionUpdate: _onInteractionUpdate,
            child: Container(
              // Make the content larger than the viewport to enable panning
              width: MediaQuery.of(context).size.width * 1.5,
              height: MediaQuery.of(context).size.height * 1.2,
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStageIndicator(theme),
                  const SizedBox(height: 40),
                  _buildSeatGrid(theme),
                  const SizedBox(height: 40),
                  _buildLegend(theme),
                ],
              ),
            ),
          ),
        ),
        if (_showZoomControls) _buildFloatingControls(theme),
      ],
    );
  }

  Widget _buildStageIndicator(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'STAGE',
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSeatGrid(ThemeData theme) {
    if (seatMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Text(
          'No seat map available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    // Group seats by row
    Map<int, List<dynamic>> seatsByRow = {};
    for (var seat in seatMap) {
      final row = (seat['row'] as num?)?.toInt() ?? 0;
      seatsByRow[row] ??= [];
      seatsByRow[row]!.add(seat);
    }

    // Sort rows and seats within rows
    final sortedRows = seatsByRow.keys.toList()..sort();
    for (var row in sortedRows) {
      seatsByRow[row]!.sort((a, b) =>
          ((a['col'] as num?) ?? 0).compareTo((b['col'] as num?) ?? 0));
    }

    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          children: sortedRows.map((row) {
            final seats = seatsByRow[row]!;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Row label
                  Container(
                    width: 30,
                    alignment: Alignment.center,
                    child: Text(
                      String.fromCharCode(65 + row), // A, B, C, etc.
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Seats in row
                  Flexible(
                    child: Wrap(
                      spacing: 4,
                      children:
                          seats.map((seat) => _buildSeat(seat, theme)).toList(),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSeat(Map<String, dynamic> seat, ThemeData theme) {
    final seatId = seat['id']?.toString() ?? '';
    final isSelected = selectedSeats.contains(seatId);

    // Handle multiple ways of indicating seat availability/booking status
    final seatStatus =
        (seat['status']?.toString() ?? 'available').toLowerCase();
    final isAvailableFromBackend = seat['available'] == true ||
        (seat['available'] == null && seat['booked'] != true);
    final isBookedExplicitly = seat['booked'] == true;

    // Determine if seat is occupied - handle all possible backend formats
    bool isOccupied;
    if (seat.containsKey('available') || seat.containsKey('booked')) {
      // Backend format: available: true/false OR booked: true/false
      isOccupied = !isAvailableFromBackend || isBookedExplicitly;
    } else {
      // Demo/alternative format: status: 'available'/'booked'/'occupied'
      isOccupied = seatStatus == 'occupied' ||
          seatStatus == 'booked' ||
          seatStatus == 'unavailable' ||
          seatStatus == 'reserved';
    }

    final tier = seat['tier']?.toString() ??
        seat['ticketType']?.toString() ??
        seat['type']?.toString() ??
        'economy';
    final colorScheme = theme.colorScheme;

    // Debug print for troubleshooting
    // if (!isAvailableFromBackend ||
    //     seatStatus != 'available' ||
    //     isBookedExplicitly) {
    //   print(
    //       '🔍 Seat ${seat['label'] ?? seatId} - Status: $seatStatus, Available: ${seat['available']}, Booked: ${seat['booked']}, isOccupied: $isOccupied');
    // }

    final isLockedByOther = lockedSeats.contains(seatId) && !isSelected;

    Color getSeatColor() {
      final isDark = theme.brightness == Brightness.dark;

      if (isOccupied) {
        // Red for booked/occupied seats - theme-aware
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
      }
      if (isSelected) {
        // Green for selected seats - theme-aware
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);
      }
      if (isLockedByOther) {
        // Orange for seats locked by other users - theme-aware
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
      }

      // Available seats with tier-based colors - theme-aware
      switch (tier.toLowerCase()) {
        case 'premium':
          // Gold/amber for premium available seats
          return isDark ? const Color(0xFFFFCC02) : const Color(0xFFFFB74D);
        case 'vip':
          // Purple for VIP available seats
          return isDark ? const Color(0xFFBA68C8) : const Color(0xFF9C27B0);
        default:
          // Blue for regular available seats
          return isDark ? const Color(0xFF42A5F5) : const Color(0xFF2196F3);
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            (isOccupied || isLockedByOther) ? null : () => _toggleSeat(seatId),
        borderRadius: BorderRadius.circular(6),
        splashColor: colorScheme.primary.withValues(alpha: 0.3),
        highlightColor: colorScheme.primary.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: getSeatColor(),
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(color: theme.colorScheme.surface, width: 3)
                : Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: getSeatColor().withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: isSelected
                ? AnimatedBuilder(
                    animation: _selectionAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.8 + (_selectionAnimation.value * 0.4),
                        child: Icon(
                          Icons.check,
                          color: theme.colorScheme.surface,
                          size: 18,
                        ),
                      );
                    },
                  )
                : isOccupied
                    ? Icon(
                        Icons.close,
                        color: theme.colorScheme.surface,
                        size: 16,
                      )
                    : isLockedByOther
                        ? AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.7 + (0.3 * _pulseAnimation.value),
                                child: const Icon(
                                  Icons.lock_outline,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              );
                            },
                          )
                        : Text(
                            seat['label']?.toString().split('-').last ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildLegendItem('Available', const Color(0xFF2196F3), theme),
          _buildLegendItem('Selected', const Color(0xFF4CAF50), theme),
          _buildLegendItem('Locked', const Color(0xFFFF9800), theme),
          _buildLegendItem('Booked', const Color(0xFFD32F2F), theme),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingControls(ThemeData theme) {
    return Positioned(
      top: 20,
      right: 16,
      child: AnimatedOpacity(
        opacity: _showZoomControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            _buildZoomButton(Icons.add, () => _zoomIn(), theme),
            const SizedBox(height: 8),
            _buildZoomIndicator(theme),
            const SizedBox(height: 8),
            _buildZoomButton(Icons.remove, () => _zoomOut(), theme),
            const SizedBox(height: 16),
            _buildZoomButton(
                Icons.center_focus_strong, () => _resetZoom(), theme),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomButton(
      IconData icon, VoidCallback onPressed, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Icon(
            icon,
            color: colorScheme.onSurface,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomIndicator(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '${(_currentScale * 100).round()}%',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = math.min(currentScale * 1.2, _maxScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
    setState(() {
      _currentScale = newScale;
    });
    _resetControlsTimer();
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = math.max(currentScale / 1.2, _minScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
    setState(() {
      _currentScale = newScale;
    });
    _resetControlsTimer();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
    });
    _resetControlsTimer();
  }

  Widget _buildBottomSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final totalPrice = selectedSeats.fold<double>(
      0.0,
      (sum, seatId) {
        final seat = seatMap.firstWhere(
          (s) => s['id'].toString() == seatId,
          orElse: () => {'price': 0.0},
        );
        return sum + ((seat['price'] as num?)?.toDouble() ?? 0.0);
      },
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedSeats.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.08),
                    colorScheme.primaryContainer.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedSeats.length} seat${selectedSeats.length > 1 ? 's' : ''} selected',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total Amount',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'LKR ${totalPrice.toStringAsFixed(0)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Seats',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selectedSeats
                              .map((id) => _getSeatLabel(id))
                              .join(' • '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedSeats.isEmpty ? null : _proceedToBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedSeats.isEmpty
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : colorScheme.primary,
                foregroundColor: Colors.white, // Always white text
                disabledForegroundColor:
                    colorScheme.onSurface.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: selectedSeats.isEmpty ? 0 : 4,
              ),
              child: Text(
                selectedSeats.isEmpty
                    ? 'Select seats to continue'
                    : 'Continue to Payment',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white, // Explicit white color
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToBooking() async {
    if (selectedSeats.isEmpty) {
      HapticFeedback.heavyImpact();
      _showSnackBar('Please select at least one seat', Colors.orange);
      return;
    }

    HapticFeedback.lightImpact();

    try {
      // Show loading indicator
      _showSnackBar('Locking seats for payment...', Colors.blue);

      // Lock all selected seats for 15-minute payment process
      final lockSuccess = await _lockAllSelectedSeatsForPayment();

      if (!lockSuccess) {
        _showSnackBar(
            'Failed to lock some seats. Please try again.', Colors.red);
        return;
      }

      _showSnackBar(
          'Seats locked for payment. You have 15 minutes to complete.',
          Colors.green);

      final selectedSeatData = selectedSeats.map((seatId) {
        final seat = seatMap.firstWhere((s) => s['id'].toString() == seatId,
            orElse: () => <String, dynamic>{});
        return {
          'id': seat['id'],
          'label': seat['label'] ?? 'Seat $seatId',
          'price': (seat['price'] as num?)?.toDouble() ?? 0.0,
          'tier': seat['tier'] ?? 'general',
          'price_cents':
              ((seat['price'] as num?)?.toDouble() ?? 0.0 * 100).round(),
        };
      }).toList();

      print('🎫 Proceeding to booking with ${selectedSeats.length} seats');
      print('📊 Seat data: $selectedSeatData');

      final navigationData = {
        'eventId': widget.eventId,
        'eventName': eventName.isNotEmpty ? eventName : 'Event',
        'eventDate': eventDate.isNotEmpty ? eventDate : 'TBD',
        'ticketType': widget.ticketType,
        'seatCount': selectedSeats.length,
        'selectedSeats': selectedSeats.map((id) => id.toString()).toList(),
        'selectedSeatData': selectedSeatData,
      };

      print(
          '🚀 Navigating directly to payment screen with data: $navigationData');

      // Navigate directly to payment screen instead of user details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            eventId: widget.eventId,
            eventName: eventName.isNotEmpty ? eventName : 'Event',
            eventDate: eventDate.isNotEmpty ? eventDate : 'TBD',
            ticketType: widget.ticketType,
            seatCount: selectedSeats.length,
            selectedSeats: selectedSeats.map((id) => id.toString()).toList(),
            selectedSeatData: selectedSeatData,
          ),
        ),
      );
    } catch (e) {
      print('❌ Error proceeding to booking: $e');
      _showSnackBar(
          'Error proceeding to booking. Please try again.', Colors.red);
    }
  }
}
