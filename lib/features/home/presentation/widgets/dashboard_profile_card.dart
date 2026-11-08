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

/// Explorer identity card displaying avatar, name, email, and equipped title.
class DashboardProfileCard extends StatelessWidget {
  final AuthUser user;

  const DashboardProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.isNotEmpty
        ? user.displayName
        : user.email.split('@').first;
    final userId = user.id.isNotEmpty ? user.id : user.email;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dynamicBorder),
      ),
      child: Row(
        children: [
          ProfileBorderAvatar(
            userId: userId,
            radius: 28,
            child: FelineAvatar(
              photoUrl: user.photoUrl,
              seed: displayName,
              radius: 28,
              showBorder: true,
              borderColor: AppColors.primary.withAlpha(50),
              borderWidth: 2,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dynamicTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 13,
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
                      onTap: () =>
                          TitleSelectionSheet.show(context, userId: userId),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
