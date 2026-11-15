import 'package:flutter/services.dart';

import '../constants/app_version.dart';
import 'apk_launcher_stub.dart'
    if (dart.library.js_interop) 'apk_launcher_web.dart';

class ApkDownloadService {
  ApkDownloadService._();

  static final ApkDownloadService instance = ApkDownloadService._();

  String get directApkUrl => AppVersion.devApkDownloadUrl;
  String get releasePageUrl => AppVersion.devReleasePageUrl;

  /// Attempts to open the direct APK download URL in the system browser (Android/Web).
  /// If no browser handler is available (e.g., headless test environment), copies the URL
  /// to the clipboard and returns false.
  Future<bool> downloadDevApk({String? customUrl}) async {
    final targetUrl = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim()
        : directApkUrl;

    final opened = await platformOpenExternalUrl(targetUrl);
    if (!opened) {
      await copyDownloadLink(customUrl: targetUrl);
    }
    return opened;
  }

  /// Copies the direct APK download link to the system clipboard.
  Future<void> copyDownloadLink({String? customUrl}) async {
    final targetUrl = (customUrl != null && customUrl.trim().isNotEmpty)
        ? customUrl.trim()
        : directApkUrl;
    try {
      await Clipboard.setData(ClipboardData(text: targetUrl));
    } catch (_) {}
  }
}
