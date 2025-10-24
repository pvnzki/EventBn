import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../events/models/event_model.dart';
import '../../events/services/event_service.dart';
import '../services/user_service.dart';

class OrganizerProfileScreen extends StatefulWidget {
  final String organizerId;

  const OrganizerProfileScreen({super.key, required this.organizerId});

  @override
  State<OrganizerProfileScreen> createState() => _OrganizerProfileScreenState();
}

class _OrganizerProfileScreenState extends State<OrganizerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventService _eventService = EventService();
  final UserService _userService = UserService();

  List<Event> _organizerEvents = [];
  bool _isLoadingEvents = false;
  bool _isLoadingUser = false;

  // Organizer data - will be fetched from API
  Map<String, dynamic>? organizerData;

  // Helper getters for safe access to organizerData
  String get organizerName => organizerData?['name'] ?? 'Unknown Organizer';
  String get organizerUsername => organizerData?['username'] ?? '@organizer';
  String? get organizerAvatar =>
      organizerData?['avatar'] ?? organizerData?['avatar_url'];
  String? get organizerCoverImage =>
      organizerData?['coverImage'] ?? organizerData?['cover_image'];
  String? get organizerBio =>
      organizerData?['bio'] ?? organizerData?['description'];
  String? get organizerLocation => organizerData?['location'];
  String? get organizerWebsite => organizerData?['website'];
  String get organizerJoinedDate =>
      organizerData?['joinedDate'] ??
      organizerData?['created_at'] ??
      'Recently';
  bool get organizerIsVerified =>
      organizerData?['isVerified'] ?? true; // Organizers are typically verified
  String get organizerEventsCount => _organizerEvents.length.toString();
  String get organizerFollowersCount =>
      organizerData?['followers']?.toString() ?? '0';
  String get organizerFollowingCount =>
      organizerData?['following']?.toString() ?? '0';

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // Only Events and About tabs
    _loadOrganizerData();
    _loadOrganizerEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizerData() async {
    setState(() => _isLoadingUser = true);

    try {
      print(
          '👨‍💼 [OrganizerProfile] Loading organizer data for ID: ${widget.organizerId}');

      // Fetch organizer data from the backend using UserService
      final fetchedUserData =
          await _userService.getUserById(widget.organizerId);

      if (fetchedUserData != null) {
        setState(() {
          organizerData = {
            'id': fetchedUserData['id'] ?? widget.organizerId,
            'name': fetchedUserData['name'] ??
                fetchedUserData['firstName'] ??
                'Unknown Organizer',
            'username': '@${fetchedUserData['username'] ?? 'organizer'}',
            'avatar': fetchedUserData['avatar'] ?? fetchedUserData['avatarUrl'],
            'cover_image':
                fetchedUserData['coverImage'] ?? fetchedUserData['cover_image'],
            'bio': fetchedUserData['bio'] ??
                fetchedUserData['description'] ??
                'Professional event organizer creating amazing experiences',
            'location': fetchedUserData['location'] ?? fetchedUserData['city'],
            'website':
                fetchedUserData['website'] ?? fetchedUserData['websiteUrl'],
            'created_at': fetchedUserData['createdAt'] ??
                fetchedUserData['created_at'] ??
                '2023-01-01',
            'isVerified': fetchedUserData['isVerified'] ?? true,
            'followers': fetchedUserData['followers'] ?? 0,
            'following': fetchedUserData['following'] ?? 0,
          };
          _isLoadingUser = false;
        });
      } else {
        // Fallback: Create organizer profile based on organization data
        // Check if this looks like a generated ID (large number from hash)
        final isGeneratedId = widget.organizerId.length > 8 &&
            RegExp(r'^\d+$').hasMatch(widget.organizerId);

        setState(() {
          organizerData = {
            'id': widget.organizerId,
            'name': isGeneratedId ? 'EventBn Productions' : 'Event Organizer',
            'username':
                '@${isGeneratedId ? 'eventbn_productions' : 'organizer'}',
            'avatar': null,
            'cover_image': null,
            'bio': isGeneratedId
                ? 'Professional event production company creating memorable experiences'
                : 'Professional event organizer creating amazing experiences',
            'location': 'Event City',
            'website': isGeneratedId
                ? 'www.eventbnproductions.com'
                : 'www.eventorganizer.com',
            'created_at': '2023-01-01',
            'isVerified': true,
            'followers': isGeneratedId ? 5240 : 1250,
            'following': isGeneratedId ? 892 : 324,
          };
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print('❌ [OrganizerProfile] Error loading organizer data: $e');
      setState(() {
        // Fallback to mock data on error
        organizerData = {
          'id': widget.organizerId,
          'name': 'Event Organizer',
          'username': '@organizer',
          'avatar': null,
          'cover_image': null,
          'bio': 'Professional event organizer creating amazing experiences',
          'location': 'Event City',
          'website': 'www.eventorganizer.com',
          'created_at': '2023-01-01',
          'isVerified': true,
          'followers': 1250,
          'following': 324,
        };
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _loadOrganizerEvents() async {
    setState(() => _isLoadingEvents = true);

    try {
      print(
          '🎪 [OrganizerProfile] Loading events for organizer ID: ${widget.organizerId}');

      // Fetch all events and filter by organizer
      final allEvents = await _eventService.getAllEvents();

      // Check if this is a generated ID (from organization name hash)
      final isGeneratedId = widget.organizerId.length > 8 &&
          RegExp(r'^\d+$').hasMatch(widget.organizerId);

      // Filter events by organizer ID
      final organizerEvents = allEvents.where((event) {
        // Check if the event's organizationId matches the organizer ID
        bool isOrganizerEvent = event.organizationId == widget.organizerId;

        if (!isOrganizerEvent && event.organization != null) {
          final org = event.organization!;

          // Check additional fields in organization data
          isOrganizerEvent =
              org['creator_id']?.toString() == widget.organizerId ||
                  org['user_id']?.toString() == widget.organizerId ||
                  org['organization_id']?.toString() == widget.organizerId;

          // If this is a generated ID, also check if the organization name matches
          if (!isOrganizerEvent && isGeneratedId && org['name'] != null) {
            final orgNameHash =
                org['name'].toString().hashCode.abs().toString();
            isOrganizerEvent = orgNameHash == widget.organizerId;

            if (isOrganizerEvent) {
              print(
                  '🎯 [OrganizerProfile] Matched event by organization name: ${org['name']}');
            }
          }
        }

        // Additional debug logging
        if (isOrganizerEvent) {
          print('✅ [OrganizerProfile] Event matched: ${event.title}');
        }

        return isOrganizerEvent;
      }).toList();

      print(
          '✅ [OrganizerProfile] Found ${organizerEvents.length} events for organizer');

      // Debug: Print details about all events for troubleshooting
      print('🔍 [OrganizerProfile] Debug - All events:');
      for (int i = 0; i < allEvents.length && i < 3; i++) {
        final event = allEvents[i];
        print('  Event ${i + 1}: ${event.title}');
        print('    organizationId: "${event.organizationId}"');
        print('    organization: ${event.organization}');
        if (event.organization != null && event.organization!['name'] != null) {
          final orgNameHash =
              event.organization!['name'].toString().hashCode.abs().toString();
          print('    organization name hash: $orgNameHash');
        }
      }

      setState(() {
        _organizerEvents = organizerEvents;
        _isLoadingEvents = false;
      });
    } catch (e) {
      print('❌ [OrganizerProfile] Error loading organizer events: $e');
      setState(() {
        _organizerEvents = [];
        _isLoadingEvents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(theme, colorScheme),
        ],
        body: Column(
          children: [
            _buildProfileHeader(theme, colorScheme),
            _buildTabBar(theme, colorScheme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventsTab(theme, colorScheme),
                  _buildAboutTab(theme, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onPressed: () => _showMoreOptions(context),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            organizerCoverImage != null
                ? CachedNetworkImage(
                    imageUrl: organizerCoverImage!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surfaceVariant,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.image_not_supported,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : Container(
                    color: colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.image_not_supported,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colorScheme.surface.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingUser) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: organizerAvatar != null
                    ? CachedNetworkImageProvider(organizerAvatar!)
                    : null,
                backgroundColor: colorScheme.surfaceVariant,
                child: organizerAvatar == null
                    ? Icon(
                        Icons.person,
                        size: 40,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            organizerName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ORGANIZER TAG
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ORGANIZER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (organizerIsVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      organizerUsername,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (organizerBio != null) ...[
            const SizedBox(height: 16),
            Text(
              organizerBio!,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ],
          if (organizerLocation != null || organizerWebsite != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (organizerLocation != null) ...[
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    organizerLocation!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (organizerLocation != null && organizerWebsite != null) ...[
                  const SizedBox(width: 16),
                ],
                if (organizerWebsite != null) ...[
                  Icon(
                    Icons.link,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    organizerWebsite!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Events', organizerEventsCount, colorScheme),
              const SizedBox(width: 24),
              _buildStatItem('Followers', organizerFollowersCount, colorScheme),
              const SizedBox(width: 24),
              _buildStatItem('Following', organizerFollowingCount, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: colorScheme.primary,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: 'Events'),
          Tab(text: 'About'),
        ],
      ),
    );
  }

  Widget _buildEventsTab(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingEvents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_organizerEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Events Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This organizer hasn\'t created any events yet.',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _organizerEvents.length,
        itemBuilder: (context, index) {
          final event = _organizerEvents[index];
          return _buildEventCard(event, theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildEventCard(
      Event event, ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        context.push('/event/${event.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: colorScheme.surfaceVariant,
                    child: Center(
                      child: Icon(
                        Icons.image,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.broken_image,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatEventDate(event.startDateTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
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
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.venue,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About ${organizerName}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (organizerBio != null) ...[
            Text(
              organizerBio!,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
          _buildInfoRow(
            Icons.calendar_today,
            'Joined',
            _formatJoinDate(organizerJoinedDate),
            colorScheme,
          ),
          if (organizerLocation != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on,
              'Location',
              organizerLocation!,
              colorScheme,
            ),
          ],
          if (organizerWebsite != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.link,
              'Website',
              organizerWebsite!,
              colorScheme,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.event,
            'Events Organized',
            organizerEventsCount,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _formatEventDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatJoinDate(String joinDate) {
    try {
      final date = DateTime.parse(joinDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return joinDate;
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text('Share Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      // Implement share functionality
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.report),
                    title: const Text('Report'),
                    onTap: () {
                      Navigator.pop(context);
                      // Implement report functionality
                    },
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
