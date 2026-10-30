import 'package:flutter/material.dart';

class CatScanResult {
  final bool isCat;
  final double confidence;
  final String breed;
  final String coatPattern;
  final String dominantColor;
  final double rarityMultiplier;
  final int basePoints;
  final int patternBonus;
  final int totalPawPoints;
  final String quirk;
  final Rect? boundingBox; // Normalized 0.0 - 1.0 (left, top, right, bottom)
  final String? rejectionReason;

  const CatScanResult({
    required this.isCat,
    this.confidence = 0.95,
    this.breed = 'Domestic Shorthair (Puspin)',
    this.coatPattern = 'Tabby',
    this.dominantColor = 'Orange Tabby',
    this.rarityMultiplier = 1.0,
    this.basePoints = 50,
    this.patternBonus = 15,
    this.totalPawPoints = 65,
    this.quirk = 'A friendly neighborhood feline lounging nearby.',
    this.boundingBox,
    this.rejectionReason,
  });

  factory CatScanResult.notACat([String reason = 'No feline detected in frame']) {
    return CatScanResult(
      isCat: false,
      confidence: 0.0,
      breed: 'Unknown',
      coatPattern: 'None',
      dominantColor: 'None',
      rarityMultiplier: 0.0,
      basePoints: 0,
      patternBonus: 0,
      totalPawPoints: 0,
      quirk: '',
      rejectionReason: reason,
    );
  }

  factory CatScanResult.fromJson(Map<String, dynamic> json) {
    final isCat = json['is_cat'] == true;
    if (!isCat) {
      return CatScanResult.notACat(
        json['reason']?.toString() ?? 'No feline detected in picture',
      );
    }

    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.95;
    final breed = json['breed']?.toString() ?? 'Domestic Shorthair (Puspin)';
    final coatPattern = json['coat_pattern']?.toString() ?? 'Tabby';
    final dominantColor = json['dominant_color']?.toString() ?? 'Mixed';
    final rarityMultiplier =
        (json['rarity_multiplier'] as num?)?.toDouble() ?? 1.0;
    const base = 50;
    final patternBonus = (json['pattern_bonus_pts'] as num?)?.toInt() ?? 15;
    final total = ((base + patternBonus) * rarityMultiplier).round();
    final quirk = json['quirk']?.toString() ?? 'Observing the surroundings.';

    Rect? box;
    if (json['box_2d'] is List && (json['box_2d'] as List).length == 4) {
      final list = json['box_2d'] as List;
      final ymin = (list[0] as num).toDouble() / 1000.0;
      final xmin = (list[1] as num).toDouble() / 1000.0;
      final ymax = (list[2] as num).toDouble() / 1000.0;
      final xmax = (list[3] as num).toDouble() / 1000.0;
      box = Rect.fromLTRB(
        xmin.clamp(0.0, 1.0),
        ymin.clamp(0.0, 1.0),
        xmax.clamp(0.0, 1.0),
        ymax.clamp(0.0, 1.0),
      );
    }

    return CatScanResult(
      isCat: true,
      confidence: confidence,
      breed: breed,
      coatPattern: coatPattern,
      dominantColor: dominantColor,
      rarityMultiplier: rarityMultiplier,
      basePoints: base,
      patternBonus: patternBonus,
      totalPawPoints: total,
      quirk: quirk,
      boundingBox: box,
    );
  }
}
