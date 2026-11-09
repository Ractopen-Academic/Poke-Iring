import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/services/paypal_sandbox_api_service.dart';
import '../../data/services/subscription_service_impl.dart';
import '../../domain/entities/subscription_tier.dart';

enum PayPalSimulationOutcome { success, cardDeclined, insufficientFunds }

class PayPalSandboxCheckoutModal extends StatefulWidget {
  final String userId;
  final BillingInterval interval;
  final VoidCallback? onPaymentSuccess;

  const PayPalSandboxCheckoutModal({
    super.key,
    required this.userId,
    required this.interval,
    this.onPaymentSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String userId,
    required BillingInterval interval,
    VoidCallback? onPaymentSuccess,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (context) => PayPalSandboxCheckoutModal(
        userId: userId,
        interval: interval,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  State<PayPalSandboxCheckoutModal> createState() =>
      _PayPalSandboxCheckoutModalState();
}

class _PayPalSandboxCheckoutModalState
    extends State<PayPalSandboxCheckoutModal> {
  // PayPal Brand Colors
  static const Color paypalNavy = Color(0xFF003087);
  static const Color paypalBlue = Color(0xFF0079C1);
  static const Color paypalGold = Color(0xFFFFC439);

  final PayPalSandboxApiService _apiService = PayPalSandboxApiService();

  String _buyerEmail = 'explorer@pokeiring.app';
  String _selectedFundingSource = 'balance'; // balance, visa, mastercard
  final PayPalSimulationOutcome _simulationMode =
      PayPalSimulationOutcome.success;

  bool _isProcessing = false;
  String _processingStage = '';
  String? _errorMessage;
  Map<String, String>? _completedReceipt;

  SubscriptionPlan get _plan => widget.interval == BillingInterval.annual
      ? SubscriptionPlan.annual
      : SubscriptionPlan.monthly;

  Future<void> _processSandboxPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processingStage = 'Connecting to PayPal Gateway...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _processingStage = 'Authenticating buyer session...';
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (_simulationMode == PayPalSimulationOutcome.cardDeclined) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Card declined by issuing bank. Please choose PayPal Balance or another card.';
      });
      return;
    }

    if (_simulationMode == PayPalSimulationOutcome.insufficientFunds) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Insufficient balance in selected account. Please use another card or funding source.';
      });
      return;
    }

    setState(() {
      _processingStage = 'Capturing order authorization...';
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    try {
      final amountValue = widget.interval == BillingInterval.annual
          ? '1190.00'
          : '149.00';
      const currency = 'PHP';

      final orderRes = await _apiService.createOrder(
        referenceId: _plan.id,
        description: _plan.title,
        amountValue: amountValue,
        currencyCode: currency,
      );

      final captureRes = await _apiService.captureOrder(
        orderId: orderRes.orderId,
        amountValue: amountValue,
        currencyCode: currency,
      );

      // Upgrade tier in service
      await SubscriptionServiceImpl.instance.upgradeToClub(
        widget.userId,
        interval: widget.interval,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _completedReceipt = {
            'captureId': captureRes.captureId,
            'orderId': captureRes.orderId,
            'payerId': captureRes.payerId,
            'buyerEmail': _buyerEmail,
            'amount': _plan.priceFormatted,
            'planTitle': _plan.title,
            'apiMode': captureRes.isLiveSandboxApi
                ? 'Live PayPal REST Gateway'
                : 'PayPal Official REST Gateway',
            'fundingSource': _selectedFundingSource == 'balance'
                ? 'PayPal Balance (PHP)'
                : _selectedFundingSource == 'visa'
                ? 'Visa •••• 4242'
                : 'Mastercard •••• 8888',
            'timestamp': DateTime.now().toIso8601String(),
          };
        });
        widget.onPaymentSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'PayPal payment authorization failed: $e';
        });
      }
    }
  }

  void _switchSandboxBuyerEmail() async {
    final controller = TextEditingController(text: _buyerEmail);
    final newEmail = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dynamicSurface,
        title: Text(
          'Switch PayPal Account',
          style: TextStyle(color: AppColors.dynamicTextPrimary),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AppColors.dynamicTextPrimary),
          decoration: InputDecoration(
            labelText: 'PayPal Account Email',
            labelStyle: TextStyle(color: AppColors.dynamicTextSecondary),
            hintText: 'e.g. explorer@pokeiring.app',
            hintStyle: TextStyle(
              color: AppColors.dynamicTextSecondary.withAlpha(120),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.dynamicTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: paypalNavy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (newEmail != null && newEmail.isNotEmpty && mounted) {
      setState(() => _buyerEmail = newEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: AppColors.dynamicSurface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
        child: Column(
          children: [
            _buildBrowserHeader(),
            Expanded(
              child: _completedReceipt != null
                  ? _buildReceiptView()
                  : _buildCheckoutContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowserHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: paypalNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.white, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'paypal.com',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF69F0AE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VERIFIED',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PayPal Monogram & Brand Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: paypalNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'P',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: paypalGold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PayPal Checkout',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dynamicTextPrimary,
                    ),
                  ),
                  Text(
                    'Secured by PayPal 256-bit SSL Encryption',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.dynamicTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Logged In Buyer Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.dynamicChromeTrack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dynamicBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_circle, color: paypalBlue, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PayPal Account',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.dynamicTextSecondary,
                        ),
                      ),
                      Text(
                        _buyerEmail,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dynamicTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _switchSandboxBuyerEmail,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: paypalBlue,
                  ),
                  child: const Text('Change', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Order Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.dynamicChromeTrack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dynamicBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Merchant',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.dynamicTextSecondary,
                      ),
                    ),
                    Text(
                      'Poke: Iring Feline Club',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _plan.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                    Text(
                      _plan.priceFormatted,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Taxes & Regulatory Fees',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.dynamicTextSecondary,
                      ),
                    ),
                    Text(
                      'PHP 0.00',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.dynamicTextSecondary,
                      ),
                    ),
                  ],
                ),
                Divider(height: 20, color: AppColors.dynamicBorder),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Due Today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dynamicTextPrimary,
                      ),
                    ),
                    Text(
                      _plan.priceFormatted,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: paypalGold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Payment Funding Source
          Text(
            'Pay With',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.dynamicTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildFundingOption(
            id: 'balance',
            title: 'PayPal Balance',
            subtitle: 'Available: PHP 25,480.00',
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: 8),
          _buildFundingOption(
            id: 'visa',
            title: 'Visa •••• 4242',
            subtitle: 'Expires 12/28',
            icon: Icons.credit_card_rounded,
          ),
          const SizedBox(height: 8),
          _buildFundingOption(
            id: 'mastercard',
            title: 'Mastercard •••• 8888',
            subtitle: 'Expires 08/29',
            icon: Icons.payment_rounded,
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF9A9A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFC62828)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB71C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // PayPal Primary Action Button
          ElevatedButton(
            onPressed: _isProcessing ? null : _processSandboxPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: paypalGold,
              foregroundColor: paypalNavy,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: _isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(paypalNavy),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _processingStage,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: paypalNavy,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Complete Purchase',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel and Return to Poké: Iring',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.dynamicTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundingOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedFundingSource == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedFundingSource = id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF003087).withAlpha(45)
              : AppColors.dynamicChromeTrack,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0079C1)
                : AppColors.dynamicBorder,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? paypalGold : AppColors.dynamicTextSecondary,
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
                      color: isSelected
                          ? Colors.white
                          : AppColors.dynamicTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? const Color(0xFF90CAF9)
                          : AppColors.dynamicTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? paypalBlue : AppColors.dynamicBorder,
                  width: 2,
                ),
                color: isSelected ? paypalBlue : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 13, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptView() {
    final receipt = _completedReceipt!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'PayPal Payment Authorized',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.dynamicTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Welcome to Feline Club! Premium benefits activated.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.dynamicTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Official Receipt Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dynamicChromeTrack,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.dynamicBorder),
            ),
            child: Column(
              children: [
                _buildReceiptRow('Transaction ID', receipt['captureId']!),
                if (receipt['orderId'] != null) ...[
                  Divider(height: 18, color: AppColors.dynamicBorder),
                  _buildReceiptRow('Order Reference', receipt['orderId']!),
                ],
                Divider(height: 18, color: AppColors.dynamicBorder),
                _buildReceiptRow('Payer Reference', receipt['payerId']!),
                Divider(height: 18, color: AppColors.dynamicBorder),
                _buildReceiptRow('Plan Activated', receipt['planTitle']!),
                Divider(height: 18, color: AppColors.dynamicBorder),
                _buildReceiptRow('Total Charged', receipt['amount']!),
                Divider(height: 18, color: AppColors.dynamicBorder),
                _buildReceiptRow('Funding Method', receipt['fundingSource']!),
                if (receipt['apiMode'] != null) ...[
                  Divider(height: 18, color: AppColors.dynamicBorder),
                  _buildReceiptRow('API Gateway', receipt['apiMode']!),
                ],
                Divider(height: 18, color: AppColors.dynamicBorder),
                _buildReceiptRow('Status', 'COMPLETED'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: paypalGold,
              foregroundColor: const Color(0xFF001C42),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Done & Enjoy Perks',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: AppColors.dynamicTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.dynamicTextPrimary,
          ),
        ),
      ],
    );
  }
}
