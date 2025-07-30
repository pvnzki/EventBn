
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatelessWidget {
  SearchScreen({super.key});

  // Mock attendee posts data
  final List<Map<String, dynamic>> posts = [
    {
      'id': 'p1',
      'image': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400',
      'user': {
        'name': 'Alice',
        'avatar': 'https://i.pravatar.cc/100?img=1',
      },
      'event': {
        'id': '1',
        'title': 'International Band Music Concert',
      },
      'caption': 'Amazing vibes at the concert! 🎶',
      'likes': 120,
      'comments': 8,
    },
    {
      'id': 'p2',
      'image': 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?w=400',
      'user': {
        'name': 'Bob',
        'avatar': 'https://i.pravatar.cc/100?img=2',
      },
      'event': {
        'id': '2',
        'title': 'Summer Music Festival',
      },
      'caption': 'Festival fun with friends! ☀️',
      'likes': 98,
      'comments': 5,
    },
    {
      'id': 'p3',
      'image': 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?w=400',
      'user': {
        'name': 'Carol',
        'avatar': 'https://i.pravatar.cc/100?img=3',
      },
      'event': {
        'id': '3',
        'title': 'Jazz Night Live',
      },
      'caption': 'Jazz night was unforgettable! 🎷',
      'likes': 76,
      'comments': 3,
    },
    // Add more posts as needed
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Discover',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildPostCard(context, post, theme);
          },
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onTap: () {
        // Optionally show post details or open event
        context.push('/event/${post['event']['id']}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child: Image.network(
                post['image'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.image, color: colorScheme.onSurface.withOpacity(0.3)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(post['user']['avatar']),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post['user']['name'],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post['caption'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/event/${post['event']['id']}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            post['event']['title'],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.favorite, size: 16, color: Colors.pinkAccent),
                      const SizedBox(width: 4),
                      Text('${post['likes']}', style: theme.textTheme.labelSmall),
                      const SizedBox(width: 10),
                      Icon(Icons.comment, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${post['comments']}', style: theme.textTheme.labelSmall),
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
}
