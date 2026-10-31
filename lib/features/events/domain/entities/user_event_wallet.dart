class UserEventWallet {
  final String userId;
  final String eventId;
  final int coinBalance;
  final List<String> unlockedBorderIds;
  final String? equippedBorderId;
  final List<String> completedQuestIds;

  const UserEventWallet({
    required this.userId,
    required this.eventId,
    this.coinBalance = 0,
    this.unlockedBorderIds = const [],
    this.equippedBorderId,
    this.completedQuestIds = const [],
  });

  bool canAfford(int cost) => coinBalance >= cost;

  bool isBorderUnlocked(String borderId) =>
      unlockedBorderIds.contains(borderId);

  bool isBorderEquipped(String borderId) => equippedBorderId == borderId;

  bool isQuestCompleted(String questId) => completedQuestIds.contains(questId);

  UserEventWallet copyWith({
    String? userId,
    String? eventId,
    int? coinBalance,
    List<String>? unlockedBorderIds,
    String? equippedBorderId,
    bool clearEquippedBorder = false,
    List<String>? completedQuestIds,
  }) {
    return UserEventWallet(
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      coinBalance: coinBalance ?? this.coinBalance,
      unlockedBorderIds: unlockedBorderIds ?? this.unlockedBorderIds,
      equippedBorderId: clearEquippedBorder
          ? null
          : (equippedBorderId ?? this.equippedBorderId),
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'coinBalance': coinBalance,
      'unlockedBorderIds': unlockedBorderIds,
      'equippedBorderId': equippedBorderId,
      'completedQuestIds': completedQuestIds,
    };
  }

  factory UserEventWallet.fromMap(Map<String, dynamic> map) {
    return UserEventWallet(
      userId: map['userId'] as String? ?? '',
      eventId: map['eventId'] as String? ?? '',
      coinBalance: map['coinBalance'] as int? ?? 0,
      unlockedBorderIds:
          (map['unlockedBorderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      equippedBorderId: map['equippedBorderId'] as String?,
      completedQuestIds:
          (map['completedQuestIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
