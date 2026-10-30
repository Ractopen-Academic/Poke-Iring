class IringStory {
  final String id;
  final String userId;
  final String authorName;
  final String authorAvatarUrl;
  final String mediaUrl;
  final String caption;
  final String catBreed;
  final String locationTag;
  final int boopsCount;
  final List<String> boopedBy;
  final List<String> viewedBy;
  final DateTime createdAt;
  final DateTime expiresAt;

  const IringStory({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl = '',
    required this.mediaUrl,
    required this.caption,
    required this.catBreed,
    this.locationTag = 'Bankal, Lapu-Lapu City',
    this.boopsCount = 0,
    this.boopedBy = const [],
    this.viewedBy = const [],
    required this.createdAt,
    required this.expiresAt,
  });

  bool isViewedBy(String currentUserId) => viewedBy.contains(currentUserId);
  bool isBoopedBy(String currentUserId) => boopedBy.contains(currentUserId);
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  IringStory copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? authorAvatarUrl,
    String? mediaUrl,
    String? caption,
    String? catBreed,
    String? locationTag,
    int? boopsCount,
    List<String>? boopedBy,
    List<String>? viewedBy,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return IringStory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      caption: caption ?? this.caption,
      catBreed: catBreed ?? this.catBreed,
      locationTag: locationTag ?? this.locationTag,
      boopsCount: boopsCount ?? this.boopsCount,
      boopedBy: boopedBy ?? this.boopedBy,
      viewedBy: viewedBy ?? this.viewedBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'catBreed': catBreed,
      'locationTag': locationTag,
      'boopsCount': boopsCount,
      'boopedBy': boopedBy,
      'viewedBy': viewedBy,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory IringStory.fromMap(Map<String, dynamic> map) {
    return IringStory(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? 'Explorer',
      authorAvatarUrl: map['authorAvatarUrl']?.toString() ?? '',
      mediaUrl: map['mediaUrl']?.toString() ?? '',
      caption: map['caption']?.toString() ?? '',
      catBreed: map['catBreed']?.toString() ?? 'Domestic Shorthair (Puspin)',
      locationTag: map['locationTag']?.toString() ?? 'Bankal, Lapu-Lapu City',
      boopsCount: (map['boopsCount'] as num?)?.toInt() ?? 0,
      boopedBy: (map['boopedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      viewedBy: (map['viewedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? (DateTime.tryParse(map['expiresAt'].toString()) ??
              DateTime.now().add(const Duration(hours: 24)))
          : DateTime.now().add(const Duration(hours: 24)),
    );
  }
}
