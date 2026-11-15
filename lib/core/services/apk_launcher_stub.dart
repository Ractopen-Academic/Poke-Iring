import 'package:flutter/services.dart';

const MethodChannel _browserChannel = MethodChannel(
  'com.ryme.pokeiring/browser',
);

Future<bool> platformOpenExternalUrl(String url) async {
  try {
    final launched = await _browserChannel.invokeMethod<bool>('openUrl', {
      'url': url,
    });
    return launched == true;
  } catch (_) {
    return false;
  }
}
