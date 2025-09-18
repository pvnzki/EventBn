import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../auth/services/auth_service.dart';
import '../../../core/config/app_config.dart';

class SeatLockService {
  final String baseUrl = AppConfig.baseUrl;
  final AuthService _authService = AuthService();
  
  // Private constructor for singleton
  SeatLockService._internal();
  static final SeatLockService _instance = SeatLockService._internal();
  factory SeatLockService() => _instance;

  // Stream controllers for real-time updates
  final Map<String, StreamController<Map<String, dynamic>>> _eventLockControllers = {};

  /// Lock a seat for the current user
  /// Returns: {success: bool, message: String, lockInfo?: Map}
  Future<Map<String, dynamic>> lockSeat({
    required String eventId,
    required String seatId,
  }) async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please log in.',
        };
      }

      print('🔒 Attempting to lock seat $seatId for event $eventId');

      final response = await http.post(
        Uri.parse('$baseUrl/api/seat-locks/events/$eventId/seats/$seatId/lock'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout', const Duration(seconds: 10));
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Seat locked successfully: $seatId');
        
        // Notify listeners about the lock
        _notifyLockUpdate(eventId, {
          'action': 'locked',
          'seatId': seatId,
          'lockInfo': data['lockInfo'],
        });

        return {
          'success': true,
          'message': data['message'] ?? 'Seat locked successfully',
          'lockInfo': data['lockInfo'],
        };
      } else if (response.statusCode == 409) {
        // Seat already locked by another user
        print('⚠️ Seat already locked: $seatId');
        return {
          'success': false,
          'message': data['message'] ?? 'Seat is temporarily unavailable',
          'isLocked': true,
          'ttl': data['ttl'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to lock seat',
        };
      }
    } catch (e) {
      print('❌ Error locking seat: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Check if a seat is locked
  /// Returns: {locked: bool, ttl?: int, timestamp?: int}
  Future<Map<String, dynamic>> getSeatLockStatus({
    required String eventId,
    required String seatId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/seat-locks/events/$eventId/seats/$seatId/lock'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['lockStatus'] ?? {'locked': false};
      }
      
      return {'locked': false};
    } catch (e) {
      print('❌ Error checking seat lock status: $e');
      return {'locked': false};
    }
  }

  /// Extend seat lock duration (for payment process)
  Future<Map<String, dynamic>> extendSeatLock({
    required String eventId,
    required String seatId,
  }) async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please log in.',
        };
      }

      print('⏰ Extending lock for seat $seatId');

      final response = await http.put(
        Uri.parse('$baseUrl/api/seat-locks/events/$eventId/seats/$seatId/lock/extend'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Lock extended successfully for seat $seatId');
        
        _notifyLockUpdate(eventId, {
          'action': 'extended',
          'seatId': seatId,
          'duration': data['duration'],
        });

        return {
          'success': true,
          'message': data['message'] ?? 'Lock extended successfully',
          'duration': data['duration'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to extend lock',
        };
      }
    } catch (e) {
      print('❌ Error extending seat lock: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Release a seat lock
  Future<Map<String, dynamic>> releaseSeatLock({
    required String eventId,
    required String seatId,
  }) async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please log in.',
        };
      }

      print('🔓 Releasing lock for seat $seatId');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/seat-locks/events/$eventId/seats/$seatId/lock'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Lock released successfully for seat $seatId');
        
        _notifyLockUpdate(eventId, {
          'action': 'released',
          'seatId': seatId,
        });

        return {
          'success': true,
          'message': data['message'] ?? 'Lock released successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to release lock',
        };
      }
    } catch (e) {
      print('❌ Error releasing seat lock: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Get all locked seats for an event
  Future<Map<String, dynamic>> getEventLockedSeats({
    required String eventId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/seat-locks/events/$eventId/locks'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'lockedSeats': data['lockedSeats'] ?? [],
          };
        }
      }
      
      return {
        'success': false,
        'lockedSeats': [],
      };
    } catch (e) {
      print('❌ Error getting event locked seats: $e');
      return {
        'success': false,
        'lockedSeats': [],
      };
    }
  }

  /// Lock multiple seats at once
  Future<Map<String, dynamic>> lockMultipleSeats({
    required String eventId,
    required List<String> seatIds,
  }) async {
    final results = <String, Map<String, dynamic>>{};
    bool allSuccess = true;
    String errorMessage = '';

    for (final seatId in seatIds) {
      final result = await lockSeat(eventId: eventId, seatId: seatId);
      results[seatId] = result;
      
      if (!result['success']) {
        allSuccess = false;
        if (errorMessage.isEmpty) {
          errorMessage = result['message'] ?? 'Failed to lock some seats';
        }
      }
    }

    return {
      'success': allSuccess,
      'message': allSuccess ? 'All seats locked successfully' : errorMessage,
      'results': results,
    };
  }

  /// Release multiple seats at once
  Future<Map<String, dynamic>> releaseMultipleSeats({
    required String eventId,
    required List<String> seatIds,
  }) async {
    final results = <String, Map<String, dynamic>>{};
    bool allSuccess = true;

    for (final seatId in seatIds) {
      final result = await releaseSeatLock(eventId: eventId, seatId: seatId);
      results[seatId] = result;
      
      if (!result['success']) {
        allSuccess = false;
      }
    }

    return {
      'success': allSuccess,
      'message': allSuccess ? 'All locks released successfully' : 'Some locks failed to release',
      'results': results,
    };
  }

  /// Start polling for lock updates (for real-time seat availability)
  void startPollingEventLocks({
    required String eventId,
    Duration interval = const Duration(seconds: 10),
  }) {
    // Don't start multiple timers for the same event
    if (_eventLockControllers.containsKey(eventId)) {
      return;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _eventLockControllers[eventId] = controller;

    Timer.periodic(interval, (timer) async {
      if (!_eventLockControllers.containsKey(eventId)) {
        timer.cancel();
        return;
      }

      try {
        final result = await getEventLockedSeats(eventId: eventId);
        if (result['success']) {
          controller.add({
            'action': 'poll_update',
            'lockedSeats': result['lockedSeats'],
          });
        }
      } catch (e) {
        print('❌ Error polling event locks: $e');
      }
    });
  }

  /// Stop polling for an event
  void stopPollingEventLocks(String eventId) {
    final controller = _eventLockControllers.remove(eventId);
    controller?.close();
  }

  /// Get stream for lock updates
  Stream<Map<String, dynamic>>? getLockUpdateStream(String eventId) {
    return _eventLockControllers[eventId]?.stream;
  }

  /// Internal method to notify listeners about lock updates
  void _notifyLockUpdate(String eventId, Map<String, dynamic> update) {
    final controller = _eventLockControllers[eventId];
    if (controller != null && !controller.isClosed) {
      controller.add(update);
    }
  }

  /// Clean up all streams
  void dispose() {
    for (final controller in _eventLockControllers.values) {
      controller.close();
    }
    _eventLockControllers.clear();
  }
}

/// Timeout exception for HTTP requests
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (${timeout.inSeconds}s)';
}
