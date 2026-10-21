class PublicProfileModel {
  final String id;
  final String username;
  final String displayName;
  final String? avatarPath;
  final String bio;
  final bool isVerified;
  final int streakCount;
  final int bestQuizScore;
  final DateTime? createdAt;
  final int capturesCount;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowedByMe;
  final bool isMyProfile;

  const PublicProfileModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarPath,
    required this.bio,
    required this.isVerified,
    required this.streakCount,
    required this.bestQuizScore,
    this.createdAt,
    required this.capturesCount,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowedByMe,
    required this.isMyProfile,
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'kolektor',
      displayName: json['display_name'] as String? ?? json['full_name'] as String? ?? 'Penjelajah Satwa',
      avatarPath: json['avatar_path'] as String? ?? json['avatar_url'] as String?,
      bio: json['bio'] as String? ?? '',
      isVerified: json['is_verified'] == true,
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      bestQuizScore: (json['best_quiz_score'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      capturesCount: (json['captures_count'] as num?)?.toInt() ?? 0,
      postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      isFollowedByMe: json['is_followed_by_me'] == true,
      isMyProfile: json['is_my_profile'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_path': avatarPath,
      'bio': bio,
      'is_verified': isVerified,
      'streak_count': streakCount,
      'best_quiz_score': bestQuizScore,
      'created_at': createdAt?.toIso8601String(),
      'captures_count': capturesCount,
      'posts_count': postsCount,
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_followed_by_me': isFollowedByMe,
      'is_my_profile': isMyProfile,
    };
  }

  PublicProfileModel copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarPath,
    String? bio,
    bool? isVerified,
    int? streakCount,
    int? bestQuizScore,
    DateTime? createdAt,
    int? capturesCount,
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isFollowedByMe,
    bool? isMyProfile,
  }) {
    return PublicProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      streakCount: streakCount ?? this.streakCount,
      bestQuizScore: bestQuizScore ?? this.bestQuizScore,
      createdAt: createdAt ?? this.createdAt,
      capturesCount: capturesCount ?? this.capturesCount,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      isMyProfile: isMyProfile ?? this.isMyProfile,
    );
  }
}
