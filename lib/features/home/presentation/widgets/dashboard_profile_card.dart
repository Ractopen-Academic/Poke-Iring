import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/feline_avatar.dart';
import '../../../achievements/data/repositories/achievements_repository_impl.dart';
import '../../../achievements/domain/entities/achievement_tier.dart';
import '../../../achievements/domain/entities/explorer_title.dart';
import '../../../achievements/presentation/widgets/equipped_title_badge.dart';
import '../../../achievements/presentation/widgets/title_selection_sheet.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../events/presentation/widgets/profile_border_avatar.dart';

/// Collectible "Trainer/Explorer License" identity card.
class DashboardProfileCard extends StatelessWidget {
  final AuthUser user;

  const DashboardProfileCard({super.key, required this.user});

  String _formatExplorerTag(String userId) {
    if (userId.isEmpty) return '#IRING-0001';
    final clean = userId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final tag = clean.length >= 6
        ? clean.substring(0, 6)
        : clean.padRight(6, '0');
    return '#IRING-$tag';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.isNotEmpty
        ? user.displayName
        : user.email.split('@').first;
    final userId = user.id.isNotEmpty ? user.id : user.email;
    final explorerTag = _formatExplorerTag(userId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(70), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          children: [
            // License Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primary.withAlpha(50),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'FELINE EXPLORER LICENSE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dynamicBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(60),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      explorerTag,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main License Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProfileBorderAvatar(
                    userId: userId,
                    radius: 30,
                    child: FelineAvatar(
                      photoUrl: user.photoUrl,
                      seed: displayName,
                      radius: 30,
                      showBorder: true,
                      borderColor: AppColors.primary.withAlpha(60),
                      borderWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.dynamicTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.dynamicTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<ExplorerTitle?>(
                          stream: AchievementsRepositoryImpl.instance
                              .watchEquippedTitle(userId),
                          builder: (context, snapshot) {
                            final equipped =
                                snapshot.data ??
                                const ExplorerTitle(
                                  id: 'title_novice_scout',
                                  name: 'Novice Scout',
                                  description: 'Default title',
                                  rarity: TitleRarity.common,
                                  tier: AchievementTier.bronze,
                                );
                            return EquippedTitleBadge(
                              title: equipped,
                              onTap: () => TitleSelectionSheet.show(
                                context,
                                userId: userId,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
