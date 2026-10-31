import 'package:flutter/material.dart';

import 'profile_border.dart';

class EventQuestItem {
  final String id;
  final String title;
  final String description;
  final int rewardCoins;
  final double targetValue;
  final String type;
  final String? targetBreed;

  const EventQuestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardCoins,
    required this.targetValue,
    required this.type,
    this.targetBreed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewardCoins': rewardCoins,
      'targetValue': targetValue,
      'type': type,
      'targetBreed': targetBreed,
    };
  }

  factory EventQuestItem.fromMap(Map<String, dynamic> map) {
    return EventQuestItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Event Mission',
      description: map['description'] as String? ?? '',
      rewardCoins: map['rewardCoins'] as int? ?? 50,
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 1.0,
      type: map['type'] as String? ?? 'steps',
      targetBreed: map['targetBreed'] as String?,
    );
  }
}

class FelineEvent {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String currencyName;
  final String currencyCode;
  final DateTime startDate;
  final DateTime endDate;
  final int bannerColorValue;
  final int accentColorValue;
  final List<EventQuestItem> quests;
  final List<ProfileBorder> borders;

  const FelineEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.currencyName,
    required this.currencyCode,
    required this.startDate,
    required this.endDate,
    required this.bannerColorValue,
    required this.accentColorValue,
    required this.quests,
    required this.borders,
  });

  Color get bannerColor => Color(bannerColorValue);
  Color get accentColor => Color(accentColorValue);

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isActive => !isExpired && !isUpcoming;

  String get remainingFormatted {
    final now = DateTime.now();
    if (now.isAfter(endDate)) {
      return 'Concluded';
    }
    final diff = endDate.difference(now);
    if (diff.inDays > 0) {
      final hours = diff.inHours % 24;
      return '${diff.inDays}d ${hours}h left';
    }
    if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      return '${diff.inHours}h ${mins}m left';
    }
    return '${diff.inMinutes}m left';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'currencyName': currencyName,
      'currencyCode': currencyCode,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'bannerColorValue': bannerColorValue,
      'accentColorValue': accentColorValue,
      'quests': quests.map((q) => q.toMap()).toList(),
      'borders': borders.map((b) => b.toMap()).toList(),
    };
  }

  factory FelineEvent.fromMap(Map<String, dynamic> map) {
    return FelineEvent(
      id: map['id'] as String? ?? 'event_default',
      title: map['title'] as String? ?? 'Moonlit Strays Gala',
      subtitle: map['subtitle'] as String? ?? 'Limited-Time Festival',
      description: map['description'] as String? ?? '',
      currencyName: map['currencyName'] as String? ?? 'Moonlit Tokens',
      currencyCode: map['currencyCode'] as String? ?? 'MLT',
      startDate:
          DateTime.tryParse(map['startDate'] as String? ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(map['endDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 14)),
      bannerColorValue: map['bannerColorValue'] as int? ?? 0xFF6D28D9,
      accentColorValue: map['accentColorValue'] as int? ?? 0xFFF59E0B,
      quests:
          (map['quests'] as List<dynamic>?)
              ?.map((q) => EventQuestItem.fromMap(q as Map<String, dynamic>))
              .toList() ??
          const [],
      borders:
          (map['borders'] as List<dynamic>?)
              ?.map((b) => ProfileBorder.fromMap(b as Map<String, dynamic>))
              .toList() ??
          ProfileBorder.defaultBorders(),
    );
  }

  static FelineEvent defaultFestival() {
    final now = DateTime.now();
    return FelineEvent(
      id: 'event_moonlit_strays_2026',
      title: 'Moonlit Strays Festival',
      subtitle: 'Exclusive Seasonal Gathering',
      description: 'Stroll through dusk and dawn to map neighborhood cats! Earn special Moonlit Tokens to unlock limited-edition avatar profile borders in the festival exchange.',
      currencyName: 'Moonlit Tokens',
      currencyCode: 'MLT',
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 12)),
      bannerColorValue: 0xFF4C1D95, // Deep violet
      accentColorValue: 0xFFF59E0B, // Amber gold
      quests: const [
        EventQuestItem(
          id: 'eq_golden_hour_spot',
          title: 'Sunset Whisker Hunt',
          description: 'Scan and register a cat sighting during afternoon twilight hours.',
          rewardCoins: 60,
          targetValue: 1.0,
          type: 'golden_hour',
        ),
        EventQuestItem(
          id: 'eq_festival_patrol',
          title: 'Festival Night Patrol',
          description:
              'Accumulate 3,500 explorer steps charting local feline paths.',
          rewardCoins: 80,
          targetValue: 3500.0,
          type: 'steps',
        ),
        EventQuestItem(
          id: 'eq_community_booper',
          title: 'Friend of Strays',
          description:
              'Send 4 boops to community cat sightings on the live map.',
          rewardCoins: 50,
          targetValue: 4.0,
          type: 'boops',
        ),
        EventQuestItem(
          id: 'eq_tabby_chronicler',
          title: 'Tabby Sighting Spree',
          description:
              'Identify and catalog 2 Tabby or Puspin cats in your district.',
          rewardCoins: 110,
          targetValue: 2.0,
          type: 'scans',
          targetBreed: 'Tabby',
        ),
      ],
      borders: ProfileBorder.defaultBorders(),
    );
  }
}
