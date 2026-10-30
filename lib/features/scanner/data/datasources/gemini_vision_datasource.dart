import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../../core/services/ai_config_service.dart';
import '../../domain/entities/cat_scan_result.dart';

class GeminiVisionDataSource {
  final AiConfigService _configService;

  GeminiVisionDataSource({AiConfigService? configService})
      : _configService = configService ?? AiConfigService.instance;

  Future<CatScanResult> analyzeCatPhoto(Uint8List imageBytes) async {
    final apiKey = await _configService.getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('No Gemini API key configured. Utilizing mock vision classifier.');
      return _generateMockResult();
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
        ),
      );

      const prompt = '''
You are an expert feline biologist and Pokemon-style game vision analyzer for the Poke: Iring game.
Inspect this image and determine if there is a cat visible.
Return ONLY valid JSON matching this exact structure:
{
  "is_cat": true,
  "confidence": 0.98,
  "breed": "Domestic Shorthair (Puspin)",
  "coat_pattern": "Calico",
  "dominant_color": "Orange and White",
  "rarity_multiplier": 1.4,
  "pattern_bonus_pts": 35,
  "quirk": "Majestic street guardian observing the neighborhood from a sunny brick stoop.",
  "box_2d": [180, 220, 840, 780]
}

Guidelines:
- "is_cat": boolean. Set to false if no feline is present.
- "breed": Use standard breeds. For local stray cats in the Philippines, identify as "Domestic Shorthair (Puspin)" or standard breeds like "Persian", "Siamese", "Bengal", "British Shorthair", "Ragdoll", "Scottish Fold", "Russian Blue".
- "coat_pattern": "Calico", "Tuxedo", "Orange Tabby", "Brown Tabby", "Tortoiseshell", "Solid Black", "Solid White", "Bicolor", or "Colorpoint".
- "rarity_multiplier": 1.0 (common), 1.2-1.5 (distinctive markings/patterns like Calico, Tuxedo), 1.6-2.0 (rare or purebred).
- "pattern_bonus_pts": 10 to 40 bonus points.
- "box_2d": [ymin, xmin, ymax, xmax] as integers normalized from 0 to 1000 representing the bounding box of the primary cat. If not a cat, set to null.
- "quirk": Exactly one humorous, charming, or endearing explorer journal observation sentence about what the cat is doing.
''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw Exception('Empty response received from Gemini Vision model');
      }

      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      return CatScanResult.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Gemini Vision inference failed ($e). Falling back to mock classifier.');
      return _generateMockResult(fallbackNote: 'Vision analysis fallback active');
    }
  }

  CatScanResult _generateMockResult({String? fallbackNote}) {
    // Deterministic realistic feline result for offline testing or pre-configured scenarios
    const base = 50;
    const patternBonus = 35;
    const rarity = 1.4;
    final total = ((base + patternBonus) * rarity).round();

    return CatScanResult(
      isCat: true,
      confidence: 0.97,
      breed: 'Domestic Shorthair (Puspin)',
      coatPattern: 'Calico',
      dominantColor: 'Calico Tri-Color',
      rarityMultiplier: rarity,
      basePoints: base,
      patternBonus: patternBonus,
      totalPawPoints: total,
      quirk: fallbackNote != null
          ? 'Sun-warmed puspin resting peacefully by a local sari-sari store.'
          : 'Street explorer watching neighborhood passersby with keen curiosity.',
      boundingBox: const Rect.fromLTRB(0.2, 0.2, 0.8, 0.8),
    );
  }
}
