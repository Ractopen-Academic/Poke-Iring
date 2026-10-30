import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'network_info.dart';

class NetworkInfoImpl implements NetworkInfo {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Timer? _pollingTimer;
  bool _lastStatus = true;

  NetworkInfoImpl({Duration pollingInterval = const Duration(seconds: 12)}) {
    _startPolling(pollingInterval);
  }

  void _startPolling(Duration interval) {
    if (kIsWeb) return;
    _checkStatus();
    _pollingTimer = Timer.periodic(interval, (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final status = await isConnected;
    if (status != _lastStatus) {
      _lastStatus = status;
      if (!_controller.isClosed) {
        _controller.add(status);
      }
    }
  }

  @override
  Future<bool> get isConnected async {
    if (kIsWeb) return true;

    try {
      final result = await InternetAddress.lookup('one.one.one.one')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.close();
  }
}
