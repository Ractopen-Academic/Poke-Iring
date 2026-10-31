import 'package:flutter/material.dart';

enum LeaderboardTier {
  sleepyKitten,
  alleyProwler,
  whiskersTracker,
  felineRanger,
  territoryAlpha,
  mythicGuardian;

  String get divisionLabel => 'Division ${index + 1}';
  String get fullTitle => 'Division ${index + 1} • $displayName';

  String get displayName {
    switch (this) {
      case LeaderboardTier.sleepyKitten:
        return 'Sleepy Kitten';
      case LeaderboardTier.alleyProwler:
        return 'Alley Prowler';
      case LeaderboardTier.whiskersTracker:
        return 'Whiskers Tracker';
      case LeaderboardTier.felineRanger:
        return 'Feline Ranger';
      case LeaderboardTier.territoryAlpha:
        return 'Territory Alpha';
      case LeaderboardTier.mythicGuardian:
        return 'Mythic Paw Guardian';
    }
  }

  Color get color {
    switch (this) {
      case LeaderboardTier.sleepyKitten:
        return const Color(0xFF8D6E63);
      case LeaderboardTier.alleyProwler:
        return const Color(0xFF546E7A);
      case LeaderboardTier.whiskersTracker:
        return const Color(0xFF00897B);
      case LeaderboardTier.felineRanger:
        return const Color(0xFF1E88E5);
      case LeaderboardTier.territoryAlpha:
        return const Color(0xFF8E24AA);
      case LeaderboardTier.mythicGuardian:
        return const Color(0xFFFF8F00);
    }
  }

  int get threshold {
    switch (this) {
      case LeaderboardTier.sleepyKitten:
        return 0;
      case LeaderboardTier.alleyProwler:
        return 500;
      case LeaderboardTier.whiskersTracker:
        return 1500;
      case LeaderboardTier.felineRanger:
        return 3500;
      case LeaderboardTier.territoryAlpha:
        return 7000;
      case LeaderboardTier.mythicGuardian:
        return 12000;
    }
  }

  int? get nextThreshold {
    switch (this) {
      case LeaderboardTier.sleepyKitten:
        return 500;
      case LeaderboardTier.alleyProwler:
        return 1500;
      case LeaderboardTier.whiskersTracker:
        return 3500;
      case LeaderboardTier.felineRanger:
        return 7000;
      case LeaderboardTier.territoryAlpha:
        return 12000;
      case LeaderboardTier.mythicGuardian:
        return null;
    }
  }

  static LeaderboardTier fromPoints(int points) {
    if (points >= 12000) return LeaderboardTier.mythicGuardian;
    if (points >= 7000) return LeaderboardTier.territoryAlpha;
    if (points >= 3500) return LeaderboardTier.felineRanger;
    if (points >= 1500) return LeaderboardTier.whiskersTracker;
    if (points >= 500) return LeaderboardTier.alleyProwler;
    return LeaderboardTier.sleepyKitten;
  }

  int pointsToNextTier(int currentPoints) {
    final target = nextThreshold;
    if (target == null) return 0;
    final diff = target - currentPoints;
    return diff > 0 ? diff : 0;
  }

  double progress(int currentPoints) {
    final next = nextThreshold;
    if (next == null) return 1.0;
    final currentMin = threshold;
    final range = next - currentMin;
    if (range <= 0) return 1.0;
    final value = (currentPoints - currentMin) / range;
    return value.clamp(0.0, 1.0);
  }
}
