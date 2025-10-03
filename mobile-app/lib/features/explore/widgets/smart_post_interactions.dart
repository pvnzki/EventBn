import 'package:flutter/material.dart';
import '../../../core/services/proactive_data_preloader.dart';

/// Enhanced post interaction detector that preloads data based on user gestures
class SmartPostInteractionDetector extends StatefulWidget {
  final String postId;
  final Widget child;
  final VoidCallback? onCommentTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onShareTap;

  const SmartPostInteractionDetector({
    super.key,
    required this.postId,
    required this.child,
    this.onCommentTap,
    this.onLikeTap,
    this.onShareTap,
  });

  @override
  State<SmartPostInteractionDetector> createState() =>
      _SmartPostInteractionDetectorState();
}

class _SmartPostInteractionDetectorState
    extends State<SmartPostInteractionDetector> with ProactivePreloadingMixin {
  bool _isHoveringComment = false;
  DateTime? _hoverStartTime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Detect when user might be about to tap comment button
      onPanStart: (details) {
        _detectCommentButtonProximity(details.localPosition);
      },
      onPanUpdate: (details) {
        _detectCommentButtonProximity(details.localPosition);
      },
      onPanEnd: (details) {
        _endCommentHover();
      },
      child: MouseRegion(
        onEnter: (_) {
          // For web/desktop - preload when mouse enters post area
          onCommentButtonHover(widget.postId);
        },
        child: widget.child,
      ),
    );
  }

  void _detectCommentButtonProximity(Offset position) {
    // Approximate comment button position (usually bottom right area)
    final screenWidth = MediaQuery.of(context).size.width;
    final commentButtonArea = Rect.fromLTWH(
      screenWidth * 0.6, // Comment button typically in right 40% of screen
      0,
      screenWidth * 0.4,
      200, // Approximate height where comment button might be
    );

    final isNearCommentButton = commentButtonArea.contains(position);

    if (isNearCommentButton && !_isHoveringComment) {
      _startCommentHover();
    } else if (!isNearCommentButton && _isHoveringComment) {
      _endCommentHover();
    }
  }

  void _startCommentHover() {
    setState(() {
      _isHoveringComment = true;
      _hoverStartTime = DateTime.now();
    });

    // Preload comments after a short delay (user might just be scrolling)
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_isHoveringComment &&
          _hoverStartTime != null &&
          DateTime.now().difference(_hoverStartTime!).inMilliseconds >= 200) {
        onCommentButtonHover(widget.postId);
      }
    });
  }

  void _endCommentHover() {
    setState(() {
      _isHoveringComment = false;
      _hoverStartTime = null;
    });
  }
}

/// Enhanced comment button that provides immediate feedback and preloads data
class SmartCommentButton extends StatefulWidget {
  final String postId;
  final int commentCount;
  final VoidCallback onTap;
  final double size;
  final Color? color;

  const SmartCommentButton({
    super.key,
    required this.postId,
    required this.commentCount,
    required this.onTap,
    this.size = 24,
    this.color,
  });

  @override
  State<SmartCommentButton> createState() => _SmartCommentButtonState();
}

class _SmartCommentButtonState extends State<SmartCommentButton>
    with ProactivePreloadingMixin, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPreloaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      onExit: (_) => _onHoverEnd(),
      child: GestureDetector(
        onTapDown: (_) {
          _animationController.forward();
          // Ensure data is preloaded before showing bottom sheet
          if (!_isPreloaded) {
            onCommentButtonHover(widget.postId);
          }
        },
        onTapUp: (_) {
          _animationController.reverse();
          // Small delay to allow preloading to complete
          Future.delayed(const Duration(milliseconds: 100), () {
            widget.onTap();
          });
        },
        onTapCancel: () {
          _animationController.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isPreloaded ? Colors.blue.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.comment,
                      size: widget.size,
                      color: widget.color ?? Colors.white,
                    ),
                    if (widget.commentCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        widget.commentCount.toString(),
                        style: TextStyle(
                          color: widget.color ?? Colors.white,
                          fontSize: widget.size * 0.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onHoverStart() {
    // Start preloading on hover
    onCommentButtonHover(widget.postId);
    setState(() {
      _isPreloaded = true;
    });
  }

  void _onHoverEnd() {
    // Keep preloaded state for a while
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isPreloaded = false;
        });
      }
    });
  }
}

/// Enhanced FAB for create post that preloads events
class SmartCreatePostFAB extends StatefulWidget {
  final VoidCallback onTap;

  const SmartCreatePostFAB({
    super.key,
    required this.onTap,
  });

  @override
  State<SmartCreatePostFAB> createState() => _SmartCreatePostFABState();
}

class _SmartCreatePostFABState extends State<SmartCreatePostFAB>
    with ProactivePreloadingMixin, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPreloaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Preload events proactively since user might create a post soon
    Future.delayed(const Duration(seconds: 2), () {
      onCreatePostNavigation();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      child: GestureDetector(
        onTapDown: (_) {
          _animationController.forward();
          // Ensure events are preloaded
          if (!_isPreloaded) {
            onCreatePostNavigation();
          }
        },
        onTapUp: (_) {
          _animationController.reverse();
          // Small delay to allow preloading
          Future.delayed(const Duration(milliseconds: 150), () {
            widget.onTap();
          });
        },
        onTapCancel: () {
          _animationController.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isPreloaded
                        ? [Colors.green[400]!, Colors.blue[400]!]
                        : [Colors.blue[400]!, Colors.purple[400]!],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onHoverStart() {
    // Preload events when user hovers over create button
    onCreatePostNavigation();
    setState(() {
      _isPreloaded = true;
    });
  }
}
