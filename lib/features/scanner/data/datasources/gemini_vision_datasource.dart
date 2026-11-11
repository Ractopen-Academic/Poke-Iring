import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/ai_config_service.dart';
import '../../domain/entities/cat_scan_result.dart';

/// Gemini-backed cat verifier.
///
/// This datasource NEVER fabricates a positive result. If the AI cannot be
/// reached (no key, no proxy, network/model error, malformed reply) the scan
/// is rejected with a clear [CatScanResult.rejectionReason] so no Paw Points
/// are awarded for unverified photos.
class GeminiVisionDataSource {
  /// Stable, vision-capable model. Override at build time with
  /// `--dart-define=GEMINI_VISION_MODEL=...` if needed.
  static const String defaultModel = String.fromEnvironment(
    'GEMINI_VISION_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  /// Minimum model confidence required to accept a photo as a cat.
  static const double minCatConfidence = 0.70;

  static const String unavailableReason =
      'AI verification unavailable. Configure a Gemini key or Vision Proxy '
      'to verify sightings.';
  static const String failedReason =
      'AI verification failed. Please check your connection and try again.';

  static const String visionPrompt = '''
You are a strict image verifier for the Poke: Iring cat-spotting game.
Players earn real rewards, so be skeptical and never guess.

Decide whether a REAL, LIVE domestic cat (Felis catus) is clearly visible in this photo.

Set "is_cat" to false when ANY of these apply:
- No cat is visible (people, faces, selfies, dogs, other animals, objects, scenery).
- The "cat" is a drawing, cartoon, toy, plush, statue, sticker, print, or a photo of a screen/monitor.
- The image is too dark, blurry, or cropped to be sure.
- Wild big cats (lion, tiger, leopard) - only domestic cats count.

Return ONLY valid JSON with this exact structure:
{
  "is_cat": true,
  "confidence": 0.98,
  "reason": "Short explanation of what is in the image.",
  "breed": "Uncategorized",
  "coat_pattern": "Calico",
  "dominant_color": "Orange and White",
  "rarity_multiplier": 1.4,
  "pattern_bonus_pts": 35,
  "quirk": "Majestic street guardian observing the neighborhood from a sunny brick stoop.",
  "box_2d": [180, 220, 840, 780]
}

Guidelines:
- "confidence": 0.0-1.0, your certainty that a real domestic cat is present.
- "reason": always fill this in, especially when "is_cat" is false (e.g. "Photo shows a person, no cat").
- "breed": If purebred with unmistakable distinctive breed characteristics (e.g. "Siamese", "Persian", "Bengal", "British Shorthair", "Ragdoll", "Scottish Fold", "Russian Blue", "Maine Coon", "Sphynx"), return that specific breed name. If it is a street cat, stray, mixed breed, or ordinary cat, ALWAYS return "Uncategorized". Do NOT return "Domestic Shorthair (Puspin)" unless explicitly verified. Never guess or default to Puspin. The strict default is "Uncategorized".
- "coat_pattern": "Calico", "Tuxedo", "Orange Tabby", "Brown Tabby", "Tortoiseshell", "Solid Black", "Solid White", "Bicolor", or "Colorpoint".
- "rarity_multiplier": 1.0 (common), 1.2-1.5 (distinctive markings like Calico, Tuxedo), 1.6-2.0 (rare or purebred).
- "pattern_bonus_pts": 10 to 40.
- "box_2d": [ymin, xmin, ymax, xmax] integers normalized 0-1000 for the primary cat, or null if no cat.
- "quirk": one charming explorer-journal sentence about what the cat is doing (empty string if no cat).
''';

  final AiConfigService _configService;
  final http.Client _httpClient;
  final String _modelName;
  final Future<String?> Function() _idTokenProvider;
  final bool allowDefaultProxy;

  GeminiVisionDataSource({
    AiConfigService? configService,
    http.Client? httpClient,
    String? modelName,
    Future<String?> Function()? idTokenProvider,
    this.allowDefaultProxy = true,
  }) : _configService = configService ?? AiConfigService.instance,
       _httpClient = httpClient ?? http.Client(),
       _modelName = modelName ?? defaultModel,
       _idTokenProvider = idTokenProvider ?? _firebaseIdToken;

  /// Firebase ID token of the signed-in user, sent to the Vision proxy so the
  /// server can reject anonymous callers. Null if Firebase/user unavailable.
  static Future<String?> _firebaseIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<CatScanResult> analyzeCatPhoto(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      return CatScanResult.notACat('Empty image. Please retake the photo.');
    }

    // 1. User's personal API key is prioritized first if they configured one.
    final personalKey = await _configService.getApiKey();
    if (personalKey != null && personalKey.isNotEmpty) {
      final directResult = await _analyzeViaDirectKey(personalKey, imageBytes);
      if (directResult != null) {
        return applyConfidenceGate(directResult);
      }
      debugPrint('Personal Gemini key failed or errored; falling back to Vision proxy.');
    }

    // 2. Vision proxy (routes via Vercel server proxy with zero user configuration needed).
    final proxyUrl = await _configService.getProxyUrl(allowDefault: allowDefaultProxy);
    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      final result = await _analyzeViaProxy(proxyUrl, imageBytes);
      if (result != null) return applyConfidenceGate(result);
      debugPrint('Vision proxy unavailable.');
    }

    // 3. Fallback when neither personal key nor vision proxy succeeded
    if (personalKey == null) {
      debugPrint('No personal Gemini key configured and proxy unavailable. Scan rejected.');
      return CatScanResult.notACat(unavailableReason);
    }

    return CatScanResult.notACat(failedReason);
  }

  Future<CatScanResult?> _analyzeViaDirectKey(
    String apiKey,
    Uint8List imageBytes,
  ) async {
    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
        httpClient: _httpClient,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          responseMimeType: 'application/json',
        ),
      );

      final response = await model
          .generateContent([
            Content.multi([
              TextPart(visionPrompt),
              DataPart(detectMimeType(imageBytes), imageBytes),
            ]),
          ])
          .timeout(const Duration(seconds: 45));

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const FormatException('Empty response from Gemini Vision');
      }
      return parseModelJson(text);
    } catch (e) {
      debugPrint('Direct Gemini Vision inference failed: $e');
      return null;
    }
  }

  /// Rejects positive results the model is not confident about.
  @visibleForTesting
  static CatScanResult applyConfidenceGate(CatScanResult result) {
    if (result.isCat && result.confidence < minCatConfidence) {
      return CatScanResult.notACat(
        'Not sure this is a cat '
        '(${(result.confidence * 100).round()}% confidence). '
        'Try a clearer, closer photo.',
      );
    }
    return result;
  }

  /// Parses model output, tolerating ```json fences.
  @visibleForTesting
  static CatScanResult parseModelJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
          .replaceFirst(RegExp(r'```\s*$'), '')
          .trim();
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('Vision response is not a JSON object');
    }
    return CatScanResult.fromJson(Map<String, dynamic>.from(decoded));
  }

  @visibleForTesting
  static String detectMimeType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<CatScanResult?> _analyzeViaProxy(
    String proxyUrl,
    Uint8List imageBytes,
  ) async {
    try {
      final idToken = await _idTokenProvider();
      final response = await _httpClient
          .post(
            Uri.parse(proxyUrl),
            headers: {
              'Content-Type': 'application/json',
              if (idToken != null && idToken.isNotEmpty)
                'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'imageBase64': base64Encode(imageBytes),
              'mimeType': detectMimeType(imageBytes),
            }),
          )
          .timeout(const Duration(seconds: 50));

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonMap['ok'] == true && jsonMap['data'] != null) {
          return CatScanResult.fromJson(
            Map<String, dynamic>.from(jsonMap['data'] as Map),
          );
        }
      }
      // Client-side problems (not signed in, image too large, rate limited)
      // are final: surface the server's message instead of retrying.
      if (const {401, 413, 429}.contains(response.statusCode)) {
        String message = 'Verification refused (${response.statusCode}).';
        try {
          final err = (jsonDecode(response.body) as Map)['error'];
          if (err is String && err.isNotEmpty) message = err;
        } catch (_) {}
        return CatScanResult.notACat(message);
      }
    } catch (e) {
      debugPrint('Error invoking vision proxy at $proxyUrl: $e');
    }
    return null;
  }
}
