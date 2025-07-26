import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventAttendeesScreen extends StatefulWidget {
  final String eventId;

  const EventAttendeesScreen({super.key, required this.eventId});

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen> {
  String selectedTab = 'All';
  final List<String> tabs = ['All', 'Friends', 'Following'];

  final List<Map<String, dynamic>> attendees = [
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

  List<Map<String, dynamic>> get filteredAttendees {
    switch (selectedTab) {
      case 'Friends':
        return attendees.where((a) => a['isFriend'] == true).toList();
      case 'Following':
        return attendees.where((a) => a['isFollowing'] == true).toList();
      default:
        return attendees;
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
                5,
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
                      image: DecorationImage(
                        image: NetworkImage(attendees[index]['avatar']),
                        fit: BoxFit.cover,
                      ),
                    ),
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
    return ListView.builder(
      padding: const EdgeInsets.only(top: 20),
      itemCount: filteredAttendees.length,
      itemBuilder: (context, index) {
        final attendee = filteredAttendees[index];
        return _buildAttendeeCard(attendee, theme);
      },
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
            backgroundImage: NetworkImage(attendee['avatar']),
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
