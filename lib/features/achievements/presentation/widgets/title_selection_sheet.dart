import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/girly_theme.dart';
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
    final isGirly = GirlyThemeProvider.isGirly(context);
    final textPrimary =
        isGirly ? GirlyColors.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isGirly ? GirlyColors.textSecondary : AppColors.textSecondary;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isGirly ? GirlyColors.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isGirly ? GirlyColors.border : AppColors.border,
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
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Equip unlocked titles to display on your profile and leaderboards.',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isGirly ? GirlyColors.border : AppColors.border,
          ),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    final isGirly = GirlyThemeProvider.isGirly(context);
    final textPrimary =
        isGirly ? GirlyColors.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isGirly ? GirlyColors.textSecondary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isEquipped
            ? (isGirly ? GirlyColors.primaryLight : tier.backgroundColor)
            : (isUnlocked
                ? (isGirly ? GirlyColors.surface : Colors.white)
                : (isGirly
                    ? GirlyColors.primaryLight.withAlpha(150)
                    : AppColors.background.withAlpha(150))),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEquipped
              ? (isGirly ? GirlyColors.border : tier.borderColor)
              : (isUnlocked
                  ? (isGirly ? GirlyColors.border : AppColors.border)
                  : (isGirly ? GirlyColors.border : AppColors.border)
                      .withAlpha(80)),
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
                  ? (isGirly ? GirlyColors.primaryLight : tier.backgroundColor)
                  : textSecondary.withAlpha(20),
              border: Border.all(
                color: isUnlocked
                    ? (isGirly ? GirlyColors.border : tier.borderColor)
                    : (isGirly ? GirlyColors.border : AppColors.border),
              ),
            ),
            child: Icon(
              isUnlocked
                  ? Icons.military_tech_outlined
                  : Icons.lock_outline_rounded,
              size: 18,
              color: isUnlocked
                  ? (isGirly ? GirlyColors.primaryDark : tier.primaryColor)
                  : textSecondary,
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
                          color: isUnlocked ? textPrimary : textSecondary,
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
                        ? textSecondary
                        : textSecondary.withAlpha(160),
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
                color: isGirly ? GirlyColors.primaryDark : tier.primaryColor,
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
                side: BorderSide(
                  color: isGirly ? GirlyColors.border : tier.borderColor,
                ),
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
                  color:
                      isGirly ? GirlyColors.primaryDark : tier.secondaryColor,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isGirly ? GirlyColors.border : AppColors.border)
                    .withAlpha(60),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Locked',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
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
    final isGirly = GirlyThemeProvider.isGirly(context);
    Color bg;
    Color fg;

    if (isGirly) {
      bg = GirlyColors.primaryLight;
      fg = GirlyColors.primaryDark;
    } else {
      switch (rarity) {
        case TitleRarity.common:
          bg = const Color(0xFFF1F3F5);
          fg = const Color(0xFF5A6672);
          break;
        case TitleRarity.rare:
          bg = const Color(0xFFE3F2FD);
          fg = const Color(0xFF1976D2);
          break;
        case TitleRarity.epic:
          bg = const Color(0xFFF3E5F5);
          fg = const Color(0xFF7B1FA2);
          break;
        case TitleRarity.legendary:
          bg = const Color(0xFFFFF8E1);
          fg = const Color(0xFFF57F17);
          break;
      }
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
