import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool isBookmarked = false;
  bool isFollowing = false;
  bool isAboutExpanded = false;

  @override
  void initState() {
    super.initState();
    print('EventDetailsScreen initialized with eventId: ${widget.eventId}');
  }

  // Mock event data
  final Map<String, dynamic> eventData = {
    'title': 'National Music Festival',
    'heroImage':
        'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
    'category': 'Music',
    'attendeeCount': '20,000+',
    'organizer': {
      'name': 'World of Music',
      'role': 'Organizer',
      'avatar':
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=100',
      'events': 24,
      'followers': '967K',
      'following': 20,
    },
    'about':
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    'gallery': [
      'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=200',
      'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=200',
      'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=200',
    ],
    'location': {
      'address': 'Grand City St. 100, New York, United States',
      'venue': 'Madison Square Garden',
    },
    'date': 'Dec 23, 2024',
    'time': '19:00 - 23:00 PM',
    'price': 'FROM \$25',
  };

  final List<Map<String, dynamic>> attendees = [
    {
      'name': 'Leatrice Handler',
      'avatar': 'https://i.pravatar.cc/100?img=1',
      'isFollowing': false
    },
    {
      'name': 'Tanner Stafford',
      'avatar': 'https://i.pravatar.cc/100?img=2',
      'isFollowing': true
    },
    {
      'name': 'Chantal Shelburne',
      'avatar': 'https://i.pravatar.cc/100?img=3',
      'isFollowing': false
    },
    {
      'name': 'Maryland Winkles',
      'avatar': 'https://i.pravatar.cc/100?img=4',
      'isFollowing': true
    },
    {
      'name': 'Sanjuanita Ordonez',
      'avatar': 'https://i.pravatar.cc/100?img=5',
      'isFollowing': false
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeroSection(context, theme),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventHeader(theme),
                    _buildOrganizerSection(theme),
                    _buildAboutSection(theme),
                    _buildGallerySection(theme),
                    _buildLocationSection(theme),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ],
          ),
          // Fixed bottom Book button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: _buildBookEventButton(theme),
              ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              isBookmarked ? Icons.favorite : Icons.favorite_border,
              color: isBookmarked ? Colors.red : theme.colorScheme.onSurface,
            ),
            onPressed: () => setState(() => isBookmarked = !isBookmarked),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.share, color: theme.colorScheme.onSurface),
            onPressed: () => _showShareModal(context, theme),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              eventData['heroImage'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.surface,
                child: Icon(Icons.image_not_supported,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventData['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          eventData['category'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width:
                            88, // Width for 5 overlapping circles: 24 + (4 * 16)
                        height: 24,
                        child: Stack(
                          children: List.generate(
                            5,
                            (index) => Positioned(
                              left: index * 16.0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        'https://i.pravatar.cc/50?img=${index + 1}'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () =>
                            context.push('/event/${widget.eventId}/attendees'),
                        child: Row(
                          children: [
                            Text(
                              '${eventData['attendeeCount']} going',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

    // Widget _buildCircleIcon(BuildContext context,
    //     {required IconData icon,
    //     Color? iconColor,
    //     required VoidCallback onTap,
    //     required ThemeData theme}) {
    //   final colorScheme = theme.colorScheme;
    //   return Container(
    //     margin: const EdgeInsets.all(8),
    //     decoration: BoxDecoration(
    //       color: colorScheme.surface.withValues(alpha: 0.9),
    //       borderRadius: BorderRadius.circular(12),
    //       boxShadow: [
    //         BoxShadow(
    //           color: colorScheme.shadow.withValues(alpha: 0.08),
    //           blurRadius: 8,
    //           offset: const Offset(0, 2),
    //         ),
    //       ],
    //     ),
    //     child: IconButton(
    //       icon: Icon(icon, color: iconColor ?? colorScheme.onSurface),
    //       onPressed: onTap,
    //       tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    //     ),
    //   );
    // }

    Widget _buildEventHeader(ThemeData theme) {
      final colorScheme = theme.colorScheme;
      final textTheme = theme.textTheme;
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventData['date'],
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eventData['time'],
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              eventData['price'],
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildOrganizerSection(ThemeData theme) {
      final organizer = eventData['organizer'];
      final colorScheme = theme.colorScheme;
      final textTheme = theme.textTheme;

      return GestureDetector(
        onTap: () => context.push('/organizer/world-of-music'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(organizer['avatar']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organizer['name'],
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      organizer['role'],
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => setState(() => isFollowing = !isFollowing),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing
                    ? colorScheme.surface
                    : colorScheme.primary,
                  foregroundColor: isFollowing
                    ? colorScheme.primary
                    : colorScheme.onPrimary,
                  side: isFollowing
                    ? BorderSide(color: colorScheme.primary)
                    : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                  padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  elevation: 0,
                ),
                child: Text(isFollowing ? 'Following' : 'Follow'),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildAboutSection(ThemeData theme) {
      final colorScheme = theme.colorScheme;
      final textTheme = theme.textTheme;
      final aboutText = eventData['about'] as String;

      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Event',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: isAboutExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                aboutText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              secondChild: Text(
                aboutText,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  setState(() => isAboutExpanded = !isAboutExpanded),
              child: Text(
                isAboutExpanded ? 'Show less' : 'Read more...',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildGallerySection(ThemeData theme) {
      final colorScheme = theme.colorScheme;
      final textTheme = theme.textTheme;
      final gallery = eventData['gallery'] as List<String>;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gallery (Pre-Event)',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Optionally show all images in a dialog
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            itemCount: gallery.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12),
                            itemBuilder: (context, index) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                gallery[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: gallery.length + 1,
                itemBuilder: (context, index) {
                  if (index < gallery.length) {
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: colorScheme.surface,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                gallery[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(gallery[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            Text(
                              '20+',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildLocationSection(ThemeData theme) {
      final colorScheme = theme.colorScheme;
      final textTheme = theme.textTheme;
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    eventData['location']['address'],
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: colorScheme.surface,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map,
                              color: colorScheme.onSurface.withOpacity(0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Map View (Coming Soon)',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundImage:
                              NetworkImage(eventData['organizer']['avatar']),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildBookEventButton(ThemeData theme) {
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;
      final buttonBg = isDark ? Colors.white : Colors.black;
      final buttonFg = isDark ? Colors.black : Colors.white;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            context.push('/checkout/${widget.eventId}/seat-selection');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonBg,
            foregroundColor: buttonFg,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 4,
            shadowColor: colorScheme.shadow.withOpacity(0.12),
          ),
          child: const Text(
            'Book Event',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

  void _showShareModal(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                _buildShareOption('WhatsApp', Icons.chat, Colors.green, theme),
                _buildShareOption('Twitter', Icons.alternate_email,
                    const Color(0xFF1DA1F2), theme),
                _buildShareOption(
                    'Facebook', Icons.facebook, const Color(0xFF1877F2), theme),
                _buildShareOption('Instagram', Icons.camera_alt,
                    const Color(0xFFE4405F), theme),
                _buildShareOption(
                    'Yahoo', Icons.email, const Color(0xFF6B46C1), theme),
                _buildShareOption(
                    'TikTok', Icons.music_note, Colors.black, theme),
                _buildShareOption(
                    'Chat', Icons.chat_bubble, const Color(0xFF007AFF), theme),
                _buildShareOption(
                    'WeChat', Icons.chat, const Color(0xFF07C160), theme),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
      String name, IconData icon, Color color, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        // Handle share
        Navigator.pop(context);
        HapticFeedback.lightImpact();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
