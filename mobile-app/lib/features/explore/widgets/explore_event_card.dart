import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/event_model.dart';

class ExploreEventCard extends StatefulWidget {
  final ExploreEvent event;
  final int? crossAxisCellCount;
  final int? mainAxisCellCount;

  const ExploreEventCard({
    super.key,
    required this.event,
    this.crossAxisCellCount,
    this.mainAxisCellCount,
  });

  @override
  State<ExploreEventCard> createState() => _ExploreEventCardState();
}

class _ExploreEventCardState extends State<ExploreEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
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

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLargeCard = (widget.crossAxisCellCount ?? 1) > 1 ||
        (widget.mainAxisCellCount ?? 1) > 1;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        context.push('/event/${widget.event.id}');
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    _buildImage(colorScheme),

                    // Gradient Overlay
                    _buildGradientOverlay(),

                    // Content
                    if (_isImageLoaded)
                      _buildContent(theme, colorScheme, isLargeCard),

                    // Loading Skeleton
                    if (!_isImageLoaded) _buildLoadingSkeleton(colorScheme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage(ColorScheme colorScheme) {
    return Image.network(
      widget.event.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isImageLoaded) {
              setState(() {
                _isImageLoaded = true;
              });
            }
          });
          return child;
        }
        return _buildLoadingSkeleton(colorScheme);
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'Event Image',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildContent(
      ThemeData theme, ColorScheme colorScheme, bool isLargeCard) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge
          if (widget.event.badge != null) _buildBadge(theme),

          if (widget.event.badge != null) const SizedBox(height: 8),

          // Event Name
          Text(
            widget.event.name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isLargeCard ? 16 : 14,
            ),
            maxLines: isLargeCard ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: isLargeCard ? 14 : 12,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.event.location,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isLargeCard ? 12 : 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (isLargeCard) ...[
            const SizedBox(height: 8),
            _buildExtraInfo(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(ThemeData theme) {
    Color badgeColor;
    switch (widget.event.badge?.toLowerCase()) {
      case 'trending':
        badgeColor = Colors.orange;
        break;
      case 'featured':
        badgeColor = Colors.blue;
        break;
      case 'new':
        badgeColor = Colors.green;
        break;
      case 'hot':
        badgeColor = Colors.red;
        break;
      default:
        badgeColor = theme.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.event.badge!.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildExtraInfo(ThemeData theme) {
    return Row(
      children: [
        // Price
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '\$${widget.event.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Attendees
        Icon(
          Icons.people,
          size: 12,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(width: 2),
        Text(
          '${widget.event.attendees}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),

        const Spacer(),

        // Verified badge
        if (widget.event.isVerified)
          const Icon(
            Icons.verified,
            size: 16,
            color: Colors.blue,
          ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
