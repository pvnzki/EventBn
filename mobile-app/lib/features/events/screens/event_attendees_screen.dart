import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/event_service.dart';

class EventAttendeesScreen extends StatefulWidget {
  final String eventId;

  const EventAttendeesScreen({super.key, required this.eventId});

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen> {
  String selectedTab = 'All';
  final List<String> tabs = ['All', 'Friends', 'Following'];
  final EventService _eventService = EventService();

  List<Map<String, dynamic>> attendees = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? _validateAvatarUrl(dynamic avatarUrl) {
    if (avatarUrl == null || avatarUrl.toString().isEmpty) return null;

    final url = avatarUrl.toString();
    try {
      final uri = Uri.parse(url);
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return url;
      }
    } catch (e) {
      print('⚠️ Invalid avatar URL: $url, error: $e');
    }
    return null;
  }

  // Fallback dummy data for when backend is unavailable
  final List<Map<String, dynamic>> _fallbackAttendees = [
    {
      'name': 'Leatrice Handler',
      'avatar': 'https://i.pravatar.cc/100?img=1',
      'isFollowing': false,
      'mutualFriends': 12,
      'isFriend': false,
    },
    {
      'name': 'Tanner Stafford',
      'avatar': 'https://i.pravatar.cc/100?img=2',
      'isFollowing': true,
      'mutualFriends': 8,
      'isFriend': true,
    },
    {
      'name': 'Chantal Shelburne',
      'avatar': 'https://i.pravatar.cc/100?img=3',
      'isFollowing': false,
      'mutualFriends': 5,
      'isFriend': false,
    },
    {
      'name': 'Maryland Winkles',
      'avatar': 'https://i.pravatar.cc/100?img=4',
      'isFollowing': true,
      'mutualFriends': 15,
      'isFriend': true,
    },
    {
      'name': 'Sanjuanita Ordonez',
      'avatar': 'https://i.pravatar.cc/100?img=5',
      'isFollowing': false,
      'mutualFriends': 3,
      'isFriend': false,
    },
    {
      'name': 'Alex Johnson',
      'avatar': 'https://i.pravatar.cc/100?img=6',
      'isFollowing': true,
      'mutualFriends': 20,
      'isFriend': true,
    },
    {
      'name': 'Sarah Williams',
      'avatar': 'https://i.pravatar.cc/100?img=7',
      'isFollowing': false,
      'mutualFriends': 7,
      'isFriend': false,
    },
    {
      'name': 'Michael Brown',
      'avatar': 'https://i.pravatar.cc/100?img=8',
      'isFollowing': true,
      'mutualFriends': 11,
      'isFriend': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAttendees();
  }

  Future<void> _loadAttendees() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print(
          '🔄 EventAttendeesScreen: Fetching attendees for event ${widget.eventId}');
      final result = await _eventService.getEventAttendees(widget.eventId);
      print('📦 EventAttendeesScreen: Received data: $result');

      // Process data outside of setState to avoid race conditions
      List<Map<String, dynamic>> newAttendees;

      if (result.isNotEmpty) {
        try {
          final transformedList = <Map<String, dynamic>>[];
          for (int i = 0; i < result.length; i++) {
            final attendee = result[i];
            if (attendee is Map) {
              final transformedAttendee = {
                'id': attendee['id']?.toString() ??
                    attendee['_id']?.toString() ??
                    '',
                'name':
                    attendee['username'] ?? attendee['name'] ?? 'Unknown User',
                'avatar': _validateAvatarUrl(
                    attendee['profilePicture'] ?? attendee['avatar']),
                'isFollowing': attendee['isFollowing'] ?? false,
                'isFriend': attendee['isFriend'] ?? false,
                'mutualFriends': attendee['mutualFriends'] ?? 0,
              };
              transformedList.add(transformedAttendee);
              print('✅ Transformed attendee $i: $transformedAttendee');
            } else {
              print('⚠️ Invalid attendee data at index $i: $attendee');
              transformedList.add({
                'id': '',
                'name': 'Unknown User',
                'avatar': '',
                'isFollowing': false,
                'isFriend': false,
                'mutualFriends': 0,
              });
            }
          }
          newAttendees = transformedList;
          print(
              '✅ EventAttendeesScreen: Successfully transformed ${newAttendees.length} attendees');
        } catch (e) {
          print('❌ Error transforming attendees: $e');
          newAttendees = List.from(_fallbackAttendees);
        }
      } else {
        print(
            '📦 EventAttendeesScreen: No attendees found, using fallback data');
        newAttendees = List.from(_fallbackAttendees);
      }

      // Atomic state update
      if (mounted) {
        setState(() {
          attendees = newAttendees;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading attendees: $e');
      setState(() {
        // Use fallback data when backend fails
        attendees = List.from(_fallbackAttendees);
        _isLoading = false;
        _errorMessage = 'Unable to load attendees. Showing sample data.';
      });
    }
  }

  List<Map<String, dynamic>> get filteredAttendees {
    // Ensure attendees list is not null and has valid data
    if (attendees.isEmpty) {
      print('🔍 filteredAttendees: Empty attendees list, returning empty');
      return <Map<String, dynamic>>[];
    }

    try {
      final filtered = switch (selectedTab) {
        'Friends' => attendees.where((a) => a['isFriend'] == true).toList(),
        'Following' =>
          attendees.where((a) => a['isFollowing'] == true).toList(),
        _ => List<Map<String, dynamic>>.from(attendees),
      };
      print(
          '🔍 filteredAttendees: ${filtered.length} items for tab: $selectedTab');
      return filtered;
    } catch (e) {
      print('❌ Error in filteredAttendees: $e');
      return <Map<String, dynamic>>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Event Attendees',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(theme),
          _buildTabBar(theme),
          Expanded(
            child: _buildAttendeesList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${attendees.length} Going',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'People attending this event',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Overlapping avatars
          SizedBox(
            width: 120,
            height: 40,
            child: Stack(
              children: List.generate(
                attendees.length > 5 ? 5 : attendees.length,
                (index) => Positioned(
                  left: index * 20.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                      image: attendees.isNotEmpty &&
                              index < attendees.length &&
                              attendees[index]['avatar'] != null
                          ? DecorationImage(
                              image: NetworkImage(attendees[index]['avatar']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: attendees.isEmpty ||
                            index >= attendees.length ||
                            attendees[index]['avatar'] == null
                        ? Icon(
                            Icons.person,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttendeesList(ThemeData theme) {
    // Show loading indicator
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error message if present
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAttendees,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (filteredAttendees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No attendees found',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to join this event!',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Show attendees list
    return RefreshIndicator(
      onRefresh: _loadAttendees,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 20),
        itemCount: filteredAttendees.length,
        itemBuilder: (context, index) {
          print(
              '🏗️ ListView.builder: index=$index, total=${filteredAttendees.length}');
          if (index >= filteredAttendees.length) {
            print(
                '❌ Index out of bounds: $index >= ${filteredAttendees.length}');
            return const SizedBox.shrink();
          }
          final attendee = filteredAttendees[index];
          return _buildAttendeeCard(attendee, theme);
        },
      ),
    );
  }

  Widget _buildAttendeeCard(Map<String, dynamic> attendee, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage:
                (attendee['avatar'] != null && attendee['avatar'].isNotEmpty)
                    ? NetworkImage(attendee['avatar'])
                    : null,
            child: (attendee['avatar'] == null || attendee['avatar'].isEmpty)
                ? Icon(
                    Icons.person,
                    size: 24,
                    color: theme.colorScheme.onPrimaryContainer,
                  )
                : null,
            onBackgroundImageError: (exception, stackTrace) => {},
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee['name'],
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${attendee['mutualFriends']} mutual friends',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(attendee, theme),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> attendee, ThemeData theme) {
    if (attendee['isFollowing']) {
      return ElevatedButton(
        onPressed: () {
          setState(() {
            attendee['isFollowing'] = false;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.primaryColor,
          side: BorderSide(color: theme.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
        ),
        child: const Text(
          'Following',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () {
          setState(() {
            attendee['isFollowing'] = true;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
        ),
        child: const Text(
          'Follow',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }
  }
}
