import '../models/post_model.dart';

class ExplorePostService {
  static final ExplorePostService _instance = ExplorePostService._internal();
  factory ExplorePostService() => _instance;
  ExplorePostService._internal();

  final List<ExplorePost> _allPosts = [];
  final List<ExplorePost> _filteredPosts = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 0;

  List<ExplorePost> get posts => _filteredPosts;
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;

  Future<void> loadPosts({
    String? searchQuery,
    PostCategory? category,
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;

    if (refresh || _allPosts.isEmpty) {
      _currentPage = 0;
      _hasMoreData = true;
      _allPosts.clear();
      _filteredPosts.clear();
      _generateMockPosts();
    }

    await Future.delayed(const Duration(milliseconds: 800));

    _applyFilters(searchQuery: searchQuery, category: category);
    _isLoading = false;
  }

  Future<void> loadMorePosts({
    String? searchQuery,
    PostCategory? category,
  }) async {
    if (_isLoading || !_hasMoreData) return;

    _isLoading = true;
    _currentPage++;

    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentPage >= 3) {
      _hasMoreData = false;
    } else {
      _generateMoreMockPosts();
      _applyFilters(searchQuery: searchQuery, category: category);
    }

    _isLoading = false;
  }

  void _applyFilters({
    String? searchQuery,
    PostCategory? category,
  }) {
    List<ExplorePost> filtered = List.from(_allPosts);

    if (category != null && category != PostCategory.all) {
      filtered = filtered.where((post) => post.category == category).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered
          .where((post) =>
              post.content.toLowerCase().contains(searchQuery.toLowerCase()) ||
              post.userDisplayName
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              post.relatedEventName
                      ?.toLowerCase()
                      .contains(searchQuery.toLowerCase()) ==
                  true ||
              post.tags.any((tag) =>
                  tag.toLowerCase().contains(searchQuery.toLowerCase())))
          .toList();
    }

    _filteredPosts.clear();
    _filteredPosts.addAll(filtered);
  }

  Future<void> toggleLike(String postId) async {
    final index = _filteredPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final post = _filteredPosts[index];
      _filteredPosts[index] = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    }
  }

  Future<void> toggleBookmark(String postId) async {
    final index = _filteredPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final post = _filteredPosts[index];
      _filteredPosts[index] = post.copyWith(
        isBookmarked: !post.isBookmarked,
      );
    }
  }

  void _generateMockPosts() {
    final mockPosts = [
      ExplorePost(
        id: '1',
        userId: 'user1',
        userDisplayName: 'Sarah Chen',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1494790108755-2616b612b495?w=100',
        isUserVerified: true,
        content:
            'Just got my tickets for the Summer Music Festival! 🎵 Who else is going? This lineup is absolutely incredible - can\'t wait to dance under the stars! #SummerVibes #MusicFestival',
        imageUrls: [
          'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800'
        ],
        postType: PostType.eventInterest,
        category: PostCategory.music,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likesCount: 127,
        commentsCount: 23,
        sharesCount: 8,
        relatedEventId: 'event1',
        relatedEventName: 'Summer Music Festival 2024',
        relatedEventImage:
            'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=400',
        relatedEventDate: DateTime.now().add(const Duration(days: 15)),
        relatedEventLocation: 'Central Park, NYC',
        tags: ['#SummerVibes', '#MusicFestival', '#NYC'],
        location: 'New York, NY',
      ),
      ExplorePost(
        id: '2',
        userId: 'user2',
        userDisplayName: 'Alex Rodriguez',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        content:
            'Mind = blown 🤯 The Tech Innovation Summit yesterday was absolutely incredible! The AI demonstrations were next level. Special thanks to @TechSummit for organizing such an amazing event!',
        imageUrls: [
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
          'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800'
        ],
        postType: PostType.eventReview,
        category: PostCategory.tech,
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
        likesCount: 89,
        commentsCount: 12,
        sharesCount: 15,
        relatedEventId: 'event2',
        relatedEventName: 'Tech Innovation Summit',
        relatedEventImage:
            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400',
        relatedEventLocation: 'Silicon Valley, CA',
        tags: ['#TechSummit', '#AI', '#Innovation'],
        location: 'Silicon Valley, CA',
      ),
      ExplorePost(
        id: '3',
        userId: 'user3',
        userDisplayName: 'Emma Thompson',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
        isUserVerified: true,
        content:
            'Question for my foodie friends: Has anyone been to the Food & Wine Tasting in Napa? Thinking of booking but want to hear some reviews first! 🍷🍽️',
        imageUrls: [],
        postType: PostType.eventQuestion,
        category: PostCategory.food,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        likesCount: 34,
        commentsCount: 18,
        sharesCount: 2,
        relatedEventId: 'event3',
        relatedEventName: 'Food & Wine Tasting',
        relatedEventLocation: 'Napa Valley, CA',
        tags: ['#NapaValley', '#Wine', '#Foodie'],
      ),
      ExplorePost(
        id: '4',
        userId: 'user4',
        userDisplayName: 'Marcus Johnson',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
        content:
            'The Modern Art Exhibition at MoMA was absolutely breathtaking! 🎨 Each piece told such a powerful story. If you\'re in NYC, you HAVE to check this out before it ends!',
        imageUrls: [
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800',
          'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800'
        ],
        postType: PostType.eventMoment,
        category: PostCategory.art,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        likesCount: 156,
        commentsCount: 29,
        sharesCount: 12,
        relatedEventId: 'event4',
        relatedEventName: 'Modern Art Exhibition',
        relatedEventLocation: 'MoMA, NYC',
        tags: ['#MoMA', '#ModernArt', '#NYC'],
        location: 'New York, NY',
      ),
      ExplorePost(
        id: '5',
        userId: 'user5',
        userDisplayName: 'Jessica Kim',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
        isUserVerified: true,
        content:
            'Game day energy is REAL! 🏀 Madison Square Garden is electric tonight for the Basketball Championship. Best seats I\'ve ever had!',
        imageUrls: [
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800'
        ],
        postType: PostType.eventMoment,
        category: PostCategory.sports,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        likesCount: 203,
        commentsCount: 45,
        sharesCount: 18,
        isLiked: true,
        relatedEventId: 'event5',
        relatedEventName: 'Basketball Championship',
        relatedEventLocation: 'Madison Square Garden',
        tags: ['#Basketball', '#MSG', '#Championship'],
        location: 'New York, NY',
      ),
      ExplorePost(
        id: '6',
        userId: 'user6',
        userDisplayName: 'David Park',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
        content:
            'Great networking session today! 💼 Met some incredible entrepreneurs and investors. The startup ecosystem is thriving! Big thanks to everyone who attended.',
        imageUrls: [
          'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=800'
        ],
        postType: PostType.eventReview,
        category: PostCategory.business,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        likesCount: 67,
        commentsCount: 11,
        sharesCount: 6,
        relatedEventId: 'event6',
        relatedEventName: 'Business Networking',
        relatedEventLocation: 'Downtown Conference Center',
        tags: ['#Networking', '#Startup', '#Business'],
      ),
      ExplorePost(
        id: '7',
        userId: 'user7',
        userDisplayName: 'Dr. Lisa Wang',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=100',
        isUserVerified: true,
        content:
            'Excited to announce I\'ll be speaking at the AI & Machine Learning Workshop at Stanford! 🤖 We\'ll be covering the latest in neural networks and practical applications. Limited spots available!',
        imageUrls: [
          'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800'
        ],
        postType: PostType.eventPromotion,
        category: PostCategory.education,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        likesCount: 94,
        commentsCount: 16,
        sharesCount: 22,
        relatedEventId: 'event7',
        relatedEventName: 'AI & Machine Learning Workshop',
        relatedEventLocation: 'Stanford University',
        tags: ['#AI', '#MachineLearning', '#Stanford'],
        isSponsored: true,
      ),
      ExplorePost(
        id: '8',
        userId: 'user8',
        userDisplayName: 'Carlos Martinez',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1507591064344-4c6ce005b128?w=100',
        content:
            'Last night\'s Jazz performance at Blue Note was pure magic ✨🎷 The atmosphere, the music, the crowd... everything was perfect. Already planning my next visit!',
        imageUrls: [
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800'
        ],
        postType: PostType.eventMemory,
        category: PostCategory.music,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        likesCount: 78,
        commentsCount: 13,
        sharesCount: 7,
        relatedEventId: 'event8',
        relatedEventName: 'Jazz Night Live',
        relatedEventLocation: 'Blue Note Club',
        tags: ['#Jazz', '#BlueNote', '#LiveMusic'],
      ),
      ExplorePost(
        id: '9',
        userId: 'user9',
        userDisplayName: 'Rachel Green',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100',
        content:
            'Training for my first marathon! 🏃‍♀️ The Marathon Training Camp in Golden Gate Park has been incredible. Free coaching and such a supportive community!',
        imageUrls: [
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800'
        ],
        postType: PostType.eventInterest,
        category: PostCategory.sports,
        createdAt: DateTime.now().subtract(const Duration(hours: 20)),
        likesCount: 112,
        commentsCount: 25,
        sharesCount: 9,
        relatedEventId: 'event9',
        relatedEventName: 'Marathon Training Camp',
        relatedEventLocation: 'Golden Gate Park',
        tags: ['#Marathon', '#Running', '#GoldenGate'],
        location: 'San Francisco, CA',
      ),
      ExplorePost(
        id: '10',
        userId: 'user10',
        userDisplayName: 'Mike Chen',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=100',
        content:
            'The Street Food Festival in Times Square is happening NOW! 🌮🍕 So many amazing vendors and the energy is incredible. Come hungry!',
        imageUrls: [
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800',
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800'
        ],
        postType: PostType.eventMoment,
        category: PostCategory.food,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        likesCount: 89,
        commentsCount: 34,
        sharesCount: 15,
        relatedEventId: 'event10',
        relatedEventName: 'Street Food Festival',
        relatedEventLocation: 'Times Square',
        tags: ['#StreetFood', '#TimesSquare', '#NYC'],
        location: 'New York, NY',
      ),
    ];

    _allPosts.addAll(mockPosts);
  }

  void _generateMoreMockPosts() {
    final additionalPosts = [
      ExplorePost(
        id: '${_allPosts.length + 1}',
        userId: 'user11',
        userDisplayName: 'Anna Williams',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=100',
        content:
            'Photography workshop was amazing! 📸 Learned so much about composition and lighting. Thanks to all the fellow photographers who shared their tips!',
        imageUrls: [
          'https://images.unsplash.com/photo-1452587925148-ce544e77e70d?w=800'
        ],
        postType: PostType.eventReview,
        category: PostCategory.art,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        likesCount: 45,
        commentsCount: 8,
        sharesCount: 4,
        tags: ['#Photography', '#Workshop', '#Brooklyn'],
      ),
      ExplorePost(
        id: '${_allPosts.length + 2}',
        userId: 'user12',
        userDisplayName: 'James Thompson',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100',
        content:
            'Pitch night was intense! 🚀 So many innovative startups presenting. The future of tech looks bright. Congrats to all the winners!',
        imageUrls: [
          'https://images.unsplash.com/photo-1559223607-a43c990c692c?w=800'
        ],
        postType: PostType.eventReview,
        category: PostCategory.business,
        createdAt: DateTime.now().subtract(const Duration(hours: 15)),
        likesCount: 67,
        commentsCount: 12,
        sharesCount: 8,
        tags: ['#Startup', '#Pitch', '#Innovation'],
      ),
    ];

    _allPosts.addAll(additionalPosts);
  }
}
