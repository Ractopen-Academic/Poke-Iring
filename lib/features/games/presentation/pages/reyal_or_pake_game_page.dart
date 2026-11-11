import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../scanner/data/datasources/firebase_sightings_datasource.dart';
import '../../../scanner/domain/entities/cat_sighting.dart';
import '../../../rewards/services/rewards_service.dart';

class ReyalOrPakeGamePage extends StatefulWidget {
  final AuthUser user;

  const ReyalOrPakeGamePage({super.key, required this.user});

  static Future<void> navigate(BuildContext context, {required AuthUser user}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReyalOrPakeGamePage(user: user),
      ),
    );
  }

  @override
  State<ReyalOrPakeGamePage> createState() => _ReyalOrPakeGamePageState();
}

class _ReyalOrPakeGamePageState extends State<ReyalOrPakeGamePage> {
  final FirebaseSightingsDataSource _datasource =
      FirebaseSightingsDataSource.instance;
  final PageController _pageController = PageController(viewportFraction: 0.92);

  final Set<String> _votedSightingIds = {};
  int _sessionEarnedPoints = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _submitVote(CatSighting sighting, bool isCat) async {
    final userId =
        widget.user.id.isNotEmpty ? widget.user.id : widget.user.email;

    setState(() {
      _votedSightingIds.add(sighting.id);
      _sessionEarnedPoints += 15;
    });

    await _datasource.voteSighting(
      sightingId: sighting.id,
      userId: userId,
      isCat: isCat,
    );

    await RewardsService.instance.addPoints(
      userId,
      15,
      'Reyal or Pake Verification Game',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCat
                ? '+15 Paw Points! Voted Reyal (Real Cat).'
                : '+15 Paw Points! Voted Pake (Not a Cat).',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: isCat ? Colors.green.shade700 : AppColors.primaryDark,
        ),
      );

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        widget.user.id.isNotEmpty ? widget.user.id : widget.user.email;

    return Scaffold(
      backgroundColor: AppColors.dynamicBackground,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Reyal or Pake?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 19,
                color: AppColors.dynamicTextPrimary,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Stage 2 Human Verification Arena',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.dynamicTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.dynamicBackground,
        foregroundColor: AppColors.dynamicTextPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '+$_sessionEarnedPoints pts',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dynamicSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'AI checked first, now you confirm! Vote Reyal for real cats or Pake for fake/non-cats to earn +15 Paw Points each.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.dynamicTextSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<CatSighting>>(
                stream: _datasource.watchNearbySightings(
                  latitude: 10.3155,
                  longitude: 123.9730,
                  radiusKm: 20.0,
                ),
                builder: (context, snapshot) {
                  final allSightings = snapshot.data ?? [];
                  final candidates = allSightings
                      .where((s) => s.photoUrl.isNotEmpty)
                      .toList();

                  if (candidates.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 48,
                              color: AppColors.primary.withAlpha(120),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No community sightings to audit right now.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dynamicTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Take a cat photo with your camera to submit new entries!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.dynamicTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return PageView.builder(
                    controller: _pageController,
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final sighting = candidates[index];
                      final alreadyVoted =
                          _votedSightingIds.contains(sighting.id) ||
                              sighting.verifiedByUsers.contains(userId) ||
                              sighting.rejectedByUsers.contains(userId);

                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.dynamicSurface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.primary.withAlpha(45),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(24),
                                            ),
                                            child: sighting.photoUrl
                                                    .startsWith('data:image')
                                                ? Image.memory(
                                                    Uri.parse(sighting.photoUrl)
                                                        .data!
                                                        .contentAsBytes(),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, _, _) =>
                                                        _errorPlaceholder(),
                                                  )
                                                : Image.network(
                                                    sighting.photoUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, _, _) =>
                                                        _errorPlaceholder(),
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 14,
                                          left: 14,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withAlpha(165),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.auto_awesome,
                                                  color: Colors.amber,
                                                  size: 13,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'AI Stage 1: ${(sighting.aiConfidence * 100).round()}% match',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 14,
                                          right: 14,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withAlpha(165),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${index + 1} / ${candidates.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    sighting.breed,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w900,
                                                      color: AppColors
                                                          .dynamicTextPrimary,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${sighting.coatPattern} · Spotted by ${sighting.authorName}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .dynamicTextSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withAlpha(20),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${sighting.humanUpvotes} Reyal',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        if (alreadyVoted)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 11,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.dynamicChromeTrack,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'You already verified this photo',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors
                                                    .dynamicTextSecondary,
                                              ),
                                            ),
                                          )
                                        else
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.red.shade600,
                                                    side: BorderSide(
                                                      color:
                                                          Colors.red.shade400,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed: () => _submitVote(
                                                    sighting,
                                                    false,
                                                  ),
                                                  icon: const Icon(
                                                      Icons.close_rounded,
                                                      size: 18),
                                                  label: const Text(
                                                    'Pake (Fake)',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                    backgroundColor:
                                                        Colors.green.shade700,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed: () => _submitVote(
                                                    sighting,
                                                    true,
                                                  ),
                                                  icon: const Icon(
                                                      Icons.check_rounded,
                                                      size: 18),
                                                  label: const Text(
                                                    'Reyal (+15 pts)',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 13,
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
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: AppColors.primary.withAlpha(30),
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets_rounded,
        size: 54,
        color: AppColors.primary,
      ),
    );
  }
}
