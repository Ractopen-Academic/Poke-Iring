import 'package:flutter/material.dart';

enum AchievementTier {
  bronze(
    label: 'Bronze',
    tierLevel: 1,
    primaryColor: Color(0xFFC87D55),
    secondaryColor: Color(0xFF8D5B4C),
    backgroundColor: Color(0xFFFAF0E6),
    borderColor: Color(0xFFD7A184),
  ),
  silver(
    label: 'Silver',
    tierLevel: 2,
    primaryColor: Color(0xFF7E8B9B),
    secondaryColor: Color(0xFF4E5D6C),
    backgroundColor: Color(0xFFF1F3F5),
    borderColor: Color(0xFFA6B0BC),
  ),
  gold(
    label: 'Gold',
    tierLevel: 3,
    primaryColor: Color(0xFFE5A93B),
    secondaryColor: Color(0xFF996B1E),
    backgroundColor: Color(0xFFFFF8E7),
    borderColor: Color(0xFFF2C96C),
  ),
  platinum(
    label: 'Platinum',
    tierLevel: 4,
    primaryColor: Color(0xFF00ACC1),
    secondaryColor: Color(0xFF006064),
    backgroundColor: Color(0xFFE0F7FA),
    borderColor: Color(0xFF4DD0E1),
  );

  final String label;
  final int tierLevel;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color borderColor;

  const AchievementTier({
    required this.label,
    required this.tierLevel,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  static AchievementTier fromName(String name) {
    return AchievementTier.values.firstWhere(
      (t) => t.name.toLowerCase() == name.toLowerCase(),
      orElse: () => AchievementTier.bronze,
    );
  }
}
