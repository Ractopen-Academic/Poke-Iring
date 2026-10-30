import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/feline_avatar.dart';
import '../../../dex/domain/entities/feline_dex_species.dart';
import '../../../dex/domain/entities/iring_dex_entry.dart';
import '../../../dex/presentation/widgets/cat_detail_sheet.dart';
import '../../domain/entities/explorer_showcase_profile.dart';
import 'showcase_card_item.dart';

class ExplorerShowcaseSheet extends StatefulWidget {
  final ExplorerShowcaseProfile profile;

  const ExplorerShowcaseSheet({super.key, required this.profile});

  static Future<void> show(
    BuildContext context,
    ExplorerShowcaseProfile profile,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExplorerShowcaseSheet(profile: profile),
    );
  }

  @override
  State<ExplorerShowcaseSheet> createState() => _ExplorerShowcaseSheetState();
}

class _ExplorerShowcaseSheetState extends State<ExplorerShowcaseSheet> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final cards = profile.showcaseCards;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  FelineAvatar(
                    photoUrl: profile.avatarUrl,
                    seed: profile.displayName,
                    radius: 28,
                    showBorder: true,
                    borderColor: AppColors.primary,
                    borderWidth: 2,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#${profile.rank}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                profile.territory,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      label: 'Paw Points',
                      value: '${profile.pawPoints}',
                      icon: Icons.pets_rounded,
                    ),
                    _buildVerticalDivider(),
                    _buildStatItem(
                      label: 'Dex Catalog',
                      value:
                          '${profile.dexDiscoveredCount} / ${profile.totalDexSpecies}',
                      icon: Icons.collections_bookmark_outlined,
                    ),
                    _buildVerticalDivider(),
                    _buildStatItem(
                      label: 'Boops',
                      value: '${profile.totalBoops}',
                      icon: Icons.touch_app_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Privacy Guard / Showcase Section
            if (!profile.isPublic)
              _buildPrivatePlaceholder()
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Feline Showcase',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${cards.length} / ${ExplorerShowcaseProfile.maxShowcaseSlots} Cards',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Swipe horizontally to explore their top neighborhood catches.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              if (cards.isEmpty)
                _buildEmptyShowcase()
              else ...[
                // Swipable Carousel
                SizedBox(
                  height: 310,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: cards.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final sighting = cards[index];
                      return ShowcaseCardItem(
                        sighting: sighting,
                        index: index,
                        total: cards.length,
                        onTap: () {
                          final species = FelineDexSpecies.canonicalSpecies
                              .firstWhere(
                                (s) =>
                                    s.coatPattern.toLowerCase() ==
                                    sighting.coatPattern.toLowerCase(),
                                orElse: () =>
                                    FelineDexSpecies.canonicalSpecies.first,
                              );
                          final entry = IringDexEntry.fromSightings(
                            species: species,
                            matchedSightings: [sighting],
                          );
                          CatDetailSheet.show(context, entry);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Page Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(cards.length, (index) {
                    final isCurrent = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isCurrent ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ],

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Close Showcase',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 28, color: Colors.grey.shade300);
  }

  Widget _buildPrivatePlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 32,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Private Explorer Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This explorer has chosen to keep their feline showcase and collection private.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyShowcase() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.collections_outlined,
              size: 32,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 10),
            Text(
              'No Featured Cats Yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'This explorer has not pinned any cats to their showcase yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
