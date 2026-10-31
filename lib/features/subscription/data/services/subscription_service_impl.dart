import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/subscription_tier.dart';
import '../../domain/services/subscription_service.dart';

class SubscriptionServiceImpl implements SubscriptionService {
  static SubscriptionServiceImpl? _instance;
  static SubscriptionServiceImpl get instance =>
      _instance ??= SubscriptionServiceImpl();

  final Map<String, StreamController<SubscriptionStatus>> _controllers = {};
  final Map<String, SubscriptionStatus> _cache = {};

  String _prefKey(String userId) => 'subscription_status_v1_$userId';

  @override
  Stream<SubscriptionStatus> watchSubscription(String userId) {
    if (!_controllers.containsKey(userId)) {
      _controllers[userId] = StreamController<SubscriptionStatus>.broadcast(
        onListen: () {
          getSubscription(userId).then((status) {
            if (_controllers[userId]?.isClosed == false) {
              _controllers[userId]?.add(status);
            }
          });
        },
      );
    }
    return _controllers[userId]!.stream;
  }

  @override
  Future<SubscriptionStatus> getSubscription(String userId) async {
    if (_cache.containsKey(userId)) {
      return _cache[userId]!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey(userId));
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final status = SubscriptionStatus.fromMap(decoded);
        _cache.putIfAbsent(userId, () => status);
        return _cache[userId]!;
      }
    } catch (_) {}

    final defaultFree = SubscriptionStatus.free(userId);
    _cache.putIfAbsent(userId, () => defaultFree);
    return _cache[userId]!;
  }

  @override
  Future<SubscriptionStatus> upgradeToClub(
    String userId, {
    BillingInterval interval = BillingInterval.monthly,
  }) async {
    final now = DateTime.now();
    final duration = interval == BillingInterval.annual
        ? const Duration(days: 365)
        : const Duration(days: 30);

    final upgraded = SubscriptionStatus(
      userId: userId,
      tier: SubscriptionTier.felineClubMember,
      activeInterval: interval,
      activatedAt: now,
      expiresAt: now.add(duration),
      isAutoRenewing: true,
    );

    _cache[userId] = upgraded;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey(userId), jsonEncode(upgraded.toMap()));
    } catch (_) {}

    if (_controllers[userId]?.isClosed == false) {
      _controllers[userId]?.add(upgraded);
    }

    return upgraded;
  }

  @override
  Future<SubscriptionStatus> cancelSubscription(String userId) async {
    final current = await getSubscription(userId);
    final cancelled = current.copyWith(
      tier: SubscriptionTier.free,
      isAutoRenewing: false,
    );

    _cache[userId] = cancelled;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey(userId), jsonEncode(cancelled.toMap()));
    } catch (_) {}

    if (_controllers[userId]?.isClosed == false) {
      _controllers[userId]?.add(cancelled);
    }

    return cancelled;
  }
}
