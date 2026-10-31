import 'package:flutter/material.dart';

enum EventBorderRarity {
  rare,
  epic,
  legendary,
  mythic;

  String get displayName {
    switch (this) {
      case EventBorderRarity.rare:
        return 'Rare';
      case EventBorderRarity.epic:
        return 'Epic';
      case EventBorderRarity.legendary:
        return 'Legendary';
      case EventBorderRarity.mythic:
        return 'Mythic';
    }
  }

  Color get color {
    switch (this) {
      case EventBorderRarity.rare:
        return const Color(0xFF3B82F6);
      case EventBorderRarity.epic:
        return const Color(0xFF8B5CF6);
      case EventBorderRarity.legendary:
        return const Color(0xFFF59E0B);
      case EventBorderRarity.mythic:
        return const Color(0xFFEF4444);
    }
  }
}

class ProfileBorder {
  final String id;
  final String name;
  final String description;
  final EventBorderRarity rarity;
  final int cost;
  final List<int> gradientColors;
  final double strokeWidth;
  final int? glowColorValue;
  final double glowBlurRadius;
  final int? badgeIconCode;
  final bool isActive;

  const ProfileBorder({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.cost,
    required this.gradientColors,
    this.strokeWidth = 3.0,
    this.glowColorValue,
    this.glowBlurRadius = 6.0,
    this.badgeIconCode,
    this.isActive = true,
  });

  List<Color> get colors => gradientColors.map((c) => Color(c)).toList();

  Color? get glowColor =>
      glowColorValue != null ? Color(glowColorValue!) : null;

  LinearGradient get gradient => LinearGradient(
    colors: colors.length >= 2 ? colors : [colors.first, colors.first],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  ProfileBorder copyWith({
    String? id,
    String? name,
    String? description,
    EventBorderRarity? rarity,
    int? cost,
    List<int>? gradientColors,
    double? strokeWidth,
    int? glowColorValue,
    double? glowBlurRadius,
    int? badgeIconCode,
    bool? isActive,
  }) {
    return ProfileBorder(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      cost: cost ?? this.cost,
      gradientColors: gradientColors ?? this.gradientColors,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      glowColorValue: glowColorValue ?? this.glowColorValue,
      glowBlurRadius: glowBlurRadius ?? this.glowBlurRadius,
      badgeIconCode: badgeIconCode ?? this.badgeIconCode,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rarity': rarity.name,
      'cost': cost,
      'gradientColors': gradientColors,
      'strokeWidth': strokeWidth,
      'glowColorValue': glowColorValue,
      'glowBlurRadius': glowBlurRadius,
      'badgeIconCode': badgeIconCode,
      'isActive': isActive,
    };
  }

  factory ProfileBorder.fromMap(Map<String, dynamic> map) {
    return ProfileBorder(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Explorer Border',
      description: map['description'] as String? ?? '',
      rarity: EventBorderRarity.values.firstWhere(
        (r) => r.name == map['rarity'],
        orElse: () => EventBorderRarity.rare,
      ),
      cost: map['cost'] as int? ?? 100,
      gradientColors:
          (map['gradientColors'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [0xFF3B82F6, 0xFF60A5FA],
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      glowColorValue: (map['glowColorValue'] as num?)?.toInt(),
      glowBlurRadius: (map['glowBlurRadius'] as num?)?.toDouble() ?? 6.0,
      badgeIconCode: (map['badgeIconCode'] as num?)?.toInt(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  static List<ProfileBorder> defaultBorders() {
    return const [
      ProfileBorder(
        id: 'border_cherry_blossom',
        name: 'Cherry Blossom',
        description: 'Delicate spring petals and soft rose aura wrapping your explorer persona.',
        rarity: EventBorderRarity.rare,
        cost: 80,
        gradientColors: [0xFFF472B6, 0xFFFDA4AF],
        strokeWidth: 3.0,
        glowColorValue: 0x55F472B6,
        glowBlurRadius: 6.0,
      ),
      ProfileBorder(
        id: 'border_neon_pulse',
        name: 'Neon Pulse',
        description: 'Electric cyan and deep azure streams radiating high-energy exploration vibes.',
        rarity: EventBorderRarity.epic,
        cost: 150,
        gradientColors: [0xFF06B6D4, 0xFF3B82F6],
        strokeWidth: 3.2,
        glowColorValue: 0x6606B6D4,
        glowBlurRadius: 8.0,
      ),
      ProfileBorder(
        id: 'border_cyber_grid',
        name: 'Emerald Circuit',
        description: 'Luminescent cybernetic green contours forged for precision feline cartographers.',
        rarity: EventBorderRarity.epic,
        cost: 180,
        gradientColors: [0xFF10B981, 0xFF34D399],
        strokeWidth: 3.2,
        glowColorValue: 0x6610B981,
        glowBlurRadius: 8.0,
      ),
      ProfileBorder(
        id: 'border_golden_aureole',
        name: 'Golden Aureole',
        description: 'Radiant amber halo reflecting sun-warmed cat naps and champion territory conquests.',
        rarity: EventBorderRarity.legendary,
        cost: 260,
        gradientColors: [0xFFF59E0B, 0xFFFCD34D],
        strokeWidth: 3.5,
        glowColorValue: 0x77F59E0B,
        glowBlurRadius: 10.0,
      ),
      ProfileBorder(
        id: 'border_celestial_star',
        name: 'Celestial Dusk',
        description: 'Deep twilight indigo laced with sparkling cosmic violet for night prowlers.',
        rarity: EventBorderRarity.legendary,
        cost: 300,
        gradientColors: [0xFF6366F1, 0xFFA855F7],
        strokeWidth: 3.5,
        glowColorValue: 0x776366F1,
        glowBlurRadius: 10.0,
      ),
      ProfileBorder(
        id: 'border_mythic_dragon',
        name: 'Mythic Ember',
        description: 'Fiery crimson dragon flames and molten magma glow honoring apex stray protectors.',
        rarity: EventBorderRarity.mythic,
        cost: 450,
        gradientColors: [0xFFDC2626, 0xFFF97316],
        strokeWidth: 4.0,
        glowColorValue: 0x88DC2626,
        glowBlurRadius: 12.0,
      ),
    ];
  }
}
