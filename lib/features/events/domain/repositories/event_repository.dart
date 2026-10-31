import '../entities/feline_event.dart';
import '../entities/user_event_wallet.dart';

abstract class EventRepository {
  Stream<FelineEvent> watchActiveEvent();

  Future<FelineEvent> getActiveEvent();

  Stream<UserEventWallet> watchUserWallet(String userId, String eventId);

  Future<UserEventWallet> getUserWallet(String userId, String eventId);

  Future<int> earnEventCoins({
    required String userId,
    required String eventId,
    required int amount,
    required String reason,
  });

  Future<bool> purchaseBorder({
    required String userId,
    required String eventId,
    required String borderId,
  });

  Future<bool> equipBorder({required String userId, required String? borderId});

  Future<String?> getEquippedBorderId(String userId);

  Stream<String?> watchEquippedBorderId(String userId);

  Future<bool> completeEventQuest({
    required String userId,
    required String eventId,
    required String questId,
  });
}
