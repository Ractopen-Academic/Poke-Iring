import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/services/territory_service_impl.dart';
import '../../domain/entities/explorer_territory.dart';
import '../../domain/services/territory_service.dart';
import 'territory_selection_sheet.dart';

class TerritorySetupDialog extends StatefulWidget {
  final String userId;
  final ExplorerTerritory initialTerritory;
  final TerritoryService? territoryService;

  const TerritorySetupDialog({
    super.key,
    required this.userId,
    required this.initialTerritory,
    this.territoryService,
  });

  static Future<ExplorerTerritory?> checkAndShow(
    BuildContext context, {
    required String userId,
    TerritoryService? territoryService,
  }) async {
    final service = territoryService ?? TerritoryServiceImpl.instance;
    final current = await service.getTerritory(userId);

    // If territory already locked to account, no setup required
    if (current.lockedAt != null && current.isHomeConfirmed) {
      return current;
    }

    if (!context.mounted) return null;

    return showDialog<ExplorerTerritory>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TerritorySetupDialog(
        userId: userId,
        initialTerritory: current,
        territoryService: service,
      ),
    );
  }

  @override
  State<TerritorySetupDialog> createState() => _TerritorySetupDialogState();
}

class _TerritorySetupDialogState extends State<TerritorySetupDialog> {
  late ExplorerTerritory _selectedTerritory;
  late final TerritoryService _territoryService;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _selectedTerritory = widget.initialTerritory;
    _territoryService =
        widget.territoryService ?? TerritoryServiceImpl.instance;
  }

  Future<void> _pickDifferentTerritory() async {
    final updated = await TerritorySelectionSheet.show(
      context,
      userId: widget.userId,
      currentTerritory: _selectedTerritory,
    );

    if (updated != null && mounted) {
      setState(() => _selectedTerritory = updated);
    }
  }

  Future<void> _handleConfirmLock() async {
    setState(() => _isConfirming = true);

    try {
      final lockedTerritory = _selectedTerritory.copyWith(
        isHomeConfirmed: true,
        lockedAt: DateTime.now(),
      );

      await _territoryService.updateTerritory(widget.userId, lockedTerritory);

      if (mounted) {
        Navigator.of(context).pop(lockedTerritory);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'Official territory locked to "${lockedTerritory.shortLabel}". Valid for seasonal leaderboards.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to lock territory: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFFE65100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official Territory Setup',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tied to account for rankings',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To maintain fair competitive divisions across seasonal leaderboards, your home territory is tied directly to your account and can only be changed once every year (365 days).',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected Territory Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Selected Division',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _pickDifferentTerritory,
                              child: const Text(
                                'Change Area',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedTerritory.shortLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedTerritory.province}, ${_selectedTerritory.region}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Warning Notice
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFB300)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFFE65100),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Annual Cooldown: Once confirmed, you cannot switch your territory division until 365 days have passed.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF795548),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isConfirming
                              ? null
                              : () => Navigator.of(context).pop(null),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Later',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isConfirming ? null : _handleConfirmLock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isConfirming
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Confirm & Lock',
                                  style: TextStyle(
                                    fontSize: 13.5,
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
          ],
        ),
      ),
    );
  }
}
