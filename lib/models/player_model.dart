class PlayerModel {
  final String id;
  final String name;
  final String username;
  final String bio;
  final String avatarUrl;
  final String? coverPhotoUrl;
  final List<String> sportTags;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final bool isVerified;
  final bool isFollowing;
  final bool isLive;
  final bool allowMessagesFromAll;

  PlayerModel({
    required this.id,
    required this.name,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    this.coverPhotoUrl,
    required this.sportTags,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
    required this.isVerified,
    required this.isFollowing,
    required this.isLive,
    this.allowMessagesFromAll = false,
  });

  PlayerModel copyWith({
    String? id,
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
    String? coverPhotoUrl,
    List<String>? sportTags,
    int? followerCount,
    int? followingCount,
    int? postCount,
    bool? isVerified,
    bool? isFollowing,
    bool? isLive,
    bool? allowMessagesFromAll,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      sportTags: sportTags ?? this.sportTags,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      isVerified: isVerified ?? this.isVerified,
      isFollowing: isFollowing ?? this.isFollowing,
      isLive: isLive ?? this.isLive,
      allowMessagesFromAll: allowMessagesFromAll ?? this.allowMessagesFromAll,
    );
  }
}

enum PostType { text, video, story }

class PostModel {
  final String id;
  final PlayerModel author;
  final PostType type;
  final String? text;
  final String? imageUrl;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final int? videoDurationSeconds;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final DateTime createdAt;
  final bool isLive;
  final bool isSaved;
  final String? sportTag;

  PostModel({
    required this.id,
    required this.author,
    required this.type,
    this.text,
    this.imageUrl,
    this.videoUrl,
    this.videoThumbnailUrl,
    this.videoDurationSeconds,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.createdAt,
    required this.isLive,
    required this.isSaved,
    this.sportTag,
  });
}
