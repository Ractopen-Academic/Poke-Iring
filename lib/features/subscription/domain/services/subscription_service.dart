import '../entities/subscription_tier.dart';

abstract class SubscriptionService {
  Stream<SubscriptionStatus> watchSubscription(String userId);
  Future<SubscriptionStatus> getSubscription(String userId);

  Future<SubscriptionStatus> upgradeToClub(
    String userId, {
    BillingInterval interval = BillingInterval.monthly,
  });

  Future<SubscriptionStatus> cancelSubscription(String userId);
}
