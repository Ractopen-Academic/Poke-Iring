import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/subscription_tier.dart';
import 'paypal_sandbox_checkout_modal.dart';

enum SandboxPaymentMethod {
  paypal('PayPal', 'Instant & Cards', Icons.payment_rounded),
  gcash('GCash', 'via PayPal Checkout', Icons.account_balance_wallet_rounded),
  maya('Maya', 'via PayPal Checkout', Icons.credit_card_rounded);

  final String label;
  final String accountHint;
  final IconData icon;
  const SandboxPaymentMethod(this.label, this.accountHint, this.icon);
}

class FelineClubPaywallSheet extends StatefulWidget {
  final String userId;
  final VoidCallback? onSubscribed;

  const FelineClubPaywallSheet({
    super.key,
    required this.userId,
    this.onSubscribed,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    VoidCallback? onSubscribed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FelineClubPaywallSheet(userId: userId, onSubscribed: onSubscribed),
    );
  }

  @override
  State<FelineClubPaywallSheet> createState() => _FelineClubPaywallSheetState();
}

class _FelineClubPaywallSheetState extends State<FelineClubPaywallSheet> {
  BillingInterval _selectedInterval = BillingInterval.annual;
  SandboxPaymentMethod _selectedPaymentMethod = SandboxPaymentMethod.paypal;

  Future<void> _handleUpgrade() async {
    final success = await PayPalSandboxCheckoutModal.show(
      context,
      userId: widget.userId,
      interval: _selectedInterval,
    );

    if (mounted) {
      if (success == true) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Payment verified! Welcome to Feline Club.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
        widget.onSubscribed?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dynamicSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.dynamicBorder, width: 1.2),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dynamicBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feline Club Membership',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dynamicTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lossless Master Archiving & Collector Perks',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.dynamicTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Perks List
            const _PerkRow(
              icon: Icons.hourglass_top_rounded,
              title: 'Extended MyDay Story Lifespan',
              description: 'Publish stories that remain active for 24h, 48h, 72h, or up to 7 days.',
            ),
            const SizedBox(height: 10),
            const _PerkRow(
              icon: Icons.hd_rounded,
              title: 'Ultra HD 4K Story & Vault Uploads',
              description: 'Upload high-resolution 4K photographs up to 25MB without downscaling.',
            ),
            const SizedBox(height: 10),
            const _PerkRow(
              icon: Icons.camera_enhance_rounded,
              title: 'Uncompressed RAW Photo Vault',
              description: 'Keep original 12MP+ camera masters without lossy WebP compression.',
            ),
            const SizedBox(height: 10),
            const _PerkRow(
              icon: Icons.military_tech_rounded,
              title: 'Gold Club Member Badge',
              description: 'Exclusive gold flair displayed beside your name across territory rankings.',
            ),
            const SizedBox(height: 10),
            const _PerkRow(
              icon: Icons.touch_app_rounded,
              title: '2x Daily Boop Allowance',
              description: 'Double your daily boops to support neighborhood stray sightings.',
            ),
            const SizedBox(height: 10),
            const _PerkRow(
              icon: Icons.file_download_rounded,
              title: 'Lossless Sticker Export',
              description: 'Download transparent high-resolution stickers of scanned cats.',
            ),
            const SizedBox(height: 20),
            // Plan Selector Cards
            Row(
              children: [
                Expanded(
                  child: _PlanOptionCard(
                    plan: SubscriptionPlan.annual,
                    isSelected: _selectedInterval == BillingInterval.annual,
                    onTap: () => setState(
                      () => _selectedInterval = BillingInterval.annual,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlanOptionCard(
                    plan: SubscriptionPlan.monthly,
                    isSelected: _selectedInterval == BillingInterval.monthly,
                    onTap: () => setState(
                      () => _selectedInterval = BillingInterval.monthly,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.dynamicTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: SandboxPaymentMethod.values.map((method) {
                final isSelected = _selectedPaymentMethod == method;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPaymentMethod = method),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withAlpha(28)
                            : AppColors.dynamicChromeTrack,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.dynamicBorder,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            method.icon,
                            size: 18,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.dynamicTextSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            method.label.split(' ').first,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.dynamicTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Subscribe Button
            ElevatedButton(
              onPressed: _handleUpgrade,
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
                'Join Feline Club',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PerkRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dynamicTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.dynamicTextSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanOptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanOptionCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(28)
              : AppColors.dynamicChromeTrack,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dynamicBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.discountBadge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  plan.discountBadge!,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            Text(
              plan.interval == BillingInterval.annual ? 'Annual' : 'Monthly',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.dynamicTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.priceFormatted,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
