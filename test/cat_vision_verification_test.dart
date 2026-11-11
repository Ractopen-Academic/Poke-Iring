import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokeiring/core/services/ai_config_service.dart';
import 'package:pokeiring/features/scanner/data/datasources/gemini_vision_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline verification tests: the scanner must never award a cat result
/// unless the AI positively and confidently says so.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4]);
  final config = AiConfigService.instance;

  http.Response geminiReply(Map<String, dynamic> payload, {int status = 200}) {
    return http.Response(
      jsonEncode({
        'candidates': [
          {
            'content': {
              'role': 'model',
              'parts': [
                {'text': jsonEncode(payload)},
              ],
            },
            'finishReason': 'STOP',
            'index': 0,
          },
        ],
      }),
      status,
      headers: {'content-type': 'application/json'},
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await config.init();
    await config.clearApiKey();
    await config.clearProxyUrl();
  });

  test('no key and no proxy -> rejected, never a fake cat', () async {
    final ds = GeminiVisionDataSource(
      configService: config,
      httpClient: MockClient((_) async => fail('should not call network')),
      allowDefaultProxy: false,
    );
    final result = await ds.analyzeCatPhoto(jpegBytes);
    expect(result.isCat, isFalse);
    expect(result.totalPawPoints, 0);
    expect(result.rejectionReason, GeminiVisionDataSource.unavailableReason);
  });

  test('user API key is prioritized first before proxy', () async {
    await config.setApiKey('personal-gemini-key');
    await config.setProxyUrl('https://custom-proxy.internal/api/vision');

    bool directKeyCalled = false;
    final ds = GeminiVisionDataSource(
      configService: config,
      httpClient: MockClient((request) async {
        if (request.url.host.contains('googleapis')) {
          directKeyCalled = true;
          return geminiReply({
            'is_cat': true,
            'confidence': 0.99,
            'breed': 'Uncategorized',
            'coat_pattern': 'Calico',
            'dominant_color': 'Orange, White',
            'rarity_multiplier': 1.4,
            'pattern_bonus_pts': 20,
            'quirk': 'Prioritized personal key scan.',
          });
        }
        fail('Should not call proxy when personal user key is present');
      }),
    );

    final result = await ds.analyzeCatPhoto(jpegBytes);
    expect(result.isCat, isTrue);
    expect(directKeyCalled, isTrue);
    expect(result.breed, equals('Uncategorized'));
  });

  test('empty image -> rejected', () async {
    await config.setApiKey('test-key');
    final ds = GeminiVisionDataSource(
      configService: config,
      httpClient: MockClient((_) async => fail('should not call network')),
    );
    final result = await ds.analyzeCatPhoto(Uint8List(0));
    expect(result.isCat, isFalse);
  });

  test('photo of a person (model says no cat) -> rejected', () async {
    await config.setApiKey('test-key');
    late Uri calledUrl;
    final ds = GeminiVisionDataSource(
      configService: config,
      httpClient: MockClient((req) async {
        calledUrl = req.url;
        return geminiReply({
          'is_cat': false,
          'confidence': 0.99,
          'reason': 'Photo shows a smiling person, no cat present',
          'box_2d': null,
        });
      }),
    );
    final result = await ds.analyzeCatPhoto(jpegBytes);
    expect(calledUrl.path, contains(GeminiVisionDataSource.defaultModel));
    expect(result.isCat, isFalse);
    expect(result.totalPawPoints, 0);
    expect(result.rejectionReason, contains('person'));
  });

  test('low-confidence cat -> rejected by confidence gate', () async {
    await config.setApiKey('test-key');
    final ds = GeminiVisionDataSource(
      configService: config,
      httpClient: MockClient(
        (_) async => geminiReply({
          'is_cat': true,
          'confidence': 0.4,
          'breed': 'Domestic Shorthair (Puspin)',
          'coat_pattern': 'Brown Tabby',
        }),
      ),
    );
    final result = await ds.analyzeCatPhoto(jpegBytes);
    expect(result.isCat, isFalse);
    expect(result.rejectionReason, contains('40%'));
  });

  test('confident cat -> accepted with points', () async {
    await config.setApiKey('test-key');
    final ds = GeminiVisionDataSource(
      configService: config,
      httpClient: MockClient(
        (_) async => geminiReply({
          'is_cat': true,
          'confidence': 0.97,
          'breed': 'Domestic Shorthair (Puspin)',
          'coat_pattern': 'Tuxedo',
          'dominant_color': 'Black and White',
          'rarity_multiplier': 1.2,
          'pattern_bonus_pts': 25,
          'quirk': 'Napping on a jeepney hood.',
          'box_2d': [100, 100, 900, 900],
        }),
      ),
    );
    final result = await ds.analyzeCatPhoto(jpegBytes);
    expect(result.isCat, isTrue);
    expect(result.coatPattern, 'Tuxedo');
    expect(result.totalPawPoints, 90); // (50 + 25) * 1.2
  });

  test('Gemini HTTP error -> rejected, not mocked as cat', () async {
    await config.setApiKey('test-key');
    final ds = GeminiVisionDataSource(
      configService: config,
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 500, 'message': 'boom', 'status': 'INTERNAL'},
          }),
          500,
        ),
      ),
    );
    final result = await ds.analyzeCatPhoto(jpegBytes);
    expect(result.isCat, isFalse);
    expect(result.rejectionReason, GeminiVisionDataSource.failedReason);
  });

  test('garbage model output -> rejected', () async {
    await config.setApiKey('test-key');
    final ds = GeminiVisionDataSource(
      configService: config,
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'role': 'model',
                  'parts': [
                    {'text': 'Sure! I think it is a cat.'},
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    final result = await ds.analyzeCatPhoto(jpegBytes);
    expect(result.isCat, isFalse);
  });

  test('proxy receives Firebase ID token as Bearer auth', () async {
    await config.setProxyUrl('https://proxy.example/api/vision');
    String? auth;
    final ds = GeminiVisionDataSource(
      configService: config,
      idTokenProvider: () async => 'firebase-id-token-123',
      httpClient: MockClient((req) async {
        auth = req.headers['Authorization'];
        return http.Response(
          jsonEncode({
            'ok': true,
            'data': {'is_cat': false, 'reason': 'Photo shows a person'},
          }),
          200,
        );
      }),
    );
    final result = await ds.analyzeCatPhoto(jpegBytes);
    expect(auth, 'Bearer firebase-id-token-123');
    expect(result.isCat, isFalse);
  });

  test('proxy 401 (not signed in) -> rejected with server message', () async {
    await config.setProxyUrl('https://proxy.example/api/vision');
    final ds = GeminiVisionDataSource(
      configService: config,
      idTokenProvider: () async => null,
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'ok': false,
            'error': 'Sign in required to verify sightings.',
          }),
          401,
        ),
      ),
    );
    final result = await ds.analyzeCatPhoto(jpegBytes);
    expect(result.isCat, isFalse);
    expect(result.rejectionReason, 'Sign in required to verify sightings.');
  });

  test('proxy down and no key -> rejected', () async {
    await config.setProxyUrl('https://proxy.example/api/vision');
    final ds = GeminiVisionDataSource(
      configService: config,
      httpClient: MockClient((_) async => http.Response('down', 503)),
    );
    final result = await ds.analyzeCatPhoto(jpegBytes);
    expect(result.isCat, isFalse);
    expect(result.rejectionReason, GeminiVisionDataSource.unavailableReason);
  });

  test('parseModelJson tolerates markdown fences', () {
    final r = GeminiVisionDataSource.parseModelJson(
      '```json\n{"is_cat": false, "reason": "A dog"}\n```',
    );
    expect(r.isCat, isFalse);
    expect(r.rejectionReason, 'A dog');
  });

  test('detectMimeType sniffs png / webp / jpeg', () {
    expect(
      GeminiVisionDataSource.detectMimeType(
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0]),
      ),
      'image/png',
    );
    expect(
      GeminiVisionDataSource.detectMimeType(
        Uint8List.fromList(utf8.encode('RIFF\x00\x00\x00\x00WEBP')),
      ),
      'image/webp',
    );
    expect(GeminiVisionDataSource.detectMimeType(jpegBytes), 'image/jpeg');
  });
}
