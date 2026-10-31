import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/paw_quests_repository_impl.dart';
import '../../domain/entities/paw_quest.dart';
import '../../domain/repositories/paw_quests_repository.dart';
import 'paw_quest_card.dart';
import 'quest_pool_editor_sheet.dart';

class PawQuestsSection extends StatefulWidget {
  final String userId;
  final PawQuestsRepository? repository;

  const PawQuestsSection({super.key, required this.userId, this.repository});

  @override
  State<PawQuestsSection> createState() => _PawQuestsSectionState();
}

class _PawQuestsSectionState extends State<PawQuestsSection> {
  late final PawQuestsRepository _repository;
  QuestCategory _selectedCategory = QuestCategory.daily;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PawQuestsRepositoryImpl();
  }

  Future<void> _handleClaim(PawQuest quest) async {
    try {
      final points = await _repository.claimReward(
        userId: widget.userId,
        questId: quest.id,
      );

      if (points > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Claimed +$points Paw Points for "${quest.title}"!',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to claim reward: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PawQuest>>(
      stream: _repository.watchQuests(widget.userId),
      builder: (context, snapshot) {
        final allQuests = snapshot.data ?? const [];
        final filteredQuests = allQuests
            .where((q) => q.category == _selectedCategory)
            .toList();

        final resetTime = filteredQuests.isNotEmpty
            ? filteredQuests.first.remainingFormatted
            : 'midnight';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Paw Quests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Resets in $resetTime',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: 'Quest Pool Settings',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => QuestPoolEditorSheet.show(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _CategoryTab(
                      label: 'Daily Quests',
                      isSelected: _selectedCategory == QuestCategory.daily,
                      onTap: () => setState(
                        () => _selectedCategory = QuestCategory.daily,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _CategoryTab(
                      label: 'Weekly Missions',
                      isSelected: _selectedCategory == QuestCategory.weekly,
                      onTap: () => setState(
                        () => _selectedCategory = QuestCategory.weekly,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (filteredQuests.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'No active quests right now. Check back at the next cycle!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ...filteredQuests.map((quest) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PawQuestCard(
                    quest: quest,
                    onClaim: () => _handleClaim(quest),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
