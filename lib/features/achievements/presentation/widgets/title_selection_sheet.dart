import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/achievements_repository_impl.dart';
import '../../domain/entities/explorer_title.dart';

class TitleSelectionSheet extends StatelessWidget {
  final String userId;

  const TitleSelectionSheet({super.key, required this.userId});

  static Future<void> show(BuildContext context, {required String userId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TitleSelectionSheet(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.dynamicBorder, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.dynamicBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explorer Titles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dynamicTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Equip unlocked titles to display on your profile and leaderboards.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.dynamicTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.dynamicTextSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.dynamicBorder),
          Expanded(
            child: StreamBuilder<List<ExplorerTitle>>(
              stream: AchievementsRepositoryImpl.instance.watchTitles(userId),
              builder: (context, snapshot) {
                final titles = snapshot.data ?? [];
                if (titles.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                // Sort: equipped first, then unlocked by tier descending, then locked
                final sortedTitles = List<ExplorerTitle>.from(titles)
                  ..sort((a, b) {
                    if (a.isEquipped && !b.isEquipped) return -1;
                    if (!a.isEquipped && b.isEquipped) return 1;
                    if (a.isUnlocked && !b.isUnlocked) return -1;
                    if (!a.isUnlocked && b.isUnlocked) return 1;
                    return b.tier.tierLevel.compareTo(a.tier.tierLevel);
                  });

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedTitles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final title = sortedTitles[index];
                    return _TitleTile(
                      title: title,
                      onEquip: () async {
                        await AchievementsRepositoryImpl.instance.equipTitle(
                          userId: userId,
                          titleId: title.id,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Equipped title "${title.name}"'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleTile extends StatelessWidget {
  final ExplorerTitle title;
  final VoidCallback onEquip;

  const _TitleTile({required this.title, required this.onEquip});

  @override
  Widget build(BuildContext context) {
    final tier = title.tier;
    final isUnlocked = title.isUnlocked;
    final isEquipped = title.isEquipped;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isEquipped
            ? tier.primaryColor.withAlpha(32)
            : (isUnlocked
                  ? AppColors.dynamicChromeTrack
                  : AppColors.dynamicSurface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEquipped
              ? tier.primaryColor
              : (isUnlocked
                    ? AppColors.dynamicBorder
                    : AppColors.dynamicBorder.withAlpha(70)),
          width: isEquipped ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? tier.primaryColor.withAlpha(35)
                  : AppColors.dynamicChromeTrack,
              border: Border.all(
                color: isUnlocked ? tier.primaryColor : AppColors.dynamicBorder,
              ),
            ),
            child: Icon(
              isUnlocked
                  ? Icons.military_tech_outlined
                  : Icons.lock_outline_rounded,
              size: 18,
              color: isUnlocked
                  ? tier.primaryColor
                  : AppColors.dynamicTextSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? AppColors.dynamicTextPrimary
                              : AppColors.dynamicTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RarityBadge(rarity: title.rarity),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  title.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUnlocked
                        ? AppColors.dynamicTextSecondary
                        : AppColors.dynamicTextSecondary.withAlpha(140),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isEquipped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tier.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Equipped',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          else if (isUnlocked)
            OutlinedButton(
              onPressed: onEquip,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tier.primaryColor),
                foregroundColor: tier.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Equip',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tier.primaryColor,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.dynamicChromeTrack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.dynamicBorder.withAlpha(60),
                ),
              ),
              child: Text(
                'Locked',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dynamicTextSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final TitleRarity rarity;

  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (rarity) {
      case TitleRarity.common:
        bg = const Color(0xFF2B2623);
        fg = const Color(0xFFB8ABA0);
        break;
      case TitleRarity.rare:
        bg = const Color(0xFF102847);
        fg = const Color(0xFF64B5F6);
        break;
      case TitleRarity.epic:
        bg = const Color(0xFF2E173E);
        fg = const Color(0xFFCE93D8);
        break;
      case TitleRarity.legendary:
        bg = const Color(0xFF3E2310);
        fg = const Color(0xFFFFB74D);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        rarity.name.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
