enum SubscriptionTier {
  free,
  felineClubMember;

  bool get isClubMember => this == SubscriptionTier.felineClubMember;
  String get displayName =>
      isClubMember ? 'Feline Club Member' : 'Free Explorer';
}

enum BillingInterval {
  monthly,
  annual;

  String get label =>
      this == BillingInterval.annual ? 'Annual (Best Value)' : 'Monthly';
}

class SubscriptionPlan {
  final String id;
  final String title;
  final String priceFormatted;
  final BillingInterval interval;
  final String? discountBadge;
  final List<String> perks;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.priceFormatted,
    required this.interval,
    this.discountBadge,
    required this.perks,
  });

  static const monthly = SubscriptionPlan(
    id: 'plan_feline_club_monthly',
    title: 'Feline Club Monthly',
    priceFormatted: 'PHP 149 / mo',
    interval: BillingInterval.monthly,
    perks: [
      'Uncompressed RAW Photo Vault archiving',
      'Exclusive Gold Feline Club Member badge',
      '2x daily boop allowances on sightings',
      'Lossless full-fidelity sticker exports',
    ],
  );

  static const annual = SubscriptionPlan(
    id: 'plan_feline_club_annual',
    title: 'Feline Club Annual',
    priceFormatted: 'PHP 1,190 / yr',
    interval: BillingInterval.annual,
    discountBadge: 'Save 33%',
    perks: [
      'Everything in Monthly plan',
      '2 months free (Save 33%)',
      'Priority seasonal leaderboard badge flair',
      'Permanent Mythic Vault archival storage',
    ],
  );
}

class SubscriptionStatus {
  final String userId;
  final SubscriptionTier tier;
  final BillingInterval? activeInterval;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final bool isAutoRenewing;

  const SubscriptionStatus({
    required this.userId,
    this.tier = SubscriptionTier.free,
    this.activeInterval,
    this.activatedAt,
    this.expiresAt,
    this.isAutoRenewing = false,
  });

  bool get isClubMember => tier == SubscriptionTier.felineClubMember;

  static SubscriptionStatus free(String userId) =>
      SubscriptionStatus(userId: userId, tier: SubscriptionTier.free);

  SubscriptionStatus copyWith({
    String? userId,
    SubscriptionTier? tier,
    BillingInterval? activeInterval,
    DateTime? activatedAt,
    DateTime? expiresAt,
    bool? isAutoRenewing,
  }) {
    return SubscriptionStatus(
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      activeInterval: activeInterval ?? this.activeInterval,
      activatedAt: activatedAt ?? this.activatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isAutoRenewing: isAutoRenewing ?? this.isAutoRenewing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tier': tier.name,
      'activeInterval': activeInterval?.name,
      'activatedAt': activatedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isAutoRenewing': isAutoRenewing,
    };
  }

  factory SubscriptionStatus.fromMap(Map<String, dynamic> map) {
    return SubscriptionStatus(
      userId: map['userId'] as String? ?? '',
      tier: SubscriptionTier.values.firstWhere(
        (t) => t.name == map['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      activeInterval: map['activeInterval'] != null
          ? BillingInterval.values.firstWhere(
              (i) => i.name == map['activeInterval'],
              orElse: () => BillingInterval.monthly,
            )
          : null,
      activatedAt: map['activatedAt'] != null
          ? DateTime.parse(map['activatedAt'] as String)
          : null,
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
      isAutoRenewing: map['isAutoRenewing'] as bool? ?? false,
    );
  }
}
