class VaultPhotoEntry {
  final String id;
  final String userId;
  final String sightingId;
  final String breedName;
  final String photoUrl;
  final int fileSizeBytes;
  final int resolutionWidth;
  final int resolutionHeight;
  final DateTime capturedAt;
  final bool isRawMaster;
  final int iso;
  final String shutterSpeed;
  final String aperture;
  final String locationLabel;

  const VaultPhotoEntry({
    required this.id,
    required this.userId,
    required this.sightingId,
    required this.breedName,
    required this.photoUrl,
    required this.fileSizeBytes,
    required this.resolutionWidth,
    required this.resolutionHeight,
    required this.capturedAt,
    this.isRawMaster = true,
    this.iso = 100,
    this.shutterSpeed = '1/250s',
    this.aperture = 'f/1.8',
    this.locationLabel = 'Bankal, Lapu-Lapu City',
  });

  String get fileSizeFormatted {
    if (fileSizeBytes >= 1048576) {
      final mb = fileSizeBytes / 1048576;
      return '${mb.toStringAsFixed(1)} MB';
    }
    if (fileSizeBytes >= 1024) {
      final kb = fileSizeBytes / 1024;
      return '${kb.toStringAsFixed(0)} KB';
    }
    return '$fileSizeBytes B';
  }

  String get resolutionFormatted => '$resolutionWidth x $resolutionHeight';

  String get megapixelFormatted {
    final mp = (resolutionWidth * resolutionHeight) / 1000000;
    return '${mp.toStringAsFixed(1)} MP';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'sightingId': sightingId,
      'breedName': breedName,
      'photoUrl': photoUrl,
      'fileSizeBytes': fileSizeBytes,
      'resolutionWidth': resolutionWidth,
      'resolutionHeight': resolutionHeight,
      'capturedAt': capturedAt.toIso8601String(),
      'isRawMaster': isRawMaster,
      'iso': iso,
      'shutterSpeed': shutterSpeed,
      'aperture': aperture,
      'locationLabel': locationLabel,
    };
  }

  factory VaultPhotoEntry.fromMap(Map<String, dynamic> map) {
    return VaultPhotoEntry(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      sightingId: map['sightingId'] as String? ?? '',
      breedName: map['breedName'] as String? ?? 'Domestic Shorthair',
      photoUrl: map['photoUrl'] as String? ?? '',
      fileSizeBytes: map['fileSizeBytes'] as int? ?? 120000,
      resolutionWidth: map['resolutionWidth'] as int? ?? 1920,
      resolutionHeight: map['resolutionHeight'] as int? ?? 1080,
      capturedAt: map['capturedAt'] != null
          ? DateTime.parse(map['capturedAt'] as String)
          : DateTime.now(),
      isRawMaster: map['isRawMaster'] as bool? ?? true,
      iso: map['iso'] as int? ?? 100,
      shutterSpeed: map['shutterSpeed'] as String? ?? '1/250s',
      aperture: map['aperture'] as String? ?? 'f/1.8',
      locationLabel: map['locationLabel'] as String? ?? 'Lapu-Lapu City',
    );
  }
}
