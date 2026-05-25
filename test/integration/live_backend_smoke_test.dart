import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  final email = Platform.environment['SYNAPTIX_TEST_EMAIL'];
  final password = Platform.environment['SYNAPTIX_TEST_PASSWORD'];
  final webOrigin =
      Platform.environment['SYNAPTIX_WEB_ORIGIN'] ?? 'http://localhost:63033';
  final localBaseUrl =
      Platform.environment['SYNAPTIX_API_BASE_URL'] ?? 'http://localhost:5000';
  final stagingBaseUrl = Platform.environment['SYNAPTIX_STAGING_API_BASE_URL'];
  final hasCredentials = email != null &&
      email.isNotEmpty &&
      password != null &&
      password.isNotEmpty;
  final skipReason = hasCredentials
      ? false
      : 'Set SYNAPTIX_TEST_EMAIL and SYNAPTIX_TEST_PASSWORD to run live backend smoke tests.';

  group(
    'local Docker backend smoke',
    () {
      _registerSmokeTests(
        label: 'local',
        baseUrl: localBaseUrl,
        webOrigin: webOrigin,
        email: email,
        password: password,
      );
    },
    skip: skipReason,
  );

  group(
    'staging backend smoke',
    () {
      if (stagingBaseUrl == null || stagingBaseUrl.isEmpty) {
        test('skips when SYNAPTIX_STAGING_API_BASE_URL is absent', () {
          markTestSkipped('SYNAPTIX_STAGING_API_BASE_URL is not configured.');
        });
        return;
      }

      _registerSmokeTests(
        label: 'staging',
        baseUrl: stagingBaseUrl,
        webOrigin: webOrigin,
        email: email,
        password: password,
      );
    },
    skip: skipReason,
  );
}

void _registerSmokeTests({
  required String label,
  required String baseUrl,
  required String webOrigin,
  required String? email,
  required String? password,
}) {
  test('auth, wallet, and Spin & Earn endpoints are reachable', () async {
    final client = http.Client();
    final target = _LiveTarget(label: label, baseUrl: baseUrl);

    try {
      final preflight = await target.send(
        client,
        http.Request('OPTIONS', target.uri('/auth/login'))
          ..headers.addAll({
            'origin': webOrigin,
            'access-control-request-method': 'POST',
            'access-control-request-headers': 'content-type',
          }),
      );

      expect(
        preflight.statusCode,
        inInclusiveRange(200, 204),
        reason: 'OPTIONS /auth/login must allow Flutter web origin $webOrigin.',
      );
      final allowedOrigin =
          preflight.headers['access-control-allow-origin'] ?? '';
      expect(
        allowedOrigin == '*' || allowedOrigin == webOrigin,
        isTrue,
        reason:
            'CORS preflight must include Access-Control-Allow-Origin for $webOrigin.',
      );

      final login = await target.postJson(client, '/auth/login', {
        'email': email,
        'password': password,
        'deviceType': 'web',
        'deviceId': 'flutter-live-smoke',
      });

      expect(login.statusCode, inInclusiveRange(200, 299));
      final loginJson = _decodeObject(login);
      final accessToken = _findString(loginJson, const [
        'accessToken',
        'access_token',
        'token',
        'jwt',
      ]);
      final refreshToken = _findString(loginJson, const [
        'refreshToken',
        'refresh_token',
      ]);

      expect(
        accessToken,
        isNotNull,
        reason: 'Login response must include an access token.',
      );

      final authHeaders = {
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
      };

      final me = await target.get(client, '/users/me', headers: authHeaders);
      expect(me.statusCode, inInclusiveRange(200, 299));

      final wallet =
          await target.get(client, '/users/me/wallet', headers: authHeaders);
      expect(wallet.statusCode, inInclusiveRange(200, 299));
      final walletJson = _decodeObject(wallet);
      expect(walletJson['credits'], isA<num>());
      expect(walletJson['neuralXp'], isA<num>());
      expect(walletJson['synapseShards'], isA<num>());

      if (refreshToken != null && refreshToken.isNotEmpty) {
        final refresh = await target.postJson(client, '/auth/refresh', {
          'refreshToken': refreshToken,
          'deviceType': 'web',
          'deviceId': 'flutter-live-smoke',
        });
        expect(refresh.statusCode, inInclusiveRange(200, 299));
        expect(
          _findString(_decodeObject(refresh), const [
            'accessToken',
            'access_token',
            'token',
            'jwt',
          ]),
          isNotNull,
        );
      }

      final segments = await target.get(
        client,
        '/arcade/spin/segments',
        headers: authHeaders,
      );
      expect(segments.statusCode, inInclusiveRange(200, 299));
      expect(_decodeAny(segments), isNotNull);

      final claim = await target.postJson(
        client,
        '/arcade/spin/claim',
        {
          'playerId': _findString(loginJson, const ['userId', 'playerId']) ??
              'flutter-live-smoke',
          'segmentId': 'smoke-invalid-segment',
          'spinId':
              'smoke-invalid-spin-${DateTime.now().millisecondsSinceEpoch}',
        },
        headers: authHeaders,
      );
      expect(
        claim.statusCode,
        anyOf(
          inInclusiveRange(200, 299),
          400,
          404,
          409,
          422,
        ),
        reason:
            'Spin claim should either succeed for test-safe payloads or reject an invalid spin id through the confirmed route.',
      );

      final questionSet = await target.get(
        client,
        '/questions/set',
        queryParameters: const {'count': '5'},
        headers: authHeaders,
      );
      expect(questionSet.statusCode, inInclusiveRange(200, 299));
      final firstQuestion = _firstQuestion(_decodeAny(questionSet));
      expect(firstQuestion, isNotNull);
      final selectedOptionId = _firstOptionId(firstQuestion!);
      expect(selectedOptionId, isNotNull);

      final categorySet = await target.get(
        client,
        '/questions/set',
        queryParameters: const {
          'category': 'Science',
          'difficulty': 'Easy',
          'count': '5',
        },
        headers: authHeaders,
      );
      expect(categorySet.statusCode, inInclusiveRange(200, 299));

      final check = await target.postJson(
        client,
        '/questions/check',
        {
          'questionId': firstQuestion['id'] ?? firstQuestion['questionId'],
          'selectedOptionId': selectedOptionId,
        },
        headers: authHeaders,
      );
      expect(check.statusCode, inInclusiveRange(200, 299));
      expect(_decodeObject(check)['isCorrect'], isA<bool>());

      final batch = await target.postJson(
        client,
        '/questions/check-batch',
        {
          'answers': [
            {
              'questionId': firstQuestion['id'] ?? firstQuestion['questionId'],
              'selectedOptionId': selectedOptionId,
            }
          ],
        },
        headers: authHeaders,
      );
      expect(batch.statusCode, inInclusiveRange(200, 299));
      expect(_decodeAny(batch), isNotNull);
    } finally {
      client.close();
    }
  }, timeout: const Timeout(Duration(seconds: 45)));
}

class _LiveTarget {
  _LiveTarget({required this.label, required String baseUrl})
      : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final String label;
  final String baseUrl;

  Uri uri(String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> get(
    http.Client client,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) {
    final uri = queryParameters == null
        ? this.uri(path)
        : this.uri(path).replace(queryParameters: queryParameters);
    return send(
      client,
      http.Request('GET', uri)..headers.addAll(headers ?? {}),
    );
  }

  Future<http.Response> postJson(
    http.Client client,
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) {
    return send(
      client,
      http.Request('POST', uri(path))
        ..headers.addAll({
          HttpHeaders.contentTypeHeader: 'application/json',
          ...?headers,
        })
        ..body = jsonEncode(body),
    );
  }

  Future<http.Response> send(http.Client client, http.Request request) async {
    try {
      final streamed = await client.send(request).timeout(
            const Duration(seconds: 10),
          );
      return http.Response.fromStream(streamed);
    } on Object catch (error) {
      fail(
        'Configured $label backend $baseUrl is unreachable for '
        '${request.method} ${request.url.path}: $error',
      );
    }
  }
}

Object? _decodeAny(http.Response response) {
  if (response.body.isEmpty) return null;
  return jsonDecode(response.body);
}

Map<String, dynamic> _decodeObject(http.Response response) {
  final decoded = _decodeAny(response);
  expect(decoded, isA<Map>());
  return Map<String, dynamic>.from(decoded! as Map);
}

String? _findString(Object? node, List<String> keys) {
  if (node is Map) {
    for (final key in keys) {
      final value = node[key];
      if (value is String && value.isNotEmpty) return value;
    }
    for (final value in node.values) {
      final found = _findString(value, keys);
      if (found != null) return found;
    }
  }
  if (node is List) {
    for (final value in node) {
      final found = _findString(value, keys);
      if (found != null) return found;
    }
  }
  return null;
}

Map<String, dynamic>? _firstQuestion(Object? payload) {
  final items = payload is List
      ? payload
      : payload is Map
          ? payload['items'] ?? payload['questions'] ?? payload['data']
          : null;
  if (items is! List || items.isEmpty || items.first is! Map) return null;
  return Map<String, dynamic>.from(items.first as Map);
}

String? _firstOptionId(Map<String, dynamic> question) {
  final options = question['options'];
  if (options is! List || options.isEmpty) return null;
  final first = options.first;
  if (first is Map) {
    return (first['optionId'] ?? first['id'] ?? first['text'])?.toString();
  }
  return first?.toString();
}
