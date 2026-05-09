import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/avatar_upload_service.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

ApiService _fakeApi(Map<String, dynamic> ticketResponse) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: ticketResponse,
      ));
    },
  ));
  return ApiService(
      baseUrl: 'https://example.test', dio: dio, initializeCache: false);
}

/// Minimal XFile backed by in-memory bytes.
class _ByteXFile extends XFile {
  final Uint8List _bytes;
  _ByteXFile(this._bytes, {String name = 'avatar.jpg'})
      : super('fake/$name', name: name);

  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}

final _sampleFile =
    _ByteXFile(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])); // JPEG header

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const presignedUrl = 'https://minio.example.com/bucket/avatar.jpg?sig=abc';
  const publicUrl = 'https://cdn.example.com/avatars/user-1/avatar.jpg';

  test('successful upload returns publicUrl from ticket response', () async {
    final httpClient = MockClient((_) async => http.Response('', 200));

    final service = AvatarUploadService(
      _fakeApi({'uploadUrl': presignedUrl, 'publicUrl': publicUrl}),
      httpClient: httpClient,
    );

    final result = await service.uploadAvatar(file: _sampleFile);
    expect(result, publicUrl);
  });

  test('backward compat: uses avatarUrl when publicUrl absent', () async {
    const legacyUrl = 'https://cdn.example.com/avatars/user-1/legacy.jpg';
    final httpClient = MockClient((_) async => http.Response('', 200));

    final service = AvatarUploadService(
      _fakeApi({'uploadUrl': presignedUrl, 'avatarUrl': legacyUrl}),
      httpClient: httpClient,
    );

    final result = await service.uploadAvatar(file: _sampleFile);
    expect(result, legacyUrl);
  });

  test('throws exception when uploadUrl is empty', () async {
    final service = AvatarUploadService(
      _fakeApi({'uploadUrl': '', 'publicUrl': publicUrl}),
    );

    await expectLater(
      service.uploadAvatar(file: _sampleFile),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'message',
        contains('no upload URL'),
      )),
    );
  });

  test('throws exception when PUT returns non-2xx status', () async {
    final httpClient = MockClient((_) async => http.Response('Error', 500));

    final service = AvatarUploadService(
      _fakeApi({'uploadUrl': presignedUrl, 'publicUrl': publicUrl}),
      httpClient: httpClient,
    );

    await expectLater(
      service.uploadAvatar(file: _sampleFile),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'message',
        contains('HTTP 500'),
      )),
    );
  });

  test('onProgress callback receives 0.1 then 1.0 on successful upload',
      () async {
    final httpClient = MockClient((_) async => http.Response('', 204));

    final service = AvatarUploadService(
      _fakeApi({'uploadUrl': presignedUrl, 'publicUrl': publicUrl}),
      httpClient: httpClient,
    );

    final progress = <double>[];
    await service.uploadAvatar(
      file: _sampleFile,
      onProgress: progress.add,
    );

    expect(progress, [0.1, 1.0]);
  });

  test('PUT request uses the correct Content-Type header', () async {
    String? capturedContentType;
    final httpClient = MockClient((req) async {
      capturedContentType = req.headers['Content-Type'];
      return http.Response('', 200);
    });

    final service = AvatarUploadService(
      _fakeApi({'uploadUrl': presignedUrl, 'publicUrl': publicUrl}),
      httpClient: httpClient,
    );

    await service.uploadAvatar(
      file: _sampleFile,
      contentType: 'image/png',
    );

    expect(capturedContentType, 'image/png');
  });
}
