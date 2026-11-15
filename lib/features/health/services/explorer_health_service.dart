import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExplorerHealthSnapshot {
  final int stepsToday;
  final double distanceKm;
  final double caloriesBurned;
  final int activeMinutes;
  final DateTime updatedAt;

  const ExplorerHealthSnapshot({
    required this.stepsToday,
    required this.distanceKm,
    required this.caloriesBurned,
    required this.activeMinutes,
    required this.updatedAt,
  });

  factory ExplorerHealthSnapshot.empty() {
    final now = DateTime.now();
    return ExplorerHealthSnapshot(
      stepsToday: 0,
      distanceKm: 0,
      caloriesBurned: 0,
      activeMinutes: 0,
      updatedAt: now,
    );
  }
}

class ExplorerHealthService {
  ExplorerHealthService._();

  static final ExplorerHealthService instance = ExplorerHealthService._();

  StreamController<ExplorerHealthSnapshot>? _controller;
  StreamSubscription<StepCount>? _subscription;
  bool _started = false;

  ExplorerHealthSnapshot _latest = ExplorerHealthSnapshot.empty();

  ExplorerHealthSnapshot get latest => _latest;

  Stream<ExplorerHealthSnapshot> get stream =>
      _controller?.stream ?? const Stream.empty();

  Future<void> start() async {
    if (_started) {
      return;
    }

    _started = true;
    _controller ??= StreamController<ExplorerHealthSnapshot>.broadcast();

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayDateKey();
    final savedDate = prefs.getString('explorer_health_date');

    if (savedDate != todayKey) {
      await prefs.setString('explorer_health_date', todayKey);
      await prefs.remove('explorer_health_baseline');
      await prefs.setInt('explorer_health_total', 0);
    }

    try {
      _subscription = Pedometer.stepCountStream.listen(
        (event) async {
          final currentDayKey = _todayDateKey();
          final storedDate = prefs.getString('explorer_health_date');
          final int totalSteps = event.steps;

          int? baselineSteps = prefs.getInt('explorer_health_baseline');
          if (storedDate != currentDayKey ||
              baselineSteps == null ||
              totalSteps < baselineSteps) {
            baselineSteps = totalSteps;
            await prefs.setString('explorer_health_date', currentDayKey);
            await prefs.setInt('explorer_health_baseline', baselineSteps);
          }

          final int todaySteps = totalSteps - baselineSteps;

          final snapshot = ExplorerHealthSnapshot(
            stepsToday: todaySteps,
            distanceKm: todaySteps * 0.00075,
            caloriesBurned: todaySteps * 0.04,
            activeMinutes: (todaySteps / 120).floor(),
            updatedAt: DateTime.now(),
          );

          _latest = snapshot;
          _controller?.add(snapshot);

          await prefs.setInt('explorer_health_total', todaySteps);
        },
        onError: (_) {
          // Hardware step counter unavailable (e.g., Web or unsupported sensor)
        },
      );
    } catch (_) {}

    _latest = ExplorerHealthSnapshot(
      stepsToday: 0,
      distanceKm: 0,
      caloriesBurned: 0,
      activeMinutes: 0,
      updatedAt: DateTime.now(),
    );
    _controller?.add(_latest);
  }

  Future<void> stop() async {
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }
    _controller?.close();
    _controller = null;
    _started = false;
  }

  String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
