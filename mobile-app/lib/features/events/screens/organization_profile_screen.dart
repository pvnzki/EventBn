import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OrganizationProfileScreen extends StatefulWidget {
  final String organizationId;

  const OrganizationProfileScreen({super.key, required this.organizationId});

  @override
  State<OrganizationProfileScreen> createState() =>
      _OrganizationProfileScreenState();
}

class _OrganizationProfileScreenState extends State<OrganizationProfileScreen> with SingleTickerProviderStateMixin {

  // Small tile for event (used in grid)
  Widget _buildEventTile(Map<String, dynamic> event, ThemeData theme, {bool isPast = false}) {
    final image = (event['image'] ?? '').toString();
    final title = (event['title'] ?? '').toString();
    final date = (event['date'] ?? event['start_time'] ?? '').toString();
    final location = (event['location'] ?? '').toString();
    final attendees = (event['attendees'] ?? '0').toString();
    final price = (event['price'] ?? '').toString();
    final rating = (event['rating'] ?? '0').toString();
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  image,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: theme.colorScheme.surface,
                    child: Icon(
                      Icons.image_not_supported,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ),
                if (isPast)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: theme.colorScheme.secondary, size: 14),
                          const SizedBox(width: 2),
                          Text(rating, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 2),
                      Text(date, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 2),
                      Expanded(child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(isPast ? '$attendees attended' : '$attendees going', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(price, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  late TabController _tabController;
  bool isFollowing = false;

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  Map<String, dynamic>? organizationData;
  List<dynamic> upcomingEvents = [];
  List<dynamic> pastEvents = [];

  Future<void> fetchOrganizationData() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });
    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? '';
      final orgUrl = '$baseUrl/api/organizations/${widget.organizationId}';
      final eventsUrl = '$baseUrl/api/organizations/${widget.organizationId}/events';

      // Fetch organization info
      final orgResponse = await http.get(Uri.parse(orgUrl));
      // Fetch events
      final eventsResponse = await http.get(Uri.parse(eventsUrl));

      print('API Request: GET $orgUrl');
      print('Status Code: ${orgResponse.statusCode}');
      print('Response Body: ${orgResponse.body}');
      print('API Request: GET $eventsUrl');
      print('Status Code: ${eventsResponse.statusCode}');
      print('Response Body: ${eventsResponse.body}');

      if (orgResponse.statusCode == 200 && eventsResponse.statusCode == 200) {
        final orgData = json.decode(orgResponse.body);
        final eventsData = json.decode(eventsResponse.body);
        setState(() {
          organizationData = orgData;
          upcomingEvents = eventsData['upcomingEvents'] ?? [];
          pastEvents = eventsData['pastEvents'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage =
              'Failed to load organization data or events. Status: ${orgResponse.statusCode}, ${eventsResponse.statusCode}\nOrg Body: ${orgResponse.body}\nEvents Body: ${eventsResponse.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('API Error: $e');
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchOrganizationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Organization Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Organization Profile')),
        body: Center(child: Text('Error: $errorMessage')),
      );
    }
    if (organizationData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Organization Profile')),
        body: const Center(child: Text('No data found.')),
      );
    }

    // Use organizationData and event lists below
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pass organizationData to your widgets
                _buildProfileHeader(theme),
                _buildActionButtons(theme),
                _buildStatsRow(theme),
                _buildBio(theme),
                _buildTabBar(theme),
              ],
            ),
          ),
          _buildTabContent(theme),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 50,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.9),
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
            color: theme.colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
            onPressed: () => _showMoreOptions(context, theme),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                theme.colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final logoUrl = organizationData?['logo_url'] ?? '';
    final name = organizationData?['name'] ?? 'Unknown';
    final website = organizationData?['website_url'] ?? organizationData?['website'] ?? '';
    final contactEmail = organizationData?['contact_email'] ?? '';
    final joinDate = organizationData?['joinDate'] ?? '';
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurface.withOpacity(0.7);
    final accentColor = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
            child: logoUrl.isEmpty ? Icon(Icons.business, size: 40, color: secondaryTextColor) : null,
            backgroundColor: theme.colorScheme.surface,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (website.isNotEmpty)
                  Text(
                    website,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                if (contactEmail.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 16,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contactEmail,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                if (joinDate.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Joined $joinDate',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final accentColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;
    final onPrimary = theme.colorScheme.onPrimary;
    final onSurface = theme.colorScheme.onSurface;
    final borderColor = theme.colorScheme.outline.withOpacity(0.3);
    final followBg = isFollowing ? surfaceColor : accentColor;
    final followFg = isFollowing ? accentColor : onPrimary;
    final followBorder = isFollowing ? BorderSide(color: accentColor, width: 1) : BorderSide.none;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => isFollowing = !isFollowing),
              style: ElevatedButton.styleFrom(
                backgroundColor: followBg,
                foregroundColor: followFg,
                side: followBorder,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: followFg,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: () {
                // Message organizer
              },
              icon: Icon(
                Icons.message_outlined,
                color: onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    final eventsCount = organizationData?['events']?.toString() ?? '0';
    final followersCount = organizationData?['followers']?.toString() ?? '0';
    final followingCount = organizationData?['following']?.toString() ?? '0';
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Events', eventsCount, theme),
          _buildStatItem('Followers', followersCount, theme),
          _buildStatItem('Following', followingCount, theme),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor = theme.colorScheme.onSurface.withOpacity(0.7);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBio(ThemeData theme) {
    final bio = organizationData?['bio'] ?? '';
    final website = organizationData?['website_url'] ?? organizationData?['website'] ?? '';
    final joinDate = organizationData?['joinDate'] ?? '';
    final secondaryTextColor = theme.colorScheme.onSurface.withOpacity(0.7);
    final accentColor = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bio.isNotEmpty)
            Text(
              bio,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          if (website.isNotEmpty || joinDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (website.isNotEmpty) ...[
                    Icon(
                      Icons.link,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      website,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (website.isNotEmpty && joinDate.isNotEmpty)
                    const Spacer(),
                  if (joinDate.isNotEmpty)
                    Text(
                      'Joined $joinDate',
                      style: TextStyle(
                        color: secondaryTextColor,
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

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor:
            theme.colorScheme.onSurface.withValues(alpha: 0.6),
        indicator: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(25),
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Upcoming Events'),
          Tab(text: 'Past Events'),
        ],
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme) {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingEvents(theme),
          _buildPastEvents(theme),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: upcomingEvents.length,
      itemBuilder: (context, index) {
        final event = upcomingEvents[index];
        return _buildEventTile(event, theme);
      },
    );
  }

  Widget _buildPastEvents(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: pastEvents.length,
      itemBuilder: (context, index) {
        final event = pastEvents[index];
        return _buildEventTile(event, theme, isPast: true);
      },
    );
  }


  void _showMoreOptions(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 90),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.share, color: theme.colorScheme.onSurface),
              title: Text(
                'Share Profile',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.block, color: theme.colorScheme.error),
              title: Text(
                'Block Organizer',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.report, color: theme.colorScheme.error),
              title: Text(
                'Report',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
