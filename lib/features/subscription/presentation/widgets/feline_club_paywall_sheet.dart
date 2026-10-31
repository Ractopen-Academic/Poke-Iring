import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/services/subscription_service_impl.dart';
import '../../domain/entities/subscription_tier.dart';

enum SandboxPaymentMethod {
  paypal(
    'PayPal Sandbox',
    'simulated_buyer@pokeiring.app',
    Icons.payment_rounded,
  ),
  gcash(
    'GCash (PayMongo)',
    '0917-***-2026',
    Icons.account_balance_wallet_rounded,
  ),
  maya('Maya (PayMongo)', '0918-***-8822', Icons.credit_card_rounded);

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
  bool _isProcessing = false;

  Future<void> _handleUpgrade() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SandboxCheckoutDialog(
        method: _selectedPaymentMethod,
        interval: _selectedInterval,
      ),
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await SubscriptionServiceImpl.instance.upgradeToClub(
        widget.userId,
        interval: _selectedInterval,
      );

      if (mounted) {
        Navigator.of(context).pop();
        final txId = _selectedPaymentMethod == SandboxPaymentMethod.paypal
            ? 'PAYPAL-SBX-${DateTime.now().millisecondsSinceEpoch % 1000000}'
            : 'PM-${_selectedPaymentMethod.name.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch % 1000000}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Verified via ${_selectedPaymentMethod.label} ($txId). Welcome to Feline Club!',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
        widget.onSubscribed?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to activate subscription: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: AppColors.border,
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
                    color: const Color(0xFFFFB300).withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFB300),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFE65100),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feline Club Membership',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Lossless Master Archiving & Collector Perks',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Perks List
            _PerkRow(
              icon: Icons.camera_enhance_rounded,
              title: 'Uncompressed RAW Photo Vault',
              description: 'Keep original 12MP+ camera masters without lossy WebP compression.',
            ),
            const SizedBox(height: 10),
            _PerkRow(
              icon: Icons.military_tech_rounded,
              title: 'Gold Club Member Badge',
              description: 'Exclusive gold flair displayed beside your name across territory rankings.',
            ),
            const SizedBox(height: 10),
            _PerkRow(
              icon: Icons.touch_app_rounded,
              title: '2x Daily Boop Allowance',
              description: 'Double your daily boops to support neighborhood stray sightings.',
            ),
            const SizedBox(height: 10),
            _PerkRow(
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
            const Text(
              'Sandbox Payment Method',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
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
                            ? const Color(0xFFFFF8E1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFB300)
                              : AppColors.border,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            method.icon,
                            size: 18,
                            color: isSelected
                                ? const Color(0xFFE65100)
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            method.label.split(' ').first,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? const Color(0xFFE65100)
                                  : AppColors.textPrimary,
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
              onPressed: _isProcessing ? null : _handleUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
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
          color: isSelected ? const Color(0xFFFFF8E1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB300) : AppColors.border,
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
                  color: const Color(0xFFFF8F00),
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
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

class _SandboxCheckoutDialog extends StatelessWidget {
  final SandboxPaymentMethod method;
  final BillingInterval interval;

  const _SandboxCheckoutDialog({required this.method, required this.interval});

  @override
  Widget build(BuildContext context) {
    final plan = interval == BillingInterval.annual
        ? SubscriptionPlan.annual
        : SubscriptionPlan.monthly;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    method.icon,
                    color: const Color(0xFFE65100),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Sandbox Test Environment',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Due',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        plan.priceFormatted,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Test Identifier',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        method.accountHint,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This is a local sandbox simulation for feline membership validation. No real financial transaction will take place.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8F00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Authorize Sandbox',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
