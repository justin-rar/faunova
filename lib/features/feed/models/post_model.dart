// ==============================================================================
// FAUNOVA MODEL: PostModel
// Model data postingan linimasa publik komunitas satwa
// Sesuai Plan 5.7, 5.9, 18 & AGENTS.md (Sesi S9)
// Catatan Keras: Tidak pernah memuat koordinat tepat (hanya display_lat/lng dari grid server)
// ==============================================================================

class PostModel {
  final String id;
  final String captureId;
  final String caption;
  final String locationVisibility; // 'coarse' atau 'hidden'
  final double? displayLatitude;
  final double? displayLongitude;
  final String? areaLabel;
  final DateTime createdAt;

  // Metadata satwa dari captures
  final String speciesName;
  final String? category;
  final String photoUrl;
  final int blockSeq;
  final String blockHash;
  final String photoSha256;

  // Metadata akun pembuat (profiles)
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String? authorAvatar;
  final DateTime? authorVerifiedUntil;

  // Metrik sosial
  final int likesCount;
  final bool isLikedByMe;
  final DateTime? trashedAt;
  final DateTime? deletedAt;

  const PostModel({
    required this.id,
    required this.captureId,
    required this.caption,
    required this.locationVisibility,
    this.displayLatitude,
    this.displayLongitude,
    this.areaLabel,
    required this.createdAt,
    required this.speciesName,
    this.category,
    required this.photoUrl,
    required this.blockSeq,
    required this.blockHash,
    required this.photoSha256,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    this.authorAvatar,
    this.authorVerifiedUntil,
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.trashedAt,
    this.deletedAt,
  });

  bool get isTrashed => trashedAt != null;
  bool get isDeleted => deletedAt != null;

  bool get isAuthorVerified =>
      authorVerifiedUntil != null && authorVerifiedUntil!.isAfter(DateTime.now());

  bool get hasLocation =>
      locationVisibility == 'coarse' &&
      displayLatitude != null &&
      displayLongitude != null;

  String get shortBlockHash {
    if (blockHash.length < 10) return blockHash;
    return '${blockHash.substring(0, 6)}...${blockHash.substring(blockHash.length - 4)}';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  PostModel copyWith({
    String? id,
    String? captureId,
    String? caption,
    String? locationVisibility,
    double? displayLatitude,
    double? displayLongitude,
    String? areaLabel,
    DateTime? createdAt,
    String? speciesName,
    String? category,
    String? photoUrl,
    int? blockSeq,
    String? blockHash,
    String? photoSha256,
    String? authorId,
    String? authorName,
    String? authorUsername,
    String? authorAvatar,
    DateTime? authorVerifiedUntil,
    int? likesCount,
    bool? isLikedByMe,
    DateTime? trashedAt,
    bool clearTrashedAt = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return PostModel(
      id: id ?? this.id,
      captureId: captureId ?? this.captureId,
      caption: caption ?? this.caption,
      locationVisibility: locationVisibility ?? this.locationVisibility,
      displayLatitude: displayLatitude ?? this.displayLatitude,
      displayLongitude: displayLongitude ?? this.displayLongitude,
      areaLabel: areaLabel ?? this.areaLabel,
      createdAt: createdAt ?? this.createdAt,
      speciesName: speciesName ?? this.speciesName,
      category: category ?? this.category,
      photoUrl: photoUrl ?? this.photoUrl,
      blockSeq: blockSeq ?? this.blockSeq,
      blockHash: blockHash ?? this.blockHash,
      photoSha256: photoSha256 ?? this.photoSha256,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorVerifiedUntil: authorVerifiedUntil ?? this.authorVerifiedUntil,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      trashedAt: clearTrashedAt ? null : (trashedAt ?? this.trashedAt),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  /// Avatar fallback realistis untuk akun-akun dummy/komunitas resmi
  static String? getKnownDummyAvatar(String? username, [String? id]) {
    final u = (username ?? '').toLowerCase().trim();
    final i = (id ?? '').toLowerCase().trim();
    if (u.contains('wayan') || i.contains('wayan') || i == 'aa111111-1111-1111-1111-111111111111') {
      return 'https://images.unsplash.com/photo-1544168190-79c17527004f?w=200&auto=format&fit=crop&q=80';
    }
    if (u.contains('siti') || i.contains('siti') || i == 'bb222222-2222-2222-2222-222222222222') {
      return 'https://images.unsplash.com/photo-1589553009868-c7b2bb474531?w=200&auto=format&fit=crop&q=80';
    }
    if (u.contains('budi') || i.contains('budi') || i == 'cc333333-3333-3333-3333-333333333333') {
      return 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80';
    }
    if (u.contains('borneo') || u.contains('dedi') || i.contains('borneo') || i == 'dd444444-4444-4444-4444-444444444444') {
      return 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=200&auto=format&fit=crop&q=80';
    }
    if (u.contains('dewi') || i.contains('dewi') || i == 'ee555555-5555-5555-5555-555555555555') {
      return 'https://images.unsplash.com/photo-1534751516642-a1af1ef26a56?w=200&auto=format&fit=crop&q=80';
    }
    if (u.contains('faiz') || i.contains('faiz') || i == 'ff666666-6666-6666-6666-666666666666') {
      return 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80';
    }
    if (u.contains('bksda') || i.contains('bksda')) {
      return 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=200&auto=format&fit=crop&q=80';
    }
    if (u.contains('anindya') || i.contains('anindya')) {
      return 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&auto=format&fit=crop&q=80';
    }
    return null;
  }

  /// Memperbaiki foto satwa jika di database masih merujuk ke aset seed lama yang keliru
  static String resolvePostPhoto(String rawUrl, String speciesName) {
    final s = speciesName.toLowerCase();
    if (rawUrl.contains('photo-1544979590') || (s.contains('komodo') && rawUrl.contains('photo-1544979590-37e9b47eb705'))) {
      return 'https://images.unsplash.com/photo-1562578057-3ca1f7815237?w=900&auto=format&fit=crop&q=80';
    }
    if (rawUrl.contains('photo-1535083783855') || (s.contains('orangutan') && rawUrl.contains('photo-1535083783855-76ae62b2914e'))) {
      return 'https://images.unsplash.com/photo-1552656504-5fd2ed591222?w=900&auto=format&fit=crop&q=80';
    }
    if (rawUrl.contains('photo-1552728089') || (s.contains('jalak') && rawUrl.contains('photo-1552728089-57bdde30beb3'))) {
      return 'https://images.unsplash.com/photo-1521566652839-697aa473761a?w=900&auto=format&fit=crop&q=80';
    }
    if (rawUrl.contains('photo-1452570053594') || (s.contains('cenderawasih') && rawUrl.contains('photo-1452570053594-1b985d6ea890'))) {
      return 'https://images.unsplash.com/photo-1618098750285-9402745c67e7?w=900&auto=format&fit=crop&q=80';
    }
    if (rawUrl.contains('photo-1544551763') || (s.contains('penyu') && rawUrl.contains('photo-1544551763-46a013bb70d5'))) {
      return 'https://images.unsplash.com/photo-1437622368342-7a3d73a34c8f?w=900&auto=format&fit=crop&q=80';
    }
    return rawUrl;
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    double? parseCoord(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final species = json['species_name']?.toString() ?? 'Satwa Terverifikasi';
    final rawPhoto = json['photo_object_path']?.toString() ?? json['photo_url']?.toString() ?? '';
    final photo = resolvePostPhoto(rawPhoto, species);

    final authorUsername = json['author_username']?.toString() ?? 'penjelajah';
    final authorId = json['author_id']?.toString() ?? json['user_id']?.toString() ?? '';
    final rawAvatar = json['author_avatar']?.toString() ?? json['avatar_url']?.toString() ?? json['avatar_path']?.toString();
    final authorAvatar = (rawAvatar != null && rawAvatar.trim().isNotEmpty)
        ? rawAvatar
        : getKnownDummyAvatar(authorUsername, authorId);

    return PostModel(
      id: json['post_id']?.toString() ?? json['id']?.toString() ?? '',
      captureId: json['capture_id']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      locationVisibility: json['location_visibility']?.toString() ?? 'coarse',
      displayLatitude: parseCoord(json['display_latitude']),
      displayLongitude: parseCoord(json['display_longitude']),
      areaLabel: json['area_label']?.toString(),
      createdAt: parseDate(json['post_created_at'] ?? json['created_at']),
      speciesName: species,
      category: json['category']?.toString(),
      photoUrl: photo,
      blockSeq: json['block_seq'] is num
          ? (json['block_seq'] as num).toInt()
          : int.tryParse(json['block_seq']?.toString() ?? '1') ?? 1,
      blockHash: json['block_hash']?.toString() ?? '',
      photoSha256: json['photo_sha256']?.toString() ?? '',
      authorId: authorId,
      authorName: json['author_name']?.toString() ?? 'Penjelajah Fauna',
      authorUsername: authorUsername,
      authorAvatar: authorAvatar,
      authorVerifiedUntil: json['author_verified_until'] != null
          ? parseDate(json['author_verified_until'])
          : null,
      likesCount: json['likes_count'] is num
          ? (json['likes_count'] as num).toInt()
          : int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      isLikedByMe: json['is_liked_by_me'] == true,
      trashedAt: json['trashed_at'] != null ? parseDate(json['trashed_at']) : null,
      deletedAt: json['deleted_at'] != null ? parseDate(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': id,
      'capture_id': captureId,
      'caption': caption,
      'location_visibility': locationVisibility,
      'display_latitude': displayLatitude,
      'display_longitude': displayLongitude,
      'area_label': areaLabel,
      'created_at': createdAt.toIso8601String(),
      'post_created_at': createdAt.toIso8601String(),
      'species_name': speciesName,
      'category': category,
      'photo_object_path': photoUrl,
      'block_seq': blockSeq,
      'block_hash': blockHash,
      'photo_sha256': photoSha256,
      'author_id': authorId,
      'author_name': authorName,
      'author_username': authorUsername,
      'author_avatar': authorAvatar,
      'author_verified_until': authorVerifiedUntil?.toIso8601String(),
      'likes_count': likesCount,
      'is_liked_by_me': isLikedByMe,
      if (trashedAt != null) 'trashed_at': trashedAt!.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }
}
