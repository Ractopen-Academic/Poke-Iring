import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../services/reward_item.dart';
import '../../services/rewards_service.dart';

class RewardStorePage extends StatefulWidget {
  final AuthUser user;

  const RewardStorePage({super.key, required this.user});

  @override
  State<RewardStorePage> createState() => _RewardStorePageState();
}

class _RewardStorePageState extends State<RewardStorePage> {
  final RewardsService _rewardsService = RewardsService.instance;
  RewardType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _rewardsService.syncUserPoints(
      widget.user.id.isNotEmpty ? widget.user.id : widget.user.email,
    );
  }

  void _handleRedeem(RewardItem item) async {
    final balance = _rewardsService.pointsNotifier.value;
    if (balance < item.costPawPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need ${item.costPawPoints - balance} more Paw Points. Verify community photos in the game to earn more!',
          ),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dynamicSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          item.type == RewardType.catFood ? 'Redeem Real Cat Food' : 'Pledge Donation',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.dynamicTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Redeem "${item.title}" for ${item.costPawPoints} Paw Points?',
              style: TextStyle(color: AppColors.dynamicTextPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Partner: ${item.partnerName}\n${item.description}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.dynamicTextSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.dynamicTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _rewardsService.redeemReward(
        userId: widget.user.id.isNotEmpty ? widget.user.id : widget.user.email,
        item: item,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                item.type == RewardType.catFood
                    ? 'Success! Cat food voucher saved to your redemptions.'
                    : 'Success! Your welfare donation pledge was recorded.',
              ),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: Text(
          'Paw Points Exchange',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.dynamicTextPrimary,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: _rewardsService.pointsNotifier,
          builder: (context, balance, _) {
            final filteredCatalog = _selectedFilter == null
                ? RewardItem.catalog
                : RewardItem.catalog
                    .where((item) => item.type == _selectedFilter)
                    .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(40),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.pets_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Available Paw Balance',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$balance pts',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Turn real-life cat discoveries and human verifications into actual food pouches or welfare donations for stray cats in the Philippines.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All Items',
                          isSelected: _selectedFilter == null,
                          onTap: () => setState(() => _selectedFilter = null),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Real Cat Food',
                          isSelected: _selectedFilter == RewardType.catFood,
                          onTap: () => setState(() => _selectedFilter = RewardType.catFood),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Welfare Donations',
                          isSelected: _selectedFilter == RewardType.welfareDonation,
                          onTap: () => setState(
                            () => _selectedFilter = RewardType.welfareDonation,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filteredCatalog[index];
                        final canAfford = balance >= item.costPawPoints;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppColors.dynamicSurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    item.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 80,
                                      height: 80,
                                      color: AppColors.primary.withAlpha(30),
                                      child: const Icon(
                                        Icons.pets_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withAlpha(25),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.badgeText,
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${item.costPawPoints} pts',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              color: canAfford
                                                  ? AppColors.primary
                                                  : AppColors.dynamicTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.dynamicTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.dynamicTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 34,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: canAfford
                                                ? AppColors.primary
                                                : AppColors.dynamicSurface,
                                            foregroundColor: canAfford
                                                ? Colors.white
                                                : AppColors.dynamicTextSecondary,
                                            elevation: 0,
                                            side: BorderSide(
                                              color: canAfford
                                                  ? Colors.transparent
                                                  : AppColors.primary.withAlpha(60),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () => _handleRedeem(item),
                                          child: Text(
                                            canAfford
                                                ? (item.type == RewardType.catFood
                                                    ? 'Redeem Food'
                                                    : 'Pledge Donation')
                                                : 'Need ${item.costPawPoints - balance} pts',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filteredCatalog.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.dynamicSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary.withAlpha(40),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.dynamicTextPrimary,
          ),
        ),
      ),
    );
  }
}
