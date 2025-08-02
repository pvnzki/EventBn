enum PostType {
  eventInterest,
  eventReview,
  eventMoment,
  eventPromotion,
  eventQuestion,
  eventMemory
}

enum PostCategory {
  all,
  music,
  sports,
  tech,
  food,
  art,
  business,
  education,
  entertainment,
  lifestyle
}

class ExplorePost {
  final String id;
  final String userId;
  final String userDisplayName;
  final String userAvatarUrl;
  final bool isUserVerified;
  final String content;
  final List<String> imageUrls;
  final PostType postType;
  final PostCategory category;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final bool isBookmarked;

  // Event connection
  final String? relatedEventId;
  final String? relatedEventName;
  final String? relatedEventImage;
  final DateTime? relatedEventDate;
  final String? relatedEventLocation;

  // Post engagement
  final List<String> tags;
  final String? location;
  final bool allowComments;
  final bool isSponsored;

  const ExplorePost({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.userAvatarUrl,
    this.isUserVerified = false,
    required this.content,
    required this.imageUrls,
    required this.postType,
    required this.category,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.relatedEventId,
    this.relatedEventName,
    this.relatedEventImage,
    this.relatedEventDate,
    this.relatedEventLocation,
    this.tags = const [],
    this.location,
    this.allowComments = true,
    this.isSponsored = false,
  });

  ExplorePost copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userAvatarUrl,
    bool? isUserVerified,
    String? content,
    List<String>? imageUrls,
    PostType? postType,
    PostCategory? category,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    bool? isBookmarked,
    String? relatedEventId,
    String? relatedEventName,
    String? relatedEventImage,
    DateTime? relatedEventDate,
    String? relatedEventLocation,
    List<String>? tags,
    String? location,
    bool? allowComments,
    bool? isSponsored,
  }) {
    return ExplorePost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      isUserVerified: isUserVerified ?? this.isUserVerified,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      postType: postType ?? this.postType,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      relatedEventId: relatedEventId ?? this.relatedEventId,
      relatedEventName: relatedEventName ?? this.relatedEventName,
      relatedEventImage: relatedEventImage ?? this.relatedEventImage,
      relatedEventDate: relatedEventDate ?? this.relatedEventDate,
      relatedEventLocation: relatedEventLocation ?? this.relatedEventLocation,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      allowComments: allowComments ?? this.allowComments,
      isSponsored: isSponsored ?? this.isSponsored,
    );
  }

  factory ExplorePost.fromJson(Map<String, dynamic> json) {
    return ExplorePost(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String,
      isUserVerified: json['isUserVerified'] as bool? ?? false,
      content: json['content'] as String,
      imageUrls: List<String>.from(json['imageUrls'] as List),
      postType: PostType.values.firstWhere(
        (e) => e.toString() == 'PostType.${json['postType']}',
        orElse: () => PostType.eventInterest,
      ),
      category: PostCategory.values.firstWhere(
        (e) => e.toString() == 'PostCategory.${json['category']}',
        orElse: () => PostCategory.all,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      sharesCount: json['sharesCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      relatedEventId: json['relatedEventId'] as String?,
      relatedEventName: json['relatedEventName'] as String?,
      relatedEventImage: json['relatedEventImage'] as String?,
      relatedEventDate: json['relatedEventDate'] != null
          ? DateTime.parse(json['relatedEventDate'] as String)
          : null,
      relatedEventLocation: json['relatedEventLocation'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      location: json['location'] as String?,
      allowComments: json['allowComments'] as bool? ?? true,
      isSponsored: json['isSponsored'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userAvatarUrl': userAvatarUrl,
      'isUserVerified': isUserVerified,
      'content': content,
      'imageUrls': imageUrls,
      'postType': postType.toString().split('.').last,
      'category': category.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      'relatedEventId': relatedEventId,
      'relatedEventName': relatedEventName,
      'relatedEventImage': relatedEventImage,
      'relatedEventDate': relatedEventDate?.toIso8601String(),
      'relatedEventLocation': relatedEventLocation,
      'tags': tags,
      'location': location,
      'allowComments': allowComments,
      'isSponsored': isSponsored,
    };
  }

  String get postTypeDisplayName {
    switch (postType) {
      case PostType.eventInterest:
        return 'Interested';
      case PostType.eventReview:
        return 'Review';
      case PostType.eventMoment:
        return 'Moment';
      case PostType.eventPromotion:
        return 'Promotion';
      case PostType.eventQuestion:
        return 'Question';
      case PostType.eventMemory:
        return 'Memory';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
