import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/feline_event.dart';
import '../../domain/repositories/event_repository.dart';
import 'event_center_sheet.dart';

class EventPopupModal extends StatefulWidget {
  final FelineEvent event;
  final String userId;
  final String userDisplayName;
  final String? userPhotoUrl;
  final EventRepository? repository;

  const EventPopupModal({
    super.key,
    required this.event,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoUrl,
    this.repository,
  });

  static Future<bool> shouldShowEvent(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final dismissed =
          prefs.getBool('event_popup_dismissed_${eventId}_$dateKey') ?? false;
      return !dismissed;
    } catch (_) {
      return true;
    }
  }

  static Future<void> markDismissedToday(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setBool('event_popup_dismissed_${eventId}_$dateKey', true);
    } catch (_) {}
  }

  static Future<void> checkAndShow(
    BuildContext context, {
    required String userId,
    required String userDisplayName,
    String? userPhotoUrl,
    EventRepository? repository,
  }) async {
    final repo = repository ?? EventRepositoryImpl.instance;
    final events = await repo.getActiveEvents();
    final eligibleEvents = events
        .where((e) => e.showPopupOnLaunch && e.isActive)
        .toList();

    if (eligibleEvents.isEmpty) return;

    eligibleEvents.sort((a, b) => b.priority.compareTo(a.priority));
    final targetEvent = eligibleEvents.first;

    final shouldShow = await shouldShowEvent(targetEvent.id);
    if (!shouldShow) return;

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => EventPopupModal(
        event: targetEvent,
        userId: userId,
        userDisplayName: userDisplayName,
        userPhotoUrl: userPhotoUrl,
        repository: repo,
      ),
    );
  }

  @override
  State<EventPopupModal> createState() => _EventPopupModalState();
}

class _EventPopupModalState extends State<EventPopupModal> {
  bool _dontShowAgainToday = false;

  void _dismissDialog() {
    if (_dontShowAgainToday) {
      EventPopupModal.markDismissedToday(widget.event.id);
    }
    Navigator.of(context).pop();
  }

  void _openEventCenter() {
    _dismissDialog();
    EventCenterSheet.show(
      context,
      userId: widget.userId,
      userDisplayName: widget.userDisplayName,
      userPhotoUrl: widget.userPhotoUrl,
      repository: widget.repository,
      event: widget.event,
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isPartnership = event.isPartnership;
    final partnerLabel =
        event.partnerName != null && event.partnerName!.isNotEmpty
        ? event.partnerName!
        : (isPartnership ? 'Partnership Spotlight' : 'Seasonal Gala');

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
              blurRadius: 20,
              offset: const Offset(0, 10),
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
              padding: const EdgeInsets.fromLTRB(20, 20, 14, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    event.bannerColor,
                    Color.lerp(event.bannerColor, Colors.black, 0.3)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPartnership
                                  ? Icons.handshake_rounded
                                  : Icons.campaign_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              partnerLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _dismissDialog,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.remainingFormatted,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: event.accentColor.withAlpha(50),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: event.accentColor.withAlpha(120),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          event.currencyName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: event.accentColor,
                          ),
                        ),
                      ),
                    ],
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
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.military_tech_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${event.quests.length} Festival Quests Active',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Complete daily tasks to claim exclusive borders',
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
                  ),
                  const SizedBox(height: 16),

                  // Don't show again today checkbox
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _dontShowAgainToday = !_dontShowAgainToday;
                      });
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _dontShowAgainToday,
                            onChanged: (val) {
                              setState(() {
                                _dontShowAgainToday = val ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Don\'t show this announcement again today',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _dismissDialog,
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
                          onPressed: _openEventCenter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: event.bannerColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Explore Event',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
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
