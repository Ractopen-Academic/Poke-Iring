class LiveSighting {
  final String id;
  final double latitude;
  final double longitude;
  final String breed;
  final String rarity;
  final double confidence;
  final String thumbnailUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  const LiveSighting({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.breed,
    required this.rarity,
    required this.confidence,
    this.thumbnailUrl = '',
    required this.createdAt,
    required this.expiresAt,
  });

  /// Total lifespan of a live sighting spawn.
  static const Duration totalLifespan = Duration(minutes: 15);

  /// Active sticker duration before fading into a silhouette.
  static const Duration stickerPhaseDuration = Duration(minutes: 10);

  /// Age since discovery.
  Duration get age => DateTime.now().difference(createdAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the spawn is in the 10-15 minute mystery silhouette phase.
  bool get isSilhouettePhase {
    final elapsed = age;
    return elapsed >= stickerPhaseDuration && !isExpired;
  }

  /// Visual opacity during the silhouette phase (fading from 1.0 down to 0.35).
  double get markerOpacity {
    if (!isSilhouettePhase) return 1.0;
    if (isExpired) return 0.0;
    final silhouetteElapsed = age - stickerPhaseDuration;
    final silhouetteWindow = totalLifespan - stickerPhaseDuration;
    final progress =
        (silhouetteElapsed.inMilliseconds / silhouetteWindow.inMilliseconds)
            .clamp(0.0, 1.0);
    return (1.0 - (progress * 0.65)).clamp(0.35, 1.0);
  }

  /// Metallic rarity tier: 'gold' (Mythic), 'silver' (Rare), 'bronze' (Common).
  String get metallicTier {
    final r = rarity.toLowerCase();
    if (r == 'mythic' || r == 'legendary') {
      return 'gold';
    } else if (r == 'rare' || r == 'uncommon' || r == 'very rare') {
      return 'silver';
    } else {
      return 'bronze';
    }
  }

  Duration get remainingTime {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get remainingFormatted {
    final duration = remainingTime;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'breed': breed,
      'rarity': rarity,
      'confidence': confidence,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory LiveSighting.fromMap(Map<String, dynamic> map, String docId) {
    final created = map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now();

    return LiveSighting(
      id: docId,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      breed: map['breed'] as String? ?? 'Domestic Shorthair',
      rarity: map['rarity'] as String? ?? 'Common',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.9,
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      createdAt: created,
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'].toString()) ??
                created.add(totalLifespan)
          : created.add(totalLifespan),
    );
  }
}
