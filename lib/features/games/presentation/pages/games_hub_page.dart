import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../rewards/presentation/pages/reward_store_page.dart';
import '../../../rewards/services/rewards_service.dart';
import 'flappy_cat_game_page.dart';
import 'reyal_or_pake_game_page.dart';

class GamesHubPage extends StatelessWidget {
  final AuthUser user;

  const GamesHubPage({super.key, required this.user});

  static Future<void> navigate(BuildContext context, {required AuthUser user}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GamesHubPage(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = user.id.isNotEmpty ? user.id : user.email;
    RewardsService.instance.syncUserPoints(userId);

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextPrimary,
        elevation: 0,
        title: const Text(
          'Cat Arcade',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.3),
        ),
        actions: [
          IconButton(
            tooltip: 'Paw Points Exchange',
            icon: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RewardStorePage(user: user)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            ValueListenableBuilder<int>(
              valueListenable: RewardsService.instance.pointsNotifier,
              builder: (context, points, _) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dynamicSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pets_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Paw Points',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dynamicTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$points pts',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.dynamicTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RewardStorePage(user: user),
                          ),
                        ),
                        child: const Text(
                          'Redeem',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Choose a Mini-Game',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.dynamicTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _GameCard(
              title: 'Flappy Cat',
              subtitle: 'Tap to glide your calico cat through scratching posts and earn +2 Paw Points per post.',
              badge: 'Arcade',
              icon: Icons.flutter_dash_rounded,
              onTap: () => FlappyCatGamePage.navigate(context, user: user),
            ),
            const SizedBox(height: 12),
            _GameCard(
              title: 'Reyal or Pake?',
              subtitle: 'Audit community cat sightings to verify real cats and earn Paw Points.',
              badge: 'Community Audit',
              icon: Icons.verified_user_rounded,
              onTap: () => ReyalOrPakeGamePage.navigate(context, user: user),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dynamicSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.dynamicBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.dynamicTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.dynamicTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.dynamicTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
