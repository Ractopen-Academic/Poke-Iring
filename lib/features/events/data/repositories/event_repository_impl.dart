import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/feline_event.dart';
import '../../domain/entities/user_event_wallet.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/local_event_catalog.dart';

class EventRepositoryImpl implements EventRepository {
  static final EventRepositoryImpl _instance = EventRepositoryImpl._internal();

  static EventRepositoryImpl get instance => _instance;

  final FirebaseFirestore? _firestore;

  final Map<String, StreamController<UserEventWallet>> _walletControllers = {};
  final Map<String, StreamController<String?>> _equippedBorderControllers = {};
  final StreamController<FelineEvent> _eventController =
      StreamController<FelineEvent>.broadcast();

  factory EventRepositoryImpl({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      return EventRepositoryImpl._internal(firestore);
    }
    return _instance;
  }

  EventRepositoryImpl._internal([this._firestore]);

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Stream<FelineEvent> watchActiveEvent() {
    _emitActiveEvent();
    return _eventController.stream;
  }

  Future<void> _emitActiveEvent() async {
    final event = await getActiveEvent();
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  @override
  Future<FelineEvent> getActiveEvent() async {
    if (_isFirebaseAvailable) {
      try {
        final doc = await _db.collection('events').doc('active_festival').get();
        if (doc.exists && doc.data() != null) {
          return FelineEvent.fromMap({...doc.data()!, 'id': doc.id});
        }
      } catch (e) {
        debugPrint('Firestore getActiveEvent skipped: $e');
      }
    }
    return LocalEventCatalog.activeFestival;
  }

  @override
  Stream<UserEventWallet> watchUserWallet(String userId, String eventId) {
    final key = '${userId}_$eventId';
    if (!_walletControllers.containsKey(key)) {
      _walletControllers[key] = StreamController<UserEventWallet>.broadcast();
    }

    _emitUserWallet(userId, eventId);
    return _walletControllers[key]!.stream;
  }

  Future<void> _emitUserWallet(String userId, String eventId) async {
    final key = '${userId}_$eventId';
    final wallet = await getUserWallet(userId, eventId);
    final controller = _walletControllers[key];
    if (controller != null && !controller.isClosed) {
      controller.add(wallet);
    }
  }

  @override
  Future<UserEventWallet> getUserWallet(String userId, String eventId) async {
    // 1. Online-First: Try fetching latest wallet from Cloud Firestore
    if (_isFirebaseAvailable) {
      try {
        final snap = await _db
            .collection('users')
            .doc(userId)
            .collection('event_wallets')
            .doc(eventId)
            .get()
            .timeout(const Duration(milliseconds: 1500));
        if (snap.exists && snap.data() != null) {
          final wallet = UserEventWallet.fromMap(snap.data()!);
          unawaited(_saveWalletLocally(wallet));
          return wallet;
        }
      } catch (e) {
        debugPrint(
          'Firestore fetch event wallet error ($e). Using local cache.',
        );
      }
    }

    // 2. Persistent Local Cache (SharedPreferences)
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
      final raw = prefs.getString('event_wallet_${userId}_$eventId');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final equipped = prefs.getString('user_equipped_border_$userId');
        return UserEventWallet.fromMap({
          ...map,
          'equippedBorderId': equipped ?? map['equippedBorderId'],
        });
      }
    } catch (_) {}

    // 3. Built-in Fallback (Clean install zero-balance wallet)
    final defaultWallet = UserEventWallet(
      userId: userId,
      eventId: eventId,
      coinBalance: 0,
      unlockedBorderIds: const [],
      equippedBorderId: prefs?.getString('user_equipped_border_$userId'),
      completedQuestIds: const [],
    );
    unawaited(_saveWalletLocally(defaultWallet));
    return defaultWallet;
  }

  Future<void> _saveWalletLocally(UserEventWallet wallet) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'event_wallet_${wallet.userId}_${wallet.eventId}',
        jsonEncode(wallet.toMap()),
      );
      if (wallet.equippedBorderId != null) {
        await prefs.setString(
          'user_equipped_border_${wallet.userId}',
          wallet.equippedBorderId!,
        );
      }
    } catch (_) {}
  }

  @override
  Future<int> earnEventCoins({
    required String userId,
    required String eventId,
    required int amount,
    required String reason,
  }) async {
    final wallet = await getUserWallet(userId, eventId);
    final updated = wallet.copyWith(coinBalance: wallet.coinBalance + amount);
    await _persistWallet(updated);

    _emitUserWallet(userId, eventId);
    return updated.coinBalance;
  }

  @override
  Future<bool> purchaseBorder({
    required String userId,
    required String eventId,
    required String borderId,
  }) async {
    final wallet = await getUserWallet(userId, eventId);
    if (wallet.isBorderUnlocked(borderId)) {
      return true; // Already unlocked
    }

    final border = LocalEventCatalog.findBorder(borderId);
    if (border == null) return false;

    if (!wallet.canAfford(border.cost)) {
      return false; // Insufficient coins
    }

    final updated = wallet.copyWith(
      coinBalance: wallet.coinBalance - border.cost,
      unlockedBorderIds: [...wallet.unlockedBorderIds, borderId],
    );

    await _persistWallet(updated);
    _emitUserWallet(userId, eventId);
    return true;
  }

  @override
  Future<bool> equipBorder({
    required String userId,
    required String? borderId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (borderId == null) {
        await prefs.remove('user_equipped_border_$userId');
      } else {
        await prefs.setString('user_equipped_border_$userId', borderId);
      }

      final activeEvent = await getActiveEvent();
      final wallet = await getUserWallet(userId, activeEvent.id);
      final updated = borderId == null
          ? wallet.copyWith(clearEquippedBorder: true)
          : wallet.copyWith(equippedBorderId: borderId);

      await _persistWallet(updated);
      _emitUserWallet(userId, activeEvent.id);

      final controller = _equippedBorderControllers[userId];
      if (controller != null && !controller.isClosed) {
        controller.add(borderId);
      }

      if (_isFirebaseAvailable) {
        try {
          await _db.collection('users').doc(userId).set({
            'equippedProfileBorderId': borderId,
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      return true;
    } catch (e) {
      debugPrint('Error equipping border: $e');
      return false;
    }
  }

  @override
  Future<String?> getEquippedBorderId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_equipped_border_$userId');
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String?> watchEquippedBorderId(String userId) {
    if (!_equippedBorderControllers.containsKey(userId)) {
      _equippedBorderControllers[userId] =
          StreamController<String?>.broadcast();
    }

    getEquippedBorderId(userId).then((id) {
      final controller = _equippedBorderControllers[userId];
      if (controller != null && !controller.isClosed) {
        controller.add(id);
      }
    });

    return _equippedBorderControllers[userId]!.stream;
  }

  @override
  Future<bool> completeEventQuest({
    required String userId,
    required String eventId,
    required String questId,
  }) async {
    final wallet = await getUserWallet(userId, eventId);
    if (wallet.isQuestCompleted(questId)) {
      return false; // Already completed
    }

    final event = await getActiveEvent();
    final quest = event.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => EventQuestItem(
        id: questId,
        title: 'Event Quest',
        description: '',
        rewardCoins: 50,
        targetValue: 1,
        type: 'steps',
      ),
    );

    final updated = wallet.copyWith(
      coinBalance: wallet.coinBalance + quest.rewardCoins,
      completedQuestIds: [...wallet.completedQuestIds, questId],
    );

    await _persistWallet(updated);
    _emitUserWallet(userId, eventId);
    return true;
  }

  Future<void> _persistWallet(UserEventWallet wallet) async {
    await _saveWalletLocally(wallet);

    if (_isFirebaseAvailable) {
      try {
        await _db
            .collection('users')
            .doc(wallet.userId)
            .collection('event_wallets')
            .doc(wallet.eventId)
            .set(wallet.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore persist wallet error: $e');
      }
    }
  }
}
