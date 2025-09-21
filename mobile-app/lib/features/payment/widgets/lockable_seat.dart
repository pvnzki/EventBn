import 'dart:async';
import 'package:flutter/material.dart';
import '../services/seat_lock_service.dart';

class LockableSeat extends StatefulWidget {
  final String eventId;
  final String seatId;
  final String seatLabel;
  final bool isAvailable;
  final bool isSelected;
  final double price;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final Color? availableColor;
  final Color? bookedColor;
  final Color? lockedColor;
  
  const LockableSeat({
    super.key,
    required this.eventId,
    required this.seatId,
    required this.seatLabel,
    required this.isAvailable,
    required this.isSelected,
    required this.price,
    this.onTap,
    this.selectedColor,
    this.availableColor,
    this.bookedColor,
    this.lockedColor,
  });

  @override
  State<LockableSeat> createState() => _LockableSeatState();
}

class _LockableSeatState extends State<LockableSeat>
    with SingleTickerProviderStateMixin {
  final SeatLockService _lockService = SeatLockService();
  
  bool _isLocked = false;
  bool _isLoading = false;
  int? _lockTTL;
  Timer? _ttlTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation for selected seats
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    if (widget.isSelected) {
      _pulseController.repeat(reverse: true);
    }
    
    _checkInitialLockStatus();
    _listenToLockUpdates();
  }

  @override
  void didUpdateWidget(LockableSeat oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle selection animation
    if (widget.isSelected && !oldWidget.isSelected) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _ttlTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Check if seat is initially locked
  Future<void> _checkInitialLockStatus() async {
    if (!mounted) return;
    
    try {
      final status = await _lockService.getSeatLockStatus(
        eventId: widget.eventId,
        seatId: widget.seatId,
      );
      
      if (mounted && status['locked'] == true) {
        setState(() {
          _isLocked = true;
          _lockTTL = status['ttl'];
        });
        _startTTLCountdown();
      }
    } catch (e) {
      print('Error checking initial lock status: $e');
    }
  }

  /// Listen to lock updates from the service
  void _listenToLockUpdates() {
    _lockService.getLockUpdateStream(widget.eventId)?.listen((update) {
      if (!mounted) return;
      
      final seatId = update['seatId'];
      if (seatId != widget.seatId) return;
      
      switch (update['action']) {
        case 'locked':
          if (mounted) {
            setState(() {
              _isLocked = true;
              _lockTTL = 300; // 5 minutes default
            });
            _startTTLCountdown();
          }
          break;
        case 'released':
          if (mounted) {
            setState(() {
              _isLocked = false;
              _lockTTL = null;
            });
            _ttlTimer?.cancel();
          }
          break;
        case 'extended':
          if (mounted) {
            setState(() {
              _lockTTL = 600; // 10 minutes for payment
            });
            _startTTLCountdown();
          }
          break;
      }
    });
  }

  /// Start countdown timer for lock TTL
  void _startTTLCountdown() {
    _ttlTimer?.cancel();
    
    if (_lockTTL == null || _lockTTL! <= 0) return;
    
    _ttlTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _lockTTL = (_lockTTL ?? 0) - 1;
      });
      
      if (_lockTTL! <= 0) {
        setState(() {
          _isLocked = false;
          _lockTTL = null;
        });
        timer.cancel();
      }
    });
  }

  /// Handle seat tap
  Future<void> _handleTap() async {
    if (_isLoading) return;
    
    if (widget.isSelected) {
      // If selected, release the lock
      widget.onTap?.call();
      return;
    }
    
    if (_isLocked || !widget.isAvailable) {
      // Show feedback for unavailable seats
      _showUnavailableDialog();
      return;
    }
    
    // Try to lock the seat
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _lockService.lockSeat(
        eventId: widget.eventId,
        seatId: widget.seatId,
      );
      
      if (result['success']) {
        // Seat locked successfully, notify parent
        widget.onTap?.call();
        
        setState(() {
          _isLocked = true;
          _lockTTL = 300; // 5 minutes
        });
        _startTTLCountdown();
        
      } else {
        // Failed to lock seat
        _showLockFailedDialog(result['message'] ?? 'Failed to select seat');
        
        if (result['isLocked'] == true) {
          setState(() {
            _isLocked = true;
            _lockTTL = result['ttl'];
          });
          _startTTLCountdown();
        }
      }
    } catch (e) {
      _showLockFailedDialog('Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show dialog when seat is unavailable
  void _showUnavailableDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seat Unavailable'),
        content: Text(_isLocked 
          ? 'This seat is currently being selected by another user.\n\nPlease choose a different seat or try again in a moment.'
          : 'This seat has already been booked.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show dialog when lock fails
  void _showLockFailedDialog(String message) {
    if (!mounted) return;
    
    // Make the message more user-friendly
    String userMessage = message
        .replaceAll('lock', 'select')
        .replaceAll('Lock', 'Selection')
        .replaceAll('locked', 'being selected');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Select Seat'),
        content: Text(userMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine seat state and color
    Color seatColor;
    IconData? overlayIcon;
    
    if (_isLoading) {
      seatColor = Colors.grey.shade400;
    } else if (!widget.isAvailable && !_isLocked) {
      seatColor = widget.bookedColor ?? Colors.grey.shade600;
      overlayIcon = Icons.close;
    } else if (_isLocked && !widget.isSelected) {
      // Locked by another user - show as unavailable
      seatColor = widget.bookedColor ?? Colors.grey.shade500;
      overlayIcon = Icons.person_outline;
    } else if (widget.isSelected) {
      // Selected by current user (locked behind the scenes) - show in orange
      seatColor = Colors.orange.withOpacity(0.9);
      overlayIcon = Icons.check;
    } else {
      seatColor = widget.availableColor ?? Colors.green.shade400;
    }
    
    Widget seatWidget = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: seatColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.isSelected 
            ? theme.primaryColor.withOpacity(0.8)
            : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          if (widget.isSelected)
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Stack(
        children: [
          // Seat label
          Center(
            child: Text(
              widget.seatLabel,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          
          // Overlay icon
          if (overlayIcon != null && !_isLoading)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(
                overlayIcon,
                size: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
        ],
      ),
    );
    
    // Apply pulse animation to selected seats
    if (widget.isSelected) {
      seatWidget = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        ),
        child: seatWidget,
      );
    }
    
    return GestureDetector(
      onTap: _handleTap,
      child: Tooltip(
        message: _buildTooltipMessage(),
        child: seatWidget,
      ),
    );
  }

  String _buildTooltipMessage() {
    if (_isLocked && !widget.isSelected) {
      return 'Currently being selected by another user';
    } else if (!widget.isAvailable) {
      return 'Already booked';
    } else if (widget.isSelected) {
      return '${widget.seatLabel} - Selected (\$${widget.price.toStringAsFixed(2)})';
    } else {
      return '${widget.seatLabel} - Available (\$${widget.price.toStringAsFixed(2)})';
    }
  }
}

/// Seat status enum
enum SeatStatus {
  available,
  selected,
  booked,
  locked,
  loading,
}

/// Seat lock info model
class SeatLockInfo {
  final String seatId;
  final bool isLocked;
  final int? ttl;
  final DateTime? lockedAt;
  
  const SeatLockInfo({
    required this.seatId,
    required this.isLocked,
    this.ttl,
    this.lockedAt,
  });
  
  factory SeatLockInfo.fromJson(Map<String, dynamic> json) {
    return SeatLockInfo(
      seatId: json['seatId'] ?? '',
      isLocked: json['locked'] ?? false,
      ttl: json['ttl'],
      lockedAt: json['timestamp'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
        : null,
    );
  }
}
