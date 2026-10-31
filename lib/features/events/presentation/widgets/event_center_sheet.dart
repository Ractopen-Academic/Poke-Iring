import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/feline_avatar.dart';
import '../../data/datasources/local_event_catalog.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/feline_event.dart';
import '../../domain/entities/profile_border.dart';
import '../../domain/entities/user_event_wallet.dart';
import '../../domain/repositories/event_repository.dart';
import 'profile_border_avatar.dart';

class EventCenterSheet extends StatefulWidget {
  final String userId;
  final String userDisplayName;
  final String? userPhotoUrl;
  final EventRepository? repository;

  const EventCenterSheet({
    super.key,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoUrl,
    this.repository,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String userDisplayName,
    String? userPhotoUrl,
    EventRepository? repository,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventCenterSheet(
        userId: userId,
        userDisplayName: userDisplayName,
        userPhotoUrl: userPhotoUrl,
        repository: repository,
      ),
    );
  }

  @override
  State<EventCenterSheet> createState() => _EventCenterSheetState();
}

class _EventCenterSheetState extends State<EventCenterSheet> {
  late final EventRepository _repository;
  int _activeTabIndex = 0; // 0 = Quests, 1 = Border Shop
  ProfileBorder? _selectedPreviewBorder;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EventRepositoryImpl.instance;
    _selectedPreviewBorder = LocalEventCatalog.borders.first;
  }

  Future<void> _handleCompleteQuest(
    FelineEvent event,
    EventQuestItem quest,
  ) async {
    final success = await _repository.completeEventQuest(
      userId: widget.userId,
      eventId: event.id,
      questId: quest.id,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            'Completed "${quest.title}" and earned +${quest.rewardCoins} ${event.currencyCode}!',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

  Future<void> _handlePurchaseBorder(
    FelineEvent event,
    ProfileBorder border,
  ) async {
    final success = await _repository.purchaseBorder(
      userId: widget.userId,
      eventId: event.id,
      borderId: border.id,
    );

    if (mounted) {
      if (success) {
        // Automatically equip newly unlocked border
        await _repository.equipBorder(
          userId: widget.userId,
          borderId: border.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Unlocked and equipped "${border.name}" profile border!',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient festival coins to unlock this border.'),
          ),
        );
      }
    }
  }

  Future<void> _handleToggleEquip(ProfileBorder border, bool isEquipped) async {
    await _repository.equipBorder(
      userId: widget.userId,
      borderId: isEquipped ? null : border.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            isEquipped
                ? 'Unequipped profile border.'
                : 'Equipped "${border.name}" as your active avatar border!',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FelineEvent>(
      stream: _repository.watchActiveEvent(),
      builder: (context, eventSnapshot) {
        final event = eventSnapshot.data ?? LocalEventCatalog.activeFestival;

        return StreamBuilder<UserEventWallet>(
          stream: _repository.watchUserWallet(widget.userId, event.id),
          builder: (context, walletSnapshot) {
            final wallet =
                walletSnapshot.data ??
                UserEventWallet(
                  userId: widget.userId,
                  eventId: event.id,
                  coinBalance: 0,
                  unlockedBorderIds: const [],
                  completedQuestIds: const [],
                );

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Drag Handle & Close
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 32),
                        Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Festival Hero Banner
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          event.bannerColor,
                          event.bannerColor.withAlpha(200),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: event.bannerColor.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(45),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.remainingFormatted,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Wallet Coin Counter Chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: event.accentColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.toll_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${wallet.coinBalance} ${event.currencyCode}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withAlpha(220),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Segmented Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF1F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'Festival Quests',
                              icon: Icons.checklist_rounded,
                              isSelected: _activeTabIndex == 0,
                              onTap: () => setState(() => _activeTabIndex = 0),
                            ),
                          ),
                          Expanded(
                            child: _TabButton(
                              label: 'Border Shop',
                              icon: Icons.palette_outlined,
                              isSelected: _activeTabIndex == 1,
                              onTap: () => setState(() => _activeTabIndex = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab Content
                  Expanded(
                    child: _activeTabIndex == 0
                        ? _buildQuestsTab(event, wallet)
                        : _buildBorderShopTab(event, wallet),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuestsTab(FelineEvent event, UserEventWallet wallet) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: event.quests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final quest = event.quests[index];
        final isCompleted = wallet.isQuestCompleted(quest.id);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFFF9FAFB) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFECFDF5)
                      : event.bannerColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.event_available_rounded,
                  color: isCompleted
                      ? const Color(0xFF059669)
                      : event.bannerColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      quest.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary.withAlpha(200),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '+${quest.rewardCoins} ${event.currencyCode}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Claimed',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF065F46),
                    ),
                  ),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: event.bannerColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _handleCompleteQuest(event, quest),
                  child: const Text(
                    'Complete',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBorderShopTab(FelineEvent event, UserEventWallet wallet) {
    final preview = _selectedPreviewBorder ?? event.borders.first;
    final isUnlocked = wallet.isBorderUnlocked(preview.id);
    final isEquipped = wallet.isBorderEquipped(preview.id);
    final canAfford = wallet.canAfford(preview.cost);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Avatar Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Text(
                  'Live Avatar Preview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ProfileBorderAvatar(
                  border: preview,
                  radius: 36,
                  child: FelineAvatar(
                    photoUrl: widget.userPhotoUrl,
                    seed: widget.userDisplayName,
                    radius: 36,
                    showBorder: false,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      preview.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: preview.rarity.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        preview.rarity.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: preview.rarity.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  preview.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                // Action Button for selected border
                if (isEquipped)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Equipped (Tap to Unequip)'),
                    onPressed: () => _handleToggleEquip(preview, true),
                  )
                else if (isUnlocked)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _handleToggleEquip(preview, false),
                    child: const Text('Equip Border'),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford
                          ? event.accentColor
                          : const Color(0xFF9CA3AF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: canAfford
                        ? () => _handlePurchaseBorder(event, preview)
                        : null,
                    child: Text(
                      canAfford
                          ? 'Unlock for ${preview.cost} ${event.currencyCode}'
                          : 'Locked (${preview.cost} ${event.currencyCode} required)',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Border Catalog Header
          const Text(
            'Festival Collection',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Border selection grid/list
          for (final border in event.borders) ...[
            _BorderCatalogCard(
              border: border,
              isSelected: preview.id == border.id,
              isUnlocked: wallet.isBorderUnlocked(border.id),
              isEquipped: wallet.isBorderEquipped(border.id),
              currencyCode: event.currencyCode,
              onSelect: () => setState(() => _selectedPreviewBorder = border),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
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
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BorderCatalogCard extends StatelessWidget {
  final ProfileBorder border;
  final bool isSelected;
  final bool isUnlocked;
  final bool isEquipped;
  final String currencyCode;
  final VoidCallback onSelect;

  const _BorderCatalogCard({
    required this.border,
    required this.isSelected,
    required this.isUnlocked,
    required this.isEquipped,
    required this.currencyCode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Mini Preview Swatch
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: border.gradient,
                boxShadow: border.glowColor != null
                    ? [
                        BoxShadow(
                          color: border.glowColor!,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    isEquipped
                        ? Icons.check_rounded
                        : isUnlocked
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    size: 15,
                    color: isEquipped
                        ? AppColors.primary
                        : isUnlocked
                        ? const Color(0xFF059669)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        border.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: border.rarity.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          border.rarity.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: border.rarity.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    border.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isEquipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'EQUIPPED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              )
            else if (isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'UNLOCKED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF065F46),
                  ),
                ),
              )
            else
              Text(
                '${border.cost} $currencyCode',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
