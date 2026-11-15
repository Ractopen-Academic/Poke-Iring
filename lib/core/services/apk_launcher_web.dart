import 'dart:js_interop';

@JS('window.open')
external JSObject? _windowOpen(JSString url, JSString target);

Future<bool> platformOpenExternalUrl(String url) async {
  try {
    _windowOpen(url.toJS, '_blank'.toJS);
    return true;
  } catch (_) {
    return false;
  }
}
